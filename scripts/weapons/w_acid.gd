extends Weapon
## Poça Ácida: cria poças borbulhantes que causam dano contínuo e deixam lento.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 4.0 * (1.0 + 0.17 * (l - 1)),
		"count": 1 + int(l >= 4) + int(l >= 8),
		"cooldown": 2.6 * pow(0.96, l - 1),
		"area": 22.0 * (1.0 + 0.06 * (l - 1)),
		"duration": 3.0 + 0.25 * (l - 1),
		"range": 110.0 + 8.0 * (l - 1),
	}


func fire() -> bool:
	var pool := enemies_in_radius(player.global_position, stat("range"))
	if pool.is_empty():
		return false
	pool.shuffle()
	var n := int(stat("count"))
	for i in n:
		var pos: Vector2
		if i < pool.size():
			pos = pool[i].global_position
		else:
			pos = player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(30, stat("range"))
		var a := AcidPool.new()
		a.weapon = self
		a.radius = stat("area")
		a.damage = stat("damage")
		a.duration = stat("duration")
		a.global_position = pos
		fx_parent().add_child(a)
	return true
