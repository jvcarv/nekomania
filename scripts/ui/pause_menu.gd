extends CanvasLayer
class_name PauseMenu
## Menu de pausa com atributos atuais e armas.

var game: Game
var _stats: RichTextLabel
var _continue: Button


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.get_theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.1, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 30)
	panel.add_child(h)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 14)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(left)
	left.add_child(UITheme.label("PAUSADO", 40, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_continue = UITheme.button("Continuar")
	_continue.pressed.connect(func(): game.toggle_pause())
	left.add_child(_continue)
	var restart := UITheme.button("Reiniciar")
	restart.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	left.add_child(restart)
	var menu := UITheme.button("Menu principal")
	menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	left.add_child(menu)
	_stats = RichTextLabel.new()
	_stats.bbcode_enabled = true
	_stats.fit_content = true
	_stats.custom_minimum_size = Vector2(380, 380)
	_stats.scroll_active = false
	h.add_child(_stats)


func open(g: Game) -> void:
	game = g
	visible = true
	_continue.grab_focus()
	var p := g.player
	var s: Dictionary = p.stats
	var t := "[b][color=#ffd34d]Atributos[/color][/b]\n"
	t += "Vida: %d / %d\n" % [int(p.hp), int(s["max_hp"])]
	t += "Regeneração: %.1f/s\n" % s["regen"]
	t += "Armadura: %d\n" % int(s["armor"])
	t += "Dano: %d%%\n" % int(round(s["damage"] * 100))
	t += "Vel. ataque: %d%%\n" % int(round(s["attack_speed"] * 100))
	t += "Área: %d%%\n" % int(round(s["area"] * 100))
	t += "Projéteis extras: %d\n" % int(s["projectiles"])
	t += "Velocidade: %d%%\n" % int(round(s["speed"] * 100))
	t += "Crítico: %d%%\n" % int(round(s["crit_chance"] * 100))
	t += "Sorte: %d%%\n" % int(round(s["luck"] * 100))
	t += "\n[b][color=#ffd34d]Poções / poderes[/color][/b]\n"
	for w in p.weapon_list():
		t += "%s: %s Nv %d\n" % [DB.WEAPONS[w.id]["potion"], DB.WEAPONS[w.id]["name"], w.level]
	t += "\nTempo: %s   Abates: %d" % [Global.format_time(g.total_time), g.kills]
	_stats.text = t


func close() -> void:
	visible = false
