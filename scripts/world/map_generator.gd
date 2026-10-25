extends Node2D
class_name MapGenerator
## Gera o mapa de forma procedural e infinita, em pedaços (chunks) de
## CHUNK x CHUNK pixels ao redor do jogador. Mesma semente = mesmo mapa.
##
## Arte: Ninja Adventure (Pixel-boy & AAA, CC0) + Forest Trees Pack.
##  - Chão: TilesetFloor. Cada bioma usa um "bloco" do tileset (grama, areia,
##    neve...). Manchas (terra, etc.) são montadas com "marching squares":
##    cada vértice da grade é chão-base ou mancha, e o tile escolhido depende
##    dos 4 cantos (16 combinações).
##  - Árvores e enfeites: Forest Trees Pack + TilesetNature + TilesetFloorDetail.

const TILE := 16
const CHUNK := 256                     # 16 x 16 tiles
const CHUNK_TILES := CHUNK / TILE
const LOAD_RADIUS := 2                 # chunks carregados em volta do jogador
const TREE_STEP := 36                  # grade base para posicionar árvores
const SAFE_RADIUS := 150.0             # clareira garantida no início do estágio

const NINJA := "res://assets/map/Ninja Adventure - Asset Pack/Backgrounds/Tilesets/"
const FOREST_TREE := "res://assets/map/Forest Trees Pack – Pixel Art (32x32, Top-Down RPG)/Forest Trees Pack – Pixel Art (32x32, Top-Down RPG)/spr_tree_%d.png"

# fontes do TileSet
const SRC_FLOOR := 0
const SRC_DETAIL := 2
const SRC_NATURE := 3

## Marching squares: máscara dos 4 cantos (TL=1, TR=2, BR=4, BL=8; bit = mancha)
## -> posição do tile relativa à origem do bloco do bioma no TilesetFloor.
const MS := {
	0: Vector2i(0, 5), 15: Vector2i(1, 1),
	4: Vector2i(0, 0), 8: Vector2i(2, 0), 2: Vector2i(0, 2), 1: Vector2i(2, 2),
	12: Vector2i(1, 0), 3: Vector2i(1, 2), 6: Vector2i(0, 1), 9: Vector2i(2, 1),
	11: Vector2i(5, 1), 7: Vector2i(6, 1), 13: Vector2i(5, 2), 14: Vector2i(6, 2),
	5: Vector2i(9, 0), 10: Vector2i(9, 1),
}
const BASE_DETAILS := [Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5)]

static var _tileset: TileSet

var world: Node2D                      # nó com y-sort onde as árvores entram
var stage: Dictionary                  # bioma atual (DB.BIOMES)
var seed_value := 0
var origin := Vector2.ZERO
var _patch := FastNoiseLite.new()      # manchas no chão
var _forest := FastNoiseLite.new()     # bosques x clareiras
var _detail := FastNoiseLite.new()
var _chunks: Dictionary = {}           # Vector2i -> Node2D
var _textures: Dictionary = {}


# ------------------------------------------------------------------ TileSet
static func tileset() -> TileSet:
	if _tileset:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var files := {SRC_FLOOR: "TilesetFloor.png",
		SRC_DETAIL: "TilesetFloorDetail.png", SRC_NATURE: "TilesetNature.png"}
	for id in files:
		var tex: Texture2D = load(NINJA + files[id])
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(TILE, TILE)
		var cols := tex.get_width() / TILE
		var rows := tex.get_height() / TILE
		for y in rows:
			for x in cols:
				src.create_tile(Vector2i(x, y))
		ts.add_source(src, id)
	_tileset = ts
	return ts


static func make_layer(z: int) -> TileMapLayer:
	var l := TileMapLayer.new()
	l.tile_set = tileset()
	l.z_index = z
	l.z_as_relative = false
	l.y_sort_enabled = false
	return l


# ------------------------------------------------------------------ geração
func _ready() -> void:
	pass


## Gera um novo mapa para o bioma informado.
func generate(biome: Dictionary, new_seed: int, world_node: Node2D, start_pos: Vector2) -> void:
	clear()
	stage = biome
	seed_value = new_seed
	world = world_node
	origin = start_pos
	_patch.seed = new_seed + 7
	_patch.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_patch.frequency = 0.045
	_patch.fractal_octaves = 2
	_forest.seed = new_seed
	_forest.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_forest.frequency = 0.0045
	_forest.fractal_octaves = 3
	_detail.seed = new_seed + 99
	_detail.frequency = 0.03
	update_around(start_pos)


func clear() -> void:
	for c in _chunks.values():
		if is_instance_valid(c):
			c.queue_free()
	_chunks.clear()


func update_around(pos: Vector2) -> void:
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


