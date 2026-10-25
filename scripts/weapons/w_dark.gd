extends Weapon
## Caveira Sombria: caveiras teleguiadas; explodem a partir do nível 4.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 13.0 * (1.0 + 0.16 * (l - 1)),
		"count": 1 + int(l >= 3) + int(l >= 6) + int(l >= 9),
		"cooldown": 1.7 * pow(0.96, l - 1),
		"pierce": int(l >= 7),
		"area": 0.0 if l < 4 else 16.0 + 2.0 * (l - 4),
		"range": 120.0 + 9.0 * (l - 1),
	}


func fire() -> bool:
	var rng := stat("range")
	if nearest_enemy(player.global_position, rng) == null:
		return false
	var n := int(stat("count"))
	var targets := nearest_enemies(player.global_position, n, rng)
	for i in n:
		var p := Projectile.new()
		if i < targets.size():
			p.target = targets[i]
		p.weapon = self
		p.frames_name = "dark"
		p.hit_fx = "dark"
		p.hit_fx_scale = 0.8
		var base := player.aim_dir.angle()
		p.direction = Vector2.RIGHT.rotated(base + TAU * float(i) / n + randf_range(-0.3, 0.3))
		p.speed = 150.0
		p.homing = 5.0
		p.homing_range = rng
		p.damage = stat("damage")
		p.pierce = int(stat("pierce"))
		p.max_range = rng * 2.2
		p.explosion_radius = stat("area")
		p.explosion_fx = "dark_burst"
		p.sprite_scale = Vector2(0.6, 0.6)
		p.radius = 6.0
		p.global_position = player.global_position + Vector2(0, -6)
		fx_parent().add_child(p)
	return true
