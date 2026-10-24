extends Control
## Seleção e compra de personagens com moedas.

var _grid: GridContainer
var _coin_label: Label
var _preview: AnimatedSprite2D
var _name: Label
var _weapon: Label
var _perk: Label
var _action: Button
var _status: Label
var _potion: TextureRect
var _current := Global.DEFAULT_CHAR
var _cards: Dictionary = {}


func _ready() -> void:
	theme = UITheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBackground.new())

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	var title := UITheme.label("PERSONAGENS", 40, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var ci := TextureRect.new()
	ci.texture = SpriteLib.fx("coin").get_frame_texture("spin", 0)
	ci.custom_minimum_size = Vector2(36, 36)
	ci.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header.add_child(ci)
	_coin_label = UITheme.label("", 24, UITheme.GOLD)
	_coin_label.custom_minimum_size = Vector2(120, 0)
	header.add_child(_coin_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)

	var grid_panel := PanelContainer.new()
	grid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid_panel.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 8
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)

	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override("panel", UITheme.panel("orange"))
	detail.custom_minimum_size = Vector2(360, 0)
	detail.size_flags_horizontal = Control.SIZE_SHRINK_END
	body.add_child(detail)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 10)
	detail.add_child(dv)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 170)
	dv.add_child(holder)
	_preview = AnimatedSprite2D.new()
	_preview.scale = Vector2(5, 5)
	holder.add_child(_preview)
	holder.resized.connect(func(): _preview.position = Vector2(holder.size.x / 2.0, 85))
	_name = UITheme.label("", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	dv.add_child(_name)
	_potion = TextureRect.new()
	_potion.custom_minimum_size = Vector2(48, 72)
	_potion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_potion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dv.add_child(_potion)
	_weapon = UITheme.label("", 16, Color(1, 0.95, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
	_weapon.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_weapon.custom_minimum_size = Vector2(320, 0)
	dv.add_child(_weapon)
	_perk = UITheme.label("", 16, Color(0.85, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER)
	_perk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_perk.custom_minimum_size = Vector2(320, 0)
	dv.add_child(_perk)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(spacer)
	_status = UITheme.label("", 16, Color(1, 0.8, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
	dv.add_child(_status)
	_action = UITheme.button("", 16, 300)
	_action.pressed.connect(_on_action)
	dv.add_child(_action)
	var play := UITheme.button("Jogar", 24, 300)
	play.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/game.tscn"))
	dv.add_child(play)

	for id in DB.character_order():
		var card := _make_card(id)
		_grid.add_child(card)
		_cards[id] = card
	_select(Global.selected_char)


func _make_card(id: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(98, 112)
	b.toggle_mode = false
	var icon := TextureRect.new()
	icon.texture = SpriteLib.character_icon(id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 10
	icon.offset_right = -10
	icon.offset_top = 6
	icon.offset_bottom = -34
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	var lbl := UITheme.label("", 16, UITheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	lbl.add_theme_constant_override("outline_size", 0)
	lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl.offset_top = -38
	lbl.offset_bottom = -16
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.name = "Price"
	b.add_child(lbl)
	b.pressed.connect(func(): _select(id))
	_update_card(b, id)
	return b


func _update_card(b: Button, id: int) -> void:
	var icon: TextureRect = b.get_child(0)
	var lbl: Label = b.get_node("Price")
	if Global.is_unlocked(id):
		icon.modulate = Color.WHITE
		lbl.text = "EM USO" if id == Global.selected_char else DB.WEAPONS[DB.CHARACTERS[id]["weapon"]]["element"]
	else:
		icon.modulate = Color(0.22, 0.22, 0.3, 0.9)
		lbl.text = "$%d" % DB.CHARACTERS[id]["price"]


func _select(id: int) -> void:
	_current = id
	var d: Dictionary = DB.CHARACTERS[id]
	_preview.sprite_frames = SpriteLib.character(id)
	_preview.play("running_down")
	_preview.modulate = Color.WHITE if Global.is_unlocked(id) else Color(0.25, 0.25, 0.32)
	_name.text = d["name"]
	var wd: Dictionary = DB.WEAPONS[d["weapon"]]
	_weapon.text = "%s\nPoder: %s" % [wd["potion"], wd["name"]]
	_potion.texture = SpriteLib.potion_icon(d["weapon"])
	_perk.text = d["desc"]
	_status.text = ""
	_refresh()


func _refresh() -> void:
	_coin_label.text = str(Global.coins)
	var id := _current
	if Global.is_unlocked(id):
		_action.text = "Selecionado" if id == Global.selected_char else "Selecionar"
		_action.disabled = id == Global.selected_char
	else:
		var price: int = DB.CHARACTERS[id]["price"]
		_action.text = "Comprar ($%d)" % price
		_action.disabled = Global.coins < price
	for cid in _cards:
		_update_card(_cards[cid], cid)


func _on_action() -> void:
	var id := _current
	if not Global.is_unlocked(id):
		if Global.try_buy(id):
			_status.text = "Desbloqueado!"
			_preview.modulate = Color.WHITE
		else:
			_status.text = "Moedas insuficientes."
			_refresh()
			return
	Global.select_char(id)
	_refresh()
