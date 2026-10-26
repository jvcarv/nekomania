extends Node
## Autoload "Sound": músicas e efeitos sonoros.
##
## Músicas (assets/SFX, por Uendel Felipe Picoli Olivo):
##   home  = menus     phase = estágio     boss = luta contra o chefão
## Efeitos (assets/audio/sfx): cópias de arquivos do Ninja Adventure (CC0),
## renomeados pelo uso. Ver CREDITOS.md para a origem de cada um.
##
## Uso: Sound.play("coin")  /  Sound.music("boss")
## Volumes (0..1) ficam em user://settings.cfg.

const MUSIC := {
	"home": "res://assets/SFX/home.mp3",
	"phase": "res://assets/SFX/phase.mp3",
	"boss": "res://assets/SFX/boss.mp3",
}
const SFX_DIR := "res://assets/audio/sfx/"
const SETTINGS := "user://settings.cfg"

## nome -> [volume em dB, intervalo mínimo entre repetições (s), variação de tom]
const SFX := {
	"fire": [-14.0, 0.10, 0.08], "fire2": [-14.0, 0.15, 0.08],
	"holy": [-15.0, 0.10, 0.08], "holy2": [-15.0, 0.10, 0.08],
	"dark": [-14.0, 0.12, 0.08], "dark2": [-14.0, 0.15, 0.08],
	"ice": [-13.0, 0.10, 0.10], "ice2": [-12.0, 0.15, 0.08],
	"thunder": [-15.0, 0.10, 0.10], "thunder2": [-13.0, 0.25, 0.08],
	"acid": [-13.0, 0.12, 0.10], "acid2": [-13.0, 0.12, 0.10],
	"wood": [-11.0, 0.15, 0.10], "wood2": [-11.0, 0.15, 0.10],
	"enemy_hit": [-20.0, 0.06, 0.15], "enemy_die": [-17.0, 0.07, 0.15],
	"player_hurt": [-6.0, 0.25, 0.05], "arrow": [-16.0, 0.12, 0.10],
	"gem": [-21.0, 0.05, 0.12], "coin": [-12.0, 0.06, 0.08], "heart": [-8.0, 0.1, 0.0],
	"potion": [-6.0, 0.1, 0.0], "synergy": [-4.0, 0.1, 0.0], "level_up": [-5.0, 0.2, 0.0],
	"boss_alert": [-4.0, 0.3, 0.0], "boss_slam": [-5.0, 0.2, 0.0], "boss_charge": [-7.0, 0.2, 0.0],
	"boss_volley": [-7.0, 0.2, 0.0], "boss_summon": [-8.0, 0.3, 0.0], "boss_dead": [-3.0, 0.5, 0.0],
	"portal": [-5.0, 0.5, 0.0], "game_over": [-3.0, 0.5, 0.0], "victory": [-3.0, 0.5, 0.0],
	"ui_move": [-14.0, 0.04, 0.0], "ui_accept": [-10.0, 0.05, 0.0], "ui_back": [-10.0, 0.05, 0.0],
	"buy": [-8.0, 0.1, 0.0], "denied": [-10.0, 0.1, 0.0],
}
const VOICES := 24          # efeitos simultâneos no máximo

var music_volume := 0.7
var sfx_volume := 0.8
var current_music := ""

var _streams: Dictionary = {}
var _last: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _bus_music := 0
var _bus_sfx := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bus_music = _make_bus("Music")
	_bus_sfx = _make_bus("SFX")
	_music_a = _make_player("Music")
	_music_b = _make_player("Music")
	for i in VOICES:
		_pool.append(_make_player("SFX"))
	for k in SFX:
		_streams[k] = load(SFX_DIR + k + ".wav")
	_load_settings()
	get_tree().node_added.connect(_on_node_added)


func _make_bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	return idx


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p


# ------------------------------------------------------------------ efeitos
func play(sfx_name: String, volume_offset_db: float = 0.0) -> void:
	if not SFX.has(sfx_name) or sfx_volume <= 0.0:
		return
	var cfg: Array = SFX[sfx_name]
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(sfx_name, -10.0)) < float(cfg[1]):
		return
	_last[sfx_name] = now
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = _streams[sfx_name]
	p.volume_db = float(cfg[0]) + volume_offset_db
	var pv: float = cfg[2]
	p.pitch_scale = randf_range(1.0 - pv, 1.0 + pv) if pv > 0.0 else 1.0
	p.play()


# ------------------------------------------------------------------ música
## Troca a música com fade. Nome vazio = silêncio.
func music(track: String, fade: float = 0.8) -> void:
	if track == current_music:
		return
	current_music = track
	var old := _active
	var nxt := _music_b if old == _music_a else _music_a
	_active = nxt
	if old and old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -40.0, fade)
		tw.tween_callback(old.stop)
	if track == "" or not MUSIC.has(track):
		_active = null
		return
	var s: AudioStream = load(MUSIC[track])
	if s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = true
	nxt.stream = s
	nxt.volume_db = -40.0
	nxt.play()
	var tw2 := create_tween()
	tw2.tween_property(nxt, "volume_db", 0.0, fade)


func stop_music(fade: float = 0.6) -> void:
	music("", fade)


# ------------------------------------------------------------------ volume
func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_volume()
	_save_settings()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_volume()
	_save_settings()


func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(_bus_music, linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_mute(_bus_music, music_volume <= 0.0)
	AudioServer.set_bus_volume_db(_bus_sfx, linear_to_db(maxf(sfx_volume, 0.0001)))
	AudioServer.set_bus_mute(_bus_sfx, sfx_volume <= 0.0)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		music_volume = cfg.get_value("audio", "music", music_volume)
		sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	_apply_volume()


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SETTINGS)


## Controles de volume (Música / Efeitos) prontos para colocar num menu.
func make_volume_controls(width: float = 260.0) -> Control:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	for row in [["Música", music_volume, set_music_volume], ["Efeitos", sfx_volume, set_sfx_volume]]:
		g.add_child(UITheme.label(row[0], 16, Color.WHITE))
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.value = row[1]
		sl.custom_minimum_size = Vector2(width - 110.0, 24)
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.focus_mode = Control.FOCUS_ALL
		var cb: Callable = row[2]
		sl.value_changed.connect(func(v):
			cb.call(v)
			play("ui_move"))
		g.add_child(sl)
	return g


# ------------------------------------------------------------------ interface
## Todo botão criado ganha som de foco e de clique automaticamente.
func _on_node_added(n: Node) -> void:
	if n is Button and not n.has_meta("no_sound"):
		var b := n as Button
		b.focus_entered.connect(func(): play("ui_move"))
		b.pressed.connect(func():
			play("ui_back" if b.text == "Voltar" else "ui_accept"))
	elif n is HSlider:
		(n as HSlider).focus_entered.connect(func(): play("ui_move"))
