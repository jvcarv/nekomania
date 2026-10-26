extends Node2D
class_name ThunderFalcon
## Falcão do Néctar da Tempestade (sprite "Projectile 2" do Thunder Effect 01).

var weapon: Weapon
var damage := 14.0
var hits := 3
var search_range := 140.0
var stun := 0.8
var speed := 240.0

var _sprite: AnimatedSprite2D
var _target: Enemy
var _hit: Array = []
var _dir := Vector2.RIGHT
var _flying := false
var _life := 4.0


func _ready() -> void:
	z_index = 7
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteLib.fx("falcon")
	_sprite.scale = Vector2(0.8, 0.8)
	add_child(_sprite)
	_sprite.play("summon")
	await _sprite.animation_finished
	if not is_instance_valid(self):
		return
	_sprite.play("fly")
	_flying = true
	_pick_target()


func _pick_target() -> void:
	_target = null
	if is_instance_valid(weapon) and is_instance_valid(weapon.player) and hits > 0:
		_target = weapon.nearest_enemy(global_position, search_range, _hit)
		if is_instance_valid(_target):
			_target.reserve(damage)


func _physics_process(delta: float) -> void:
	if not _flying:
		return
	_life -= delta
	if is_instance_valid(_target) and not _target.dead:
		var to := _target.global_position + Vector2(0, -6) - global_position
		_dir = _dir.lerp(to.normalized(), minf(1.0, delta * 12.0)).normalized()
		if to.length() < 10.0:
			_strike(_target)
	elif hits > 0 and _life > 0.0:
		_pick_target()
		if _target == null:
			hits = 0
	global_position += _dir * speed * delta
	_sprite.flip_h = _dir.x < 0
	_sprite.rotation = clampf(_dir.y, -0.6, 0.6) * (-1.0 if _dir.x < 0 else 1.0)
	if (hits <= 0 and _target == null) or _life <= 0.0:
		_flying = false
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.25)
		tw.parallel().tween_property(self, "global_position", global_position + _dir * 50.0, 0.25)
		tw.tween_callback(queue_free)


func _strike(e: Enemy) -> void:
	e.release(damage)
	_hit.append(e)
	hits -= 1
	if is_instance_valid(weapon) and is_instance_valid(weapon.player):
		weapon.hit(e, damage, _dir * 40.0)
		e.apply_shock(stun)
		Sound.play("thunder", -2.0)
		SpriteLib.spawn_fx(get_parent(), "thunder", e.global_position + Vector2(0, -6), "hit", 0.8)
	_target = null
	_pick_target()


func _exit_tree() -> void:
	if is_instance_valid(_target):
		_target.release(damage)
