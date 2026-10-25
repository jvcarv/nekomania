extends Node
## Estado persistente do jogo (moedas, personagens desbloqueados, recordes)
## e utilidades globais. Registrado como autoload "Global".

const SAVE_PATH := "user://save.cfg"
const DEFAULT_CHAR := 13

var coins: int = 0
var unlocked: Array = [DEFAULT_CHAR]
var selected_char: int = DEFAULT_CHAR
var best_time: float = 0.0
var best_stage: int = 0
var best_level: int = 0
var total_kills: int = 0
var runs: int = 0
# progresso para os desafios (ver "req" em DB.CHARACTERS)
var boss_kills: int = 0
var wins: int = 0
var potions_total: int = 0
var elem_kills: Dictionary = {}     # elemento -> abates
var synergies: Array = []           # elementos com sinergia já ativada

## Resultado da última partida (lido pela tela de fim de jogo).
var last_run: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	UITheme.font()        # deixa a fonte padrão nítida (pixel art)
	UITheme.font(true)
	load_game()


# ---------------------------------------------------------------- input
func _setup_input() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("move_up", [KEY_W, KEY_UP])
	_add_keys("move_down", [KEY_S, KEY_DOWN])
	_add_keys("pause", [KEY_ESCAPE, KEY_P])
	_add_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	InputMap.action_add_event("pause", start)


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)


func _add_keys(action: String, keys: Array) -> void:
	_ensure_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _add_axis(action: String, axis: int, value: float) -> void:
	_ensure_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)


# ---------------------------------------------------------------- save
func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "coins", coins)
	cfg.set_value("player", "unlocked", unlocked)
	cfg.set_value("player", "selected_char", selected_char)
	cfg.set_value("records", "best_time", best_time)
	cfg.set_value("records", "best_stage", best_stage)
	cfg.set_value("records", "best_level", best_level)
	cfg.set_value("records", "total_kills", total_kills)
	cfg.set_value("records", "runs", runs)
	cfg.set_value("records", "boss_kills", boss_kills)
	cfg.set_value("records", "wins", wins)
	cfg.set_value("records", "potions_total", potions_total)
	cfg.set_value("records", "elem_kills", elem_kills)
	cfg.set_value("records", "synergies", synergies)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	coins = int(cfg.get_value("player", "coins", 0))
	unlocked = Array(cfg.get_value("player", "unlocked", [DEFAULT_CHAR]))
	selected_char = int(cfg.get_value("player", "selected_char", DEFAULT_CHAR))
	best_time = float(cfg.get_value("records", "best_time", 0.0))
	best_stage = int(cfg.get_value("records", "best_stage", 0))
	best_level = int(cfg.get_value("records", "best_level", 0))
	total_kills = int(cfg.get_value("records", "total_kills", 0))
	runs = int(cfg.get_value("records", "runs", 0))
	boss_kills = int(cfg.get_value("records", "boss_kills", 0))
	wins = int(cfg.get_value("records", "wins", 0))
	potions_total = int(cfg.get_value("records", "potions_total", 0))
	elem_kills = Dictionary(cfg.get_value("records", "elem_kills", {}))
	synergies = Array(cfg.get_value("records", "synergies", []))
	if not unlocked.has(DEFAULT_CHAR):
		unlocked.append(DEFAULT_CHAR)
	if not DB.CHARACTERS.has(selected_char) or not unlocked.has(selected_char):
		selected_char = DEFAULT_CHAR


func reset_save() -> void:
	coins = 0
	unlocked = [DEFAULT_CHAR]
	selected_char = DEFAULT_CHAR
	best_time = 0.0
	best_stage = 0
	best_level = 0
	total_kills = 0
	runs = 0
	boss_kills = 0
	wins = 0
	potions_total = 0
	elem_kills = {}
	synergies = []
	save_game()


