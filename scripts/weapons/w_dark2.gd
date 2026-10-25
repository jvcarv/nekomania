extends Weapon
## Nova Sombria: explosão ao redor do jogador, empurra os inimigos e rouba vida.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 14.0 * (1.0 + 0.16 * (l - 1)),
		"cooldown": 3.0 * pow(0.95, l - 1),
		"area": 46.0 + 3.0 * (l - 1),
		"steal": 1.0 + 0.25 * (l - 1),   # vida por inimigo atingido (máx. 6 por explosão)
	}


func fire() -> bool:
	var center := player.global_position + Vector2(0, -4)
	var radius := stat("area")
	var targets := enemies_in_radius(center, radius)
	if targets.is_empty():
		return false
	var dmg := stat("damage")
	for e in targets:
		hit(e, dmg, center.direction_to(e.global_position) * 140.0)
	player.heal(minf(targets.size(), 6) * float(raw("steal")))
	var ring := 8
	for i in ring:
		var pos := center + Vector2.RIGHT.rotated(TAU * i / ring) * radius * 0.7
		SpriteLib.spawn_fx(fx_parent(), "dark_burst", pos, "hit", 0.6, 0.0, Vector2(0, -16))
	SpriteLib.spawn_fx(fx_parent(), "dark_burst", center, "hit", 0.9, 0.0, Vector2(0, -16))
	return true
