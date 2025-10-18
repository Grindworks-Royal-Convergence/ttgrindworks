@tool
extends StatusEffect

@export var rc_effect_id: String = ""
var global_path = "/root/ModLoader/buckstrom-royalconvergence/RCglobal"

func apply() -> void:
	var dict = manager.get_node(global_path).statuses
	if dict[rc_effect_id] is Array:
		dict[rc_effect_id].append(self)
	else:
		dict.set(rc_effect_id,[self])
	print(("RC Effect %s applied to Cog " % rc_effect_id) + str(target))
	super()

func cleanup() -> void:
	var dict = manager.get_node(global_path).statuses
	if dict[rc_effect_id] is Array:
		dict[rc_effect_id].erase(self)
	super()
