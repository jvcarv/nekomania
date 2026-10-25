extends Weapon
## Prisão de Gelo: espinhos de gelo brotam sob inimigos próximos e os congelam.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 12.0 * (1.0 + 0.16 * (l - 1)),
		"count": 1 + (l - 1) / 2,
		"cooldown": 2.4 * pow(0.96, l - 1),
		"freeze": 1.0 + 0.08 * (l - 1),
		"range": 100.0 + 8.0 * (l - 1),
	}


func fire() -> bool:
	var targets := nearest_enemies(player.global_position, int(stat("count")), stat("range"))
	if targets.is_empty():
		return false
	var dmg := stat("damage")
	var freeze := float(raw("freeze"))
	for e: Enemy in targets:
		SpriteLib.spawn_fx(fx_parent(), "ice_prison", e.global_position, "hit", 1.0, 0.0, Vector2(0, -10))
		hit(e, dmg)
		e.apply_slow(1.0, freeze)
	return true
