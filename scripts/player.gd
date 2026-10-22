extends CharacterBody2D

const SPEED = 150.0

var facing_towards = "down"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	handle_movement()
	move_and_slide()
		
func handle_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
	velocity = direction * SPEED
	
	if velocity != Vector2.ZERO:
		animation_logic(direction)
	else:
		animation_logic(direction, true)

func animation_logic(dir: Vector2, is_stopped: bool = false) -> void:
	
	if is_stopped:
		sprite.play("stop_" + facing_towards)
	
	if dir.x > 0: #right
		sprite.play("running_right")
		facing_towards = "right"	
	elif dir.y < 0: #down
		sprite.play("running_up")
		facing_towards = "up"
	elif dir.y > 0: #up
		sprite.play("running_down")
		facing_towards = "down"
	elif dir.x < 0: #left
		sprite.play("running_left")
		facing_towards = "left"	
