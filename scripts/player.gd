extends CharacterBody2D
class_name Player
## Protagonista: movimento, atributos, vida, experiência e armas.

signal health_changed(hp: float, max_hp: float)
signal xp_changed(xp: int, need: int, level: int)
signal leveled_up(level: int)
signal weapons_changed
signal stats_changed
signal died

const BASE_SPEED := 105.0

## Atributos base. Perks de personagem e melhorias somam valores aqui.
const BASE_STATS := {
	"max_hp": 100.0,
	"regen": 0.0,          # vida por segundo
	"armor": 0.0,          # redução = armor / (armor + 15)
	"speed": 1.0,          # multiplicador de velocidade
	"damage": 1.0,         # multiplicador de dano
	"attack_speed": 1.0,   # multiplicador de recarga das armas
	"area": 1.0,           # multiplicador de área/tamanho
	"projectiles": 0,      # projéteis extras
	"magnet": 45.0,        # raio de coleta (px)
	"luck": 0.0,
	"xp_gain": 1.0,
	"crit_chance": 0.05,
	"crit_mult": 2.0,
}

var char_id: int = Global.DEFAULT_CHAR
var stats: Dictionary = {}
var hp: float = 100.0
var level: int = 1
var xp: int = 0
var xp_need: int = 10
var passive_counts: Dictionary = {}   # id -> quantas vezes pegou
var is_dead := false
var facing_towards := "down"
var aim_dir := Vector2.DOWN
var invuln := 0.0
var _regen_acc := 0.0
var _shake := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapons: Node2D = $Weapons
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	stats = BASE_STATS.duplicate()
	setup_character(Global.selected_char)


func setup_character(id: int) -> void:
	char_id = id
	var data: Dictionary = DB.CHARACTERS[id]
	sprite.sprite_frames = SpriteLib.character(id)
	sprite.play("stop_down")
	var perk: Dictionary = data["perk"]
	for k in perk:
		stats[k] = stats[k] + perk[k]
	hp = stats["max_hp"]
	xp_need = DB.xp_to_next(level)
	add_weapon(data["weapon"])


# ------------------------------------------------------------------ loop
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if invuln > 0.0:
		invuln -= delta
		sprite.modulate.a = 0.5 if int(invuln * 20.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0

	var regen: float = stats["regen"]
	if regen > 0.0 and hp < stats["max_hp"]:
		_regen_acc += regen * delta
		if _regen_acc >= 1.0:
			heal(floor(_regen_acc))
			_regen_acc -= floor(_regen_acc)

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * BASE_SPEED * float(stats["speed"])
	if direction != Vector2.ZERO:
		aim_dir = direction.normalized()
	animation_logic(direction, direction == Vector2.ZERO)
	move_and_slide()

	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 30.0)
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	else:
		camera.offset = Vector2.ZERO


func animation_logic(dir: Vector2, is_stopped: bool = false) -> void:
	if is_stopped:
		sprite.play("stop_" + facing_towards)
		return
	if absf(dir.x) >= absf(dir.y):
		facing_towards = "right" if dir.x > 0 else "left"
	else:
		facing_towards = "down" if dir.y > 0 else "up"
	sprite.play("running_" + facing_towards)


# ------------------------------------------------------------------ vida
func take_damage(amount: float) -> void:
	if is_dead or invuln > 0.0:
		return
	var armor: float = stats["armor"]
	var reduced := amount * (1.0 - armor / (armor + 15.0))
	reduced = maxf(1.0, round(reduced))
	hp -= reduced
	invuln = 0.35
	_shake = 4.0
	var g := Game.current
	if g:
		g.show_number(global_position + Vector2(0, -14), reduced, Color(1, 0.3, 0.3))
	health_changed.emit(hp, stats["max_hp"])
	if hp <= 0.0:
		hp = 0.0
		is_dead = true
		sprite.modulate = Color(1, 0.4, 0.4)
		died.emit()


func heal(amount: float) -> void:
	if is_dead:
		return
	hp = minf(hp + amount, stats["max_hp"])
	health_changed.emit(hp, stats["max_hp"])


## Brilho ao beber uma poção.
func drink_effect(color: Color) -> void:
	SpriteLib.spawn_fx(Game.current.fx_layer if Game.current else get_parent(), "holy_spark",
			global_position + Vector2(0, -10), "hit", 1.4, 0.0, Vector2.ZERO, color)
	var tw := create_tween()
	tw.tween_property(sprite, "self_modulate", color * 1.8, 0.1)
	tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.35)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


# ------------------------------------------------------------------ xp
func add_xp(amount: int) -> void:
	xp += int(ceil(amount * float(stats["xp_gain"])))
	while xp >= xp_need:
		xp -= xp_need
		level += 1
		xp_need = DB.xp_to_next(level)
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_need, level)


# ------------------------------------------------------------------ armas
func get_weapon(id: String) -> Weapon:
	for w in weapons.get_children():
		if w is Weapon and w.id == id:
			return w
	return null


func weapon_list() -> Array:
	var out: Array = []
	for w in weapons.get_children():
		if w is Weapon:
			out.append(w)
	return out


func add_weapon(id: String) -> void:
	var existing := get_weapon(id)
	if existing:
		existing.level_up(0)
		weapons_changed.emit()
		return
	var script: Script = load(DB.WEAPONS[id]["script"])
	var w: Weapon = script.new()
	w.id = id
	w.player = self
	weapons.add_child(w)
	weapons_changed.emit()


# ------------------------------------------------------------------ melhorias
func apply_passive(id: String, rarity: int) -> void:
	var p: Dictionary = DB.PASSIVES[id]
	var value: float = p["value"]
	if not p.get("flat", false):
		value *= DB.RARITIES[rarity]["mult"]
	if id == "projectiles":
		stats[id] = int(stats[id]) + int(value)
	else:
		stats[id] = float(stats[id]) + value
	if id == "max_hp":
		hp += value
		health_changed.emit(hp, stats["max_hp"])
	passive_counts[id] = int(passive_counts.get(id, 0)) + 1
	stats_changed.emit()
