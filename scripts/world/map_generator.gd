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
##  - Planaltos (verticalidade): TilesetRelief + escada do TilesetReliefDetail.
##    São retângulos elevados, cercados por paredes, que só podem ser
##    acessados pela(s) escada(s). Inimigos usam as escadas para subir/descer.
##  - Árvores e enfeites: Forest Trees Pack + TilesetNature + TilesetFloorDetail.

const TILE := 16
const CHUNK := 256                     # 16 x 16 tiles
const CHUNK_TILES := CHUNK / TILE
const LOAD_RADIUS := 2                 # chunks carregados em volta do jogador
const TREE_STEP := 36                  # grade base para posicionar árvores
const SAFE_RADIUS := 150.0             # clareira garantida no início do estágio
const CLIFF_LAYER := 16                # camada física 5 = paredes dos planaltos

const NINJA := "res://assets/map/Ninja Adventure - Asset Pack/Backgrounds/Tilesets/"
const FOREST_TREE := "res://assets/map/Forest Trees Pack – Pixel Art (32x32, Top-Down RPG)/Forest Trees Pack – Pixel Art (32x32, Top-Down RPG)/spr_tree_%d.png"

# fontes do TileSet
const SRC_FLOOR := 0
const SRC_RELIEF := 1
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
var _plateaus: Dictionary = {}         # Vector2i -> Dictionary (ou {} sem planalto)
var _textures: Dictionary = {}


# ------------------------------------------------------------------ TileSet
static func tileset() -> TileSet:
	if _tileset:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var files := {SRC_FLOOR: "TilesetFloor.png", SRC_RELIEF: "TilesetRelief.png",
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
	_plateaus.clear()


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

	# ---------- planalto (verticalidade)
	var plat := plateau_for_chunk(key)
	if not plat.is_empty():
		_build_plateau(chunk, plat, decor)

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
			if not plat.is_empty() and Rect2(plat["clear"]).has_point(p):
				continue
			var n := _forest.get_noise_2dv(p)               # -1..1 (bosques x clareiras)
			var chance := smoothstep(0.0, 0.45, n) * density * 0.9 + 0.025
			chance += _detail.get_noise_2dv(p) * 0.05
			if rng.randf() < chance:
				_add_tree(chunk, p, tree_list[rng.randi() % tree_list.size()], rng)
	return chunk


# ------------------------------------------------------------------ planaltos
## Dados do planalto de um chunk ({} se não houver). Determinístico e em cache.
func plateau_for_chunk(key: Vector2i) -> Dictionary:
	if _plateaus.has(key):
		return _plateaus[key]
	var plat: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, key.x, key.y, "planalto"])
	if rng.randf() < float(stage.get("plateau_chance", 0.35)):
		var w := rng.randi_range(5, 9)
		var h := rng.randi_range(4, 7)                   # inclui borda de cima e a parede
		var tx := rng.randi_range(2, CHUNK_TILES - w - 2)
		var ty := rng.randi_range(1, CHUNK_TILES - h - 3)
		var t0 := key * CHUNK_TILES + Vector2i(tx, ty)
		var px := Vector2(t0 * TILE)
		var full := Rect2(px, Vector2(w, h) * TILE)
		if full.grow(48.0).has_point(origin) or full.get_center().distance_to(origin) < SAFE_RADIUS + 80.0:
			_plateaus[key] = {}
			return {}
		var ladders: Array = []
		var lcols: Array = [rng.randi_range(1, w - 2)]
		if w >= 8:
			var other := rng.randi_range(1, w - 2)
			if absi(other - lcols[0]) >= 2:
				lcols.append(other)
		for lc in lcols:
			var lx: float = px.x + float(lc) * TILE + TILE / 2.0
			ladders.append({
				"col": lc,
				"top": Vector2(lx, px.y + (h - 2) * TILE + TILE / 2.0),
				"bottom": Vector2(lx, px.y + h * TILE + TILE / 2.0 + 2.0),
			})
		plat = {
			"key": key, "t0": t0, "w": w, "h": h, "rect": full,
			# área "de cima" (onde se anda no alto)
			"high": Rect2(px + Vector2(4, 6), Vector2(w * TILE - 8, (h - 1) * TILE - 6)),
			# área sem árvores (planalto + entorno da escada)
			"clear": full.grow(24.0).expand(px + Vector2(0, (h + 3) * TILE)),
			"ladders": ladders,
		}
	_plateaus[key] = plat
	return plat


