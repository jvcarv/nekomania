extends Weapon
## Bola de Fogo: projéteis no inimigo mais próximo; explode a partir do nível 4.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 10.0 * (1.0 + 0.22 * (l - 1)),
		"count": 1 + int(l >= 3) + int(l >= 6),
		"cooldown": 0.95 * pow(0.94, l - 1),
		"pierce": int(l >= 5) + int(l >= 8),
		"area": 0.0 if l < 4 else (22.0 if l < 7 else 30.0),
		"range": 260.0,
	}


func fire() -> bool:
	var origin := player.global_position + Vector2(0, -6)
	var n := int(stat("count"))
	var targets := nearest_enemies(origin, n, stat("range"))
	if targets.is_empty():
		return false
	for i in n:
		var t: Enemy = targets[i % targets.size()]
		var dir := origin.direction_to(t.global_position)
		if i >= targets.size():
			dir = dir.rotated(randf_range(-0.35, 0.35))
		var p := Projectile.new()
		p.weapon = self
		p.frames_name = "firebolt"
		p.hit_fx = "firebolt"
		p.direction = dir
		p.speed = 320.0
		p.damage = stat("damage")
		p.pierce = int(stat("pierce"))
		p.max_range = 420.0
		p.explosion_radius = stat("area")
		p.explosion_fx = "fire_burst"
		p.sprite_scale = Vector2(0.55, 0.5)
		p.global_position = origin
		fx_parent().add_child(p)
	return true
