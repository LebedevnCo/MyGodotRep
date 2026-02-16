extends CharacterBody2D

var botcount = Global.difficulty + 1
var SPEED: float = 150.0

@onready var camera: Camera2D = $Camera2D
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

	# Camera stays exactly on player
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE



func _physics_process(delta: float) -> void:
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
	update_ui()
	# -------------------------------------------------
	# # CAMERA ZOOM (always available)
	# -------------------------------------------------
	if Input.is_action_just_pressed("zoom_out"):
		camera.zoom *= 0.5   # zoom out
		camera.zoom.x = clamp(camera.zoom.x, 0.2, 4.0)
		camera.zoom.y = clamp(camera.zoom.y, 0.2, 4.0)

	if Input.is_action_just_pressed("zoom_in"):
		camera.zoom *= 2  # zoom in
		camera.zoom.x = clamp(camera.zoom.x, 0.2, 4.0)
		camera.zoom.y = clamp(camera.zoom.y, 0.2, 4.0)


# -------------------------------------------------
# UI (CanvasLayer stays under Player as requested)
# -------------------------------------------------

func update_ui():
	var player_size: int = int(round(animated_sprite.scale.x * 100))
	var bot_count: int = get_tree().get_nodes_in_group("bot").size()

	$CanvasLayer/SizeLabel.text = "Alex (" + str(player_size) + ") | Bots: " + str(bot_count)+ " | Score: "+ str(Global.score)

func show_win_screen():
	$CanvasLayer/WinScreen.visible = true
	$CanvasLayer/WinScreen/Label2.text = "Score: " + str(Global.score)
	animated_sprite.visible = false
	get_tree().paused = true

func show_lose_screen():
	$CanvasLayer/LoseScreen.visible = true
	$CanvasLayer/LoseScreen/Label2.text = "Score: " + str(Global.score)
	animated_sprite.visible = false
	

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

func on_bot_size_update(size_value: int):
	$CanvasLayer/SizeLabel2.text = "Last bot size: " + str(size_value)
func die():
	remove_from_group("Player")

	set_process(false)
	set_physics_process(false)
	set_process_input(false)

	animated_sprite.visible = false
