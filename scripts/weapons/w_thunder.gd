extends Weapon
## Raio em Cadeia: atinge um inimigo e salta para os próximos.


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 12.0 * (1.0 + 0.22 * (l - 1)),
		"chains": 3 + (l - 1),
		"count": 1 + int(l >= 5) + int(l >= 8),
		"cooldown": 1.8 * pow(0.94, l - 1),
		"range": 130.0,
	}


func fire() -> bool:
	var origin := player.global_position + Vector2(0, -8)
	var n := int(stat("count"))
	var used: Array = []
	var fired := false
	for b in n:
		var first := nearest_enemy(origin, 240.0, used)
		if first == null:
			break
		fired = true
		var points: Array = [origin]
		var current: Enemy = first
		var dmg := stat("damage")
		var jumps := int(stat("chains"))
		var jump_range := stat("range") * float(player.stats["area"])
		while current != null and jumps >= 0:
			used.append(current)
			points.append(current.global_position)
			SpriteLib.spawn_fx(fx_parent(), "thunder", current.global_position, "hit", 0.7)
			hit(current, dmg)
			dmg *= 0.9
			jumps -= 1
			current = nearest_enemy(current.global_position, jump_range, used)
		_draw_bolt(points)
	return fired


func _draw_bolt(points: Array) -> void:
	var line := Line2D.new()
	line.width = 2.0
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
	fx_parent().add_child(line)
	var glow := line.duplicate() as Line2D
	glow.width = 5.0
	glow.default_color = Color(1.0, 0.8, 0.2, 0.35)
	glow.z_index = 5
	fx_parent().add_child(glow)
	for l: Line2D in [line, glow]:
		var tw: Tween = l.create_tween()
		tw.tween_property(l, "modulate:a", 0.0, 0.22)
		tw.tween_callback(l.queue_free)
