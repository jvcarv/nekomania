extends Node2D
class_name ElectricOrb
## Orbe do Néctar da Tempestade.

var weapon: Weapon
var direction := Vector2.RIGHT
var speed := 55.0
var damage := 6.0
var zap_radius := 40.0
var max_range := 130.0
var _travel := 0.0
var _zap_t := 0.0


func _ready() -> void:
	z_index = 5
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SpriteLib.fx("thunder_orb")
	s.play("fly")
	s.scale = Vector2(0.9, 0.9)
	add_child(s)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_travel += speed * delta
	_zap_t -= delta
	if _zap_t <= 0.0 and is_instance_valid(weapon) and is_instance_valid(weapon.player):
		_zap_t = 0.3
		var targets := weapon.nearest_enemies(global_position, 2, zap_radius)
		for e in targets:
			weapon.hit(e, damage)
			WThunder.draw_bolt(get_parent(), [global_position, e.global_position])
	if _travel >= max_range:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.2)
		tw.tween_callback(queue_free)
		set_physics_process(false)
