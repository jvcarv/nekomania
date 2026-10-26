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
	_title = UITheme.label("SUBIU DE NÍVEL!", 40, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_title)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 20)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_cards)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 20)
	v.add_child(bottom)
	_reroll_btn = UITheme.button("Sortear de novo", 16, 240)
	_reroll_btn.pressed.connect(_on_reroll)
	_reroll_btn.icon = _key_icon("R")
	bottom.add_child(_reroll_btn)
	var skip := UITheme.button("Pular (+20 vida)", 16, 240)
	skip.pressed.connect(func(): _pick({"type": "skip"}))
	skip.icon = _key_icon("X")
	bottom.add_child(skip)
	for btn: Button in [_reroll_btn, skip]:
		btn.add_theme_constant_override("icon_max_width", 32)
		btn.custom_minimum_size.x = 280


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
	var cards: Array = []
	for i in options.size():
		var card := _make_card(options[i], i)
		_cards.add_child(card)
		cards.append(card)
	_reroll_btn.text = "Sortear de novo (%d)" % game.rerolls
	_reroll_btn.disabled = game.rerolls <= 0
	await get_tree().process_frame
	# todas as cartas ficam com a altura da mais alta (o texto nunca vaza)
	var h := 360.0
	for c: Button in cards:
		var content: Control = c.get_node("Content")
		h = maxf(h, content.get_combined_minimum_size().y + 56.0)
	for c: Button in cards:
		c.custom_minimum_size.y = h
	if not cards.is_empty():
		(cards[0] as Control).grab_focus()


func _make_card(opt: Dictionary, idx: int) -> Button:
	var rarity: Dictionary = DB.RARITIES[opt["rarity"]]
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 360)
	b.focus_mode = Control.FOCUS_ALL
	var v := VBoxContainer.new()
	v.name = "Content"
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
			title = wd["potion"]
			subtitle = "Novo poder: %s (%s)" % [wd["name"], DB.element_name(opt["id"])]
			desc = wd["desc"]
			for ow in game.player.weapon_list():
				if DB.WEAPONS[ow.id]["elem"] == wd["elem"]:
					desc += " SINERGIA: +%d%% dano nos dois!" % int(DB.SYNERGY_BONUS * 100)
			icon = UITheme.weapon_icon(opt["id"])
		"weapon_up":
			var w := game.player.get_weapon(opt["id"])
			title = DB.WEAPONS[opt["id"]]["potion"]
			subtitle = "%s Nv %d -> %d" % [DB.WEAPONS[opt["id"]]["name"], w.level, w.level + 1]
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
			var key: String = opt["id"]
			var cur: float = game.player.stats[key]
			var nxt: float = cur + (int(val) if key == "projectiles" else val)
			desc += "\nAtual: %s -> %s" % [UITheme.stat_text(key, cur), UITheme.stat_text(key, nxt)]
	var rarity_lbl := UITheme.label(rarity["name"].to_upper() if opt["type"] != "weapon_new" else "NOVA POÇÃO", 16, rarity["color"], HORIZONTAL_ALIGNMENT_CENTER)
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
	var t := UITheme.label(title, 24, UITheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	t.add_theme_constant_override("outline_size", 0)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var st := UITheme.label(subtitle, 16, Color(0.45, 0.3, 0.2), HORIZONTAL_ALIGNMENT_CENTER)
	st.add_theme_constant_override("outline_size", 0)
	v.add_child(st)
	var d := UITheme.label(desc, 16, UITheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	d.add_theme_constant_override("outline_size", 0)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(260, 0)
	v.add_child(d)
	for c in v.get_children():
		if c is Control:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if c is Label:
			# quebra de linha para nada vazar da carta
			c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			c.custom_minimum_size.x = 260
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
	# contorno grosso de seleção (teclado/controle/mouse)
	var focus := Panel.new()
	focus.name = "Focus"
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_border_width_all(7)
	sb.border_color = Color(1, 0.95, 0.35)
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(1, 0.85, 0.2, 0.45)
	sb.shadow_size = 10
	focus.add_theme_stylebox_override("panel", sb)
	focus.set_anchors_preset(Control.PRESET_FULL_RECT)
	focus.offset_left = -9
	focus.offset_top = -9
	focus.offset_right = 9
	focus.offset_bottom = -5
	focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus.visible = false
	b.add_child(focus)
	# tecla de atalho (1, 2, 3) no canto superior esquerdo da carta — assets/Keys
	var key_tex := AtlasTexture.new()
	key_tex.atlas = load("res://assets/Keys/%d-Key.png" % (idx + 1))
	key_tex.region = Rect2(0, 0, 32, 32)   # quadro 0 = tecla solta
	var key_hint := TextureRect.new()
	key_hint.texture = key_tex
	key_hint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	key_hint.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	key_hint.position = Vector2(-10, -12)
	key_hint.size = Vector2(48, 48)
	key_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(key_hint)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.focus_entered.connect(func():
		focus.visible = true
		b.pivot_offset = b.size / 2.0
		b.scale = Vector2(1.05, 1.05)
		b.z_index = 1)
	b.focus_exited.connect(func():
		focus.visible = false
		b.scale = Vector2.ONE
		b.z_index = 0)
	b.mouse_entered.connect(func(): b.grab_focus())
	b.pressed.connect(func(): _pick(_options[idx]))
	return b


func _pick(opt: Dictionary) -> void:
	if _input_lock > 0.0:
		return
	chosen.emit(opt)


func _on_reroll() -> void:
	if game.rerolls > 0:
		_show(game.reroll())


## Ícone de tecla (assets/Keys, Gerald's Keys — CC0). Quadro 0 = tecla solta.
func _key_icon(letter: String) -> Texture2D:
	var t := AtlasTexture.new()
	t.atlas = load("res://assets/Keys/%s-Key.png" % letter)
	t.region = Rect2(0, 0, 32, 32)
	return t


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _input_lock > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_1 and k <= KEY_3 and k - KEY_1 < _options.size():
			_pick(_options[k - KEY_1])
			get_viewport().set_input_as_handled()
		elif k == KEY_R:
			if game.rerolls > 0:
				Sound.play("ui_accept")
				_on_reroll()
			else:
				Sound.play("denied")
			get_viewport().set_input_as_handled()
		elif k == KEY_X:
			_pick({"type": "skip"})
			get_viewport().set_input_as_handled()
		elif k in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT]:
			_move_focus(-1 if k in [KEY_A, KEY_LEFT] else 1)
			get_viewport().set_input_as_handled()
		elif k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			var f := get_viewport().gui_get_focus_owner()
			if f is Button:
				(f as Button).pressed.emit()
				get_viewport().set_input_as_handled()


func _move_focus(step: int) -> void:
	var cards := _cards.get_children().filter(func(c): return not c.is_queued_for_deletion())
	if cards.is_empty():
		return
	var f := get_viewport().gui_get_focus_owner()
	var i := cards.find(f)
	i = 0 if i < 0 else clampi(i + step, 0, cards.size() - 1)
	(cards[i] as Control).grab_focus()
