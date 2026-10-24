extends Node2D
class_name Game
## Controla a partida: estágios, chefões, portal, drops, level-up,
## pausa e fim de jogo.

static var current: Game

signal boss_spawned(boss: Enemy)
signal boss_health_changed(hp: float, max_hp: float)
signal boss_cleared
signal stage_started(index: int)
signal coins_changed(run_coins: int)
signal kills_changed(kills: int)
signal announced(text: String, color: Color)

const MAX_GEMS := 250
const MAX_NUMBERS := 70

@onready var world: Node2D = $World
@onready var player: Player = $World/Player
@onready var map: MapGenerator = $MapGenerator
@onready var director: SpawnDirector = $SpawnDirector
@onready var fx_layer: Node2D = $World/FX
@onready var hud: HUD = $HUD
@onready var level_up_menu: LevelUpMenu = $LevelUpMenu
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var game_over_screen: GameOverScreen = $GameOverScreen

var stage_index := 0
var stage_time := 0.0
var total_time := 0.0
var kills := 0
var run_coins := 0
var boss: Enemy = null
var boss_defeated := false
var is_over := false
var rerolls := 2
var _pending_levels := 0
var _portal: Node2D = null
var _numbers := 0


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


func _ready() -> void:
	get_tree().paused = false
	randomize()
	director.game = self
	player.leveled_up.connect(_on_player_leveled_up)
	player.died.connect(_on_player_died)
	level_up_menu.chosen.connect(_on_upgrade_chosen)
	hud.bind(self)
	start_stage(0)


# ------------------------------------------------------------------ estágios
func start_stage(index: int) -> void:
	stage_index = index
	stage_time = 0.0
	boss = null
	boss_defeated = false
	if _portal:
		_portal.queue_free()
		_portal = null
	director.clear_enemies()
	director.reset()
	map.generate(DB.STAGES[index], randi(), world, player.global_position)
	director.active = true
	stage_started.emit(index)
	var st: Dictionary = DB.STAGES[index]
	announce("Estágio %d — %s" % [index + 1, st["name"]], Color(1, 1, 0.8))


func _process(delta: float) -> void:
	if is_over:
		return
	stage_time += delta
	total_time += delta
	map.update_around(player.global_position)

	if stage_time >= DB.STAGE_TIME and boss == null and not boss_defeated:
		boss = director.spawn_boss()
		boss.killed.connect(_on_boss_killed)
		boss_spawned.emit(boss)
		announce("%s apareceu!" % boss.boss_name, Color(1, 0.35, 0.3))
		player.shake(6.0)

	if _portal and player.global_position.distance_to(_portal.global_position) < 16.0:
		_enter_portal()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not is_over and not level_up_menu.visible:
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if pause_menu.visible:
		pause_menu.close()
		get_tree().paused = false
	else:
		get_tree().paused = true
		pause_menu.open(self)


# ------------------------------------------------------------------ chefão e portal
func _on_boss_killed(_e: Enemy) -> void:
	boss_defeated = true
	var pos := boss.global_position
	boss = null
	boss_cleared.emit()
	director.active = false
	director.clear_enemies()
	for i in 12:
		_drop(Pickup.Kind.COIN, pos + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(8, 40), 1)
	add_coins(10 * (stage_index + 1))
	if stage_index >= DB.STAGES.size() - 1:
		announce("Você derrotou o último chefão!", Color(1, 0.9, 0.3))
		await get_tree().create_timer(2.5, false).timeout
		_end_run(true)
		return
	announce("Estágio concluído! Entre no portal.", Color(0.8, 0.6, 1))
	_portal = Node2D.new()
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SpriteLib.fx("portal")
	s.play("spin")
	_portal.add_child(s)
	_portal.global_position = pos
	_portal.z_index = -2
	world.add_child(_portal)
	var tw := _portal.create_tween().set_loops()
	tw.tween_property(s, "scale", Vector2(1.1, 1.1), 0.5)
	tw.tween_property(s, "scale", Vector2(0.95, 0.95), 0.5)
	hud.show_portal_arrow(_portal)


func _enter_portal() -> void:
	# coleta tudo que ficou no chão antes de trocar de estágio
	for p in get_tree().get_nodes_in_group("pickups"):
		p.attract()
	player.heal(player.stats["max_hp"] * 0.3)
	_portal.queue_free()
	_portal = null
	hud.show_portal_arrow(null)
	await get_tree().create_timer(0.6, false).timeout
	for p in get_tree().get_nodes_in_group("pickups"):
		p.queue_free()
	start_stage(stage_index + 1)


