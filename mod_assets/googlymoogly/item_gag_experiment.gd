extends ItemScript

# This item runs a x second battle timer on every round
# And shuffles the order of gags on the menu

## Battle Timer created by Util
var timer: GameTimer

var do_refresh : bool

var level_boost := 1
var current_boost : int
var actual_levels : Dictionary
var modded_gags : Array
@onready var COLOR_REACH = Color('a3dbad').darkened(0.1)
var price_mod := 2
var discount := 0

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	do_refresh = true
	BattleService.s_round_ended.connect(on_round_reset)
	BattleService.s_battle_started.connect(on_battle_start)

## Connect the gag track elements up to be shuffled
func on_battle_start(manager: BattleManager) -> void:
	current_boost = 0
	actual_levels = {}
	modded_gags = []
	
	#manager.battle_stats[Util.get_player()].gag_discount -= discount
	await manager.s_ui_initialized
	initialize_ui(manager)

func initialize_ui(manager: BattleManager) -> void:
	var ui := manager.battle_ui
	for element: Control in ui.gag_tracks.get_children():
		actual_levels[element.track.track_name] = element.unlocked
		element.s_refreshing.connect(on_track_refresh)
	
	# Also run the round reset method for this first round
	on_round_reset(manager)

func on_track_refresh(element: Control) -> void:
	if !do_refresh:
		return
	var unlocked: int = element.unlocked
	if unlocked > 0:
		element.gags = element.gags.slice(0,unlocked)
		element.gags.shuffle()

## Shuffles the gag order of each track at the start of the round
func on_round_reset(manager: BattleManager) -> void:
	var ui := manager.battle_ui
	do_refresh = true
	for gag in modded_gags:
		gag.price_mod = 0
	modded_gags = []
	current_boost += level_boost
	for element: Control in ui.gag_tracks.get_children():
		var actual_level = actual_levels[element.track.track_name]
		if manager.cogs.size() > 0 and actual_level > 0 and element.unlocked < 7:
			element.unlocked = actual_level + current_boost
			for i in element.unlocked:
				element.gag_buttons[i].default_color = Globals.COLOR_GAG_BUTTON
				if i in range(actual_level, actual_level + current_boost):
					element.gag_buttons[i].show()
					var gag = element.gags[i]
					if gag not in modded_gags:
						gag.price_mod += price_mod
						modded_gags.append(gag)
					element.refresh()
					var modded_button = element.gag_buttons[gag.button_position]
					modded_button.default_color = COLOR_REACH
	do_refresh = false
