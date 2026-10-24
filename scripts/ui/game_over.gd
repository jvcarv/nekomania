extends CanvasLayer
class_name GameOverScreen
## Tela de fim de partida (derrota ou vitória) com o resumo da run.

var _title: Label
var _body: RichTextLabel
var _again: Button


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.get_theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.02, 0.08, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(480, 0)
	panel.add_child(v)
	_title = UITheme.label("", 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_title)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.add_theme_font_size_override("normal_font_size", 24)
	_body.add_theme_font_size_override("bold_font_size", 24)
	v.add_child(_body)
	_again = UITheme.button("Jogar novamente")
	_again.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	v.add_child(_again)
	var chars := UITheme.button("Personagens")
	chars.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn"))
	v.add_child(chars)
	var menu := UITheme.button("Menu principal")
	menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	v.add_child(menu)


func open(r: Dictionary) -> void:
	visible = true
	var win: bool = r["victory"]
	_title.text = "VITÓRIA!" if win else "FIM DE JOGO"
	_title.add_theme_color_override("font_color", UITheme.GOLD if win else Color(1, 0.45, 0.45))
	var t := "[center]"
	t += "Personagem: [b]%s[/b]\n" % DB.CHARACTERS[r["char"]]["name"]
	t += "Tempo: [b]%s[/b]\n" % Global.format_time(r["time"])
	t += "Estágio alcançado: [b]%d[/b]\n" % r["stage"]
	t += "Nível: [b]%d[/b]\n" % r["level"]
	t += "Abates: [b]%d[/b]\n" % r["kills"]
	t += "[color=#ffd34d]Moedas ganhas: [b]+%d[/b][/color]\n" % r["coins"]
	t += "Total de moedas: [b]%d[/b]" % Global.coins
	t += "[/center]"
	_body.text = t
	_again.grab_focus()
