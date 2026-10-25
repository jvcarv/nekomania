extends Weapon
## Frasco Arremessado: frascos lançados em arco que estouram e envenenam.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 10.0 * (1.0 + 0.16 * (l - 1)),
		"poison": 3.0 * (1.0 + 0.18 * (l - 1)),
		"count": 1 + int(l >= 4) + int(l >= 8),
		"cooldown": 1.9 * pow(0.96, l - 1),
		"area": 20.0 + 1.5 * (l - 1),
		"range": 120.0 + 9.0 * (l - 1),
	}


func fire() -> bool:
	var targets := nearest_enemies(player.global_position, int(stat("count")) + 2, stat("range"))
	if targets.is_empty():
		return false
	targets.shuffle()
	var n := int(stat("count"))
	for i in n:
		var t: Enemy = targets[i % targets.size()]
		_throw(t.global_position + t.velocity * 0.3, i * 0.1)
	return true


func _throw(target: Vector2, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
		if not is_instance_valid(player):
			return
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SpriteLib.fx("acid_flask")
	s.play("fly")
	s.scale = Vector2(0.7, 0.7)
	s.z_index = 6
	var start := player.global_position + Vector2(0, -8)
	s.global_position = start
	fx_parent().add_child(s)
	var dur := 0.45
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		s.global_position = start.lerp(target, k) + Vector2(0, -36.0 * 4.0 * k * (1.0 - k))
		s.rotation = k * TAU, 0.0, 1.0, dur)
	await tw.finished
	s.queue_free()
	if not is_instance_valid(player):
		return
	var area := stat("area") * float(player.stats["area"])
	SpriteLib.spawn_fx(fx_parent(), "acid_flask", target, "hit", area / 14.0)
	var dmg := stat("damage")
	var poison := float(raw("poison")) * float(player.stats["damage"])
	for e in enemies_in_radius(target, area):
		hit(e, dmg)
		e.apply_poison(poison, 3.5)
