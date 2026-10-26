class_name Names
## Nomes e descrições editáveis de gatos, inimigos e chefões.
##
## Os textos vêm de res://data/nomes.json (edite à vontade). No jogo exportado,
## um arquivo "nomes.json" ao lado do .exe também é lido e tem prioridade, então
## dá para trocar os nomes sem exportar de novo.
## Se um nome faltar no JSON, usa o padrão de scripts/data/db.gd.

const PATH := "res://data/nomes.json"

static var _data: Dictionary = {}
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	_data = _read(PATH)
	if not OS.has_feature("editor"):
		var extra := OS.get_executable_path().get_base_dir().path_join("nomes.json")
		if FileAccess.file_exists(extra):
			_merge(_data, _read(extra))


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var txt := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(txt)
	if parsed is Dictionary:
		return parsed
	push_warning("nomes.json inválido: " + path)
	return {}


static func _merge(into: Dictionary, from: Dictionary) -> void:
	for k in from:
		if from[k] is Dictionary and into.get(k) is Dictionary:
			_merge(into[k], from[k])
		else:
			into[k] = from[k]


static func _text(section: String, key: String, field: String, fallback: String) -> String:
	_load()
	var sec = _data.get(section)
	if sec is Dictionary:
		var e = sec.get(key)
		if e is Dictionary and e.get(field) is String and String(e[field]).strip_edges() != "":
			return e[field]
	return fallback


## Recarrega o arquivo (útil para testar mudanças sem reiniciar).
static func reload() -> void:
	_loaded = false
	_load()


# ------------------------------------------------------------------ gatos
static func cat(id: int) -> String:
	return _text("gatos", str(id), "nome", DB.CHARACTERS[id]["name"])


static func cat_desc(id: int) -> String:
	return _text("gatos", str(id), "descricao", DB.CHARACTERS[id]["desc"])


# ------------------------------------------------------------------ inimigos
static func enemy(type: String) -> String:
	return _text("inimigos", type, "nome", DB.ENEMIES[type]["name"])


static func enemy_desc(type: String) -> String:
	return _text("inimigos", type, "descricao", "")


# ------------------------------------------------------------------ chefões
## boss: o dicionário "boss" de DB.STAGES (a chave é o tipo: orc, werewolf, werebear)
static func boss(b: Dictionary) -> String:
	return _text("chefoes", b["type"], "nome", b["name"])


static func boss_desc(b: Dictionary) -> String:
	return _text("chefoes", b["type"], "descricao", "")
