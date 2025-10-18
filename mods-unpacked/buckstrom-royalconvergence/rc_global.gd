extends Node

var rc_gags: Array[String] = [
	"zap"
]

var statuses: Dictionary[String, Array] = {
	"jumped": []
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

func battle_end_zap(_manager):
	statuses['jumped'].clear()
