extends CanvasLayer
class_name HUD
## Interface durante a partida: vida, XP, nível, tempo, estágio, moedas,
## abates, armas, barra do chefão, avisos e seta do portal.

var game: Game
var hp_bar: PixelBar
var xp_bar: PixelBar
var boss_bar: PixelBar
var boss_label: Label
var boss_box: VBoxContainer
var level_label: Label
var timer_label: Label
var stage_label: Label
var coin_label: Label
var kill_label: Label
var announce_label: Label
var weapon_row: HBoxContainer
var portal_arrow: Polygon2D
var _portal: Node2D
var _announce_tw: Tween


func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	add_child(root)

	# XP no topo
	xp_bar = PixelBar.new()
	xp_bar.fill_color = Color(0.3, 0.65, 1.0)
	xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	xp_bar.offset_left = 8
	xp_bar.offset_right = -8
	xp_bar.offset_top = 6
	xp_bar.offset_bottom = 36
	root.add_child(xp_bar)

	# Vida + nível (esquerda)
	var left := VBoxContainer.new()
	left.position = Vector2(14, 42)
	left.add_theme_constant_override("separation", 4)
	root.add_child(left)
	level_label = UITheme.label("Nv 1", 24, UITheme.GOLD)
	left.add_child(level_label)
	hp_bar = PixelBar.new()
	hp_bar.fill_color = Color(0.88, 0.2, 0.25)
	hp_bar.custom_minimum_size = Vector2(260, 34)
	left.add_child(hp_bar)
	weapon_row = HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 6)
	left.add_child(weapon_row)

	# Tempo + estágio (centro)
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER_TOP)
	center.position = Vector2(-200, 40)
	center.size = Vector2(400, 60)
	center.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(center)
	timer_label = UITheme.label("00:00", 34, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	center.add_child(timer_label)
	stage_label = UITheme.label("", 18, Color(0.9, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	center.add_child(stage_label)

	# Moedas + abates (direita)
	var right := VBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.position = Vector2(-220, 44)
	right.size = Vector2(206, 60)
	root.add_child(right)
	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(coin_row)
	var coin_icon := TextureRect.new()
	var cf := SpriteLib.fx("coin")
	coin_icon.texture = cf.get_frame_texture("spin", 0)
	coin_icon.custom_minimum_size = Vector2(28, 28)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_row.add_child(coin_icon)
	coin_label = UITheme.label("0", 26, UITheme.GOLD)
	coin_row.add_child(coin_label)
	kill_label = UITheme.label("Abates: 0", 20, Color(1, 0.85, 0.85), HORIZONTAL_ALIGNMENT_RIGHT)
	right.add_child(kill_label)

	# Barra do chefão (embaixo)
	boss_box = VBoxContainer.new()
	boss_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	boss_box.position = Vector2(-320, -90)
	boss_box.size = Vector2(640, 70)
	boss_box.visible = false
	root.add_child(boss_box)
	boss_label = UITheme.label("", 22, Color(1, 0.6, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	boss_box.add_child(boss_label)
	boss_bar = PixelBar.new()
	boss_bar.fill_color = Color(0.75, 0.15, 0.6)
	boss_bar.custom_minimum_size = Vector2(640, 34)
	boss_box.add_child(boss_bar)

	# Avisos
	announce_label = UITheme.label("", 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	announce_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	announce_label.position = Vector2(-400, 150)
	announce_label.size = Vector2(800, 40)
	announce_label.modulate.a = 0.0
	root.add_child(announce_label)

	portal_arrow = Polygon2D.new()
	portal_arrow.polygon = PackedVector2Array([Vector2(22, 0), Vector2(-14, -16), Vector2(-6, 0), Vector2(-14, 16)])
	portal_arrow.color = Color(0.85, 0.6, 1.0)
	portal_arrow.visible = false
	root.add_child(portal_arrow)


func bind(g: Game) -> void:
	game = g
	var p := g.player
	p.health_changed.connect(_on_health)
	p.xp_changed.connect(_on_xp)
	p.weapons_changed.connect(_refresh_weapons)
	g.coins_changed.connect(func(c): coin_label.text = str(c))
	g.kills_changed.connect(func(k): kill_label.text = "Abates: %d" % k)
	g.announced.connect(announce)
	g.stage_started.connect(_on_stage)
	g.boss_spawned.connect(_on_boss)
	g.boss_health_changed.connect(func(hp, mx): boss_bar.ratio = hp / mx)
	g.boss_cleared.connect(func(): boss_box.visible = false)
	_on_health(p.hp, p.stats["max_hp"])
	_on_xp(p.xp, p.xp_need, p.level)
	_refresh_weapons()


func _process(_delta: float) -> void:
	if game == null:
		return
	var remaining := DB.STAGE_TIME - game.stage_time
	if game.boss != null:
		timer_label.text = "CHEFÃO!"
		timer_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	elif game.boss_defeated:
		timer_label.text = "PORTAL"
		timer_label.add_theme_color_override("font_color", Color(0.85, 0.6, 1.0))
	else:
		timer_label.text = Global.format_time(maxf(remaining, 0.0))
		timer_label.add_theme_color_override("font_color", Color.WHITE if remaining > 30.0 else Color(1, 0.75, 0.4))
	_update_portal_arrow()


func _on_health(hp: float, mx: float) -> void:
	hp_bar.ratio = hp / mx
	hp_bar.text = "%d / %d" % [int(ceil(hp)), int(mx)]


func _on_xp(xp: int, need: int, lvl: int) -> void:
	xp_bar.ratio = float(xp) / float(need)
	level_label.text = "Nv %d" % lvl


func _on_stage(i: int) -> void:
	stage_label.text = "Estágio %d/%d — %s" % [i + 1, DB.STAGES.size(), DB.STAGES[i]["name"]]
	boss_box.visible = false


func _on_boss(b: Enemy) -> void:
	boss_box.visible = true
	boss_label.text = b.boss_name
	boss_bar.ratio = 1.0


func _refresh_weapons() -> void:
	for c in weapon_row.get_children():
		c.queue_free()
	for w in game.player.weapon_list():
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", UITheme.slot("orange"))
		box.custom_minimum_size = Vector2(52, 52)
		var icon := TextureRect.new()
		icon.texture = UITheme.weapon_icon(w.id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(36, 36)
		box.add_child(icon)
		var lv := UITheme.label(str(w.level), 14, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		lv.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		box.add_child(lv)
		box.tooltip_text = DB.WEAPONS[w.id]["name"]
		weapon_row.add_child(box)


func announce(text: String, color: Color = Color.WHITE) -> void:
	announce_label.text = text
	announce_label.add_theme_color_override("font_color", color)
	if _announce_tw:
		_announce_tw.kill()
	announce_label.modulate.a = 1.0
	_announce_tw = create_tween()
	_announce_tw.tween_interval(2.2)
	_announce_tw.tween_property(announce_label, "modulate:a", 0.0, 0.6)


func show_portal_arrow(portal: Node2D) -> void:
	_portal = portal
	portal_arrow.visible = portal != null


func _update_portal_arrow() -> void:
	if _portal == null or not is_instance_valid(_portal):
		portal_arrow.visible = false
		return
	var vp := get_viewport()
	var screen_pos := vp.get_canvas_transform() * _portal.global_position
	var rect := vp.get_visible_rect()
	var center := rect.size / 2.0
	if rect.grow(-40).has_point(screen_pos):
		portal_arrow.visible = false
		return
	portal_arrow.visible = true
	var dir := (screen_pos - center).normalized()
	var edge := center + dir * (minf(center.x, center.y) - 50.0)
	portal_arrow.position = edge
	portal_arrow.rotation = dir.angle()
