extends Control
## Menu principal.

var _coin_label: Label
var _char_sprite: AnimatedSprite2D
var _char_name: Label


func _ready() -> void:
	get_tree().paused = false
	theme = UITheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBackground.new())

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)

	var title := UITheme.label("NEKO ARCANO", 64, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_constant_override("outline_size", 16)
	v.add_child(title)
	v.add_child(UITheme.label("Gatinhos alquimistas contra a floresta encantada.", 16, Color(0.95, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER))

	# personagem selecionado
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 104)
	v.add_child(holder)
	_char_sprite = AnimatedSprite2D.new()
	_char_sprite.scale = Vector2(3, 3)
	holder.add_child(_char_sprite)
	holder.resized.connect(func(): _char_sprite.position = Vector2(holder.size.x / 2.0, 50))
	_char_name = UITheme.label("", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_char_name)

	var play := UITheme.button("Jogar", 24, 320)
	play.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/game.tscn"))
	v.add_child(play)
	var chars := UITheme.button("Personagens", 24, 320)
	chars.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn"))
	v.add_child(chars)
	var challenges := UITheme.button("Desafios", 24, 320)
	challenges.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/challenges.tscn"))
	v.add_child(challenges)
	var credits := UITheme.button("Créditos", 24, 320)
	credits.pressed.connect(_show_credits)
	v.add_child(credits)
	var quit := UITheme.button("Sair", 24, 320)
	quit.pressed.connect(func(): get_tree().quit())
	v.add_child(quit)
	for b in [play, chars, challenges, credits, quit]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# moedas e recordes
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top.position = Vector2(-260, 20)
	top.size = Vector2(240, 40)
	top.alignment = BoxContainer.ALIGNMENT_END
	add_child(top)
	var ci := TextureRect.new()
	ci.texture = SpriteLib.fx("coin").get_frame_texture("spin", 0)
	ci.custom_minimum_size = Vector2(36, 36)
	ci.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top.add_child(ci)
	_coin_label = UITheme.label(str(Global.coins), 24, UITheme.GOLD)
	top.add_child(_coin_label)

	var rec := UITheme.label("Recordes — Tempo: %s   Estágio: %d   Nível: %d   Abates totais: %d" % [
			Global.format_time(Global.best_time), Global.best_stage, Global.best_level, Global.total_kills],
			18, Color(0.9, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	rec.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	rec.position = Vector2(-500, -50)
	rec.size = Vector2(1000, 30)
	add_child(rec)
	var hint := UITheme.label("WASD / Setas: mover   •   ESC: pausar   •   Os poderes atacam sozinhos", 16, Color(0.85, 0.85, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-500, -26)
	hint.size = Vector2(1000, 24)
	add_child(hint)

	_refresh()
	play.grab_focus()


func _show_credits() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.02, 0.08, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(UITheme.label("CRÉDITOS", 40, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.custom_minimum_size = Vector2(820, 0)
	t.text = CREDITS
	v.add_child(t)
	var back := UITheme.button("Voltar", 24, 240)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(overlay.queue_free)
	v.add_child(back)
	back.grab_focus()


const CREDITS := """[b]Gatinhos:[/b] Pipoya
[b]Inimigos e magias:[/b] (preencher autores)
[b]Árvores:[/b] Pocket Cozy Pixels / BloomPixle
[b]Interface:[/b] Crusenho Agus Hennihuno (CC BY 4.0)
[b]Poções:[/b] Onocentaur
[b]Chão, enfeites e itens:[/b] Ninja Adventure — Pixel-boy & AAA (CC0)
[b]Fonte:[/b] Silkscreen, Jason Kottke (OFL)
[b]Motor:[/b] Godot Engine

Código feito com auxílio de IA."""


func _refresh() -> void:
	var id := Global.selected_char
	_char_sprite.sprite_frames = SpriteLib.character(id)
	_char_sprite.play("running_down")
	var d: Dictionary = DB.CHARACTERS[id]
	_char_name.text = "%s  •  %s" % [d["name"], DB.WEAPONS[d["weapon"]]["potion"]]
