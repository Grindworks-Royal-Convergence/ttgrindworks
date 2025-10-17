extends TextureRect
class_name SelectedGagOtto

var otto_boost: ItemScript

func _ready() -> void:
	for item in Util.get_player().item_node.get_children():
		if item is OttoBoost:
			otto_boost = item
			continue
	if otto_boost:
		otto_boost.s_auto_move_created.emit(self)
