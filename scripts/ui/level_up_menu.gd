extends CanvasLayer
class_name LevelUpMenu
## Tela de escolha de melhoria ao subir de nível (3 cartas com raridade).

signal chosen(option: Dictionary)

var game: Game
var _cards: HBoxContainer
var _title: Label
var _reroll_btn: Button
var _options: Array = []
var _input_lock := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.get_theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.1, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	_title = UITheme.label("SUBIU DE NÍVEL!", 44, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_title)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 20)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_cards)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 20)
	v.add_child(bottom)
	_reroll_btn = UITheme.button("Sortear de novo", 20, 240)
	_reroll_btn.pressed.connect(_on_reroll)
	bottom.add_child(_reroll_btn)
	var skip := UITheme.button("Pular (+20 vida)", 20, 240)
	skip.pressed.connect(func(): _pick({"type": "skip"}))
	bottom.add_child(skip)


func open(g: Game, options: Array) -> void:
	game = g
	visible = true
	_input_lock = 0.35   # evita clicar sem querer enquanto se movimenta
	_title.text = "SUBIU DE NÍVEL! (Nv %d)" % (g.player.level - g._pending_levels + 1)
	_show(options)


func close() -> void:
	visible = false


func _process(delta: float) -> void:
	if _input_lock > 0.0:
		_input_lock -= delta


func _show(options: Array) -> void:
	_options = options
	for c in _cards.get_children():
		c.queue_free()
	for i in options.size():
		_cards.add_child(_make_card(options[i], i))
	_reroll_btn.text = "Sortear de novo (%d)" % game.rerolls
	_reroll_btn.disabled = game.rerolls <= 0
	await get_tree().process_frame
	if _cards.get_child_count() > 0:
		(_cards.get_child(0) as Control).grab_focus()


func _make_card(opt: Dictionary, idx: int) -> Button:
	var rarity: Dictionary = DB.RARITIES[opt["rarity"]]
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 330)
	b.focus_mode = Control.FOCUS_ALL
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 18
	v.offset_right = -18
	v.offset_top = 16
	v.offset_bottom = -30
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)

	var title := ""
	var subtitle := ""
	var desc := ""
	var icon: Texture2D = null
	match opt["type"]:
		"weapon_new":
			var wd: Dictionary = DB.WEAPONS[opt["id"]]
			title = wd["name"]
			subtitle = "NOVA ARMA — " + wd["element"]
			desc = wd["desc"]
			icon = UITheme.weapon_icon(opt["id"])
		"weapon_up":
			var w := game.player.get_weapon(opt["id"])
			title = DB.WEAPONS[opt["id"]]["name"]
			subtitle = "Nível %d → %d" % [w.level, w.level + 1]
			desc = w.upgrade_text(opt["rarity"])
			icon = UITheme.weapon_icon(opt["id"])
		"passive":
			var p: Dictionary = DB.PASSIVES[opt["id"]]
			title = p["name"]
			subtitle = "Melhoria — %s" % rarity["name"]
			var val: float = p["value"]
			if not p.get("flat", false):
				val *= rarity["mult"]
			var shown := str(int(round(val * 100.0))) if p["pct"] else ("%.1f" % val).trim_suffix(".0")
			desc = String(p["desc"]).replace("{v}", shown)
	var rarity_lbl := UITheme.label(rarity["name"].to_upper() if opt["type"] != "weapon_new" else "NOVA", 16, rarity["color"], HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(rarity_lbl)
	if icon:
		var tr := TextureRect.new()
		tr.texture = icon
		tr.custom_minimum_size = Vector2(72, 72)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tr)
	else:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 24)
		v.add_child(spacer)
	var t := UITheme.label(title, 26, UITheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	t.add_theme_constant_override("outline_size", 0)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var st := UITheme.label(subtitle, 16, Color(0.45, 0.3, 0.2), HORIZONTAL_ALIGNMENT_CENTER)
	st.add_theme_constant_override("outline_size", 0)
	v.add_child(st)
	var d := UITheme.label(desc, 18, UITheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	d.add_theme_constant_override("outline_size", 0)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(260, 0)
	v.add_child(d)
	for c in v.get_children():
		if c is Control:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# borda colorida pela raridade
	var border := ReferenceRect.new()
	border.border_color = rarity["color"]
	border.border_width = 3.0
	border.editor_only = false
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.offset_left = 6
	border.offset_top = 6
	border.offset_right = -6
	border.offset_bottom = -20
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(border)
	b.pressed.connect(func(): _pick(_options[idx]))
	return b


func _pick(opt: Dictionary) -> void:
	if _input_lock > 0.0:
		return
	chosen.emit(opt)


func _on_reroll() -> void:
	if game.rerolls > 0:
		_show(game.reroll())


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _input_lock > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_1 and k <= KEY_3 and k - KEY_1 < _options.size():
			_pick(_options[k - KEY_1])
