extends ItemScript

#const DROP_GAGS := preload("res://objects/battle/battle_resources/gag_loadouts/gag_tracks/drop.tres")
const AUTO_MOVE := preload("res://mods-unpacked/buckstrom-kptc_otto/extensions/objects/battle/battle_resources/status_effects/resources/auto_move.tres")
const OTTO_SELECTED_GAG := preload("res://mods-unpacked/buckstrom-kptc_otto/extensions/objects/battle/battle_ui/selected_gag_otto.tscn")
const OTTO_TARGET_SELECT := preload("res://mods-unpacked/buckstrom-kptc_otto/extensions/objects/battle/battle_ui/target_select_otto.tscn")

var player: Player
var manager: BattleManager

var outgoing_gags: Array[ToonAttack] = []
var overrides: Array[Vector2i] = []
var override_prices: Array[int] = []
var rolled_targets: Array[int] = []
var rolled_gags: Dictionary[ToonAttack, int] = {}
var statuses: Array[StatusEffect] = []
var target_select: Node

var jackpot := false

signal s_auto_move_created(move)

func on_collect(_item: Item, _object: Node3D) -> void:
	var _player: Player
	if not Util.get_player():
		_player = await Util.s_player_assigned
	else:
		_player = Util.get_player()
	setup(_player)

func on_load(item: Item) -> void:
	on_collect(item, null)

func setup(_player: Player) -> void:
	# OTTO ONLINE
	get_node("/root/ModLoader/buckstrom-kptc_otto/KPTCglobal").otto_boost = self
	print("OTTO ONLINE")
	player = _player
	BattleService.s_battle_started.connect(battle_started)
	BattleService.s_round_ended.connect(new_round)
	
func battle_started(_manager: BattleManager) -> void:
	manager = _manager
	#manager.battle_stats[player].turns *= 2
	
	outgoing_gags.clear()
	rolled_gags.clear()
	rolled_targets.clear()
	overrides.clear()
	jackpot = false
	
	await manager.s_ui_initialized
	target_select = OTTO_TARGET_SELECT.instantiate()
	manager.battle_ui.add_child(target_select)
	target_select.hide()
	
	var gag_order_menu: Control = manager.battle_ui.gag_order_menu
	manager.battle_ui.gag_order_menu.panels.clear()
	manager.battle_ui.attack_label.hide()
	var i := 0
	manager.battle_ui.gag_order_menu.pivot_offset = Vector2(900.0, 96.0)
	manager.battle_ui.gag_order_menu.scale = Vector2(1.25, 1.25)
	for old_sg in manager.battle_ui.gag_order_menu.get_children():
		old_sg.queue_free()
		var otto_sg = OTTO_SELECTED_GAG.instantiate()
		manager.battle_ui.gag_order_menu.add_child(otto_sg)
		manager.battle_ui.gag_order_menu.panels.append(otto_sg)
	for otto_sg in manager.battle_ui.gag_order_menu.panels:
		for connection in otto_sg.mouse_entered.get_connections():
			otto_sg.mouse_entered.disconnect(connection.callable)
		for connection in otto_sg.mouse_exited.get_connections():
			otto_sg.mouse_exited.disconnect(connection.callable)
		otto_sg.get_node('GagIcon').mouse_entered.connect(gag_order_menu.hover_slot.bind(gag_order_menu.panels.find(otto_sg)))
		otto_sg.get_node('GagIcon').mouse_exited.connect(gag_order_menu.stop_hover)
		otto_sg.get_node("GeneralButton").pressed.connect(edit_auto_move.bind(i))
		#otto_sg.get_node("LetterLabel").text = char(65 + i)
		otto_sg.get_node("LetterLabel").text = str(i + 1)
		i += 1
	manager.battle_ui.gag_order_menu.gag_panel = manager.battle_ui.gag_order_menu.panels[0]
	s_auto_move_created.connect(new_move)
	await get_tree().process_frame
	new_gags()
	update_ui_gags()
	edit_auto_move(0)

func new_round(_manager: BattleManager) -> void:
	#apply_statuses()
	#for track: TrackElement in manager.battle_ui.gag_tracks.get_children():
	#	track.refresh()
	new_gags()
	#update_buttons(-1)
	if not manager.cogs:
		return
	await get_tree().process_frame
	update_ui_gags()
	edit_auto_move(0)

func new_gags() -> void:
	outgoing_gags.clear()
	rolled_gags.clear()
	rolled_targets.clear()
	overrides.clear()
	jackpot = false
	for i in range(manager.battle_stats[player].turns):
		manager.battle_ui.turn += 1
		new_gag()

