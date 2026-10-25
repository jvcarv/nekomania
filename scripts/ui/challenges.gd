extends Control
## Tela de Desafios: lista os personagens que exigem um desafio,
## com o progresso de cada um.

var _list: VBoxContainer
var _summary: Label


func _ready() -> void:
	theme = UITheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBackground.new())

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var back := UITheme.button("Voltar", 16, 160)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	header.add_child(back)
	var title := UITheme.label("DESAFIOS", 40, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_summary = UITheme.label("", 16, Color(0.85, 1, 0.85), HORIZONTAL_ALIGNMENT_RIGHT)
	_summary.custom_minimum_size = Vector2(160, 0)
	header.add_child(_summary)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	var hint := UITheme.label("Conclua um desafio para poder comprar o personagem na tela Personagens.",
			16, Color(0.9, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(hint)

	_build()
	back.grab_focus()


func _build() -> void:
	var ids: Array = []
	for id in DB.CHARACTERS:
		if DB.CHARACTERS[id].has("req"):
			ids.append(id)
	# concluídos primeiro, depois por progresso
	ids.sort_custom(func(a, b):
		var pa := Global.req_progress(a)
		var pb := Global.req_progress(b)
		var ra := float(pa[0]) / float(pa[1])
		var rb := float(pb[0]) / float(pb[1])
		return ra > rb if ra != rb else a < b)
	var done := 0
	for id in ids:
		if Global.req_met(id):
			done += 1
		_list.add_child(_row(id))
	_summary.text = "%d/%d concluídos" % [done, ids.size()]


func _row(id: int) -> Control:
	var d: Dictionary = DB.CHARACTERS[id]
	var p := Global.req_progress(id)
	var met: bool = p[0] >= p[1]
	var owned := Global.is_unlocked(id)

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.slot("orange" if met else "gray"))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	box.add_child(h)

	var icon := TextureRect.new()
	icon.texture = SpriteLib.character_icon(id)
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE if met else Color(0.15, 0.15, 0.2)
	h.add_child(icon)

	var potion := TextureRect.new()
	potion.texture = SpriteLib.potion_icon(d["weapon"])
	potion.custom_minimum_size = Vector2(32, 48)
	potion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	potion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	potion.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(potion)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(info)
	var name_lbl := UITheme.label(d["name"] if met else "???", 24, Color.WHITE)
	info.add_child(name_lbl)
	var req := UITheme.label(Global.req_text(id), 16, Color(1, 0.95, 0.8))
	req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(req)
	var bar := PixelBar.new()
	bar.custom_minimum_size = Vector2(0, 30)
	bar.fill_color = Color(0.35, 0.9, 0.4) if met else Color(1.0, 0.7, 0.2)
	bar.ratio = float(p[0]) / float(p[1])
	bar.text = "%d / %d" % [p[0], p[1]] if p[1] > 1 else ("Feito" if met else "Pendente")
	info.add_child(bar)

	var status := UITheme.label("", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	status.custom_minimum_size = Vector2(200, 0)
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if owned:
		status.text = "DESBLOQUEADO"
		status.add_theme_color_override("font_color", Color(0.5, 1, 0.55))
	elif met:
		status.text = "CONCLUÍDO!\nCompre por $%d" % d["price"]
		status.add_theme_color_override("font_color", UITheme.GOLD)
	else:
		status.text = "Bloqueado\n$%d" % d["price"]
		status.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	h.add_child(status)
	return box
