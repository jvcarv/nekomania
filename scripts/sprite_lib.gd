class_name SpriteLib
## Monta SpriteFrames a partir das spritesheets em tempo de execução
## (com cache), para não precisar criar centenas de AtlasTextures à mão.

static var _cache: Dictionary = {}


## Adiciona uma animação a partir de uma tira (horizontal ou vertical) de quadros.
static func add_strip(sf: SpriteFrames, anim: String, path: String, fw: int, fh: int,
		fps: float = 10.0, loop: bool = true, row: int = 0, start: int = 0, count: int = -1,
		vertical: bool = false) -> void:
	var tex: Texture2D = load(path)
	if tex == null:
		push_warning("SpriteLib: textura não encontrada: " + path)
		return
	if sf.has_animation(anim):
		sf.remove_animation(anim)
	sf.add_animation(anim)
	sf.set_animation_speed(anim, fps)
	sf.set_animation_loop(anim, loop)
	var total: int = (tex.get_height() / fh) if vertical else (tex.get_width() / fw)
	if count < 0:
		count = total - start
	for i in range(start, start + count):
		var at := AtlasTexture.new()
		at.atlas = tex
		if vertical:
			at.region = Rect2(row * fw, i * fh, fw, fh)
		else:
			at.region = Rect2(i * fw, row * fh, fw, fh)
		sf.add_frame(anim, at)


static func cached(key: String, builder: Callable) -> SpriteFrames:
	if _cache.has(key):
		return _cache[key]
	var sf: SpriteFrames = builder.call()
	_cache[key] = sf
	return sf


static func _new_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	return sf


# ------------------------------------------------------------ personagem
static func character(id: int) -> SpriteFrames:
	return cached("char_%d" % id, func():
		var sf := _new_frames()
		var p := DB.char_texture_path(id)
		var dirs := ["down", "left", "right", "up"]
		for r in 4:
			add_strip(sf, "running_" + dirs[r], p, 32, 32, 10.0, true, r)
			add_strip(sf, "stop_" + dirs[r], p, 32, 32, 5.0, true, r, 1, 1)
		return sf)


## Ícone (quadro parado, de frente) do personagem.
static func character_icon(id: int) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = load(DB.char_texture_path(id))
	at.region = Rect2(32, 0, 32, 32)
	return at


## Ícone da poção de um poder (assets/potions, por Onocentaur).
static func potion_icon(weapon_id: String) -> Texture2D:
	var key := "potion_" + weapon_id
	if not _cache.has(key):
		var cell: Vector2i = DB.WEAPONS[weapon_id]["potion_cell"]
		var at := AtlasTexture.new()
		at.atlas = load(DB.POTION_SHEET)
		at.region = Rect2(Vector2(cell * DB.POTION_SIZE), Vector2(DB.POTION_SIZE))
		_cache[key] = at
	return _cache[key]


# ------------------------------------------------------------ inimigos
static func enemy(type_id: String) -> SpriteFrames:
	return cached("enemy_" + type_id, func():
		var sf := _new_frames()
		var d: Dictionary = DB.ENEMIES[type_id]
		var dir: String = d["dir"]
		var base := "res://assets/chars/%s/%s/%s" % [dir, dir, dir]
		add_strip(sf, "walk", base + "-Walk.png", 100, 100, 10.0, true)
		add_strip(sf, "idle", base + "-Idle.png", 100, 100, 8.0, true)
		add_strip(sf, "hurt", base + "-Hurt.png", 100, 100, 14.0, false)
		add_strip(sf, "death", base + "-Death.png", 100, 100, 10.0, false)
		add_strip(sf, "attack", "res://assets/chars/%s/%s/%s.png" % [dir, dir, d["attack"]], 100, 100, 14.0, false)
		return sf)


# ------------------------------------------------------------ efeitos / armas
const FX := "res://assets/spells/"

