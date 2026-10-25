extends Weapon
## Sopro de Fogo: cone curto na direção do inimigo mais próximo; deixa inimigos queimando.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 8.0 * (1.0 + 0.16 * (l - 1)),
		"burn": 3.0 * (1.0 + 0.15 * (l - 1)),
		"cooldown": 1.5 * pow(0.96, l - 1),
		"range": 55.0 + 4.0 * (l - 1),
		"area": 0.55 + 0.04 * (l - 1),   # meia-abertura do cone (radianos)
	}


func fire() -> bool:
	var origin := player.global_position + Vector2(0, -6)
	var rng := stat("range")
	var t := nearest_enemy(origin, rng + 10.0)
	if t == null:
		return false
	var dir := origin.direction_to(t.global_position)
	var half := float(raw("area")) * float(player.stats["area"])
	var dmg := stat("damage")
	var burn := float(raw("burn")) * float(player.stats["damage"])
	for e in enemies_in_radius(origin, rng):
		var to: Vector2 = e.global_position - origin
		if absf(dir.angle_to(to)) <= half or to.length() < 14.0:
			hit(e, dmg, dir * 50.0)
			e.apply_burn(burn, 2.5)
	var fx := SpriteLib.spawn_fx(fx_parent(), "fire_breath", origin + dir * rng * 0.45, "hit", rng / 34.0, dir.angle())
	if fx:
		fx.offset = Vector2(4, 0)
	return true
