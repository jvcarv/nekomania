extends Control
class_name MenuBackground
## Fundo animado dos menus: chão procedural rolando + árvores + slimes passando.

var _ground: ColorRect
var _t := 0.0
var _walkers: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ground = ColorRect.new()
	_ground.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/ui/menu_ground.gdshader")
	_ground.material = mat
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ground)
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


func _process(delta: float) -> void:
	_t += delta
	(_ground.material as ShaderMaterial).set_shader_parameter("offset", Vector2(_t * 20.0, 0.0))
	var w := size.x
	for s in _walkers:
		s.position.x += delta * 50.0
		if s.position.x > w + 150.0:
			s.position.x = -150.0 - randf() * 600.0
