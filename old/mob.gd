extends CharacterBody2D

var health = 5
const SPEED = 50.0

var is_alive = true

var direction: Vector2 = Vector2.ZERO

@onready var sprite:AnimatedSprite2D = $slime
@onready var player = get_node("/root/Game/Player")

func _ready() -> void:
	sprite.play_walk()

func _physics_process(_delta: float) -> void:
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if is_alive:
		direction = global_position.direction_to(player.global_position)
	else:
		await sprite.play_death()
		queue_free()
	
	velocity = direction * SPEED
	
	_handle_animation()
	move_and_slide()

func hit():
	health -= 1
	sprite.play_hurt()
	
	if health == 0:
		is_alive = false

func _handle_animation():
	if velocity.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
