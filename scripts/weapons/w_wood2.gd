extends Weapon
## Onda de Espinhos: um anel de espinhos se expande a partir do jogador.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 13.0 * (1.0 + 0.17 * (l - 1)),
		"cooldown": 2.6 * pow(0.96, l - 1),
		"area": 48.0 + 4.0 * (l - 1),
	}


func fire() -> bool:
	var center := player.global_position
	var max_r := stat("area")
	if nearest_enemy(center, max_r) == null:
		return false
	_wave(center, max_r)
	return true


func _wave(center: Vector2, max_r: float) -> void:
	var hit_set: Array = []
	var dmg := stat("damage")
	var steps := 3
	for s in steps:
		var r := max_r * float(s + 1) / steps
		var n := 6 + s * 4
		for i in n:
			var pos := center + Vector2.RIGHT.rotated(TAU * i / n + s * 0.3) * r
			SpriteLib.spawn_fx(fx_parent(), "wood_thorn", pos, "hit", 0.9, 0.0, Vector2(0, -10))
		for e in enemies_in_radius(center, r + 6.0):
			if hit_set.has(e):
				continue
			hit_set.append(e)
			hit(e, dmg, center.direction_to(e.global_position) * 90.0)
			e.apply_slow(0.5, 0.8)
		await get_tree().create_timer(0.09, false).timeout
		if not is_instance_valid(player):
			return
