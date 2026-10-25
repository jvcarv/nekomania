extends Area2D
class_name Projectile
## Projétil genérico do jogador. Configure os campos antes de add_child().

var weapon: Weapon
var frames_name := "firebolt"
var hit_fx := "firebolt"
var hit_fx_scale := 0.6
var sprite_scale := Vector2(0.6, 0.6)
var direction := Vector2.RIGHT
var speed := 300.0
var damage := 10.0
var pierce := 0              # inimigos extras que atravessa
var max_range := 400.0
var radius := 5.0
var homing := 0.0            # força de curva (rad/s); 0 = reto
var homing_range := 260.0
var explosion_radius := 0.0  # > 0 causa dano em área ao acertar
var explosion_fx := ""
var slow := 0.0              # 0..1
var knockback := 40.0
var rotate_sprite := true

var _travel := 0.0
var _hit: Array = []
var _target: Enemy
var _sprite: AnimatedSprite2D
var _done := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4  # inimigos
	monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteLib.fx(frames_name)
	_sprite.scale = sprite_scale
	add_child(_sprite)
	_sprite.play("fly")
	z_index = 4
	rotation = direction.angle() if rotate_sprite else 0.0
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if homing > 0.0:
		if not is_instance_valid(_target) or _target.dead:
			_target = weapon.nearest_enemy(global_position, homing_range, _hit) if is_instance_valid(weapon) else null
		if _target:
			var want := global_position.direction_to(_target.global_position)
			var ang := direction.angle_to(want)
			direction = direction.rotated(clampf(ang, -homing * delta, homing * delta))
	if rotate_sprite:
		rotation = direction.angle()
	var step := speed * delta
	global_position += direction * step
	_travel += step
	if _travel > max_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _done or not (body is Enemy) or _hit.has(body) or body.dead:
		return
	_hit.append(body)
	if is_instance_valid(weapon):
		weapon.hit(body, damage, direction * knockback)
		if slow > 0.0:
			body.apply_slow(slow, 1.5)
		if explosion_radius > 0.0:
			for e in weapon.enemies_in_radius(global_position, explosion_radius):
				if e != body:
					weapon.hit(e, damage * 0.6, global_position.direction_to(e.global_position) * knockback)
			if explosion_fx != "":
				SpriteLib.spawn_fx(weapon.fx_parent(), explosion_fx, global_position, "hit", explosion_radius / 22.0)
	SpriteLib.spawn_fx(get_parent(), hit_fx, global_position, "hit", hit_fx_scale, direction.angle())
	if pierce <= 0:
		_done = true
		queue_free()
	else:
		pierce -= 1
