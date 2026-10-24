extends Weapon
## Luz Sagrada: pilares de luz caem sobre inimigos aleatórios por perto.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 18.0 * (1.0 + 0.25 * (l - 1)),
		"count": 1 + (l - 1) / 2,
		"cooldown": 2.0 * pow(0.95, l - 1),
		"area": 22.0 * (1.0 + 0.06 * (l - 1)),
		"range": 210.0,
	}


func fire() -> bool:
	var pool := enemies_in_radius(player.global_position, stat("range"))
	if pool.is_empty():
		return false
	pool.shuffle()
	var n := int(stat("count"))
	for i in n:
		var target: Enemy = pool[i % pool.size()]
		var pos := target.global_position
		if i >= pool.size():
			pos += Vector2(randf_range(-30, 30), randf_range(-30, 30))
		_strike(pos, i * 0.08)
	return true


func _strike(pos: Vector2, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
		if not is_instance_valid(player):
			return
	var area := stat("area")
	SpriteLib.spawn_fx(fx_parent(), "holy", pos, "hit", area / 18.0, 0.0, Vector2(0, -14))
	await get_tree().create_timer(0.12, false).timeout
	if not is_instance_valid(player):
		return
	SpriteLib.spawn_fx(fx_parent(), "holy_spark", pos, "hit", area / 16.0)
	var dmg := stat("damage")
	for e in enemies_in_radius(pos, area):
		hit(e, dmg, pos.direction_to(e.global_position) * 30.0)
