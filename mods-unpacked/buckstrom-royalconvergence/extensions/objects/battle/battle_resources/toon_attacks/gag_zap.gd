extends ToonAttack

@export var model: PackedScene
@export var position: Vector3
@export var rotation: Vector3
@export var scale := Vector3(1,1,1)

@export var anim_delay := 1.9

@export var sfx_windup: AudioStream
@export var sfx_blast: AudioStream

var zap_jumps = 2
var jump_range = 2
var jump_decay = -0.25
var direction := -1

var do_knockback := false
var status_jumped_path := "res://mods-unpacked/buckstrom-royalconvergence/zap/status_effect_zap_jumped.tres"

func action():
	# Play the movie's sfx
	sfx_track()
	
	# Begin
	if is_instance_valid(main_target):
		user.face_position(main_target.global_position)
	else:
		user.face_position(manager.battle_node.global_position)
	user.set_animation('shout')
	manager.s_focus_char.emit(user)
	
	# Add the megaphone
	var megaphone: Node3D = load("res://models/props/gags/megaphone/megaphone.tscn").instantiate()
	user.toon.right_hand_bone.add_child(megaphone)
	megaphone.rotation_degrees += Vector3(0.0, 180.0, 0.0)
	
	# Add gag to megaphone
	var gag = model.instantiate()
	megaphone.add_child(gag)
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
		var jumped_status: StatusEffect = load(status_jumped_path)
		#var rc_global = user.get_node("/root/ModLoader/buckstrom-royalconvergence/RCglobal")
		var animator_target: Cog = null
		# zap is single target but finds jump targets 
		#var zapped: Array[Cog]
		for target: Cog in targets:
			if not is_instance_valid(target):
				continue
			animator_target = target
			var search_indices: Array[int]
			for i in range(jump_range):
				search_indices.append((i + 1) * (direction))
				search_indices.append(-(i + 1) * (direction))
			var cog_index = manager.cogs.find(target)
			var jump_target := -1
			var jump_damage := 1.0
			var hit_targets: Dictionary[Cog, float] = {
				target: jump_damage
			}
			for j in range(zap_jumps):
				jump_damage += jump_decay
				for i in search_indices:
					var i_relative = i + cog_index
					if (i_relative < 0) or (i_relative >= manager.cogs.size()):
						continue
					var i_cog: Cog = manager.cogs[i_relative]
					if i_cog in hit_targets.keys():
						continue
					var _skip := false
					for se in manager.status_effects:
						if se.status_name == "Zap Jumped" and se.target == i_cog:
							_skip = true
					if _skip: continue
					jump_target = i_relative
					break
				if jump_target > -1:
					hit_targets.set(manager.cogs[jump_target], jump_damage)
					var new_status = jumped_status.duplicate()
					new_status.target = manager.cogs[jump_target]
					manager.add_status_effect(new_status)
					cog_index = jump_target
				else:
					break
			for hit_target in hit_targets.keys():
				print("RC Gag Zap: Hitting jump no. %s on Cog %s with %sx Damage" % [hit_targets.keys().find(hit_target), str(hit_target), str(hit_targets[hit_target])])
				if get_immunity(hit_target):
					manager.battle_text(hit_target, 'IMMUNE')
				else:
					manager.affect_target(hit_target, damage * hit_targets[hit_target])
				do_react_animation(hit_target)
			targets = hit_targets.keys()
		
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
	
	megaphone.queue_free()

func sfx_track():
	await manager.sleep(1.0)
	if sfx_windup:
		AudioManager.play_sound(sfx_windup)
	await manager.sleep(1.4)
	if sfx_blast:
		AudioManager.play_sound(sfx_blast, -6.0)

func get_stats() -> String:
	var string := "Damage: " + get_main_damage_str() + "\n"\
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

	string += "\nJumps: %s" % get_jump_damage_str()

	return string

func get_main_damage_str() -> String:
	return get_true_damage()

func get_jump_damage_str() -> String:
	return "%s, %s" % [get_true_damage(0.75), get_true_damage(0.5)]
	
func do_react_animation(target: Cog) -> void:
	if not target.lured or not do_knockback:
		target.set_animation('flailing')
		target.animator.seek(0.7)
		do_dizzy_stars(target)
	elif not get_immunity(target):
		manager.knockback_cog(target)
		do_dizzy_stars(target)
