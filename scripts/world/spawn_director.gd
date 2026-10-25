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
	return 1.0 + 0.5 * d + 0.42 * d * d


func dmg_mult() -> float:
	var d := difficulty()
	return 1.0 + 0.25 * d + 0.06 * d * d


func reset() -> void:
	_budget = 0.0
	_swarm_t = 60.0
	_elite_t = 50.0
	_kill_times.clear()
	pressure = 1.0


## Ritmo adaptativo: quanto mais rápido o jogador mata, mais inimigos aparecem.
var pressure := 1.0
var _kill_times: Array = []
var _clock := 0.0
const KILL_WINDOW := 12.0


func register_kill() -> void:
	_kill_times.append(_clock)


func kill_rate() -> float:
	while not _kill_times.is_empty() and _clock - float(_kill_times[0]) > KILL_WINDOW:
		_kill_times.pop_front()
	return _kill_times.size() / KILL_WINDOW


func _physics_process(delta: float) -> void:
	if not active or game == null or game.player == null:
		return
	_clock += delta
	var d := difficulty()
	var alive := get_tree().get_nodes_in_group("enemies").size()
	var base_rate := 0.5 + 1.35 * d                 # inimigos por segundo
	# pressão sobe se o jogador mata mais rápido do que os inimigos chegam
	var want := clampf(kill_rate() / (base_rate * 1.2), 1.0, minf(2.5, 1.0 + difficulty()))
	pressure = move_toward(pressure, want, delta * (0.08 if want > pressure else 0.12))
	var max_alive := int(minf(300.0, (45.0 + 60.0 * d) * (0.8 + 0.4 * pressure)))
	var rate := base_rate * pressure
	if alive < int(10.0 + 20.0 * d):
		rate *= 2.0                                # tela vazia: reabastece rápido
	if game.boss != null:
		rate *= 0.5
	_budget = minf(_budget + rate * delta, 14.0)
	while _budget >= 1.0 and alive < max_alive:
		_budget -= 1.0
		alive += 1
		spawn(_pick_type(), _ring_pos())

	_swarm_t -= delta * pressure
	if _swarm_t <= 0.0:
		_swarm_t = randf_range(38.0, 50.0)
		spawn_swarm()

	_elite_t -= delta * pressure
	if _elite_t <= 0.0:
		_elite_t = randf_range(50.0, 70.0)
		var st: Dictionary = DB.STAGES[game.stage_index]
		spawn(_pick_from(st["elite"]), _ring_pos(), true)
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


func _pick_from(list: Array) -> String:
	return list[randi() % list.size()]


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
	var n := mini(60, int(10 + 9 * difficulty() + 6.0 * (pressure - 1.0)))
	var center := game.player.global_position
	var radius := 260.0
	var kind := _pick_from(st["swarm"])
	for i in n:
		var pos := center + Vector2.RIGHT.rotated(TAU * i / n) * radius
		spawn(kind, pos)
	game.announce("Uma horda está cercando você!", Color(1, 0.4, 0.4))


func summon_minions(at: Vector2, n: int) -> void:
	var st: Dictionary = DB.STAGES[game.stage_index]
	for i in n:
		spawn(_pick_from(st["swarm"]), at + Vector2.RIGHT.rotated(TAU * i / n) * 30.0)


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
