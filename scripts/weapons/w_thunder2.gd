extends Weapon
## Orbe Elétrico: orbe lento que atravessa tudo e dá choques em quem chega perto.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 6.0 * (1.0 + 0.16 * (l - 1)),
		"count": 1 + int(l >= 5) + int(l >= 9),
		"cooldown": 3.0 * pow(0.96, l - 1),
		"radius": 40.0 + 3.0 * (l - 1),
		"range": 130.0 + 8.0 * (l - 1),
	}


func fire() -> bool:
	var t := nearest_enemy(player.global_position, stat("range"))
	if t == null:
		return false
	var n := int(stat("count"))
	var base := player.global_position.direction_to(t.global_position)
	for i in n:
		var orb := ElectricOrb.new()
		orb.weapon = self
		orb.direction = base.rotated((float(i) - (n - 1) / 2.0) * 0.6)
		orb.damage = stat("damage")
		orb.zap_radius = stat("radius") * float(player.stats["area"])
		orb.max_range = stat("range")
		orb.global_position = player.global_position + Vector2(0, -6)
		fx_parent().add_child(orb)
	return true
