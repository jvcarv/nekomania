extends Weapon
## Caveira Sombria: caveiras teleguiadas; explodem a partir do nível 4.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 14.0 * (1.0 + 0.22 * (l - 1)),
		"count": 1 + int(l >= 3) + int(l >= 5) + int(l >= 8),
		"cooldown": 1.6 * pow(0.94, l - 1),
		"pierce": int(l >= 6),
		"area": 0.0 if l < 4 else 20.0 + 2.0 * (l - 4),
		"speed": 170.0 + 8.0 * (l - 1),
	}


func fire() -> bool:
	if nearest_enemy(player.global_position, 300.0) == null:
		return false
	var n := int(stat("count"))
	for i in n:
		var p := Projectile.new()
		p.weapon = self
		p.frames_name = "dark"
		p.hit_fx = "dark"
		p.hit_fx_scale = 0.8
		var base := player.aim_dir.angle()
		p.direction = Vector2.RIGHT.rotated(base + TAU * float(i) / n + randf_range(-0.3, 0.3))
		p.speed = stat("speed")
		p.homing = 5.0
		p.damage = stat("damage")
		p.pierce = int(stat("pierce"))
		p.max_range = 600.0
		p.explosion_radius = stat("area")
		p.explosion_fx = "dark_burst"
		p.sprite_scale = Vector2(0.6, 0.6)
		p.radius = 6.0
		p.global_position = player.global_position + Vector2(0, -6)
		fx_parent().add_child(p)
	return true