# ---------------------------------------------------------------- personagens
func is_unlocked(id: int) -> bool:
	return unlocked.has(id)


func try_buy(id: int) -> bool:
	if is_unlocked(id):
		return true
	var price: int = DB.CHARACTERS[id]["price"]
	if coins < price or not can_buy(id):
		return false
	coins -= price
	unlocked.append(id)
	save_game()
	return true


func select_char(id: int) -> void:
	if is_unlocked(id):
		selected_char = id
		save_game()


## Chamado pelo jogo quando a partida termina (morte ou vitória).
## Retorna a lista de personagens cujo desafio foi concluído nesta partida.
func finish_run(result: Dictionary) -> Array:
	var before := _completed_challenges()
	last_run = result
	runs += 1
	coins += int(result.get("coins", 0))
	total_kills += int(result.get("kills", 0))
	best_time = maxf(best_time, float(result.get("time", 0.0)))
	best_stage = maxi(best_stage, int(result.get("stage", 0)))
	best_level = maxi(best_level, int(result.get("level", 0)))
	boss_kills += int(result.get("boss_kills", 0))
	potions_total += int(result.get("potions", 0))
	if result.get("victory", false):
		wins += 1
	var ek: Dictionary = result.get("elem_kills", {})
	for e in ek:
		elem_kills[e] = int(elem_kills.get(e, 0)) + int(ek[e])
	for e in result.get("synergies", []):
		if not synergies.has(e):
			synergies.append(e)
	save_game()
	var newly: Array = []
	for id in _completed_challenges():
		if not before.has(id):
			newly.append(id)
	return newly


# ---------------------------------------------------------------- desafios
func _completed_challenges() -> Array:
	var out: Array = []
	for id in DB.CHARACTERS:
		if DB.CHARACTERS[id].has("req") and req_met(id):
			out.append(id)
	return out


## [atual, meta] do desafio de um personagem.
func req_progress(id: int) -> Array:
	var r: Dictionary = DB.CHARACTERS[id].get("req", {})
	if r.is_empty():
		return [1, 1]
	var goal: int = int(r.get("value", 1))
	var cur := 0
	match r["type"]:
		"kills": cur = total_kills
		"boss_kills": cur = boss_kills
		"wins": cur = wins
		"stage": cur = best_stage
		"level": cur = best_level
		"survive": cur = int(best_time)
		"runs": cur = runs
		"potions": cur = potions_total
		"elem_kills": cur = int(elem_kills.get(r["elem"], 0))
		"synergy": cur = 1 if synergies.has(r["elem"]) else 0
	return [mini(cur, goal), goal]


func req_met(id: int) -> bool:
	var p := req_progress(id)
	return p[0] >= p[1]


## Texto do desafio, ex.: "Derrote 3 chefões".
static func req_text(id: int) -> String:
	var r: Dictionary = DB.CHARACTERS[id].get("req", {})
	if r.is_empty():
		return ""
	var v: int = int(r.get("value", 1))
	match r["type"]:
		"kills": return "Derrote %d inimigos (no total)" % v
		"boss_kills": return "Derrote %d chefões" % v
		"wins": return "Vença uma partida" if v == 1 else "Vença %d partidas" % v
		"stage": return "Chegue ao estágio %d" % v
		"level": return "Chegue ao nível %d numa partida" % v
		"survive": return "Sobreviva %s numa partida" % format_time(v)
		"runs": return "Jogue %d partidas" % v
		"potions": return "Beba %d poções (no total)" % v
		"elem_kills": return "Derrote %d inimigos com poderes de %s" % [v, DB.ELEMENTS[r["elem"]]["name"]]
		"synergy": return "Ative a sinergia de %s" % DB.ELEMENTS[r["elem"]]["name"]
	return ""


## Pode comprar? (tem desafio concluído, ou não tem desafio)
func can_buy(id: int) -> bool:
	return req_met(id)


static func format_time(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [s / 60, s % 60]