func new_move(move) -> void:
	var count : int = manager.battle_ui.gag_order_menu.panels.size()
	await get_tree().process_frame
	var gag_order_menu = move.get_parent()
	move.get_node('GagIcon').mouse_entered.connect(gag_order_menu.hover_slot.bind(gag_order_menu.panels.find(move)))
	move.get_node('GagIcon').mouse_exited.connect(gag_order_menu.stop_hover)
	var button = move.get_node("GeneralButton")
	for connection in button.pressed.get_connections():
		button.pressed.disconnect(connection.callable)
	button.pressed.connect(edit_auto_move.bind(count))
	button.show()
	#move.get_node("LetterLabel").text = char(65 + i)
	move.get_node("LetterLabel").text = str(count + 1)
	new_gag()
	update_ui_gags()
	edit_auto_move(count)

func new_gag() -> void:
	var gag_and_lvl = get_random_gag_resource()
	var gag = gag_and_lvl[0]
	var lvl = gag_and_lvl[1]
	gag.user = player
	if manager.cogs:
		var cog: Cog = manager.cogs.pick_random()
		gag.targets = [cog]
		gag.main_target = cog
		if gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
			gag.reassess_splash_targets(manager.cogs.find(cog), manager)
		rolled_targets.append(manager.cogs.find(cog))
	rolled_gags.set(gag, lvl)
	outgoing_gags.append(gag)
	overrides.append(Vector2i(-1, -1))

func apply_statuses() -> void:
	for i in range(manager.battle_stats[player].turns):
		apply_status(i)

func apply_status(i: int) -> void:
	# Pick a random cog in the battle and apply the auto-gag status onto them.
	var new_status := AUTO_MOVE.duplicate(true)
	new_status.gag = ToonAttack.new()
	#var gag = rolled_gags.keys()[i]
	#new_status.gag = gag
	new_status.idx = i
	#var cog: Cog = gag.main_target
	#new_status.target = cog
	#manager.add_status_effect(new_status)

func update_statuses() -> void:
	var i = 0
	for status in statuses:
		#manager.expire_status_effect(status)
		var gag = outgoing_gags[i]
		status.gag = gag
		status.target = gag.main_target
		manager.add_status_effect(status)
		i += 1

func update_ui_gags() -> void:
	manager.battle_ui.selected_gags.clear()
	for idx in range(outgoing_gags.size()):
		var gag: ToonAttack = outgoing_gags[idx]
		manager.battle_ui.selected_gags.append(gag)
		var panel = manager.battle_ui.gag_order_menu.get_children()[idx]
		panel.get_node("TargetLabel").text = get_atk_string(idx)
		panel.get_node("RolledGagIcon").texture = rolled_gags.keys()[idx].icon
		panel.get_node("RolledTargetLabel").text = get_target_string(rolled_gags.keys()[idx])
	manager.battle_ui.gag_order_menu.refresh_gags(outgoing_gags)
	manager.battle_ui.s_gags_updated.emit(outgoing_gags)

func find_gag_vector(gag) -> Vector2i:
	var y := 0
	for track: TrackElement in manager.battle_ui.gag_tracks.get_children():
		var x := 0
		for button: GagButton in track.gag_buttons:
			if track.track == gag.track and x == rolled_gags[gag]:
				return Vector2i(x, y)
			x += 1
		y += 1
	return Vector2i(-1, -1)
	
func edit_auto_move(idx: int) -> void:
	print("Edit move! %d" % idx)
	var gag = rolled_gags.keys()[idx]
	var y := 0
	var vec = find_gag_vector(gag)
	for track: TrackElement in manager.battle_ui.gag_tracks.get_children():
		track.refresh()
		var x := 0
		for button: GagButton in track.gag_buttons:
			for connection in button.pressed.get_connections():
				button.pressed.disconnect(connection.callable)
			var price = 0
			if track.track == gag.track:
				if x > rolled_gags[gag]: price += x - rolled_gags[gag]
				else: price = 0
			else:
				price += (mini(abs(y - vec.y) - 1, 3))
			price = maxi(0, price - manager.battle_stats[player].gag_discount)
			button.set_count(price)
			var unlocked: int = track.unlocked
			if x < unlocked:
				var track_gag = get_gag(track, x)
				if track.is_gag_free(track_gag):
					price = 0
				#var lambda := func(ta: ToonAttack) -> ToonAttack:
				#	return ta.duplicate(true)
				if track.track == gag.track or x == rolled_gags[gag]:
					if track.track == gag.track and x == rolled_gags[gag]:
						price = 0
						button.set_count(price)
						button.pressed.connect(gag_selected.bind(track, track_gag, idx, Vector2i(-1, -1), price))
						#button.pressed.connect(gag_selected.bind(track, lambda.call(track.track.gags[x]), idx, Vector2i(-1, -1)))
					else:
						button.pressed.connect(gag_selected.bind(track, track_gag, idx, Vector2i(x, y), price))
						# button.pressed.connect(gag_selected.bind(track, lambda.call(track.track.gags[x]), idx, Vector2i(x, y)))
				track.gags[x].price = price
			x += 1
		y += 1
	update_buttons(idx)
		#track.refresh()
	pass

