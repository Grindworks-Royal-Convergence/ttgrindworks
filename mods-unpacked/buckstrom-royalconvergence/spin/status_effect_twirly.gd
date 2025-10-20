@tool
extends StatEffectRegeneration

var tick_adjacent_factor := 2.0
var tick_range := 1
var stat_boosts: Dictionary[String, float] = {
	"accuracy" = -0.30
}

var SpinUtil

func apply():
	var battle_stats: BattleStats = manager.battle_stats[target]
	for stat in stat_boosts.keys():
		if stat in battle_stats:
			battle_stats.set(stat,battle_stats.get(stat) + stat_boosts[stat])
	super()

func expire():
	var battle_stats: BattleStats = manager.battle_stats[target]
	for stat in stat_boosts.keys():
		if stat in battle_stats:
			battle_stats.set(stat,battle_stats.get(stat) - stat_boosts[stat])
	super()

func renew() -> void:
	# Don't do movie for dead actors
	if not is_instance_valid(target) or target.stats.hp <= 0:
		return
	var targets = [target]
	
	manager.battle_node.focus_character(target)
	if target is Player:
		target.set_animation('cringe')
		manager.affect_target(target, amount)
	if target is Cog:
		hit_cog_source(target, amount)
		SpinUtil.animate_target_spin(target)
		if tick_range > 0:
			for i in range(-tick_range, tick_range + 1):
				if i == 0: continue
				var i_relative: int = i + manager.cogs.find(target)
				var cog = manager.cogs.get(i_relative)
				if !is_instance_valid(cog): continue
				hit_cog_neighbor(cog, amount * tick_adjacent_factor)
				targets.append(cog)
	await manager.sleep(3.0)
	await manager.check_pulses(targets)

func hit_cog_neighbor(cog, damage) -> void:
	cog.set_animation('pie-small')
	manager.affect_target(cog, damage)
	do_dizzy_stars(target)

func hit_cog_source(cog, damage) -> void:
	cog.set_animation('soak')
	manager.affect_target(cog, damage)

func get_icon() -> Texture2D:
	return load("res://mods-unpacked/buckstrom-royalconvergence/spin/icon_twirly.png")

func get_status_name() -> String:
	return "Twirly"

func get_description() -> String:
	if not description == "":
		return description
	var _str: String = "At round end, take %d damage and deal %d damage to neighbors" % [amount, amount * tick_adjacent_factor]
	for stat in stat_boosts.keys():
		_str += "\n%s%% %s" % [str(ceili(stat_boosts[stat] * 100)), stat]
	return _str

func combine(effect: StatusEffect) -> bool:
	if effect.rounds == rounds:
		amount += effect.amount
		return true
	return false

func randomize_effect() -> void:
	super.randomize_effect()

func do_dizzy_stars(cog: Cog, time := 2.0) -> Node3D:
	var stars: Node3D = load("res://models/props/cog_props/stun_stars/stun_stars.tscn").instantiate()
	stars.delete_time = time
	cog.body.head_bone.add_child(stars)
	stars.rotation_degrees.x = 90.0
	return stars
