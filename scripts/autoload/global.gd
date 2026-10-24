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

## Resultado da última partida (lido pela tela de fim de jogo).
var last_run: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
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
	save_game()


# ---------------------------------------------------------------- personagens
func is_unlocked(id: int) -> bool:
	return unlocked.has(id)


func try_buy(id: int) -> bool:
	if is_unlocked(id):
		return true
	var price: int = DB.CHARACTERS[id]["price"]
	if coins < price:
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
func finish_run(result: Dictionary) -> void:
	last_run = result
	runs += 1
	coins += int(result.get("coins", 0))
	total_kills += int(result.get("kills", 0))
	best_time = maxf(best_time, float(result.get("time", 0.0)))
	best_stage = maxi(best_stage, int(result.get("stage", 0)))
	best_level = maxi(best_level, int(result.get("level", 0)))
	save_game()


static func format_time(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [s / 60, s % 60]
