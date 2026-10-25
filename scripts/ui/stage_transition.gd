extends CanvasLayer
class_name StageTransition
## Transição entre mundos: escurece a tela e mostra o número e o nome do estágio.

var _rect: ColorRect
var _title: Label
var _sub: Label


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	add_child(root)
	_rect = ColorRect.new()
	_rect.color = Color(0.03, 0.01, 0.07)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	root.add_child(_rect)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(v)
	_title = UITheme.label("", 24, Color(0.85, 0.7, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	_sub = UITheme.label("", 48, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_title)
	v.add_child(_sub)
	_title.modulate.a = 0.0
	_sub.modulate.a = 0.0


func fade_out(t: float = 0.45) -> void:
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 1.0, t)
	await tw.finished


## Mostra o título sobre a tela escura e depois clareia.
func show_title(stage: int, biome_name: String) -> void:
	_title.text = "ESTÁGIO %d" % stage
	_sub.text = biome_name
	_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_title, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(_sub, "modulate:a", 1.0, 0.3)
	tw.tween_property(_sub, "scale", Vector2.ONE, 0.0)
	tw.tween_interval(1.1)
	tw.tween_property(_title, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(_sub, "modulate:a", 0.0, 0.3)
	tw.tween_property(_rect, "modulate:a", 0.0, 0.45)
	await tw.finished


## Abertura da partida (sem escurecer antes).
func intro(stage: int, biome_name: String) -> void:
	_rect.modulate.a = 1.0
	await show_title(stage, biome_name)
