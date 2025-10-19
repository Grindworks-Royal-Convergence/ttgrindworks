extends Node

func emit_gag(chain: ModLoaderHookChain, gag: ToonAttack, price: int):
	var main_node := chain.reference_object as TrackElement
	var newgag := gag.duplicate(true)
	newgag.track = main_node.track
	if not Util.get_player().gags_cost_beans:
		Util.get_player().stats.gag_balance[main_node.track.track_name] -= price
	else:
		Util.get_player().stats.money -= price
	main_node.refresh()
	main_node.ui_root.s_gag_pressed.emit(newgag)
	newgag.price = price
