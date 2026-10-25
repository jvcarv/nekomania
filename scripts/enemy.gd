extends CharacterBody2D
class_name Enemy
## Inimigo genérico. O tipo (slime, orc...) vem de DB.ENEMIES.
## Configure com setup() antes de adicionar à árvore.
##
## Efeitos de estado (cada elemento tem o seu):
##   QUEIMANDO   (fogo)    laranja, perde vida de tempos em tempos
##   CONGELANDO  (gelo)    azul, mais lento
##   ELETRIZADO  (trovão)  amarelo, parado por um tempo
##   ENVENENADO  (ácido)   verde, anda cambaleando de lado e perde vida

signal killed(enemy: Enemy)

const TINT_BURN := Color(1.6, 0.85, 0.45)
const TINT_CHILL := Color(0.55, 0.8, 1.6)
const TINT_SHOCK := Color(1.7, 1.6, 0.5)
const TINT_POISON := Color(0.7, 1.45, 0.6)

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
var last_elem := ""          # elemento que causou o último dano (para desafios)

## Dano "a caminho" (projéteis já disparados neste inimigo). As armas evitam
## mirar em quem já vai morrer, para não desperdiçar tiros.
var pending_damage := 0.0

# efeitos de estado
var _burn_t := 0.0
var _burn_dps := 0.0
var _chill_t := 0.0
var _chill_f := 0.0
var _shock_t := 0.0
var _poison_t := 0.0
var _poison_dps := 0.0
var _dot_tick := 0.5
var _slow_t := 0.0           # lentidão neutra (sem cor), ex.: espinhos
var _slow_f := 0.0
var _wobble := 0.0

var _attack_cd := 0.0
var _shoot_cd := 2.0
var _knock := Vector2.ZERO
var _flash := 0.0
var _attacking := false
var _base_scale := 1.0
var _base_tint := Color.WHITE
var _contact_range := 14.0
var _brain: BossBrain
var _boss_data: Dictionary = {}

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
		_base_scale *= 1.4
	if not boss.is_empty():
		is_boss = true
		boss_name = boss["name"]
		max_hp = boss["hp"]
		damage = boss["damage"]
		speed = boss["speed"]
		_base_scale = boss["scale"]
		xp_value = 150
		ranged = false
		_boss_data = boss
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
	_wobble = randf() * TAU
	if is_elite:
		_base_tint = Color(1.35, 1.1, 0.6)
	if is_boss:
		_base_tint = Color(1.25, 0.9, 0.9)
		_contact_range += 6.0
		collision_mask = 2   # atravessa árvores (e as derruba) e outros inimigos
		_brain = BossBrain.new()
		_brain.boss = self
		_brain.attacks = _boss_data.get("attacks", ["summon"])
		add_child(_brain)
	sprite.modulate = _base_tint


func contact_range() -> float:
	return _contact_range


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
	if _update_status(delta):
		return

	var slow_mult := 1.0
	if _chill_t > 0.0:
		slow_mult *= 1.0 - _chill_f
	if _slow_t > 0.0:
		slow_mult *= 1.0 - _slow_f
	var stunned := _shock_t > 0.0
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player / maxf(dist, 0.001)
	# planaltos: se o jogador estiver em outro nível, vai pela escada
	if not is_boss and Game.current.map:
		var goal := Game.current.map.route(global_position, player.global_position)
		if goal != player.global_position:
			dir = global_position.direction_to(goal)

	var move := dir
	if _poison_t > 0.0:
		# envenenado: cambaleia de lado enquanto tenta avançar
		_wobble += delta * 7.0
		move = (dir * 0.45 + dir.orthogonal() * sin(_wobble) * 1.1).normalized() * 0.8
	if ranged:
		_shoot_cd -= delta
		# fica a uma distância média (ao alcance dos poderes do jogador) e atira
		if dist < 60.0:
			move = -dir * 0.6
		elif dist < 95.0:
			move = Vector2.ZERO
		if _shoot_cd <= 0.0 and dist < 150.0 and not stunned:
			_shoot_cd = randf_range(3.2, 4.2)
			_shoot(player)
	var override := Vector2.INF
	if is_boss:
		if hp < max_hp * 0.5:
			slow_mult *= 1.25
		if not stunned:
			override = _brain.update(delta, player)

	if stunned:
		velocity = _knock
	elif override != Vector2.INF:
		velocity = override
	else:
		velocity = move * speed * slow_mult + _knock
	_knock = _knock.move_toward(Vector2.ZERO, 600.0 * delta)
	move_and_slide()

	if stunned:
		sprite.speed_scale = 0.0
	elif _chill_t > 0.0:
		sprite.speed_scale = maxf(0.3, slow_mult)
	if not _attacking and not stunned:
		sprite.flip_h = to_player.x < 0
		var want := "walk" if velocity.length() > 2.0 else "idle"
		if sprite.animation != want and sprite.animation != "hurt":
			sprite.play(want)

	_attack_cd -= delta
	if dist < _contact_range and _attack_cd <= 0.0 and not stunned:
		_attack_cd = 1.0
		player.take_damage(damage)
		_attacking = true
		sprite.play("attack")


