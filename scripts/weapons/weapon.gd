extends Node2D
class_name Weapon
## Classe base das armas. Cada arma define stats_for_level() e fire().

var id: String = ""
var player: Player
var level: int = 1
var bonus_damage: float = 0.0   # bônus extra vindo da raridade das melhorias
var _cd := 0.5

## Nomes amigáveis dos atributos para o texto das cartas de melhoria.
const STAT_LABELS := {
	"damage": "dano", "count": "projéteis", "cooldown": "recarga", "pierce": "perfuração",
	"area": "área", "chains": "saltos", "duration": "duração", "speed": "velocidade",
	"range": "alcance", "slow": "lentidão", "burn": "queimadura", "poison": "veneno", "freeze": "congelamento",
	"radius": "raio", "steal": "roubo de vida",
}


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		return
	_tick(delta)
	_cd -= delta * float(player.stats["attack_speed"])
	if _cd <= 0.0:
		if fire():
			_cd = stat("cooldown")
			Sound.play(id)
		else:
			_cd = 0.15


## Sobrescreva: retorna os atributos crus da arma para um nível.
func stats_for_level(_l: int) -> Dictionary:
	return {"damage": 10.0, "cooldown": 1.0}


## Sobrescreva: dispara. Retorna true se disparou (inicia recarga).
func fire() -> bool:
	return false


## Sobrescreva para lógica contínua (ex.: troncos orbitando).
func _tick(_delta: float) -> void:
	pass


func data() -> Dictionary:
	return DB.WEAPONS[id]


func raw(key: String, default_value = 0.0):
	return stats_for_level(level).get(key, default_value)


## Atributo final já com os multiplicadores do jogador.
func stat(key: String) -> float:
	var v: float = float(raw(key, 0.0))
	match key:
		"damage":
			return v * (1.0 + bonus_damage) * float(player.stats["damage"]) * (1.0 + synergy())
		"area":
			return v * float(player.stats["area"])
		"count":
			return v + float(player.stats["projectiles"])
	return v


## Bônus de sinergia: o jogador tem os dois poderes do mesmo elemento.
func synergy() -> float:
	var elem: String = DB.WEAPONS[id]["elem"]
	for w in player.weapon_list():
		if w != self and DB.WEAPONS[w.id]["elem"] == elem:
			return DB.SYNERGY_BONUS
	return 0.0


func level_up(rarity: int) -> void:
	level = mini(level + 1, DB.WEAPON_MAX_LEVEL)
	bonus_damage += [0.0, 0.1, 0.2, 0.35, 0.5][rarity]


func is_maxed() -> bool:
	return level >= DB.WEAPON_MAX_LEVEL


## Texto da próxima melhoria, comparando o nível atual com o próximo.
func upgrade_text(rarity: int) -> String:
	var a := stats_for_level(level)
	var b := stats_for_level(level + 1)
	var parts: Array = []
	for k in b:
		if not a.has(k) or is_equal_approx(float(a[k]), float(b[k])):
			continue
		var label: String = STAT_LABELS.get(k, k)
		var va := float(a[k])
		var vb := float(b[k])
		if k == "cooldown":
			parts.append("-%d%% %s" % [int(round((1.0 - vb / va) * 100.0)), label])
		elif k in ["count", "pierce", "chains"]:
			parts.append("+%d %s" % [int(vb - va), label])
		elif va != 0.0:
			parts.append("+%d%% %s" % [int(round((vb / va - 1.0) * 100.0)), label])
	var extra: float = [0.0, 0.1, 0.2, 0.35, 0.5][rarity]
	if extra > 0.0:
		parts.append("+%d%% dano bônus" % int(extra * 100))
	return ", ".join(parts)


# ------------------------------------------------------------ utilidades
func game() -> Game:
	return Game.current


func enemies() -> Array:
	return get_tree().get_nodes_in_group("enemies")


## Distância "efetiva": inimigos que já vão morrer pelos tiros a caminho
## ficam para o fim da fila, assim cada arma mira num alvo diferente.
func _score(from: Vector2, e: Enemy) -> float:
	var d := from.distance_squared_to(e.global_position)
	if e.is_doomed():
		d += 1.0e7
	return d


func nearest_enemy(from: Vector2, max_dist: float = 99999.0, exclude: Array = []) -> Enemy:
	var best: Enemy = null
	var best_s := INF
	var md := max_dist * max_dist
	for e in enemies():
		if exclude.has(e):
			continue
		if from.distance_squared_to(e.global_position) > md:
			continue
		var sc := _score(from, e)
		if sc < best_s:
			best_s = sc
			best = e
	return best


## N inimigos mais próximos (para mirar vários projéteis), evitando os condenados.
func nearest_enemies(from: Vector2, n: int, max_dist: float = 99999.0) -> Array:
	var list: Array = []
	var md := max_dist * max_dist
	for e in enemies():
		if from.distance_squared_to(e.global_position) < md:
			list.append([_score(from, e), e])
	list.sort_custom(func(x, y): return x[0] < y[0])
	var out: Array = []
	for i in mini(n, list.size()):
		out.append(list[i][1])
	return out


func enemies_in_radius(center: Vector2, radius: float) -> Array:
	var out: Array = []
	var r2 := radius * radius
	for e in enemies():
		if center.distance_squared_to(e.global_position) <= r2:
			out.append(e)
	return out


## Aplica dano com chance de crítico.
func hit(e: Enemy, dmg: float, knock: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(e):
		return
	var crit := randf() < float(player.stats["crit_chance"])
	if crit:
		dmg *= float(player.stats["crit_mult"])
	e.take_hit(dmg, crit, knock, DB.WEAPONS[id]["elem"])


func fx_parent() -> Node:
	var g := game()
	return g.fx_layer if g else get_tree().current_scene
