extends ItemCharSetup

func first_time_setup(player : Player) -> void:
	var stats := player.stats
	stats.gag_cap += 3
	stats.gag_regeneration['Zap'] += 2
