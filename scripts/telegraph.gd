extends Node2D
class_name Telegraph
## Aviso de ataque do chefão: círculo ou linha vermelha que "enche" até o golpe.

var mode := "circle"          # "circle" ou "line"
var radius := 60.0
var vec := Vector2.RIGHT * 200.0
var width := 22.0
var duration := 0.8
var color := Color(1.0, 0.15, 0.1)
var _t := 0.0


func _ready() -> void:
	z_index = -3


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func progress() -> float:
	return clampf(_t / duration, 0.0, 1.0)


func _draw() -> void:
	var k := progress()
	var blink := 0.75 + 0.25 * sin(_t * 30.0)
	if mode == "circle":
		draw_circle(Vector2.ZERO, radius, Color(color, 0.18))
		draw_circle(Vector2.ZERO, radius * k, Color(color, 0.30 * blink))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(color, 0.9), 2.0)
	else:
		var n := vec.normalized().orthogonal() * width * 0.5
		var full := PackedVector2Array([n, vec + n, vec - n, -n])
		draw_colored_polygon(full, Color(color, 0.18))
		var part := PackedVector2Array([n, vec * k + n, vec * k - n, -n])
		draw_colored_polygon(part, Color(color, 0.32 * blink))
		draw_polyline(PackedVector2Array([n, vec + n, vec - n, -n, n]), Color(color, 0.9), 1.5)
