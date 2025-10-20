extends Node

func animate_target_spin(target: Node3D):
	var manager := BattleService.ongoing_battle
	var tween: Tween = target.create_tween()
	tween.tween_property(target.get_node('Body'), 'rotation_degrees:y', -180.0 * 6.0, 0.0001).set_ease(Tween.EASE_IN)
	tween.tween_property(target.get_node('Body'), 'rotation_degrees:y', -180.0 * 3.0, 0.6).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target.get_node('Body'), 'rotation_degrees:y', -180.0 * 1.2, 0.6)
	tween.tween_property(target.get_node('Body'), 'rotation_degrees:y', -180.0, 0.4).set_ease(Tween.EASE_OUT)
	await manager.sleep(3.0)
	#target.get_node('Body')['rotation:y'] = -0.5
	#tween.set_parallel(true)
	await tween.finished
	tween.kill()
