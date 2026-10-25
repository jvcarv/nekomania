extends Node2D
class_name AcidPool
## Poça ácida: círculo no chão com bolhas estourando (quadros do Acid VFX 01).

var weapon: Weapon
var radius := 22.0
var damage := 4.0
var duration := 3.0
var tick := 0.4
var slow := 0.25
var poison := 0.0          # dano por segundo extra (envenenamento)

var _t := 0.0
var _tick_t := 0.0
var _bubble_t := 0.0
var _alpha := 0.0


func _ready() -> void:
	z_index = -5
	SpriteLib.spawn_fx(get_parent(), "acid_blob", global_position, "hit", radius / 16.0)


func _process(delta: float) -> void:
	_t += delta
	_alpha = minf(1.0, _t * 4.0) * clampf((duration - _t) * 3.0, 0.0, 1.0)
	queue_redraw()
	if _t >= duration:
		queue_free()
		return
	_bubble_t -= delta
	if _bubble_t <= 0.0:
		_bubble_t = randf_range(0.12, 0.25)
		var off := Vector2.RIGHT.rotated(randf() * TAU) * randf() * radius * 0.75
		var b := SpriteLib.spawn_fx(get_parent(), "acid_blob", global_position + off, "hit", randf_range(0.3, 0.5))
		if b:
			b.z_index = -4
			b.modulate.a = 0.85 * _alpha
	_tick_t -= delta
	if _tick_t <= 0.0 and is_instance_valid(weapon) and is_instance_valid(weapon.player):
		_tick_t = tick
		for e in weapon.enemies_in_radius(global_position, radius):
			weapon.hit(e, damage)
			e.apply_slow(slow, 0.5)
			if poison > 0.0:
				e.apply_dot(poison, 2.0, Color(0.5, 1.0, 0.3))


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.30, 0.75, 0.15, 0.30 * _alpha))
	draw_circle(Vector2.ZERO, radius * 0.65, Color(0.45, 0.95, 0.25, 0.22 * _alpha))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.15, 0.45, 0.08, 0.7 * _alpha), 1.0)
