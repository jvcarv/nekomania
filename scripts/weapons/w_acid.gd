extends Weapon
## Gêiser Ácido: cria poças que causam dano contínuo e deixam lento.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 4.0 * (1.0 + 0.25 * (l - 1)),
		"count": 1 + int(l >= 3) + int(l >= 6),
		"cooldown": 2.6 * pow(0.95, l - 1),
		"area": 26.0 * (1.0 + 0.08 * (l - 1)),
		"duration": 3.0 + 0.3 * (l - 1),
	}


func fire() -> bool:
	var pool := enemies_in_radius(player.global_position, 220.0)
	if pool.is_empty():
		return false
	pool.shuffle()
	var n := int(stat("count"))
	for i in n:
		var pos: Vector2
		if i < pool.size():
			pos = pool[i].global_position
		else:
			pos = player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(40, 140)
		var a := AcidPool.new()
		a.weapon = self
		a.radius = stat("area")
		a.damage = stat("damage")
		a.duration = stat("duration")
		a.global_position = pos
		fx_parent().add_child(a)
	return true
