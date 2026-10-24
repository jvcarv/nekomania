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
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)

	var title := UITheme.label("NEKO ARCANO", 84, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_constant_override("outline_size", 16)
	v.add_child(title)
	v.add_child(UITheme.label("Sobreviva à floresta. Derrote os chefões.", 22, Color(0.95, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER))

	# personagem selecionado
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 130)
	v.add_child(holder)
	_char_sprite = AnimatedSprite2D.new()
	_char_sprite.scale = Vector2(4, 4)
	holder.add_child(_char_sprite)
	holder.resized.connect(func(): _char_sprite.position = Vector2(holder.size.x / 2.0, 64))
	_char_name = UITheme.label("", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_char_name)

	var play := UITheme.button("Jogar", 30, 320)
	play.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/game.tscn"))
	v.add_child(play)
	var chars := UITheme.button("Personagens", 26, 320)
	chars.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn"))
	v.add_child(chars)
	var quit := UITheme.button("Sair", 26, 320)
	quit.pressed.connect(func(): get_tree().quit())
	v.add_child(quit)
	for b in [play, chars, quit]:
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
	_coin_label = UITheme.label(str(Global.coins), 32, UITheme.GOLD)
	top.add_child(_coin_label)

	var rec := UITheme.label("Recordes — Tempo: %s   Estágio: %d   Nível: %d   Abates totais: %d" % [
			Global.format_time(Global.best_time), Global.best_stage, Global.best_level, Global.total_kills],
			18, Color(0.9, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	rec.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	rec.position = Vector2(-500, -50)
	rec.size = Vector2(1000, 30)
	add_child(rec)
	var hint := UITheme.label("WASD / Setas: mover   •   ESC: pausar   •   As armas atacam sozinhas", 16, Color(0.85, 0.85, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-500, -26)
	hint.size = Vector2(1000, 24)
	add_child(hint)

	_refresh()
	play.grab_focus()


func _refresh() -> void:
	var id := Global.selected_char
	_char_sprite.sprite_frames = SpriteLib.character(id)
	_char_sprite.play("running_down")
	var d: Dictionary = DB.CHARACTERS[id]
	_char_name.text = "%s  •  %s" % [d["name"], DB.WEAPONS[d["weapon"]]["name"]]