func get_gag(track: TrackElement, idx: int) -> ToonAttack:
	return track.gags[idx].duplicate(true)

func update_buttons(idx: int) -> void:
	var gag = rolled_gags.keys()[idx]
	var y := 0
	for track: TrackElement in manager.battle_ui.gag_tracks.get_children():
		var track_gags = track.gags.duplicate(true)
		var x := 0
		for button: GagButton in track.gag_buttons:
			if idx == -1 or x not in range(track_gags.size()):
				#button.disable()
				continue
			if track.track == gag.track or x == rolled_gags[gag]:
				var price_offset = 0
				if outgoing_gags[idx].track.track_name == track.track.track_name:
					price_offset = outgoing_gags[idx].price
				if track.should_disable(track_gags[x], track_gags[x].price - price_offset):
					button.disable()
				else:
					button.modulate = Color(1.0, 1.0, 1.0, 1.0)
					button.self_modulate = Color(0.0, 0.631, 1.0, 1.0)
					button.enable()
				button.count_label.visible = true
				if overrides[idx] == Vector2i(x, y):
					button.self_modulate = Color(0.399, 0.37, 0.684, 1.0)
				if track.track == gag.track and x == rolled_gags[gag]:
					if overrides[idx] == Vector2i(-1, -1):
						button.self_modulate = Color(0.205, 0.392, 0.203, 1.0)
					else:
						button.self_modulate = Color(0.514, 0.576, 0.282, 1.0)
			else:
				button.disable()
				button.modulate = Color(0.5, 0.5, 0.5, 1.0)
				button.self_modulate = Color(0.0, 0.0, 0.0, 0.4)
				button.count_label.visible = false
			x += 1
		y += 1

func override_gag(gag: ToonAttack, idx: int, coord: Vector2i) -> void:
	#gag.user = outgoing_gags[idx].user
	#gag.main_target = outgoing_gags[idx].main_target
	#gag.targets.clear()
	#if gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
	#	gag.reassess_splash_targets(manager.cogs.find(gag.main_target), manager)
	#else:
	#	gag.targets.append(gag.main_target)
	#if outgoing_gags[idx] == gag:
	#	return
	for track: TrackElement in manager.battle_ui.gag_tracks.get_children():
		if track.track.track_name == outgoing_gags[idx].track.track_name:
			refund_gag(outgoing_gags[idx], track)
	outgoing_gags[idx] = gag
	overrides[idx] = coord
	update_buttons(idx)
	update_ui_gags()
	update_statuses()

func get_random_gag_resource() -> Array:
	var tracks = [
		"squirt", "sound", "throw", "drop"
	]
	if !all_cogs_lured():
		tracks.append("lure")
	if !((all_cogs_lured() and Util.get_player().trap_needs_lure) or all_cogs_trapped()):
		tracks.append("trap")
	var track: String = RandomService.array_pick_random("auto_move", tracks)
	var track_resource = load('res://objects/battle/battle_resources/gag_loadouts/gag_tracks/%s.tres' % track) 
	var idx: int = 0
	# Min drop level works as follows:
	# 1 (flowerpot) on floors 0-2
	# 2 (sandbag) on floor 3
	# 3 (anvil) on floor 4
	# 4 (big weight) on floor 5 and directors
	var min_gag_level: int = max(0, Util.floor_number - 4)
	min_gag_level = mini(min_gag_level, 4)
	# Prevent range errors by making sure the max drop level is at least 1 higher than the min drop level
	var max_gag_level: int = max(min_gag_level, player.stats.gags_unlocked[track.capitalize()] - 1)
	if !jackpot and max_gag_level == 6:
		jackpot = RandomService.randf_channel("kptc_otto") < 0.1
		if jackpot:
			idx = max_gag_level
	else:
		idx = randi_range(min_gag_level, max_gag_level - 1)
	var gag: ToonAttack = track_resource.gags[idx].duplicate(true)
	gag.track = track_resource
	return [gag, idx]

