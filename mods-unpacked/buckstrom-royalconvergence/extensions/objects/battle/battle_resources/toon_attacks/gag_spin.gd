extends ToonAttack

@export var model: PackedScene
@export var position: Vector3
@export var rotation: Vector3
@export var scale := Vector3(1,1,1)

@export var anim_delay := 1.9

@export var sfx_windup: AudioStream
@export var sfx_blast: AudioStream

var animations: Dictionary[String, String] = {
}

var do_knockback := false
const DEBUFF := preload("res://mods-unpacked/buckstrom-royalconvergence/spin/status_effect_twirly.tres")

var tick_adjacent_factor := 2.0

var SpinUtil: Node

func action():
	SpinUtil = manager.get_node("/root/ModLoader/buckstrom-royalconvergence/SpinUtil")
	# Play the movie's sfx
	sfx_track()
	
	# Begin
	if is_instance_valid(main_target):
		user.face_position(main_target.global_position)
	else:
		user.face_position(manager.battle_node.global_position)
	var anim = 'shout'
	if action_name in animations: anim = animations[action_name]
	user.set_animation(anim)
	manager.s_focus_char.emit(user)
	
	# Add the megaphone
	#var megaphone: Node3D = load("res://models/props/gags/megaphone/megaphone.tscn").instantiate()
	#user.toon.right_hand_bone.add_child(megaphone)
	#megaphone.rotation_degrees += Vector3(0.0, 180.0, 0.0)
	
	# Add gag
	var gag = model.instantiate()
	user.toon.right_hand_bone.add_child(gag)
	#megaphone.add_child(gag)
	# Transform the model
	gag.position = position
	gag.rotation_degrees = rotation
	gag.scale = scale
	
	# Wait until sound plays
	await manager.sleep(anim_delay)
	#gag.get_node('AnimationPlayer').play('sound')
	
	# Wait until sound plays
	await manager.sleep(2.4 - anim_delay)
	manager.battle_node.focus_cogs()
	
	var hit := manager.roll_for_accuracy(self)
	
	if hit:
		#var rc_global = user.get_node("/root/ModLoader/buckstrom-royalconvergence/RCglobal")
		var animator_target: Cog = null
		
		for target in targets:
			target.set_animation('soak')
			if not get_immunity(target):
				var damage_dealt: int = manager.affect_target(target, damage)
				do_dizzy_stars(target)
				SpinUtil.animate_target_spin(target)
				apply_debuff(target, damage_dealt)
				await Task.delay(0.5)
				manager.battle_text(target, "Twirly!", BattleText.colors.orange[0], BattleText.colors.orange[1])
			else:
				manager.battle_text(target, "IMMUNE")
		
		if animator_target:
			await manager.barrier(animator_target.animator.animation_finished, 5.0)
		
		# Check if any cogs are lured, and unlure them
		var lured_targets: Array[Cog] = []
		for target in targets:
			if target.lured:
				lured_targets.append(target)
		if not lured_targets.is_empty():
			var unlure_tween: Tween = manager.create_tween()
			unlure_tween.set_parallel(true)
			for target in lured_targets:
				target.set_animation('walk')
				unlure_tween.tween_property(target.get_node('Body'),'position:z',0,1.0)
				manager.force_unlure(target)
			await unlure_tween.finished
			for target in lured_targets:
				target.set_animation('neutral')
		await manager.check_pulses(targets)
	else:
		for target in targets:
			manager.battle_text(target,"MISSED")
		await manager.sleep(1.0)
	
	if user.get_animation() == 'shout':
		await manager.barrier(user.animator.animation_finished, 4.0)
	
	gag.queue_free()

func sfx_track():
	await manager.sleep(1.0)
	if sfx_windup:
		AudioManager.play_sound(sfx_windup)
	await manager.sleep(1.4)
	if sfx_blast:
		AudioManager.play_sound(sfx_blast, -6.0)

func get_stats() -> String:
	var string := "Damage Over Time:\n%s Target, %s Adjacent\n" % [get_main_damage_str(), get_jump_damage_str()]\
	+ "Affects: "
	match target_type:
		ActionTarget.SELF:
			string += "Self"
		ActionTarget.ENEMIES:
			string += "All Cogs"
		ActionTarget.ENEMY:
			string += "One Cog"
		ActionTarget.ENEMY_SPLASH:
			string += "Three Cogs"

	string += "\nApplies: Accuracy Down"

	return string

func get_main_damage_str() -> String:
	return get_true_damage()

func get_jump_damage_str() -> String:
	return "%s" % get_true_damage(1.0 * tick_adjacent_factor)
	
func do_react_animation(target: Cog) -> void:
	if not target.lured or not do_knockback:
		target.set_animation('soak')
		#target.animator.seek(1.0)
		#target.animator.speed_scale = -1
		do_dizzy_stars(target)
	elif not get_immunity(target):
		manager.knockback_cog(target)
		do_dizzy_stars(target)

func apply_debuff(target: Cog, damage_dealt: int) -> void:
	var new_effect = DEBUFF.duplicate(true)
	new_effect.amount = roundi(damage_dealt * 0.5)
	new_effect.target = target
	new_effect.tick_adjacent_factor = tick_adjacent_factor
	new_effect.SpinUtil = manager.get_node("/root/ModLoader/buckstrom-royalconvergence/SpinUtil")
	#if user.stats.get_stat("drop_aftershock_round_boost") != 0:
	#	new_effect.rounds += user.stats.get_stat("drop_aftershock_round_boost")
	manager.add_status_effect(new_effect)
