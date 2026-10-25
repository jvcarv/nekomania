extends Node2D
class_name Weather
## Partículas de clima de cada bioma (folhas, neve, pétalas, esporos, vagalumes).
## Sprites: Ninja Adventure / FX / Particle (Pixel-boy & AAA, CC0).

const PARTICLES := "res://assets/map/Ninja Adventure - Asset Pack/FX/Particle/"

## tipo -> [arquivo, quadros]
const KINDS := {
	"snow": ["Snow.png", 7],
	"leaves": ["Leaf.png", 6],
	"petals": ["LeafPink.png", 6],
	"spores": ["Spark.png", 7],
	"fireflies": ["Spark.png", 7],
}

var _p: CPUParticles2D


func _ready() -> void:
	z_index = 30
	_p = CPUParticles2D.new()
	_p.local_coords = false
	_p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_p.emission_rect_extents = Vector2(340, 200)
	var mat := CanvasItemMaterial.new()
	mat.particles_animation = true
	mat.particles_anim_loop = true
	_p.material = mat
	add_child(_p)


func set_kind(kind: String, tint: Color) -> void:
	_p.emitting = KINDS.has(kind)
	if not KINDS.has(kind):
		return
	var info: Array = KINDS[kind]
	_p.texture = load(PARTICLES + info[0])
	var mat := _p.material as CanvasItemMaterial
	mat.particles_anim_h_frames = int(info[1])
	mat.particles_anim_v_frames = 1
	_p.anim_speed_min = 0.6
	_p.anim_speed_max = 1.2
	_p.anim_offset_max = 1.0
	_p.restart()
	_p.gravity = Vector2.ZERO
	_p.scale_amount_min = 0.8
	_p.scale_amount_max = 1.0
	_p.color = Color.WHITE
	_p.lifetime = 6.0
	match kind:
		"snow":
			_p.amount = 140
			_p.direction = Vector2(0.3, 1)
			_p.spread = 15.0
			_p.initial_velocity_min = 18.0
			_p.initial_velocity_max = 36.0
		"leaves", "petals":
			_p.amount = 40
			_p.direction = Vector2(1, 0.6)
			_p.spread = 25.0
			_p.initial_velocity_min = 15.0
			_p.initial_velocity_max = 35.0
			if kind == "leaves":
				_p.color = Color(1.0, 0.65, 0.3)
		"spores":
			_p.amount = 45
			_p.color = Color(tint, 0.8)
			_p.direction = Vector2(0, -1)
			_p.spread = 40.0
			_p.initial_velocity_min = 4.0
			_p.initial_velocity_max = 12.0
			_p.scale_amount_min = 0.5
			_p.scale_amount_max = 0.8
		"fireflies":
			_p.amount = 25
			_p.color = Color(1.0, 0.95, 0.5, 0.9)
			_p.direction = Vector2(0, -1)
			_p.spread = 180.0
			_p.initial_velocity_min = 3.0
			_p.initial_velocity_max = 10.0
			_p.scale_amount_min = 0.5
			_p.scale_amount_max = 0.8


func _process(_delta: float) -> void:
	var g := Game.current
	if g and g.player:
		global_position = g.player.global_position
