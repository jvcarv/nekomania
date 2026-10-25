extends Weapon
class_name WThunder
## Raio em Cadeia: atinge um inimigo e salta para os próximos.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 11.0 * (1.0 + 0.16 * (l - 1)),
		"chains": 2 + (l - 1) / 2,
		"count": 1 + int(l >= 6) + int(l >= 10),
		"cooldown": 1.8 * pow(0.96, l - 1),
		"range": 105.0 + 8.0 * (l - 1),
		"stun": 0.45 + 0.04 * (l - 1),
	}


func fire() -> bool:
	var origin := player.global_position + Vector2(0, -8)
	var n := int(stat("count"))
	var used: Array = []
	var fired := false
	for b in n:
		var first := nearest_enemy(origin, stat("range"), used)
		if first == null:
			break
		fired = true
		var points: Array = [origin]
		var current: Enemy = first
		var dmg := stat("damage")
		var jumps := int(stat("chains"))
		var jump_range := 70.0 * float(player.stats["area"])
		while current != null and jumps >= 0:
			used.append(current)
			points.append(current.global_position)
			SpriteLib.spawn_fx(fx_parent(), "thunder", current.global_position, "hit", 0.7)
			hit(current, dmg)
			current.apply_shock(float(raw("stun")))
			dmg *= 0.9
			jumps -= 1
			current = nearest_enemy(current.global_position, jump_range, used)
		draw_bolt(fx_parent(), points)
	return fired


static func draw_bolt(parent: Node, points: Array, width: float = 2.0) -> void:
	var line := Line2D.new()
	line.width = width
	line.default_color = Color(1.0, 0.95, 0.55)
	line.z_index = 6
	for i in points.size():
		var p: Vector2 = points[i]
		if i > 0:
			var prev: Vector2 = points[i - 1]
			for s in range(1, 4):
				var mid := prev.lerp(p, s / 4.0)
				var normal := (p - prev).orthogonal().normalized()
				line.add_point(mid + normal * randf_range(-6, 6))
		line.add_point(p)
	parent.add_child(line)
	var glow := line.duplicate() as Line2D
	glow.width = width * 2.5
	glow.default_color = Color(1.0, 0.8, 0.2, 0.35)
	glow.z_index = 5
	parent.add_child(glow)
	for l: Line2D in [line, glow]:
		var tw: Tween = l.create_tween()
		tw.tween_property(l, "modulate:a", 0.0, 0.22)
		tw.tween_callback(l.queue_free)
