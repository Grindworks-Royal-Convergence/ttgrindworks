extends TextureRect

const ARROW_NORM := preload("res://ui_assets/battle/target_select/PckMn_Arrow_Up.png")
const ARROW_RED := preload("res://ui_assets/battle/target_select/PckMn_Arrow_Up_RED.png")

# Child references
@onready var arrow := $Buttons/Arrows/ArrowButton

# Signals
signal s_arrow_pressed_otto(args: Array[int])

# Locals
var gag: ToonAttack
var rolled_target: int
var price_offset: int = 0

func reposition_buttons(cogs: int):
	for i in cogs:
		var difference = abs(i - rolled_target)
		var price = gag.price + difference
		var newbutton: GeneralButton
		if i == 0:
			newbutton = arrow
		else:
			newbutton = arrow.duplicate()
		var price_label = newbutton.get_node("CostLabel")
		var add_label = newbutton.get_node("AddLabel")
		%GagCostLabel.text = "Gag Cost: %d" % gag.price
		if price > 0:
			price_label.show()
			price_label.text = "%d" % price
		else:
			price_label.hide()
		if difference > 0:
			add_label.show()
			add_label.text = "+%d" % difference
		else:
			add_label.hide()
		$Buttons/Arrows.add_child(newbutton)
		newbutton.pressed.connect(arrow_pressed.bind(i, price))
		newbutton.mouse_entered.connect(on_arrow_hovered.bind(i))
		newbutton.mouse_exited.connect(on_arrow_unhovered.bind(i))
		newbutton.disabled = false
		
		var cog: Cog = get_parent().get_parent().cogs[i]
		if gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
			%TargetCenterLabel.text = "Which Cogs?"
		else:
			%TargetCenterLabel.text = "Which Cog?"
		if gag is LureFish and cog.lured:
			newbutton.disabled = true
		elif gag is GagTrap:
			if (Util.get_player().trap_needs_lure and cog.lured) or cog.trap:
				newbutton.disabled = true
			else:
				newbutton.disabled = false
		if Util.get_player().gags_cost_beans and (Util.get_player().stats.money + price_offset < price):
			newbutton.disabled = true
		elif not Util.get_player().gags_cost_beans and (Util.get_player().stats.gag_balance[gag.track.track_name] + price_offset < price):
			newbutton.disabled = true
		match newbutton.disabled:
			true:
				newbutton.self_modulate = Color(0.5, 0.5, 0.5, 1.0)
			false:
				newbutton.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	$GagPanel/GagImage.set_texture(gag.icon)
	$GagPanel.self_modulate = Globals.get_gag_color(gag)

func reset_buttons():
	for i in range($Buttons/Arrows.get_child_count()-1,0,-1):
		$Buttons/Arrows.get_child(i).queue_free()
	arrow.disconnect('pressed',arrow_pressed)
	arrow.mouse_entered.disconnect(on_arrow_hovered)
	arrow.mouse_exited.disconnect(on_arrow_unhovered)

func arrow_pressed(index : int, price : int):
	s_arrow_pressed_otto.emit([index, price])
	reset_buttons()

func on_arrow_hovered(index : int) -> void:
	if not gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
		return
	
	for button in get_neighbors(index):
		button.texture_normal = ARROW_RED

## Returns splash neighbors
func get_neighbors(index : int) -> Array[GeneralButton]:
	var neighbors : Array[GeneralButton] = []
	var button_container : HBoxContainer = $Buttons/Arrows
	
	if index == 0:
		var i := 1
		while i < button_container.get_child_count() and i < 3:
			neighbors.append(button_container.get_child(i))
			i += 1
	elif index == button_container.get_child_count() - 1:
		var i := button_container.get_child_count() - 2
		while i >= 0 and i > button_container.get_child_count() - 4:
			neighbors.append(button_container.get_child(i))
			i -= 1
	else:
		neighbors.append(button_container.get_child(index - 1))
		neighbors.append(button_container.get_child(index + 1))
	
	return neighbors

func on_arrow_unhovered(_index : int) -> void:
	for button : GeneralButton in $Buttons/Arrows.get_children():
		button.texture_normal = ARROW_NORM
