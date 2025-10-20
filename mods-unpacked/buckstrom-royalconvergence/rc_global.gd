extends Node

var rc_gags: Array[String] = [
	"zap"
]

var statuses: Dictionary[String, Array] = {
	"jumped": []
}

const RC_OUTLINE_COLORS := {
	"Trap": Color("3a3a01"),
	"Lure": Color("173a13"),
	"Sound": Color("0f1542"),
	"Throw": Color("541e00"),
	"Squirt": Color("6a024c"),
	"Drop": Color("004347"),
	"Zap": Color("736b31ff"),
	"Spin": Color(0.414, 0.314, 0.494, 1.0)
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
