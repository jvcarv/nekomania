extends AnimatedSprite2D

@onready var sprite: AnimatedSprite2D = $"."

func play_walk():
	sprite.play("walk")

func play_hurt():
	sprite.play("hurt")
	await sprite.animation_finished
	sprite.play("walk")

func play_death():
	sprite.play("death")
	await sprite.animation_finished
