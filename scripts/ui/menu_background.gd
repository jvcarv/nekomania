extends Control
class_name MenuBackground
## Fundo animado dos menus: chão de grama (tiles do Ninja Adventure, CC0)
## rolando devagar + inimigos passando.

const SCALE := 3.0
const TILES_W := 160
const TILES_H := 18

var _ground: Node2D
var _t := 0.0
var _walkers: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_ground = Node2D.new()
	_ground.scale = Vector2.ONE * SCALE
	add_child(_ground)
	var layer := MapGenerator.make_layer(0)
	layer.z_as_relative = true
	_ground.add_child(layer)
	_fill(layer)
	var types := ["slime", "skeleton", "orc", "werewolf", "archer", "slime", "werebear"]
	for i in types.size():
		var s := AnimatedSprite2D.new()
		s.sprite_frames = SpriteLib.enemy(types[i])
		s.play("walk")
		s.scale = Vector2(3, 3)
		s.position = Vector2(-200 - i * 260, 560 + (i % 3) * 40)
		add_child(s)
		_walkers.append(s)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.02, 0.12, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


## Grama com manchas de terra (mesmo marching squares do mapa do jogo).
func _fill(layer: TileMapLayer) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 4
	noise.frequency = 0.08
	var block := Vector2i(0, 7)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for ty in TILES_H:
		for tx in TILES_W:
			var m := 0
			if noise.get_noise_2d(tx, ty) > 0.35: m |= 1
			if noise.get_noise_2d(tx + 1, ty) > 0.35: m |= 2
			if noise.get_noise_2d(tx + 1, ty + 1) > 0.35: m |= 4
			if noise.get_noise_2d(tx, ty + 1) > 0.35: m |= 8
			var cell: Vector2i = MapGenerator.MS[m]
			if m == 0 and rng.randf() < 0.12:
				cell = MapGenerator.BASE_DETAILS[rng.randi() % MapGenerator.BASE_DETAILS.size()]
			layer.set_cell(Vector2i(tx, ty), MapGenerator.SRC_FLOOR, block + cell)


func _process(delta: float) -> void:
	_t += delta
	var max_scroll := TILES_W * 16 * SCALE - size.x - 16.0
	_ground.position.x = -fmod(_t * 12.0, maxf(1.0, max_scroll))
	var w := size.x
	for s in _walkers:
		s.position.x += delta * 50.0
		if s.position.x > w + 150.0:
			s.position.x = -150.0 - randf() * 600.0
