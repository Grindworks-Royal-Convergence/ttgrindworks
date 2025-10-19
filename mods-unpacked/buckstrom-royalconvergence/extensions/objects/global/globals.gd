extends "res://objects/globals/globals.gd"

const RC_GAGTRACK_COLORS := {
	"Squirt": Color("f733b8ff"),
	"Trap": Color("e34541ff"),
	"Lure": Color("489f3fff"),
	"Sound": Color("4f63d5ff"),
	"Throw": Color("ed8a42ff"),
	"Drop": Color("35f4ffff"),
	"Zap": Color("fcfd55ff")
}

# only god has witnessed what events resulted in the deranged original function
func get_gag_color(gag : ToonAttack) -> Color:
	if !RC_GAGTRACK_COLORS.has(gag.track.track_name):
		return Color.WHITE
	return RC_GAGTRACK_COLORS[gag.track.track_name]
