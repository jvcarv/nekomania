extends Node2D
class_name MapGenerator
## Gera o mapa de forma procedural e infinita, em pedaços (chunks) de
## CHUNK x CHUNK pixels ao redor do jogador. Usa ruído (FastNoiseLite)
## para formar bosques densos e clareiras. Mesma semente = mesmo mapa.

const CHUNK := 256
const LOAD_RADIUS := 2          # chunks carregados em volta do jogador
const TREE_STEP := 36           # grade base para posicionar árvores
const SAFE_RADIUS := 140.0      # clareira garantida no início do estágio
const TREE_DIR := "res://assets/map/Forest Trees Pack – Pixel Art (32x32, Top-Down RPG)/Forest Trees Pack – Pixel Art (32x32, Top-Down RPG)/spr_tree_%d.png"

var world: Node2D               # nó com y-sort onde as árvores entram
var stage: Dictionary
var seed_value := 0
var origin := Vector2.ZERO
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _chunks: Dictionary = {}    # Vector2i -> Node2D
var _ground: ColorRect
var _textures: Dictionary = {}
var _tree_shape := CircleShape2D.new()


func _ready() -> void:
	_tree_shape.radius = 6.0
	_ground = ColorRect.new()
	_ground.size = Vector2(2600, 1800)
	_ground.z_index = -100
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/world/ground.gdshader")
	_ground.material = mat
	add_child(_ground)


## Gera um novo mapa para o estágio informado.
func generate(stage_data: Dictionary, new_seed: int, world_node: Node2D, start_pos: Vector2) -> void:
	clear()
	stage = stage_data
	seed_value = new_seed
	world = world_node
	origin = start_pos
	_noise.seed = new_seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.0045
	_noise.fractal_octaves = 3
	_detail.seed = new_seed + 99
	_detail.frequency = 0.03
	var mat := _ground.material as ShaderMaterial
	mat.set_shader_parameter("col_a", stage["ground_a"])
	mat.set_shader_parameter("col_b", stage["ground_b"])
	mat.set_shader_parameter("col_c", stage["ground_c"])
	mat.set_shader_parameter("seed", float(new_seed % 1000))
	mat.set_shader_parameter("flower", stage_data.get("flower", Color(1.0, 0.9, 0.5)))
	update_around(start_pos)


func clear() -> void:
	for c in _chunks.values():
		if is_instance_valid(c):
			c.queue_free()
	_chunks.clear()


func update_around(pos: Vector2) -> void:
	_ground.global_position = (pos - _ground.size / 2.0).snapped(Vector2(2, 2))
	if world == null:
		return
	var cc := Vector2i(floori(pos.x / CHUNK), floori(pos.y / CHUNK))
	var wanted: Dictionary = {}
	for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var key := cc + Vector2i(dx, dy)
			wanted[key] = true
			if not _chunks.has(key):
				_chunks[key] = _build_chunk(key)
	for key in _chunks.keys():
		if not wanted.has(key):
			var c: Node2D = _chunks[key]
			if is_instance_valid(c):
				c.queue_free()
			_chunks.erase(key)


func _build_chunk(key: Vector2i) -> Node2D:
	var chunk := Node2D.new()
	chunk.name = "Chunk_%d_%d" % [key.x, key.y]
	chunk.y_sort_enabled = true
	world.add_child(chunk)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, key.x, key.y])
	var base := Vector2(key.x * CHUNK, key.y * CHUNK)
	var density: float = stage.get("tree_density", 0.55)
	var tree_ids: Array = stage["trees"]
	var steps := CHUNK / TREE_STEP
	for gy in steps:
		for gx in steps:
			var p := base + Vector2(gx * TREE_STEP, gy * TREE_STEP)
			p += Vector2(rng.randf_range(4, TREE_STEP - 4), rng.randf_range(4, TREE_STEP - 4))
			if p.distance_to(origin) < SAFE_RADIUS:
				continue
			var n := _noise.get_noise_2dv(p)               # -1..1 (bosques x clareiras)
			var chance := smoothstep(0.0, 0.45, n) * density * 0.9 + 0.025
			chance += _detail.get_noise_2dv(p) * 0.05
			if rng.randf() < chance:
				_add_tree(chunk, p, tree_ids[rng.randi() % tree_ids.size()], rng)
	return chunk


func _add_tree(parent: Node2D, pos: Vector2, tree_id: int, rng: RandomNumberGenerator) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var cs := CollisionShape2D.new()
	cs.shape = _tree_shape
	cs.position = Vector2(0, -3)
	body.add_child(cs)
	var s := Sprite2D.new()
	s.texture = _tree_texture(tree_id)
	s.centered = false
	s.offset = Vector2(-32, -58)
	if rng.randf() < 0.5:
		s.flip_h = true
		s.offset.x = -32
	var tint: Color = stage["tree_tint"]
	var v := rng.randf_range(0.9, 1.08)
	s.modulate = Color(tint.r * v, tint.g * v, tint.b * v)
	body.add_child(s)
	parent.add_child(body)


func _tree_texture(id: int) -> Texture2D:
	if not _textures.has(id):
		_textures[id] = load(TREE_DIR % id)
	return _textures[id]


## Procura um ponto livre (longe de árvores) perto de uma posição.
func is_blocked(pos: Vector2, radius: float = 10.0) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	q.shape = c
	q.transform = Transform2D(0, pos)
	q.collision_mask = 1
	return not space.intersect_shape(q, 1).is_empty()
