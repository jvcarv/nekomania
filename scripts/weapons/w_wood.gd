extends Weapon
## Troncos Orbitais: troncos giram ao redor do jogador.

var _angle := 0.0
var _logs: Array = []
var _hit_cd: Dictionary = {}   # inimigo -> tempo restante


func stats_for_level(l: int) -> Dictionary:
	return {
		"damage": 16.0 * (1.0 + 0.17 * (l - 1)),
		"count": 2 + (l - 1) / 3,
		"area": 32.0 * (1.0 + 0.04 * (l - 1)),
		"speed": 3.2 + 0.12 * l,
	}


func _tick(delta: float) -> void:
	var n := int(stat("count"))
	if _logs.size() != n:
		_rebuild(n)
	var radius := stat("area")
	_angle = fmod(_angle + stat("speed") * delta, TAU)
	var center := player.global_position + Vector2(0, -6)
	var dmg := stat("damage")
	for k in _hit_cd.keys():
		_hit_cd[k] -= delta
		if _hit_cd[k] <= 0.0 or not is_instance_valid(k):
			_hit_cd.erase(k)
	for i in n:
		var a := _angle + TAU * i / n
		var log_node: AnimatedSprite2D = _logs[i]
		log_node.global_position = center + Vector2.RIGHT.rotated(a) * radius
		log_node.rotation = a + PI / 2
		for e in enemies_in_radius(log_node.global_position, 11.0 * float(player.stats["area"])):
			if _hit_cd.has(e):
				continue
			_hit_cd[e] = 0.45
			hit(e, dmg, center.direction_to(e.global_position) * 70.0)
			SpriteLib.spawn_fx(fx_parent(), "wood", e.global_position, "hit", 0.5)


func _rebuild(n: int) -> void:
	for l in _logs:
		l.queue_free()
	_logs.clear()
	for i in n:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = SpriteLib.fx("wood")
		s.scale = Vector2(0.65, 0.65)
		s.z_index = 4
		s.top_level = true
		add_child(s)
		s.play("fly")
		_logs.append(s)


func fire() -> bool:
	return false


func stat(key: String) -> float:
	if key == "cooldown":
		return 1.0
	return super.stat(key)