func get_atk_string(idx: int) -> String:
	var atk_string: String = ""
	var gag = outgoing_gags[idx]
	# damage
	if gag is GagLure:
		atk_string += str(gag.lure_effect.get_true_knockback()) + " KB"
	else:
		atk_string += "-" + str(gag.get_true_damage())
	# target
	atk_string += "\n"
	if gag.main_target != manager.cogs[rolled_targets[idx]]:
		atk_string += "*"
	atk_string += get_target_string(gag)
	if gag.main_target != manager.cogs[rolled_targets[idx]]:
		atk_string += "*"
	# price
	atk_string += "\n%d PTS" % gag.price
	return atk_string

func get_target_string(gag: ToonAttack) -> String:
	var has_main_target: bool = gag.main_target != null
	var tgt_string = ""
	for cog in manager.cogs:
		if cog in gag.targets:
			tgt_string += "X" if ((not has_main_target) or (has_main_target and cog == gag.main_target)) else "x"
		else:
			tgt_string += "-"
		if manager.cogs.find(cog) < manager.cogs.size() - 1:
			tgt_string += ""
	return tgt_string

func all_cogs_trapped() -> bool:
	var all_trapped := true
	for cog in manager.cogs:
		if not cog.trap:
			all_trapped = false
			break
	return all_trapped
	
func all_cogs_lured() -> bool:
	var all_lured := true
	for cog in manager.cogs:
		if not cog.lured:
			all_lured = false
			break
	return all_lured

func gag_selected(track: TrackElement, _gag: BattleAction, idx: int, coord: Vector2i, price: int) -> void:
	# Un-preview gag
	var ui = manager.battle_ui
	ui.gag_hovered(null)
	var gag = _gag.duplicate(true)

	# Parse gag data
	gag.user = Util.get_player()
	gag.price = price
	gag.track = track.track
	# Infer target
	match gag.target_type:
		BattleAction.ActionTarget.SELF:
			gag.targets = [Util.get_player()]
		BattleAction.ActionTarget.ENEMY, BattleAction.ActionTarget.ENEMY_SPLASH:
			# Skip choice UI if only one Cog
			if manager.cogs.size() == 1:
				gag.targets = manager.cogs.duplicate(true)
				gag.main_target = gag.targets[0]
			else:
				# Swap UIs
				target_select.show()
				target_select.gag = gag
				if outgoing_gags[idx].track.track_name == track.track.track_name:
					target_select.price_offset = outgoing_gags[idx].price
				target_select.get_node("GagPointLabel").text = "Points: " + str(roundi(player.stats.gag_balance[track.track.track_name] + target_select.price_offset)) + '/' + str(roundi(player.stats.gag_cap))
				target_select.rolled_target = rolled_targets[idx]
				target_select.reposition_buttons(manager.cogs.size())
				ui.main_container.hide()
				var selection = await target_select.s_arrow_pressed_otto
				if selection[0] == -1:
					# Swap UIs back
					target_select.hide()
					ui.main_container.show()
					#ui.s_gag_canceled.emit(gag)
					return
				else:
					# Set the target
					gag.main_target = manager.cogs[selection[0]]
					gag.price = selection[1]
					if gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
						gag.reassess_splash_targets(selection[0], manager)
					else:
						gag.targets = [manager.cogs[selection[0]]]
					# Swap UIs back
					target_select.hide()
					ui.main_container.show()
		_:
			gag.targets = manager.cogs.duplicate(true)
	if not player.gags_cost_beans:
		player.stats.gag_balance[track.track.track_name] -= gag.price
	else:
		player.stats.money -= gag.price
	#manager.battle_ui.s_gag_pressed.emit(gag)
	track.point_label.text = "Points: " + str(roundi(player.stats.gag_balance[track.track.track_name])) + '/' + str(roundi(player.stats.gag_cap))
	override_gag(gag, idx, coord)

func refund_gag(gag: ToonAttack, track: TrackElement):
	if player.gags_cost_beans:
		player.stats.add_money(gag.price)
		return
	var new_balance: int = player.stats.gag_balance[track.track.track_name]
	new_balance = clamp(new_balance + gag.price, 0, player.stats.gag_cap)
	player.stats.gag_balance[track.track.track_name] = new_balance
	track.point_label.text = "Points: " + str(roundi(player.stats.gag_balance[track.track.track_name])) + '/' + str(roundi(player.stats.gag_cap))