## Vértice da grade de manchas (true = mancha). Determinístico.
func _vertex(vx: int, vy: int) -> bool:
	var n := _patch.get_noise_2d(vx, vy)
	return n > float(stage.get("patch_threshold", 0.3))


func _build_chunk(key: Vector2i) -> Node2D:
	var chunk := Node2D.new()
	chunk.name = "Chunk_%d_%d" % [key.x, key.y]
	chunk.y_sort_enabled = true
	world.add_child(chunk)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, key.x, key.y])
	var t0 := key * CHUNK_TILES
	var block: Vector2i = stage["floor_block"]
	var tint: Color = stage.get("ground_tint", Color.WHITE)

	# ---------- chão (marching squares)
	var ground := make_layer(-60)
	ground.modulate = tint
	chunk.add_child(ground)
	var decor := make_layer(-59)
	decor.modulate = tint
	chunk.add_child(decor)
	var verts: Array = []
	for vy in CHUNK_TILES + 1:
		var row: Array = []
		for vx in CHUNK_TILES + 1:
			row.append(_vertex(t0.x + vx, t0.y + vy))
		verts.append(row)
	var decor_list: Array = stage.get("decor", [])
	for ty in CHUNK_TILES:
		for tx in CHUNK_TILES:
			var m := (1 if verts[ty][tx] else 0) | (2 if verts[ty][tx + 1] else 0) \
					| (4 if verts[ty + 1][tx + 1] else 0) | (8 if verts[ty + 1][tx] else 0)
			var cell: Vector2i = MS[m]
			if m == 0 and rng.randf() < 0.12:
				cell = BASE_DETAILS[rng.randi() % BASE_DETAILS.size()]
			ground.set_cell(Vector2i(tx, ty), SRC_FLOOR, block + cell)
			if m == 0 and not decor_list.is_empty() and rng.randf() < 0.045:
				var d: Array = decor_list[rng.randi() % decor_list.size()]
				decor.set_cell(Vector2i(tx, ty), d[0], d[1])
	ground.position = Vector2(t0 * TILE)
	decor.position = ground.position

	# ---------- árvores
	var density: float = stage.get("tree_density", 0.55)
	var tree_list: Array = stage["trees"]
	var base := Vector2(key * CHUNK)
	var steps := CHUNK / TREE_STEP
	for gy in steps:
		for gx in steps:
			var p := base + Vector2(gx * TREE_STEP, gy * TREE_STEP)
			p += Vector2(rng.randf_range(4, TREE_STEP - 4), rng.randf_range(4, TREE_STEP - 4))
			if p.distance_to(origin) < SAFE_RADIUS:
				continue
			var n := _forest.get_noise_2dv(p)               # -1..1 (bosques x clareiras)
			var chance := smoothstep(0.0, 0.45, n) * density * 0.9 + 0.025
			chance += _detail.get_noise_2dv(p) * 0.05
			if rng.randf() < chance:
				_add_tree(chunk, p, tree_list[rng.randi() % tree_list.size()], rng)
	return chunk


# ------------------------------------------------------------------ árvores
## tree_def: int (Forest Trees Pack) ou Array [coluna, linha, largura, altura]
## em tiles do TilesetNature (Ninja Adventure).
func _add_tree(parent: Node2D, pos: Vector2, tree_def, rng: RandomNumberGenerator) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var shape := CircleShape2D.new()
	var s := Sprite2D.new()
	s.centered = false
	if tree_def is int:
		s.texture = _tex(FOREST_TREE % tree_def)
		s.offset = Vector2(-32, -58)
		shape.radius = 6.0
	else:
		var r: Array = tree_def
		s.texture = _tex(NINJA + "TilesetNature.png")
		s.region_enabled = true
		s.region_rect = Rect2(r[0] * TILE, r[1] * TILE, r[2] * TILE, r[3] * TILE)
		s.offset = Vector2(-r[2] * TILE / 2.0, -r[3] * TILE + 3)
		shape.radius = 5.0 + 1.5 * (r[2] - 2)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -3)
	body.add_child(cs)
	if rng.randf() < 0.5:
		s.flip_h = true
	var tint: Color = stage.get("tree_tint", Color.WHITE)
	var v := rng.randf_range(0.92, 1.06)
	s.modulate = Color(tint.r * v, tint.g * v, tint.b * v)
	body.add_child(s)
	parent.add_child(body)


func _tex(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path]


## Há alguma árvore neste ponto?
func is_blocked(pos: Vector2, radius: float = 10.0) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	q.shape = c
	q.transform = Transform2D(0, pos)
	q.collision_mask = 1
	return not space.intersect_shape(q, 1).is_empty()
