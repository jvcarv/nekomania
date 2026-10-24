class_name UITheme
## Tema visual montado a partir do pacote "01_Flat_Theme" (assets/UI).

const DIR := "res://assets/generated/ui/"   # cópias 3x (nearest) do pacote Flat UI
const TEXT_DARK := Color(0.23, 0.16, 0.12)
const TEXT_LIGHT := Color(1, 0.98, 0.92)
const GOLD := Color(1.0, 0.82, 0.3)

static var _theme: Theme


static func tex(name: String) -> Texture2D:
	return load(DIR + name + ".png")


static func box(name: String, margin: int, content: Vector4 = Vector4(10, 8, 10, 10)) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex(name)
	var m := margin * 3
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m
	sb.content_margin_left = content.x
	sb.content_margin_top = content.y
	sb.content_margin_right = content.z
	sb.content_margin_bottom = content.w
	return sb


## Painel (molduras do pacote). kind: "blue", "orange", "gray"
static func panel(kind: String = "blue") -> StyleBoxTexture:
	var n: String = {"gray": "UI_Flat_Frame01a", "blue": "UI_Flat_Frame02a", "orange": "UI_Flat_Frame03a"}[kind]
	return box(n, 6, Vector4(18, 14, 18, 16))


static func slot(kind: String = "blue") -> StyleBoxTexture:
	var n: String = {"gray": "UI_Flat_FrameSlot01a", "blue": "UI_Flat_FrameSlot02a", "orange": "UI_Flat_FrameSlot03a"}[kind]
	return box(n, 5, Vector4(6, 6, 6, 6))


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 22
	# Botões
	t.set_stylebox("normal", "Button", box("UI_Flat_Button02a_3", 8, Vector4(16, 8, 16, 14)))
	t.set_stylebox("hover", "Button", box("UI_Flat_Button02a_4", 8, Vector4(16, 6, 16, 16)))
	t.set_stylebox("pressed", "Button", box("UI_Flat_Button02a_1", 8, Vector4(16, 12, 16, 10)))
	t.set_stylebox("disabled", "Button", box("UI_Flat_Button02a_1", 8, Vector4(16, 12, 16, 10)))
	t.set_stylebox("focus", "Button", box("UI_Flat_Button02a_4", 8, Vector4(16, 6, 16, 16)))
	t.set_color("font_color", "Button", TEXT_DARK)
	t.set_color("font_hover_color", "Button", Color(0.55, 0.25, 0.05))
	t.set_color("font_pressed_color", "Button", TEXT_DARK)
	t.set_color("font_focus_color", "Button", Color(0.55, 0.25, 0.05))
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.45, 0.4))
	# Painéis
	t.set_stylebox("panel", "PanelContainer", panel("blue"))
	t.set_stylebox("panel", "Panel", panel("blue"))
	# Rótulos
	t.set_color("font_color", "Label", TEXT_LIGHT)
	t.set_color("font_outline_color", "Label", Color(0.08, 0.06, 0.12))
	t.set_constant("outline_size", "Label", 6)
	t.set_color("default_color", "RichTextLabel", TEXT_LIGHT)
	t.set_color("font_outline_color", "RichTextLabel", Color(0.08, 0.06, 0.12))
	t.set_constant("outline_size", "RichTextLabel", 5)
	t.set_font_size("normal_font_size", "RichTextLabel", 18)
	t.set_font_size("bold_font_size", "RichTextLabel", 18)
	# Barras de rolagem discretas
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.25)
	t.set_stylebox("scroll", "VScrollBar", sb)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(1, 0.85, 0.5, 0.8)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	_theme = t
	return t


static func label(text: String, size: int = 22, color: Color = TEXT_LIGHT, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


static func button(text: String, size: int = 24, min_w: float = 260.0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(min_w, 0)
	b.focus_mode = Control.FOCUS_ALL
	return b


## Ícone de cada arma (um quadro do próprio efeito).
static func weapon_icon(id: String) -> Texture2D:
	var map := {
		"fire": ["firebolt", "fly", 1], "holy": ["holy_spark", "hit", 1], "dark": ["dark", "fly", 0],
		"ice": ["ice", "fly", 2], "thunder": ["thunder", "hit", 1], "acid": ["acid_blob", "hit", 0],
		"wood": ["wood", "fly", 0],
	}
	var m: Array = map[id]
	return SpriteLib.fx(m[0]).get_frame_texture(m[1], m[2])