# ------------------------------------------------------------------ drops
func on_enemy_killed(e: Enemy) -> void:
	kills += 1
	kills_changed.emit(kills)
	var pos := e.global_position
	var xp := int(e.xp_value * (1.0 + 0.4 * stage_index))
	_drop_xp(pos, xp)
	var luck: float = player.stats["luck"]
	if randf() < e.coin_chance * (1.0 + luck):
		var n := 1
		if e.is_elite:
			n = 5 + stage_index * 2
		for i in n:
			_drop(Pickup.Kind.COIN, pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 1)
	if randf() < 0.008 * (1.0 + luck) or e.is_elite:
		_drop(Pickup.Kind.HEART, pos + Vector2(6, 0), 1)


func _drop_xp(pos: Vector2, value: int) -> void:
	var gems := get_tree().get_nodes_in_group("xp")
	if gems.size() >= MAX_GEMS:
		# junta a experiência na gema mais próxima para não pesar o jogo
		var best: Pickup = null
		var bd := INF
		for g in gems:
			var d := pos.distance_squared_to(g.global_position)
			if d < bd:
				bd = d
				best = g
		if best:
			best.add_value(value)
			return
	_drop(Pickup.Kind.XP, pos, value)


func _drop(kind: Pickup.Kind, pos: Vector2, value: int) -> void:
	var p := Pickup.new()
	p.kind = kind
	p.value = value
	p.global_position = pos
	world.call_deferred("add_child", p)


func add_coins(n: int) -> void:
	run_coins += n
	coins_changed.emit(run_coins)


# ------------------------------------------------------------------ level-up
func _on_player_leveled_up(_lvl: int) -> void:
	_pending_levels += 1
	if not level_up_menu.visible:
		_open_level_up()


func _open_level_up() -> void:
	get_tree().paused = true
	level_up_menu.open(self, build_upgrade_options(3))


func _on_upgrade_chosen(option: Dictionary) -> void:
	match option.get("type", ""):
		"weapon_new":
			player.add_weapon(option["id"])
		"weapon_up":
			var w := player.get_weapon(option["id"])
			if w:
				w.level_up(option["rarity"])
				player.weapons_changed.emit()
		"passive":
			player.apply_passive(option["id"], option["rarity"])
		"skip":
			player.heal(20.0)
	_pending_levels -= 1
	if _pending_levels > 0:
		_open_level_up()
	else:
		level_up_menu.close()
		get_tree().paused = false


func reroll() -> Array:
	rerolls -= 1
	return build_upgrade_options(3)


## Monta as opções de melhoria (armas novas, armas a evoluir e passivas).
func build_upgrade_options(n: int) -> Array:
	var luck: float = player.stats["luck"]
	var pool: Array = []
	var owned := player.weapon_list()
	for w in owned:
		if not w.is_maxed():
			pool.append({"type": "weapon_up", "id": w.id, "weight": 3.0})
	if owned.size() < DB.MAX_WEAPONS:
		for id in DB.WEAPONS:
			if player.get_weapon(id) == null:
				pool.append({"type": "weapon_new", "id": id, "weight": 1.6})
	for id in DB.PASSIVES:
		pool.append({"type": "passive", "id": id, "weight": 1.0 if id != "projectiles" else 0.35})
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		var total := 0.0
		for o in pool:
			total += o["weight"]
		var r := randf() * total
		var pick: Dictionary = pool.back()
		for o in pool:
			r -= o["weight"]
			if r <= 0.0:
				pick = o
				break
		pool.erase(pick)
		var opt := pick.duplicate()
		opt.erase("weight")
		var min_r := 0
		if opt["type"] == "passive":
			min_r = DB.PASSIVES[opt["id"]].get("min_rarity", 0)
		opt["rarity"] = 0 if opt["type"] == "weapon_new" else DB.roll_rarity(luck, min_r)
		out.append(opt)
	return out


# ------------------------------------------------------------------ fim de jogo
func _on_player_died() -> void:
	director.active = false
	announce("Você caiu...", Color(1, 0.3, 0.3))
	await get_tree().create_timer(1.2, false).timeout
	_end_run(false)


func _end_run(victory: bool) -> void:
	if is_over:
		return
	is_over = true
	director.active = false
	var result := {
		"victory": victory,
		"time": total_time,
		"stage": stage_index + 1,
		"level": player.level,
		"kills": kills,
		"coins": run_coins,
		"char": player.char_id,
	}
	Global.finish_run(result)
	get_tree().paused = true
	game_over_screen.open(result)


# ------------------------------------------------------------------ feedback
func announce(text: String, color: Color = Color.WHITE) -> void:
	announced.emit(text, color)


func show_number(pos: Vector2, amount: float, color: Color = Color.WHITE, big: bool = false) -> void:
	if _numbers >= MAX_NUMBERS:
		return
	_numbers += 1
	var l := Label.new()
	l.text = str(int(round(amount)))
	l.add_theme_font_size_override("font_size", 10 if big else 7)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 3)
	l.z_index = 20
	l.position = pos - Vector2(10, 6)
	l.size = Vector2(20, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 12.0, 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(l, "modulate:a", 0.0, 0.25).set_delay(0.35)
	tw.chain().tween_callback(func():
		_numbers -= 1
		l.queue_free())
