extends ItemScript

var current_battle: BattleManager
var round_limit := 3
var stacks: int:
	set(x):
		stacks = x
		if item is Item:
			item.arbitrary_data["stacks"] = stacks
var streak_bonus := 6

var item: Item

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_start)

func on_battle_start(manager: BattleManager) -> void:
	current_battle = manager
	manager.s_battle_ended.connect(on_battle_ended.bind(manager))
	manager.s_round_started.connect(on_round_start.bind(manager))
	
func on_battle_ended(manager: BattleManager) -> void:
	resolve_hype(manager.current_round)
		
func resolve_hype(current_round: int) -> void:
	var result = current_round <= round_limit
	print("Hype: " + str(result))
	var popup_message := ""
	var player = Util.get_player()
	
	if result:
		popup_message += "Hype Train"
		stacks += round_limit - current_round + 1
		print("Hype Streak: " + str(stacks))
		for i in stacks:
			popup_message += "!"
		var bonus := floori((stacks * streak_bonus) / 100)
		bonus += int(RandomService.randi_channel('true_random') % 100 < (stacks * streak_bonus))
		if bonus > 1:
			popup_message += " (x" + str(1 + bonus) + ")"
		player.stats.gag_vouchers["Sound"] += 1 + bonus
	else:
		stacks = 0
		popup_message += "Influence Reset"
	player.boost_queue.queue_text(popup_message, Color.MEDIUM_PURPLE)

func on_round_start(_actions: Array[BattleAction], manager: BattleManager) -> void:
	manager.s_round_started.disconnect(on_round_start)
	manager.s_action_added.connect(on_action_added.bind(manager))
	manager.s_round_ended.connect(on_round_ended.bind(manager))

func on_action_added(action: BattleAction, manager: BattleManager) -> void:
	pass
	#if action.user is Cog:
		#manager.round_actions.erase(action)

func on_round_ended(manager: BattleManager) -> void:
	if manager.s_action_added.is_connected(on_action_added):
		manager.s_action_added.disconnect(on_action_added)

func on_collect(_item: Item, _model: Node3D) -> void:
	item = _item
	stacks = item.arbitrary_data["stacks"]
	setup()

func on_load(_item: Item) -> void:
	on_collect(_item, null)
