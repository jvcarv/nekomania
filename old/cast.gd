extends Area2D

var travelled_distance = 0

const SPEED = 1000
const RANGE = 1200

# Called when the node enters the scene tree for the first time.
func _physics_process(delta: float) -> void:
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta
	travelled_distance += SPEED * delta
	
	if travelled_distance > RANGE:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	queue_free()
	if body.has_method("hit"):
		body.hit()
