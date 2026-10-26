extends Control
## Compêndio: explora gatos, inimigos e chefões, com todas as animações.
## Os nomes e descrições vêm de data/nomes.json (ver scripts/data/names.gd).

const BOSS_ATTACKS := {"slam": "Pancada em área", "charge": "Investida",
	"volley": "Rajada de projéteis", "summon": "Chama lacaios"}
const CAT_ANIMS := [["running_down", "Baixo"], ["running_left", "Esquerda"],
	["running_right", "Direita"], ["running_up", "Cima"], ["stop_down", "Parado"]]
const ENEMY_ANIMS := [["walk", "Andando"], ["idle", "Parado"], ["attack", "Atacando"],
	["hurt", "Dano"], ["death", "Morte"]]

var _tab := "cats"
var _tab_buttons: Dictionary = {}
var _list: VBoxContainer
var _holder: Control
var _sprite: AnimatedSprite2D
var _anim_row: HFlowContainer
var _name: Label
var _sub: Label
var _desc: Label
var _info: VBoxContainer
var _replay_t := 0.0


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
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	var back := UITheme.button("Voltar", 16, 160)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	header.add_child(back)
	var title := UITheme.label("COMPÊNDIO", 40, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	for t in [["cats", "Gatos"], ["enemies", "Inimigos"], ["bosses", "Chefões"]]:
		var b := UITheme.button(t[1], 16, 130)
		b.toggle_mode = true
		var key: String = t[0]
		b.pressed.connect(func(): _set_tab(key))
		header.add_child(b)
		_tab_buttons[key] = b

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)

	# lista à esquerda
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(360, 0)
	body.add_child(list_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

	# detalhe à direita
	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override("panel", UITheme.panel("orange"))
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail)
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 16)
	detail.add_child(dh)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(330, 0)
	left.add_theme_constant_override("separation", 8)
	dh.add_child(left)
	_holder = Control.new()
	_holder.custom_minimum_size = Vector2(330, 300)
	_holder.clip_contents = true
	left.add_child(_holder)
	var floor_bg := ColorRect.new()
	floor_bg.color = Color(0, 0, 0, 0.18)
	floor_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_holder.add_child(floor_bg)
	_sprite = AnimatedSprite2D.new()
	_holder.add_child(_sprite)
	_sprite.animation_finished.connect(func(): _replay_t = 0.6)
	_anim_row = HFlowContainer.new()
	_anim_row.add_theme_constant_override("h_separation", 6)
	_anim_row.add_theme_constant_override("v_separation", 6)
	left.add_child(_anim_row)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	dh.add_child(right)
	_name = UITheme.label("", 32, Color.WHITE)
	right.add_child(_name)
	_sub = UITheme.label("", 16, UITheme.GOLD)
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_sub)
	_desc = UITheme.label("", 16, Color(0.85, 1, 0.85))
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(300, 0)
	right.add_child(_desc)
	_info = VBoxContainer.new()
	_info.add_theme_constant_override("separation", 6)
	right.add_child(_info)

	var hint := UITheme.label("Os nomes e descrições podem ser trocados no arquivo data/nomes.json.",
			16, Color(0.9, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(hint)

	_set_tab("cats")
	back.grab_focus()


func _process(delta: float) -> void:
	_sprite.position = _holder.size / 2.0
	# animações que não repetem (ataque, dano, morte) recomeçam depois de uma pausa
	if _replay_t > 0.0:
		_replay_t -= delta
		if _replay_t <= 0.0:
			_sprite.frame = 0
			_sprite.play()


func _set_tab(key: String) -> void:
	_tab = key
	for k in _tab_buttons:
		(_tab_buttons[k] as Button).button_pressed = k == key
	for c in _list.get_children():
		c.queue_free()
	var first: Button = null
	match key:
		"cats":
			for id in DB.character_order():
				var b := _entry(SpriteLib.character_icon(id), Names.cat(id),
						"" if Global.is_unlocked(id) else "bloqueado", func(): _show_cat(id))
				first = first if first else b
		"enemies":
			for t in DB.ENEMIES:
				var b := _entry(_enemy_icon(t), Names.enemy(t), "", func(): _show_enemy(t))
				first = first if first else b
		"bosses":
			for i in DB.STAGES.size():
				var bd: Dictionary = DB.STAGES[i]["boss"]
				var b := _entry(_enemy_icon(bd["type"]), Names.boss(bd), "Estágio %d" % (i + 1),
						func(): _show_boss(i))
				first = first if first else b
	if first:
		first.pressed.emit()


func _entry(icon: Texture2D, text: String, note: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 52)
	b.focus_mode = Control.FOCUS_ALL
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -10
	h.offset_bottom = -6
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var tr := TextureRect.new()
	tr.texture = icon
	tr.custom_minimum_size = Vector2(40, 40)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tr)
	var l := UITheme.label(text, 16, UITheme.TEXT_DARK)
	l.add_theme_constant_override("outline_size", 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	if note != "":
		var n := UITheme.label(note, 16, Color(0.5, 0.35, 0.25), HORIZONTAL_ALIGNMENT_RIGHT)
		n.add_theme_constant_override("outline_size", 0)
		n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(n)
	b.pressed.connect(on_press)
	_list.add_child(b)
	return b


## Quadro parado do inimigo, recortado (a spritesheet tem muito espaço vazio).
func _enemy_icon(type: String) -> Texture2D:
	var src: Texture2D = SpriteLib.enemy(type).get_frame_texture("idle", 0)
	if src is AtlasTexture:
		var at := AtlasTexture.new()
		at.atlas = (src as AtlasTexture).atlas
		var r: Rect2 = (src as AtlasTexture).region
		at.region = Rect2(r.position + Vector2(30, 30), Vector2(40, 40))
		return at
	return src


# ------------------------------------------------------------------ detalhes
func _set_anims(frames: SpriteFrames, anims: Array, scale_v: float, tint: Color) -> void:
	_sprite.sprite_frames = frames
	_sprite.scale = Vector2.ONE * scale_v
	_sprite.modulate = tint
	for c in _anim_row.get_children():
		c.queue_free()
	for a in anims:
		var anim: String = a[0]
		var b := UITheme.button(a[1], 16, 0)
		b.pressed.connect(func(): _play(anim))
		_anim_row.add_child(b)
	_play(anims[0][0])


func _play(anim: String) -> void:
	_replay_t = 0.0
	_sprite.play(anim)
	_sprite.frame = 0


func _clear_info() -> void:
	for c in _info.get_children():
		c.queue_free()


func _info_line(text: String, color: Color = Color.WHITE) -> void:
	var l := UITheme.label(text, 16, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(300, 0)
	_info.add_child(l)


func _show_cat(id: int) -> void:
	var d: Dictionary = DB.CHARACTERS[id]
	_set_anims(SpriteLib.character(id), CAT_ANIMS, 7.0, Color.WHITE)
	_name.text = Names.cat(id)
	var wd: Dictionary = DB.WEAPONS[d["weapon"]]
	_sub.text = "%s — Poder: %s (%s)" % [wd["potion"], wd["name"], DB.element_name(d["weapon"])]
	_desc.text = Names.cat_desc(id)
	_clear_info()
	_info_line("Atributos iniciais (verde = bônus deste gato):", Color(1, 0.95, 0.8))
	_info.add_child(UITheme.stats_grid(UITheme.char_stats(id)))
	if Global.is_unlocked(id):
		_info_line("Desbloqueado", Color(0.5, 1, 0.55))
	else:
		var price: int = d["price"]
		_info_line("Preço: %d moedas" % price, UITheme.GOLD)
		if d.has("req"):
			_info_line("Desafio: " + Global.req_text(id), Color(1, 0.8, 0.45))


func _show_enemy(t: String) -> void:
	var d: Dictionary = DB.ENEMIES[t]
	_set_anims(SpriteLib.enemy(t), ENEMY_ANIMS, 6.5, Color.WHITE)
	_name.text = Names.enemy(t)
	_sub.text = "Ataque à distância" if d.get("ranged", false) else "Ataque corpo a corpo"
	_desc.text = Names.enemy_desc(t)
	_clear_info()
	_info_line("Vida: %d    Dano: %d" % [int(d["hp"]), int(d["damage"])])
	_info_line("Velocidade: %d    XP: %d" % [int(d["speed"]), int(d["xp"])])
	var stages: Array = []
	for i in DB.STAGES.size():
		for s in DB.STAGES[i]["spawn"]:
			if s[0] == t:
				stages.append(str(i + 1))
	_info_line("Aparece nos estágios: " + ", ".join(stages), Color(1, 0.95, 0.8))
	_info_line("Elites (dourados) têm 5x vida e sempre deixam uma poção.", Color(0.85, 0.85, 0.95))


func _show_boss(i: int) -> void:
	var bd: Dictionary = DB.STAGES[i]["boss"]
	_set_anims(SpriteLib.enemy(bd["type"]), ENEMY_ANIMS, 8.0, Color(1.25, 0.9, 0.9))
	_name.text = Names.boss(bd)
	_sub.text = "Chefão do estágio %d" % (i + 1)
	_desc.text = Names.boss_desc(bd)
	_clear_info()
	_info_line("Vida: %d    Dano: %d" % [int(bd["hp"]), int(bd["damage"])])
	_info_line("Velocidade: %d" % int(bd["speed"]))
	var atk: Array = []
	for a in bd["attacks"]:
		var n: String = BOSS_ATTACKS.get(a, a)
		if not atk.has(n):
			atk.append(n)
	_info_line("Ataques: " + ", ".join(atk), Color(1, 0.7, 0.6))
	_info_line("Aparece quando o tempo do estágio acaba (%d s)." % int(DB.STAGE_TIME), Color(0.85, 0.85, 0.95))