static func fx(name: String) -> SpriteFrames:
	return cached("fx_" + name, func():
		var sf := _new_frames()
		match name:
			"firebolt":
				add_strip(sf, "fly", FX + "Fire Effect 1/Fire Effect 1/Firebolt SpriteSheet.png", 48, 48, 15.0, true, 0, 0, 4)
				add_strip(sf, "hit", FX + "Fire Effect 1/Fire Effect 1/Firebolt SpriteSheet.png", 48, 48, 18.0, false, 0, 5, 6)
			"fire_burst":
				add_strip(sf, "hit", FX + "Fire Effect 1/Fire Effect 1/Fire Breath SpriteSheet.png", 48, 48, 16.0, false, 2, 0, 8)
			"holy":
				add_strip(sf, "hit", FX + "Holy VFX 01-02/Holy VFX 02/Holy VFX 02.png", 48, 48, 22.0, false)
			"holy_spark":
				add_strip(sf, "hit", FX + "Holy VFX 01-02/Holy VFX 01/Holy VFX 01 Impact.png", 32, 32, 18.0, false)
			"dark":
				add_strip(sf, "fly", FX + "Dark VFX 01 - 02/Dark VFX 1/Dark VFX 1 (40x32).png", 40, 32, 14.0, true, 0, 0, 10)
				add_strip(sf, "hit", FX + "Dark VFX 01 - 02/Dark VFX 1/Dark VFX 1 (40x32).png", 40, 32, 16.0, false, 1, 0, 7)
			"dark_burst":
				add_strip(sf, "hit", FX + "Dark VFX 01 - 02/Dark VFX 2/Dark VFX 2 (48x64).png", 48, 64, 20.0, false)
			"ice":
				add_strip(sf, "fly", FX + "Ice Effect 01/Ice Effect 01/Ice VFX 1/IceVFX 1 Repeatable.png", 48, 32, 16.0, true)
				add_strip(sf, "hit", FX + "Ice Effect 01/Ice Effect 01/Ice VFX 1/Ice VFX 1 Hit.png", 48, 32, 18.0, false)
			"thunder":
				add_strip(sf, "hit", FX + "Thunder Effect 01/Thunder Effect 01/Thunder Hit/Thunder hit w blur.png", 32, 32, 18.0, false)
			"acid":
				add_strip(sf, "loop", FX + "Acid VFX 01 - 02/Acid VFX 01 - 02/Acid VFX 2/Acid VFX 02Repeatable.png", 56, 32, 14.0, true, 0, 0, -1, true)
				add_strip(sf, "end", FX + "Acid VFX 01 - 02/Acid VFX 01 - 02/Acid VFX 2/Acid VFX 02Ending.png", 56, 32, 14.0, false, 0, 0, -1, true)
			"acid_blob":
				add_strip(sf, "hit", FX + "Acid VFX 01 - 02/Acid VFX 01 - 02/Acid VFX 1/Acid VFX 01.png", 32, 32, 18.0, false, 0, 10, 6)
			"wood":
				add_strip(sf, "fly", FX + "Wood VFX 01 - 02/Wood VFX 01 - 02/Wood VFX 01/Wood VFX 01 Repeatable.png", 32, 32, 14.0, true)
				add_strip(sf, "hit", FX + "Wood VFX 01 - 02/Wood VFX 01 - 02/Wood VFX 01/Wood VFX 01 Hit.png", 32, 32, 18.0, false)
			"arrow":
				add_strip(sf, "fly", "res://assets/chars/Skeleton Archer/Arrow(projectile)/Arrow03(32x32).png", 32, 32, 1.0, true)
			"coin":
				add_strip(sf, "spin", "res://assets/generated/coin.png", 16, 16, 12.0, true)
			"portal":
				add_strip(sf, "spin", "res://assets/generated/portal.png", 48, 48, 12.0, true)
		return sf)


## Cria um efeito animado que se destrói ao terminar.
static func spawn_fx(parent: Node, name: String, pos: Vector2, anim: String = "hit",
		scale: float = 1.0, rot: float = 0.0, offset: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE) -> AnimatedSprite2D:
	if parent == null:
		return null
	var s := AnimatedSprite2D.new()
	s.sprite_frames = fx(name)
	s.global_position = pos
	s.scale = Vector2.ONE * scale
	s.rotation = rot
	s.offset = offset
	s.modulate = tint
	s.z_index = 5
	parent.add_child(s)
	s.global_position = pos
	s.play(anim)
	s.animation_finished.connect(s.queue_free)
	return s
