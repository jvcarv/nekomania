extends Node2D
class_name Weather
## Partículas de clima de cada bioma (folhas, neve, pétalas, esporos, vagalumes).
## Usa só quadradinhos coloridos (sem sprites).

var _p: CPUParticles2D


func _ready() -> void:
	z_index = 30
	_p = CPUParticles2D.new()
	_p.local_coords = false
	_p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_p.emission_rect_extents = Vector2(340, 200)
	add_child(_p)


func set_kind(kind: String, tint: Color) -> void:
	_p.emitting = kind != ""
	_p.restart()
	_p.gravity = Vector2.ZERO
	_p.scale_amount_min = 1.0
	_p.scale_amount_max = 2.0
	_p.color = tint
	_p.lifetime = 6.0
	match kind:
		"snow":
			_p.amount = 160
			_p.color = Color(1, 1, 1, 0.9)
			_p.direction = Vector2(0.3, 1)
			_p.spread = 15.0
			_p.initial_velocity_min = 20.0
			_p.initial_velocity_max = 40.0
		"leaves":
			_p.amount = 40
			_p.color = Color(0.95, 0.5, 0.15, 0.9)
			_p.direction = Vector2(1, 0.6)
			_p.spread = 25.0
			_p.initial_velocity_min = 15.0
			_p.initial_velocity_max = 35.0
			_p.scale_amount_min = 2.0
			_p.scale_amount_max = 3.0
			_p.angular_velocity_min = -90.0
			_p.angular_velocity_max = 90.0
		"petals":
			_p.amount = 50
			_p.color = Color(1.0, 0.7, 0.85, 0.9)
			_p.direction = Vector2(1, 0.5)
			_p.spread = 30.0
			_p.initial_velocity_min = 12.0
			_p.initial_velocity_max = 28.0
			_p.scale_amount_min = 1.5
			_p.scale_amount_max = 2.5
		"spores":
			_p.amount = 60
			_p.color = Color(tint, 0.6)
			_p.direction = Vector2(0, -1)
			_p.spread = 40.0
			_p.initial_velocity_min = 4.0
			_p.initial_velocity_max = 12.0
		"fireflies":
			_p.amount = 30
			_p.color = Color(1.0, 0.95, 0.5, 0.8)
			_p.direction = Vector2(0, -1)
			_p.spread = 180.0
			_p.initial_velocity_min = 3.0
			_p.initial_velocity_max = 10.0


func _process(_delta: float) -> void:
	var g := Game.current
	if g and g.player:
		global_position = g.player.global_position
