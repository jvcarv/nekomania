extends Weapon
## Falcão Elétrico: um falcão de raios nasce acima do gato e mergulha em
## vários inimigos seguidos, deixando cada um eletrizado (parado).


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 14.0 * (1.0 + 0.16 * (l - 1)),
		"chains": 3 + (l - 1) / 2,
		"count": 1 + int(l >= 5) + int(l >= 9),
		"cooldown": 2.8 * pow(0.96, l - 1),
		"range": 140.0 + 9.0 * (l - 1),
		"stun": 0.8 + 0.05 * (l - 1),
	}


func fire() -> bool:
	var rng := stat("range")
	if nearest_enemy(player.global_position, rng) == null:
		return false
	var n := int(stat("count"))
	for i in n:
		var f := ThunderFalcon.new()
		f.weapon = self
		f.damage = stat("damage")
		f.hits = int(stat("chains"))
		f.search_range = rng
		f.stun = float(raw("stun"))
		f.global_position = player.global_position + Vector2((i - (n - 1) / 2.0) * 18.0, -22)
		fx_parent().add_child(f)
	return true
