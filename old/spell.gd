extends Area2D

@onready var sprite:AnimatedSprite2D = $SpellPivot/Fire

func _ready():
	sprite.play("default")

func _physics_process(_delta):
	var enemies_in_range = get_overlapping_bodies()
	
	if enemies_in_range.size() > 0:
		var target = enemies_in_range.front()
		look_at(target.global_position)

func cast_a_spell():
	const FIRE = preload("res://scenes/cast.tscn")
	var new_shoot = FIRE.instantiate()
	new_shoot.global_position = %ShootPoint.global_position
	new_shoot.global_rotation = %ShootPoint.global_rotation
	%ShootPoint.add_child(new_shoot)


func _on_timer_timeout() -> void:
	cast_a_spell()