func _build_plateau(chunk: Node2D, plat: Dictionary, decor: TileMapLayer) -> void:
	var w: int = plat["w"]
	var h: int = plat["h"]
	var t0: Vector2i = plat["t0"]
	var row0: int = int(stage.get("relief_row", 0))   # 0 = pedra/neve, 5 = areia
	var relief := make_layer(-58)
	relief.modulate = stage.get("ground_tint", Color.WHITE)
	relief.position = Vector2(t0 * TILE)
	chunk.add_child(relief)
	for j in h:
		for i in w:
			var col := 1 if i == 0 else (3 if i == w - 1 else 2)
			var row := 0 if j == 0 else (2 if j == h - 1 else 1)
			relief.set_cell(Vector2i(i, j), SRC_RELIEF, Vector2i(col, row0 + row))
	# topo do planalto com o chão do bioma (deixa a borda de pedra em volta)
	if stage.has("plateau_top"):
		var top := make_layer(-57)
		top.modulate = relief.modulate
		top.position = relief.position
		chunk.add_child(top)
		var tb: Vector2i = stage["plateau_top"]
		var trng := RandomNumberGenerator.new()
		trng.seed = hash([seed_value, t0.x, t0.y])
		for j in range(1, h - 1):
			for i in range(1, w - 1):
				var cell: Vector2i = MS[0]
				if trng.randf() < 0.15:
					cell = BASE_DETAILS[trng.randi() % BASE_DETAILS.size()]
				top.set_cell(Vector2i(i, j), SRC_FLOOR, tb + cell)
	# remove enfeites do chão debaixo do planalto e da escada
	var local0: Vector2i = t0 - (plat["key"] as Vector2i) * CHUNK_TILES
	for j in range(-1, h + 2):
		for i in range(-1, w + 1):
			decor.erase_cell(local0 + Vector2i(i, j))

	# paredes (só as escadas ficam abertas)
	var body := StaticBody2D.new()
	body.collision_layer = CLIFF_LAYER
	body.collision_mask = 0
	var r: Rect2 = plat["rect"]
	var thick := 6.0
	_add_box(body, Rect2(r.position.x, r.position.y, r.size.x, thick))                       # topo
	_add_box(body, Rect2(r.position.x, r.position.y, thick, r.size.y))                       # esquerda
	_add_box(body, Rect2(r.end.x - thick, r.position.y, thick, r.size.y))                    # direita
	var face_y := r.position.y + (h - 1) * TILE
	var open_cols: Array = []
	for l in plat["ladders"]:
		open_cols.append(l["col"])
	var start := 0
	for i in w + 1:
		if i == w or open_cols.has(i):
			if i > start:
				_add_box(body, Rect2(r.position.x + start * TILE, face_y, (i - start) * TILE, TILE))
			start = i + 1
	chunk.add_child(body)

	# escadas (TilesetReliefDetail: coluna 3, 3 tiles de altura)
	var ladder_row := 0 if row0 == 0 else 3
	for l in plat["ladders"]:
		var s := Sprite2D.new()
		s.texture = _tex(NINJA + "TilesetReliefDetail.png")
		s.region_enabled = true
		s.region_rect = Rect2(3 * TILE, ladder_row * TILE, TILE, 3 * TILE)
		s.centered = false
		s.position = Vector2(r.position.x + float(l["col"]) * TILE, r.position.y + (h - 2) * TILE)
		s.z_index = -56
		s.z_as_relative = false
		s.modulate = stage.get("ground_tint", Color.WHITE)
		chunk.add_child(s)


func _add_box(body: StaticBody2D, rect: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.get_center()
	body.add_child(cs)


## Planalto em que a posição está (no alto), ou {} se estiver no chão.
func plateau_at(pos: Vector2) -> Dictionary:
	var key := Vector2i(floori(pos.x / CHUNK), floori(pos.y / CHUNK))
	var p := plateau_for_chunk(key)
	if not p.is_empty() and Rect2(p["high"]).has_point(pos):
		return p
	return {}


## Planaltos perto de um ponto (para o minimapa).
func plateaus_near(pos: Vector2, radius: float) -> Array:
	var out: Array = []
	var cc := Vector2i(floori(pos.x / CHUNK), floori(pos.y / CHUNK))
	var n := int(ceil(radius / CHUNK))
	for dy in range(-n, n + 1):
		for dx in range(-n, n + 1):
			var p := plateau_for_chunk(cc + Vector2i(dx, dy))
			if not p.is_empty():
				out.append(p)
	return out


## Para onde um inimigo deve andar para chegar ao alvo, usando as escadas
## quando um dos dois está em cima de um planalto.
func route(from: Vector2, to: Vector2) -> Vector2:
	var pf := plateau_at(from)
	var pt := plateau_at(to)
	var kf = pf.get("key")
	var kt = pt.get("key")
	if kf == kt:
		return to
	if not pf.is_empty():
		# está no alto e o alvo não: desce pela escada mais próxima
		var l := _nearest_ladder(pf, from)
		if from.distance_to(l["top"]) > 6.0:
			return l["top"]
		return l["bottom"]
	# está embaixo e o alvo está num planalto: vai até a escada e sobe
	var l2 := _nearest_ladder(pt, from)
	var bottom: Vector2 = l2["bottom"]
	var top: Vector2 = l2["top"]
	var in_column := absf(from.x - bottom.x) < 7.0 and from.y < bottom.y + 6.0 and from.y > top.y - 4.0
	if in_column:
		return top + Vector2(0, -10)
	return bottom


func _nearest_ladder(p: Dictionary, from: Vector2) -> Dictionary:
	var best: Dictionary = p["ladders"][0]
	for l in p["ladders"]:
		if from.distance_squared_to(l["bottom"]) < from.distance_squared_to(best["bottom"]):
			best = l
	return best


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


## Há algo sólido (árvore ou parede de planalto) neste ponto?
func is_blocked(pos: Vector2, radius: float = 10.0) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	q.shape = c
	q.transform = Transform2D(0, pos)
	q.collision_mask = 1 | CLIFF_LAYER
	if not space.intersect_shape(q, 1).is_empty():
		return true
	for p in plateaus_near(pos, 1.0):
		if Rect2(p["rect"]).grow(radius).has_point(pos) and not Rect2(p["high"]).has_point(pos):
			return true
	return false
