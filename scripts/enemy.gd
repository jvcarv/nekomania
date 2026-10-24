extends CharacterBody2D
class_name Enemy
## Inimigo genérico. O tipo (slime, orc...) vem de DB.ENEMIES.
## Configure com setup() antes de adicionar à árvore.

signal killed(enemy: Enemy)

var type_id := "slime"
var max_hp := 10.0
var hp := 10.0
var speed := 40.0
var damage := 5.0
var xp_value := 1
var coin_chance := 0.05
var is_elite := false
var is_boss := false
var ranged := false
var boss_name := ""
var dead := false

var _slow_t := 0.0
var _slow_f := 0.0
var _attack_cd := 0.0
var _shoot_cd := 2.0
var _summon_cd := 7.0
var _knock := Vector2.ZERO
var _flash := 0.0
var _attacking := false
var _base_scale := 1.0
var _contact_range := 14.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shape: CollisionShape2D = $CollisionShape2D


func setup(t: String, hp_mult: float, dmg_mult: float, elite: bool = false, boss: Dictionary = {}) -> void:
	type_id = t
	var d: Dictionary = DB.ENEMIES[t]
	max_hp = d["hp"] * hp_mult
	speed = d["speed"] * randf_range(0.92, 1.08)
	damage = d["damage"] * dmg_mult
	xp_value = d["xp"]
	coin_chance = d["coin"]
	ranged = d.get("ranged", false)
	_base_scale = d["scale"]
	is_elite = elite
	if elite:
		max_hp *= 5.0
		damage *= 1.4
		speed *= 1.1
		xp_value *= 8
		coin_chance = 1.0
		_base_scale *= 1.5
	if not boss.is_empty():
		is_boss = true
		boss_name = boss["name"]
		max_hp = boss["hp"]
		damage = boss["damage"]
		speed = boss["speed"]
		_base_scale = boss["scale"]
		xp_value = 150
		ranged = false
	hp = max_hp


func _ready() -> void:
	add_to_group("enemies")
	var d: Dictionary = DB.ENEMIES[type_id]
	sprite.sprite_frames = SpriteLib.enemy(type_id)
	sprite.scale = Vector2.ONE * _base_scale
	sprite.play("walk")
	sprite.frame = randi() % 4
	sprite.animation_finished.connect(_on_anim_finished)
	var circle := CircleShape2D.new()
	circle.radius = float(d["radius"]) * (_base_scale / float(d["scale"]))
	shape.shape = circle
	_contact_range = circle.radius + 9.0
	if is_elite:
		sprite.modulate = Color(1.35, 1.1, 0.6)
	if is_boss:
		sprite.modulate = Color(1.25, 0.9, 0.9)
		_contact_range += 6.0


func _physics_process(delta: float) -> void:
	if dead:
		return
	var player := Game.current.player if Game.current else null
	if player == null:
		return
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			sprite.self_modulate = Color.WHITE
	if _slow_t > 0.0:
		_slow_t -= delta
	var slow_mult := 1.0 - (_slow_f if _slow_t > 0.0 else 0.0)
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player / maxf(dist, 0.001)

	var move := dir
	if ranged:
		_shoot_cd -= delta
		if dist < 110.0:
			move = -dir * 0.6
		elif dist < 160.0:
			move = Vector2.ZERO
		if _shoot_cd <= 0.0 and dist < 200.0:
			_shoot_cd = randf_range(2.4, 3.2)
			_shoot(player)
	if is_boss:
		_summon_cd -= delta
		if _summon_cd <= 0.0:
			_summon_cd = 8.0
			Game.current.director.summon_minions(global_position, 6)
		if hp < max_hp * 0.5:
			slow_mult *= 1.3

	velocity = move * speed * slow_mult + _knock
	_knock = _knock.move_toward(Vector2.ZERO, 600.0 * delta)
	move_and_slide()

	if not _attacking:
		sprite.flip_h = to_player.x < 0
		var want := "walk" if velocity.length() > 2.0 else "idle"
		if sprite.animation != want and sprite.animation != "hurt":
			sprite.play(want)

	_attack_cd -= delta
	if dist < _contact_range and _attack_cd <= 0.0:
		_attack_cd = 1.0
		player.take_damage(damage)
		_attacking = true
		sprite.play("attack")


func _shoot(player: Player) -> void:
	_attacking = true
	sprite.play("attack")
	await get_tree().create_timer(0.35, false).timeout
	if dead or not is_instance_valid(player):
		return
	var a := EnemyArrow.new()
	a.damage = damage
	a.direction = global_position.direction_to(player.global_position)
	a.global_position = global_position + Vector2(0, -4)
	Game.current.fx_layer.add_child(a)


func _on_anim_finished() -> void:
	if dead:
		return
	if sprite.animation in ["attack", "hurt"]:
		_attacking = false
		sprite.play("walk")


func apply_slow(amount: float, duration: float) -> void:
	if is_boss:
		amount *= 0.4
	_slow_f = maxf(_slow_f if _slow_t > 0.0 else 0.0, amount)
	_slow_t = maxf(_slow_t, duration)


func take_hit(amount: float, crit: bool = false, knock: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	hp -= amount
	var g := Game.current
	if g:
		g.show_number(global_position + Vector2(randf_range(-5, 5), -12 * _base_scale),
				amount, Color(1, 0.85, 0.2) if crit else Color.WHITE, crit)
	sprite.self_modulate = Color(3, 3, 3)
	_flash = 0.08
	if not is_boss:
		_knock += knock * (0.4 if is_elite else 1.0)
	if is_boss and g:
		g.boss_health_changed.emit(hp, max_hp)
	if hp <= 0.0:
		die()


func die() -> void:
	if dead:
		return
	dead = true
	remove_from_group("enemies")
	shape.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	sprite.self_modulate = Color.WHITE
	sprite.play("death")
	killed.emit(self)
	if Game.current:
		Game.current.on_enemy_killed(self)
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)
