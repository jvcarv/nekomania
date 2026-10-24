extends Node2D
class_name AcidPool
## Poça ácida criada pelo Gêiser Ácido.

var weapon: Weapon
var radius := 26.0
var damage := 4.0
var duration := 3.0
var tick := 0.4

var _t := 0.0
var _tick_t := 0.0
var _alpha := 0.0


func _ready() -> void:
	z_index = -5
	SpriteLib.spawn_fx(get_parent(), "acid_blob", global_position, "hit", radius / 14.0)
	var geysers := 1 + int(radius / 18.0)
	for i in geysers:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = SpriteLib.fx("acid")
		s.position = Vector2.RIGHT.rotated(TAU * i / geysers + randf()) * radius * 0.45 * float(i > 0)
		s.offset = Vector2(0, -12)
		s.scale = Vector2(0.6, 0.6)
		s.z_index = 10
		s.z_as_relative = false
		add_child(s)
		s.play("loop")
		s.frame = randi() % 6


func _process(delta: float) -> void:
	_t += delta
	_alpha = minf(1.0, _t * 4.0) * clampf((duration - _t) * 3.0, 0.0, 1.0)
	queue_redraw()
	if _t >= duration:
		queue_free()
		return
	_tick_t -= delta
	if _tick_t <= 0.0 and is_instance_valid(weapon) and is_instance_valid(weapon.player):
		_tick_t = tick
		for e in weapon.enemies_in_radius(global_position, radius):
			weapon.hit(e, damage)
			e.apply_slow(0.25, 0.5)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.35, 0.9, 0.2, 0.28 * _alpha))
	draw_circle(Vector2.ZERO, radius * 0.7, Color(0.5, 1.0, 0.3, 0.22 * _alpha))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.2, 0.6, 0.1, 0.6 * _alpha), 1.0)
