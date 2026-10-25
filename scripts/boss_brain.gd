extends Node
class_name BossBrain
## Padrões de ataque dos chefões (ver "attacks" em DB.STAGES):
##  charge  - aviso em linha e investida rápida
##  slam    - aviso em círculo e pancada em área
##  volley  - rajada de projéteis em todas as direções
##  summon  - invoca lacaios
## Abaixo de 50% de vida (fase 2) os ataques ficam mais frequentes.

var boss: Enemy
var attacks: Array = ["summon"]
var state := "chase"
var _cd := 2.5
var _t := 0.0
var _last := ""
var _dir := Vector2.ZERO
var _hit_in_charge := false
var _tele: Telegraph
var _tree_t := 0.0


func phase2() -> bool:
	return boss.hp < boss.max_hp * 0.5


## Retorna a velocidade desejada, ou Vector2.INF para usar a perseguição normal.
func update(delta: float, player: Player) -> Vector2:
	_break_trees(delta)
	match state:
		"chase":
			_cd -= delta * (1.5 if phase2() else 1.0)
			if _cd <= 0.0:
				_start_attack(player)
			return Vector2.INF
		"charge_tele":
			_t -= delta
			if _t <= 0.0:
				_clear_tele()
				state = "charging"
				_t = 0.55
				_hit_in_charge = false
				boss.sprite.play("walk")
				boss.sprite.speed_scale = 2.5
			return Vector2.ZERO
		"charging":
			_t -= delta
			if not _hit_in_charge and boss.global_position.distance_to(player.global_position) < boss.contact_range() + 4.0:
				_hit_in_charge = true
				player.take_damage(boss.damage * 1.2)
				player.shake(5.0)
			if _t <= 0.0:
				boss.sprite.speed_scale = 1.0
				_recover(0.45)
			return _dir * boss.speed * 5.0
		"slam_tele":
			_t -= delta
			if _t <= 0.0:
				_do_slam(player)
			return Vector2.ZERO
		"volley_tele":
			_t -= delta
			if _t <= 0.0:
				_do_volley(player)
			return Vector2.ZERO
		"recover":
			_t -= delta
			if _t <= 0.0:
				state = "chase"
			return Vector2.ZERO
	return Vector2.INF


func _start_attack(player: Player) -> void:
	var options := attacks.duplicate()
	if options.size() > 1:
		options.erase(_last)
	var a: String = options[randi() % options.size()]
	_last = a
	_cd = randf_range(3.0, 4.0)
	match a:
		"charge":
			_dir = boss.global_position.direction_to(player.global_position)
			_tele = Telegraph.new()
			_tele.mode = "line"
			_tele.vec = _dir * boss.speed * 5.0 * 0.55
			_tele.width = 14.0 * boss.sprite.scale.x / 2.0
			_tele.duration = 0.75 if not phase2() else 0.55
			_t = _tele.duration
			_add_tele()
			state = "charge_tele"
		"slam":
			_tele = Telegraph.new()
			_tele.mode = "circle"
			_tele.radius = 26.0 * boss.sprite.scale.x
			_tele.duration = 0.9 if not phase2() else 0.7
			_t = _tele.duration
			_add_tele()
			boss.sprite.play("idle")
			state = "slam_tele"
		"volley":
			_t = 0.5
			boss.sprite.self_modulate = Color(2, 1.2, 1.2)
			state = "volley_tele"
		_:
			Game.current.director.summon_minions(boss.global_position, 5 + (2 if phase2() else 0))
			Game.current.announce("%s chamou reforços!" % boss.boss_name, Color(1, 0.6, 0.5))
			_recover(0.6)


func _add_tele() -> void:
	_tele.global_position = boss.global_position
	Game.current.fx_layer.add_child(_tele)


func _clear_tele() -> void:
	if is_instance_valid(_tele):
		_tele.queue_free()
	_tele = null


func _do_slam(player: Player) -> void:
	var r: float = _tele.radius if is_instance_valid(_tele) else 60.0
	var center := boss.global_position
	_clear_tele()
	boss.sprite.play("attack")
	if center.distance_to(player.global_position) <= r:
		player.take_damage(boss.damage * 1.4)
	player.shake(7.0)
	var fx := Game.current.fx_layer
	for i in 10:
		var p := center + Vector2.RIGHT.rotated(TAU * i / 10.0) * r * 0.8
		SpriteLib.spawn_fx(fx, "fire_burst", p, "hit", 0.8, 0.0, Vector2.ZERO, Color(1, 0.6, 0.5))
	_recover(0.5)


func _do_volley(player: Player) -> void:
	boss.sprite.self_modulate = Color.WHITE
	boss.sprite.play("attack")
	var n := 12 if not phase2() else 16
	var waves := 1 if not phase2() else 2
	var base := boss.global_position.direction_to(player.global_position).angle()
	for w in waves:
		for i in n:
			var a := EnemyArrow.new()
			a.damage = boss.damage * 0.6
			a.speed = 105.0
			a.direction = Vector2.RIGHT.rotated(base + TAU * i / n + w * PI / n)
			a.global_position = boss.global_position + Vector2(0, -8)
			a.modulate = Color(1.4, 0.6, 0.6)
			Game.current.fx_layer.add_child(a)
		if w < waves - 1:
			await get_tree().create_timer(0.35, false).timeout
			if boss.dead:
				return
	_recover(0.4)


func _recover(t: float) -> void:
	state = "recover"
	_t = t


## O chefão atravessa e derruba as árvores no caminho.
func _break_trees(delta: float) -> void:
	_tree_t -= delta
	if _tree_t > 0.0:
		return
	_tree_t = 0.12
	var space := boss.get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = boss.contact_range()
	q.shape = c
	q.transform = Transform2D(0, boss.global_position)
	q.collision_mask = 1
	for hit in space.intersect_shape(q, 8):
		var body = hit["collider"]
		if body is StaticBody2D and is_instance_valid(body):
			SpriteLib.spawn_fx(Game.current.fx_layer, "wood", body.global_position + Vector2(0, -12), "hit", 1.2)
			var tw: Tween = body.create_tween()
			tw.tween_property(body, "modulate:a", 0.0, 0.25)
			tw.tween_callback(body.queue_free)
			body.collision_layer = 0


func cleanup() -> void:
	_clear_tele()


func _exit_tree() -> void:
	_clear_tele()
