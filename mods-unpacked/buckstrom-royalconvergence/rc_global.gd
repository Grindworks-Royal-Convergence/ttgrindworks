extends Node

var rc_gags: Array[String] = [
	"zap"
]

var statuses: Dictionary[String, Array] = {
	"jumped": []
}

const RC_VOUCHER_SFXDATA := {
	"Trap": [preload("res://audio/sfx/battle/gags/trap/TL_banana.ogg"), 0.75],
	"Squirt": [preload("res://audio/sfx/battle/gags/squirt/AA_squirt_flowersquirt.ogg"), 0.67],
	"Lure": [preload("res://audio/sfx/battle/gags/lure/TL_fishing_pole.ogg"), 1.24],
	"Sound": [preload("res://audio/sfx/battle/gags/sound/AA_sound_bikehorn.ogg"), 0.0],
	"Throw": [preload("res://audio/sfx/battle/gags/throw/AA_pie_throw_only.ogg"), 0.0],
	"Drop": [preload("res://audio/sfx/battle/gags/drop/AA_drop_anvil.ogg"), 0.0],
	"Zap": [preload("res://mods-unpacked/buckstrom-royalconvergence/zap/lightning_2.ogg"), 1.2]
}

const RC_OUTLINE_COLORS := {
	"Trap": Color("3a3a01"),
	"Lure": Color("173a13"),
	"Sound": Color("0f1542"),
	"Throw": Color("541e00"),
	"Squirt": Color("6a024c"),
	"Drop": Color("004347"),
	"Zap": Color("736b31ff")
}

func _ready() -> void:
	BattleService.s_battle_started.connect(battle_setup_rc_gags)
	
func battle_setup_rc_gags(_manager: BattleManager) -> void:
	for _track: String in _manager.player.stats.gags_unlocked.keys():
		var track = _track.to_lower()
		if track in rc_gags:
			call("battle_setup_%s" % track, _manager)

var zap_targets: Array[int]
signal s_zap_selected(gag: ToonAttack)

func battle_setup_zap(_manager):
	BattleService.s_battle_ended.connect(battle_end_zap)
	zap_targets = []

func battle_end_zap():
	statuses['jumped'].clear()
