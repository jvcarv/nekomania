extends Control
class_name PixelBar
## Barra (vida, experiência, chefão) usando a moldura do pacote Flat UI.

var fill_color := Color(0.85, 0.15, 0.2):
	set(v):
		fill_color = v
		if _fill:
			_fill.color = v
var ratio := 1.0:
	set(v):
		ratio = clampf(v, 0.0, 1.0)
		_layout()
var text := "":
	set(v):
		text = v
		if _label:
			_label.text = v

var _frame: NinePatchRect
var _back: ColorRect
var _fill: ColorRect
var _label: Label
const INSET := 9


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = NinePatchRect.new()
	_frame.texture = load("res://assets/generated/ui/UI_Flat_Bar05a.png")
	_frame.patch_margin_left = 9
	_frame.patch_margin_right = 9
	_frame.patch_margin_top = 9
	_frame.patch_margin_bottom = 9
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_back = ColorRect.new()
	_back.color = Color(0.2, 0.16, 0.22)
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_back)
	_fill = ColorRect.new()
	_fill.color = fill_color
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	resized.connect(_layout)


func _layout() -> void:
	if _back == null:
		return
	var inner := Rect2(Vector2(INSET, INSET - 1), size - Vector2(INSET * 2, INSET * 2 - 2))
	_back.position = inner.position
	_back.size = inner.size
	_fill.position = inner.position
	_fill.size = Vector2(inner.size.x * ratio, inner.size.y)
