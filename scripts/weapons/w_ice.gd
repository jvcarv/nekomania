extends Weapon
## Estilhaço de Gelo: projéteis rápidos e perfurantes que deixam lento.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 8.0 * (1.0 + 0.15 * (l - 1)),
		"count": 1 + int(l >= 4) + int(l >= 8),
		"cooldown": 1.3 * pow(0.96, l - 1),
		"pierce": 1 + l / 3,
		"slow": 0.35 + 0.03 * l,
		"range": 120.0 + 9.0 * (l - 1),
	}


func fire() -> bool:
	var origin := player.global_position + Vector2(0, -6)
	var rng := stat("range")
	var t := nearest_enemy(origin, rng)
	if t == null:
		return false
	var base := origin.direction_to(t.global_position)
	var n := int(stat("count"))
	for i in n:
		var p := Projectile.new()
		p.weapon = self
		p.frames_name = "ice"
		p.hit_fx = "ice"
		p.hit_fx_scale = 0.5
		var spread := (float(i) - (n - 1) / 2.0) * 0.18
		p.direction = base.rotated(spread)
		if i == 0:
			p.target = t
		p.speed = 320.0
		p.damage = stat("damage")
		p.pierce = int(stat("pierce"))
		p.slow = stat("slow")
		p.max_range = rng * 1.3
		p.sprite_scale = Vector2(0.6, 0.6)
		p.global_position = origin
		fx_parent().add_child(p)
	return true
