extends Node2D
class_name Pickup
## Itens coletáveis: experiência, moedas e corações.

enum Kind { XP, COIN, HEART, POTION }

var kind: Kind = Kind.XP
var value := 1
var element := ""      # para poções: id do poder (DB.WEAPONS)
var _attracted := false
var _vel := Vector2.ZERO
var _t := 0.0
var _visual: Node2D

## Gemas, moeda e coração: Ninja Adventure (Pixel-boy & AAA, CC0).
const ITEMS := "res://assets/map/Ninja Adventure - Asset Pack/Items/"
const GEMS := ["Resource/GemGreen.png", "Resource/GemYellow.png", "Resource/GemRed.png"]


func _ready() -> void:
	add_to_group("pickups")
	z_index = -1
	_t = randf() * TAU
	match kind:
		Kind.XP:
			add_to_group("xp")
			_make_gem()
		Kind.COIN:
			var s := AnimatedSprite2D.new()
			s.sprite_frames = SpriteLib.fx("coin")
			s.scale = Vector2(0.8, 0.8)
			s.play("spin")
			_visual = s
			add_child(s)
		Kind.HEART:
			var h := Sprite2D.new()
			h.texture = load(ITEMS + "Potion/Heart.png")
			h.scale = Vector2(1.2, 1.2)
			_visual = h
			add_child(h)
		Kind.POTION:
			var glow := Sprite2D.new()
			glow.texture = SpriteLib.fx("holy_spark").get_frame_texture("hit", 1)
			glow.modulate = Color(DB.weapon_color(element), 0.55)
			glow.scale = Vector2(1.3, 1.3)
			glow.z_index = -1
			add_child(glow)
			var ps := Sprite2D.new()
			ps.texture = SpriteLib.potion_icon(element)
			ps.offset = Vector2(0, -6)
			_visual = ps
			add_child(ps)
			var tw := glow.create_tween().set_loops()
			tw.tween_property(glow, "scale", Vector2(1.6, 1.6), 0.6)
			tw.tween_property(glow, "scale", Vector2(1.2, 1.2), 0.6)


func _make_gem() -> void:
	var s: Sprite2D
	if _visual == null:
		s = Sprite2D.new()
		_visual = s
		add_child(s)
	s = _visual
	var tier := 0 if value < 5 else (1 if value < 25 else 2)
	s.texture = load(ITEMS + GEMS[tier])
	s.scale = Vector2.ONE * (0.45 + 0.1 * tier)


func add_value(v: int) -> void:
	value += v
	_make_gem()


func attract() -> void:
	_attracted = true


func _physics_process(delta: float) -> void:
	var g := Game.current
	if g == null or g.player == null:
		return
	var p: Player = g.player
	var target := p.global_position + Vector2(0, -4)
	var d := global_position.distance_to(target)
	if not _attracted:
		_t += delta * 3.0
		if _visual:
			_visual.position.y = sin(_t) * 1.5
		if d < float(p.stats["magnet"]):
			_attracted = true
			_vel = (global_position - target).normalized() * 60.0
		return
	_vel = _vel.move_toward((target - global_position).normalized() * 320.0, 900.0 * delta)
	global_position += _vel * delta
	if d < 7.0:
		_collect(p)


func _collect(p: Player) -> void:
	var g := Game.current
	match kind:
		Kind.XP:
			p.add_xp(value)
		Kind.COIN:
			g.add_coins(value)
		Kind.HEART:
			p.heal(25.0)
			g.show_number(p.global_position + Vector2(0, -16), 25, Color(0.4, 1, 0.4))
		Kind.POTION:
			g.drink_potion(element)
	queue_free()
