extends ItemScript

const LAFF_IT_UP := "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_overheal.gd"

var stat_mult: StatMultiplier
var mantle_up := true

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	# Set up our stat multiplier
	stat_mult = StatMultiplier.new()
	stat_mult.additive = true
	stat_mult.stat = 'evasiveness'
	stat_mult.amount = 0.0
	
	var player: Player = Util.get_player()
	player.stats.s_defense_changed.connect(on_defense_changed)
	on_defense_changed(player.stats.defense)
	player.stats.multipliers.append(stat_mult)
	player.stats.max_hp_changed.connect(on_max_hp_changed)
	
	BattleService.s_action_started.connect(on_action_started)
	BattleService.s_battle_ended.connect(func(): mantle_up = true)
	Util.s_floor_started.connect(on_floor_start)

func on_defense_changed(new_def: float) -> void:
	stat_mult.amount = new_def - 1.0

func on_max_hp_changed(new_hp: int) -> void:
	var player := Util.get_player()
	await get_tree().process_frame
	if not new_hp == 1:
		player.stats.max_hp = 1
		player.stats.hp = 1
		player.laff_meter.set_max_laff(1)

func on_action_started(action: BattleAction) -> void:
	if action is CogAttack and Util.get_player() in action.targets and mantle_up:
		action.accuracy = Globals.ACCURACY_GUARANTEE_MISS
		action.damage = 0
		mantle_up = false

func on_floor_start(gfloor: GameFloor) -> void:
	var mod_node: Node = gfloor.get_node('Modifiers')
	mod_node.child_entered_tree.connect(on_modifier_added)

func on_modifier_added(modifier: FloorModifier) -> void:
	if modifier.get_script().resource_path == LAFF_IT_UP:
		await Task.delay(1.0)
		modifier.raw_boost = 0