## Atualiza os efeitos de estado. Retorna true se o inimigo morreu.
func _update_status(delta: float) -> bool:
	var had := _burn_t > 0.0 or _chill_t > 0.0 or _shock_t > 0.0 or _poison_t > 0.0
	_burn_t = maxf(0.0, _burn_t - delta)
	_chill_t = maxf(0.0, _chill_t - delta)
	_shock_t = maxf(0.0, _shock_t - delta)
	_poison_t = maxf(0.0, _poison_t - delta)
	_slow_t = maxf(0.0, _slow_t - delta)
	if _burn_t > 0.0 or _poison_t > 0.0:
		_dot_tick -= delta
		if _dot_tick <= 0.0:
			_dot_tick = 0.5
			if _burn_t > 0.0:
				take_hit(_burn_dps * 0.5, false, Vector2.ZERO, "fire", Color(1, 0.6, 0.25))
			if _poison_t > 0.0 and not dead:
				take_hit(_poison_dps * 0.5, false, Vector2.ZERO, "acid", Color(0.55, 1, 0.4))
			if dead:
				return true
	var has := _burn_t > 0.0 or _chill_t > 0.0 or _shock_t > 0.0 or _poison_t > 0.0
	if has or had:
		_refresh_tint()
	if had and _shock_t <= 0.0 and _chill_t <= 0.0:
		sprite.speed_scale = 1.0
	return false


func _refresh_tint() -> void:
	var t := _base_tint
	if _shock_t > 0.0:
		t = TINT_SHOCK
	elif _chill_t > 0.0:
		t = TINT_CHILL
	elif _burn_t > 0.0:
		t = TINT_BURN
	elif _poison_t > 0.0:
		t = TINT_POISON
	sprite.modulate = t


func _shoot(player: Player) -> void:
	_attacking = true
	sprite.play("attack")
	await get_tree().create_timer(0.35, false).timeout
	if dead or not is_instance_valid(player) or _shock_t > 0.0:
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


# ------------------------------------------------------------------ efeitos
## Fogo: queima (dano por segundo).
func apply_burn(dps: float, duration: float) -> void:
	if dead:
		return
	_burn_dps = maxf(dps, _burn_dps if _burn_t > 0.0 else 0.0)
	_burn_t = maxf(_burn_t, duration)
	_refresh_tint()


## Gelo: fica azul e mais lento (amount = 0..1).
func apply_chill(amount: float, duration: float) -> void:
	if dead:
		return
	if is_boss:
		amount *= 0.4
	_chill_f = maxf(amount, _chill_f if _chill_t > 0.0 else 0.0)
	_chill_t = maxf(_chill_t, duration)
	_refresh_tint()


## Trovão: fica amarelo e parado.
func apply_shock(duration: float) -> void:
	if dead:
		return
	if is_boss:
		duration *= 0.25
	_shock_t = maxf(_shock_t, duration)
	_refresh_tint()


## Ácido: envenenado, anda cambaleando e perde vida.
func apply_poison(dps: float, duration: float) -> void:
	if dead:
		return
	_poison_dps = maxf(dps, _poison_dps if _poison_t > 0.0 else 0.0)
	_poison_t = maxf(_poison_t, duration)
	_refresh_tint()


## Lentidão neutra (sem cor), usada por espinhos/troncos.
func apply_slow(amount: float, duration: float) -> void:
	if is_boss:
		amount *= 0.4
	_slow_f = maxf(_slow_f if _slow_t > 0.0 else 0.0, amount)
	_slow_t = maxf(_slow_t, duration)


## Marca/desmarca dano a caminho (mira inteligente das armas).
func reserve(amount: float) -> void:
	pending_damage += amount


func release(amount: float) -> void:
	pending_damage = maxf(0.0, pending_damage - amount)


func is_doomed() -> bool:
	return dead or pending_damage >= hp


# ------------------------------------------------------------------ dano
func take_hit(amount: float, crit: bool = false, knock: Vector2 = Vector2.ZERO,
		elem: String = "", num_color: Color = Color.WHITE) -> void:
	if dead:
		return
	hp -= amount
	if elem != "":
		last_elem = elem
	var g := Game.current
	if g:
		g.show_number(global_position + Vector2(randf_range(-5, 5), -12 * _base_scale),
				amount, Color(1, 0.85, 0.2) if crit else num_color, crit)
	sprite.self_modulate = Color(3, 3, 3)
	_flash = 0.08
	if not is_boss and _shock_t <= 0.0:
		_knock += knock * (0.4 if is_elite else 1.0)
	if is_boss and g:
		g.boss_health_changed.emit(hp, max_hp)
	if hp <= 0.0:
		die()


func die() -> void:
	if dead:
		return
	dead = true
	if _brain:
		_brain.cleanup()
	remove_from_group("enemies")
	shape.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	sprite.self_modulate = Color.WHITE
	sprite.modulate = _base_tint
	sprite.speed_scale = 1.0
	sprite.play("death")
	killed.emit(self)
	if Game.current:
		Game.current.on_enemy_killed(self)
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)
