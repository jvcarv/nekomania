extends Area2D
class_name EnemyArrow
## Flecha disparada pelo Esqueleto Arqueiro.

var damage := 8.0
var direction := Vector2.RIGHT
var speed := 115.0
var _life := 4.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # jogador
	monitorable = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.0
	cs.shape = c
	add_child(cs)
	var s := Sprite2D.new()
	s.texture = load("res://assets/chars/Skeleton Archer/Arrow(projectile)/Arrow03(32x32).png")
	s.scale = Vector2(0.6, 0.6)
	add_child(s)
	rotation = direction.angle()
	z_index = 4
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage)
		queue_free()
