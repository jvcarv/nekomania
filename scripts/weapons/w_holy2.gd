extends Weapon
## Lanças de Luz: lanças perfurantes em várias direções (para frente/trás, depois em cruz, depois em estrela).


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 9.0 * (1.0 + 0.16 * (l - 1)),
		"count": 2 + 2 * int(l >= 3) + 2 * int(l >= 6) + 2 * int(l >= 9),
		"cooldown": 1.9 * pow(0.96, l - 1),
		"range": 110.0 + 8.0 * (l - 1),
		"pierce": 2 + l / 2,
	}


func fire() -> bool:
	if nearest_enemy(player.global_position, stat("range")) == null:
		return false
	var n := int(stat("count"))
	var base := player.aim_dir.angle()
	for i in n:
		var p := Projectile.new()
		p.weapon = self
		p.frames_name = "holy_lance"
		p.hit_fx = "holy_spark"
		p.hit_fx_scale = 0.5
		p.direction = Vector2.RIGHT.rotated(base + TAU * float(i) / n)
		p.speed = 230.0
		p.damage = stat("damage")
		p.pierce = int(stat("pierce"))
		p.max_range = stat("range")
		p.sprite_scale = Vector2(0.7, 0.7)
		p.knockback = 25.0
		p.global_position = player.global_position + Vector2(0, -6)
		fx_parent().add_child(p)
	return true
