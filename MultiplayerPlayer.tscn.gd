extends CharacterBody2D

signal player_died(peer_id: int)

var SPEED: float = 155.0
var last_input := Vector2.ZERO
var is_dead: bool = false
@export var owner_peer_id: int = 1
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var head_circle: Polygon2D = $HeadCircle


@rpc("any_peer", "unreliable")
func send_input(dir: Vector2) -> void:
	# Only the server stores inputs
	if not multiplayer.is_server():
		return

	var sender := multiplayer.get_remote_sender_id()

	# ✅ Validate by authority (no owner_peer_id needed)
	if sender != owner_peer_id:
		return

	last_input = dir


@rpc("unreliable")
func sync_state(pos: Vector2, rot: float, scale_x: float, speed_val: float) -> void:
	# Server is the source of truth
	if multiplayer.is_server():
		return

	global_position = pos
	rotation = rot
	animated_sprite.scale = Vector2.ONE * scale_x
	SPEED = speed_val
	
	if animated_sprite.animation != "walk" or not animated_sprite.is_playing():
		animated_sprite.play("walk")


func _ready() -> void:
	add_to_group("Player")
	add_to_group("AllPlayers")

	var initial_player_size: float = 0.3
	animated_sprite.scale = Vector2.ONE * initial_player_size
	$"Yamnyam-Area2D".scale = Vector2.ONE * initial_player_size
	$PlayerCollisionShape2D.scale = Vector2.ONE * initial_player_size
	
	apply_player_color()
	var cb := Callable(self, "apply_player_color")
	if not Global.is_connected("player_colors_updated", cb):
		Global.connect("player_colors_updated", cb)
	call_deferred("apply_player_color")
	
	animated_sprite.play("walk")

func _physics_process(_delta: float) -> void:
	# Only server simulates movement
	if not multiplayer.is_server():
		return

	# ✅ Host input (listen-server): read input locally for host-owned player
	if owner_peer_id == 1:
		last_input = Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		)

	var input_vector := last_input

	if input_vector.length() > 0:
		velocity = input_vector.normalized() * SPEED
		rotation = velocity.angle()
	else:
		velocity = Vector2.ZERO
		

	move_and_slide()

	# Replicate state to everyone (unreliable because of @rpc("unreliable"))
	sync_state.rpc(global_position, rotation, animated_sprite.scale.x, SPEED)


func _process(_delta: float) -> void:
	# Clients send input to server for THEIR avatar only
	if multiplayer.is_server():
		return

	var my_id := multiplayer.get_unique_id()
	if owner_peer_id != my_id:
		return

	var input_vector := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	send_input.rpc_id(1, input_vector)


# -------------------------------------------------
# Food collision (server-authoritative)
# -------------------------------------------------
func _on_yamnyam_area_2d_body_entered(body: Node2D) -> void:
	if is_dead:
		return
		
	if Global.is_multiplayer and not multiplayer.is_server():
		return

	if body.is_in_group("Food"):
		animated_sprite.scale *= 1.02
		$"Yamnyam-Area2D".scale *= 1.02
		$PlayerCollisionShape2D.scale *= 1.02

		SPEED = min(SPEED + 2.0, 500.0)

		body.queue_free()
		get_node("../Spowner")._on_food_eaten()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	remove_from_group("Player")

	# скрыть игрока у всех
	if Global.is_multiplayer and multiplayer.is_server():
		set_dead_visual.rpc()
	else:
		set_dead_visual()

	emit_signal("player_died", owner_peer_id)

	# zoom-out только для умершего локального игрока
	if Global.is_multiplayer and multiplayer.is_server():
		var battlefield := get_tree().current_scene
		if battlefield and battlefield.has_method("notify_player_died"):
			battlefield.notify_player_died.rpc(owner_peer_id)

func apply_player_color() -> void:
	if head_circle == null:
		return
	head_circle.color = Color(Global.get_player_color(owner_peer_id),0.3)
	
@rpc("authority", "call_local")
func set_dead_visual() -> void:
	is_dead = true

	# скрываем визуал
	animated_sprite.visible = false
	head_circle.visible = true

	# отключаем зоны/коллизии, чтобы "призрак" не участвовал в игре
	$"Yamnyam-Area2D".monitoring = false
	$"Yamnyam-Area2D".monitorable = false
	$PlayerCollisionShape2D.disabled = true
