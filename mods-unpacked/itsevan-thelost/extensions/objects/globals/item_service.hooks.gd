extends Node

func get_laff_rate() -> float:
	var player: Player = Util.get_player()
	
	if player.character.character_name == "The Lost":
		return 0.0
	
	return standard_laff_rate_calc()


const STARTING_LAFF := 30
const FLOOR_LAFF_INCREMENT := 14
const LIKELIHOOD_PER_POINT := 0.1
func standard_laff_rate_calc() -> float:
	if not is_instance_valid(Util.get_player()):
		return 0.0
	
	# Get the current laff total
	# Take player's max hp + all the other laff boost items in play
	var laff_total := Util.get_player().stats.max_hp
	for laff_boost : Item in ItemService.get_items_in_play("Laff Boost"):
		if laff_boost.stats_add.has('max_hp'):
			laff_total += laff_boost.stats_add['max_hp']
	
	# Get the laff goal
	var laff_goal := STARTING_LAFF + (FLOOR_LAFF_INCREMENT * Util.floor_number + 1)
	
	var goal_diff : = laff_goal - laff_total
	
	var laff_rate := clampf(goal_diff * LIKELIHOOD_PER_POINT, 0.0, 0.5)
	
	return laff_rate
