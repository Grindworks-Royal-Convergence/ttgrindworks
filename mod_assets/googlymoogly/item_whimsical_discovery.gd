extends ItemScript

# - Each round, another gag above the current level becomes available for +2 point cost on unlocked tracks
# - Defeating a Cog with a discovered Gag refunds its base cost

var level_boost := 1
var current_boost : int
var actual_levels : Dictionary
var new_gags : Array
const COLOR_REACH = Color('777777')
var price_mod := 2

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_round_ended.connect(on_round_reset)
	BattleService.s_battle_started.connect(on_battle_start)

## Level up the gag tracks
func on_battle_start(manager: BattleManager) -> void:
	current_boost = 0
	actual_levels = {}
	new_gags = []
	await manager.s_ui_initialized
	initialize_ui(manager)

func initialize_ui(manager: BattleManager) -> void:
	var ui := manager.battle_ui
	for element: Control in ui.gag_tracks.get_children():
		actual_levels[element.track.track_name] = element.unlocked
		#element.s_refreshing.connect(on_track_refresh)
		element.refresh()
	
	# Also run the round reset method for this first round
	on_round_reset(manager)

func on_track_refresh(element: Control) -> void:
	pass
	#var unlocked: int = element.unlocked
	#if unlocked > 0:
		#element.gags = element.gags.slice(0,unlocked)
		#element.gags.shuffle()

## Unlocks the track
func on_round_reset(manager: BattleManager) -> void:
	var ui := manager.battle_ui
	current_boost += level_boost
	for element: Control in ui.gag_tracks.get_children():
		var actual_level = actual_levels[element.track.track_name]
		if manager.cogs.size() > 0:
			if actual_level > 0 and element.unlocked < 7:
				element.unlocked = actual_level + current_boost
				for i in range(actual_level, actual_level + current_boost):
					var button = element.gag_buttons[i]
					button.show()
					button.default_color = COLOR_REACH
					var gag = element.gags[i]
					if gag not in new_gags:
						gag.price_mod += price_mod
						new_gags.append(gag)
					element.refresh()
		else:
			element.unlocked = actual_level
			for i in range(actual_level, actual_level + current_boost):
				element.gags[i].price_mod = 0
