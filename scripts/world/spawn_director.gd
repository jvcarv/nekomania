extends Node
class_name SpawnDirector
## Decide QUANDO, ONDE e QUAIS inimigos aparecem (estilo Megabonk/Survivors):
##  - orçamento contínuo de spawn que cresce com a dificuldade
##  - hordas que cercam o jogador periodicamente
##  - elites de tempos em tempos
##  - inimigos muito longe são reposicionados à frente do jogador

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const SPAWN_MIN := 300.0
const SPAWN_MAX := 360.0
const DESPAWN_DIST := 650.0

var game: Game
var active := false
var _budget := 0.0
var _swarm_t := 40.0
var _elite_t := 55.0
var _relocate_t := 1.0


## Dificuldade contínua: 0 no início do estágio 1, ~3 no fim do estágio 3.
func difficulty() -> float:
	return game.stage_index + clampf(game.stage_time / DB.STAGE_TIME, 0.0, 1.2)


func hp_mult() -> float:
	var d := difficulty()
	return 1.0 + 0.55 * d + 0.3 * d * d


func dmg_mult() -> float:
	return 1.0 + 0.3 * difficulty()


func reset() -> void:
	_budget = 0.0
	_swarm_t = 40.0
	_elite_t = 55.0


func _physics_process(delta: float) -> void:
	if not active or game == null or game.player == null:
		return
	var d := difficulty()
	var alive := get_tree().get_nodes_in_group("enemies").size()
	var max_alive := int(minf(240.0, 40.0 + 55.0 * d))
	var rate := 0.7 + 1.6 * d                     # inimigos por segundo
	if game.boss != null:
		rate *= 0.45
	_budget = minf(_budget + rate * delta, 12.0)
	while _budget >= 1.0 and alive < max_alive:
		_budget -= 1.0
		alive += 1
		spawn(_pick_type(), _ring_pos())

	_swarm_t -= delta
	if _swarm_t <= 0.0:
		_swarm_t = randf_range(38.0, 50.0)
		spawn_swarm()

	_elite_t -= delta
	if _elite_t <= 0.0:
		_elite_t = randf_range(50.0, 70.0)
		var st: Dictionary = DB.STAGES[game.stage_index]
		spawn(st["elite"], _ring_pos(), true)
		game.announce("Um inimigo de elite apareceu!", Color(1, 0.8, 0.3))

	_relocate_t -= delta
	if _relocate_t <= 0.0:
		_relocate_t = 1.0
		_relocate_far()


func _pick_type() -> String:
	var st: Dictionary = DB.STAGES[game.stage_index]
	var progress := game.stage_time / DB.STAGE_TIME
	var total := 0.0
	var options: Array = []
	for entry in st["spawn"]:
		if progress >= float(entry[2]):
			options.append(entry)
			total += float(entry[1])
	var r := randf() * total
	for entry in options:
		r -= float(entry[1])
		if r <= 0.0:
			return entry[0]
	return options[0][0]


func _ring_pos(dist_min: float = SPAWN_MIN, dist_max: float = SPAWN_MAX) -> Vector2:
	var p := game.player
	var ang := randf() * TAU
	# 40% das vezes nasce na direção em que o jogador anda
	if p.velocity.length() > 10.0 and randf() < 0.4:
		ang = p.velocity.angle() + randf_range(-0.8, 0.8)
	for i in 6:
		var pos := p.global_position + Vector2.RIGHT.rotated(ang) * randf_range(dist_min, dist_max)
		if not game.map.is_blocked(pos, 8.0):
			return pos
		ang += 0.7
	return p.global_position + Vector2.RIGHT.rotated(ang) * dist_max


func spawn(type_id: String, pos: Vector2, elite: bool = false, boss: Dictionary = {}) -> Enemy:
	var e: Enemy = ENEMY_SCENE.instantiate()
	e.setup(type_id, hp_mult(), dmg_mult(), elite, boss)
	e.global_position = pos
	game.world.add_child(e)
	return e


## Horda: um anel de inimigos cercando o jogador.
func spawn_swarm() -> void:
	var st: Dictionary = DB.STAGES[game.stage_index]
	var n := int(14 + 7 * difficulty())
	var center := game.player.global_position
	var radius := 260.0
	for i in n:
		var pos := center + Vector2.RIGHT.rotated(TAU * i / n) * radius
		spawn(st["swarm"], pos)
	game.announce("Uma horda está cercando você!", Color(1, 0.4, 0.4))


func summon_minions(at: Vector2, n: int) -> void:
	var st: Dictionary = DB.STAGES[game.stage_index]
	for i in n:
		spawn(st["swarm"], at + Vector2.RIGHT.rotated(TAU * i / n) * 30.0)


func spawn_boss() -> Enemy:
	var st: Dictionary = DB.STAGES[game.stage_index]
	var b: Dictionary = st["boss"]
	var e := spawn(b["type"], _ring_pos(220.0, 240.0), false, b)
	# o chefão não escala com o tempo extra, só com o estágio
	return e


func _relocate_far() -> void:
	var p := game.player.global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_boss:
			continue
		if e.global_position.distance_to(p) > DESPAWN_DIST:
			e.global_position = _ring_pos()


func clear_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
