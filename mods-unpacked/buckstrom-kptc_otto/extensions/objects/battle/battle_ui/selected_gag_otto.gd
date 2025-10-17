extends TextureRect

var otto_boost: ItemScript

func _ready() -> void:
	otto_boost = get_node("/root/ModLoader/buckstrom-kptc_otto/KPTCglobal").otto_boost
	if !is_instance_valid(otto_boost):
		return
	if otto_boost:
		otto_boost.s_auto_move_created.emit(self)
