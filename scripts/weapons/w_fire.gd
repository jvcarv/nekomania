extends Weapon
## Bola de Fogo: projéteis no inimigo mais próximo; explode a partir do nível 4.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 12.0 * (1.0 + 0.16 * (l - 1)),
		"count": 1 + int(l >= 4) + int(l >= 8),
		"cooldown": 1.0 * pow(0.96, l - 1),
		"pierce": int(l >= 6),
		"area": 0.0 if l < 4 else 18.0 + 2.0 * (l - 4),
		"range": 125.0 + 9.0 * (l - 1),
		"burn": 2.0 * (1.0 + 0.15 * (l - 1)),
	}


func fire() -> bool:
	var origin := player.global_position + Vector2(0, -6)
	var n := int(stat("count"))
	var rng := stat("range")
	var targets := nearest_enemies(origin, n, rng)
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
		if i < targets.size():
			p.target = t
		p.burn = float(raw("burn")) * float(player.stats["damage"])
		p.speed = 260.0
		p.damage = stat("damage")
		p.pierce = int(stat("pierce"))
		p.max_range = rng * 1.25
		p.explosion_radius = stat("area")
		p.explosion_fx = "fire_burst"
		p.sprite_scale = Vector2(0.55, 0.5)
		p.global_position = origin
		fx_parent().add_child(p)
	return true
