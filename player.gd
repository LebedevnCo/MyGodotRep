extends CharacterBody2D

var SPEED: float = 155.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Detect multiplayer mode
	if Global.is_multiplayer:
		queue_free()
		return
	print("Player global position:", global_position)
	
	add_to_group("Player")
	add_to_group("AllPlayers")
	
	
	# Initial player size
	var initial_player_size: float = 0.3
	animated_sprite.scale = Vector2.ONE * initial_player_size
	$"Yamnyam-Area2D".scale = Vector2.ONE * initial_player_size
	$PlayerCollisionShape2D.scale = Vector2.ONE * initial_player_size


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	if input_vector.length() > 0:
		velocity = input_vector.normalized() * SPEED
		animated_sprite.play("walk")
		rotation = velocity.angle()
	else:
		velocity = Vector2.ZERO
		animated_sprite.stop()

	move_and_slide()

# -------------------------------------------------
# Food collision
# -------------------------------------------------
func _on_yamnyam_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Food"):
		animated_sprite.scale *= 1.02
		$"Yamnyam-Area2D".scale *= 1.02
		$PlayerCollisionShape2D.scale *= 1.02

		SPEED = min(SPEED + 2.0, 500.0)

		print(
			"[PLAYER] EATEN | size:",
			int(round(animated_sprite.scale.x * 100)),
			"| speed:", SPEED
		)

		body.queue_free()
		get_node("../Spowner")._on_food_eaten()


func die():
	remove_from_group("Player")
	remove_from_group("AllPlayers")

	set_process(false)
	set_physics_process(false)
	set_process_input(false)

	animated_sprite.visible = false
