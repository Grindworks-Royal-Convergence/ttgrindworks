extends Node

const RC_VOUCHER_SFXDATA := {
	"Trap": [preload("res://audio/sfx/battle/gags/trap/TL_banana.ogg"), 0.75],
	"Squirt": [preload("res://audio/sfx/battle/gags/squirt/AA_squirt_flowersquirt.ogg"), 0.67],
	"Lure": [preload("res://audio/sfx/battle/gags/lure/TL_fishing_pole.ogg"), 1.24],
	"Sound": [preload("res://audio/sfx/battle/gags/sound/AA_sound_bikehorn.ogg"), 0.0],
	"Throw": [preload("res://audio/sfx/battle/gags/throw/AA_pie_throw_only.ogg"), 0.0],
	"Drop": [preload("res://audio/sfx/battle/gags/drop/AA_drop_anvil.ogg"), 0.0],
	"Zap": [preload("res://mods-unpacked/buckstrom-royalconvergence/zap/lightning_2.ogg"), 0.0],
	"Spin": [preload("res://audio/sfx/battle/gags/lure/TL_fishing_pole.ogg"), 1.24],
}

func use_voucher(chain: ModLoaderHookChain, track: Track) -> void:
	var _main := chain.reference_object as TextureRect
	Util.get_player().stats.gag_vouchers[track.track_name] -= 1
	Util.get_player().stats.gag_balance[track.track_name] += 5
	_main._refresh_vouchers()
	for child in _main.get_parent().gag_tracks.get_children():
		child.refresh()
	_main.s_voucher_used.emit()
	var sfx_data: Array = RC_VOUCHER_SFXDATA[track.track_name]
	AudioManager.play_snippet(sfx_data[0], sfx_data[1])
