@tool
extends StatusEffect
class_name StatusAutoMove

@export var gag: ToonAttack
@export var idx: int = 0

func apply() -> void:
	manager.s_round_started.connect(round_started)

func cleanup() -> void:
	if manager.s_round_started.is_connected(round_started):
		manager.s_round_started.disconnect(round_started)

func round_started(actions: Array[BattleAction]) -> void:
	pass
	#var new_gag: ToonAttack = gag.duplicate(true)
	#new_gag.targets = [target]
	#new_gag.user = Util.get_player()
	#var action_index := find_inject_pos(actions)
	
	#manager.inject_battle_action(new_gag, action_index)

func find_inject_pos(actions: Array[BattleAction]) -> int:
	var action_index := 0
	var found_player := false
	while action_index < actions.size():
		var action: BattleAction = actions[action_index]
		if action is ToonAttack:
			found_player = true
		if action is CogAttack and found_player:
			break
		action_index += 1
	if found_player == false:
		action_index = 0
		while action_index < actions.size() and BattleAction.ActionTag.PRIORITY_ACTION in actions[action_index].action_tags:
			action_index += 1
	return action_index

func get_icon() -> Texture2D:
	return gag.icon

func get_status_name() -> String:
	return "Auto Move"

func get_description() -> String:
	return "Will be hit by %s\nDamage: %s" % [gag.action_name, gag.get_true_damage(1.0, 0)]
