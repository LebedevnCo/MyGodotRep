extends CharacterBody2D

@export var speed: float = 120.0
@export var bot_size_multiplier: float = 1.3
@export var base_scale: float = 0.3
@export var growth_multiplier: float = 1.015
@export var speed_gain: float = 4.0
@export var animation_name: String = "bot2"

@export var ground_tilemap_path: NodePath = "../../GroundTileMap"
@export var ground_layer: int = 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var eat_area: Area2D = $EatArea2D
@onready var collision: CollisionShape2D = $BotCollisionShape2D
@onready var detector: Area2D = $DetectorArea2D

var ground: TileMap
var direction: Vector2
var target: Node2D = null
var turn_timer := 0.0

# UI (debug)
signal bot_grew(new_size: int)
# -------------------------------------------------
# Init
# -------------------------------------------------
func _ready() -> void:
	add_to_group("bot")

	ground = get_node(ground_tilemap_path) as TileMap
	if ground == null:
		push_error("Bot2: GroundTileMap not found")
		return

	direction = Vector2.RIGHT.rotated(randf() * TAU)

	_init_size()
	
	
	print("Bot2 spawned | size:",
	int(round(sprite.scale.x * 100)),
	"| speed:", speed)

# -------------------------------------------------
# Size logic
# -------------------------------------------------
func _init_size():
	var bot_size: float = base_scale * bot_size_multiplier

	sprite.scale = Vector2.ONE * bot_size
	eat_area.scale = Vector2.ONE * bot_size
	collision.scale = Vector2.ONE * bot_size
	detector.scale = Vector2.ONE * bot_size

# -------------------------------------------------
# UI helpers
# -------------------------------------------------


# -------------------------------------------------
# Movement (TileMap-aware, wall-priority)
# -------------------------------------------------
func _physics_process(delta: float) -> void:
	turn_timer += delta
	if turn_timer >= 3.0:
		turn_timer = 0.0
		direction = direction.rotated(deg_to_rad(randf_range(-35, 35)))

	# --- TARGET VALIDATION (same priority logic as Bot1) ---
	if target:
		var desired_dir := (target.global_position - global_position).normalized()

		if _can_move_towards(desired_dir):
			direction = desired_dir
		else:
			target = null
			direction = direction.rotated(deg_to_rad(randf_range(90, 180)))

	var next_pos := global_position + direction * speed * delta

	if _is_on_ground(next_pos):
		velocity = direction * speed
	else:
		# Hard wall → always turn
		direction = direction.rotated(deg_to_rad(randf_range(90, 180)))
		velocity = Vector2.ZERO

	if velocity.length() > 0:
		sprite.play(animation_name)
		rotation = velocity.angle()
	else:
		sprite.stop()

	move_and_slide()

# -------------------------------------------------
# Ground checks (IDENTICAL TO BOT1)
# -------------------------------------------------
func _is_on_ground(world_pos: Vector2) -> bool:
	var cell: Vector2i = ground.local_to_map(world_pos)
	return ground.get_cell_source_id(ground_layer, cell) != -1

func _can_move_towards(dir: Vector2) -> bool:
	var look_ahead := global_position + dir.normalized() * 16.0
	return _is_on_ground(look_ahead)

# -------------------------------------------------
# Detection logic (advisory only)
# -------------------------------------------------
func _on_detector_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Food") and target == null:
		var dir := (body.global_position - global_position).normalized()
		if _can_move_towards(dir):
			target = body

	if body.is_in_group("Player"):
		_handle_player_detected(body)

func _on_detector_area_2d_body_exited(body: Node2D) -> void:
	if body == target:
		target = null

func _handle_player_detected(player: Node2D):
	var player_size: float = player.animated_sprite.scale.x
	var bot_size: float = sprite.scale.x

	var dir := (player.global_position - global_position).normalized()
	if not _can_move_towards(dir):
		return

	if player_size > bot_size * 1.1:
		target = null
		direction = (global_position - player.global_position).normalized()
	elif bot_size > player_size * 1.1:
		target = player

# -------------------------------------------------
# Growth
# -------------------------------------------------
func _grow():
	sprite.scale *= 1.03
	eat_area.scale *= 1.03
	collision.scale *= 1.03
	detector.scale *= 1.03

	speed = min(speed + 1.0, 500.0)

	var size_value: int = int(round(sprite.scale.x * 100))
	emit_signal("bot_grew", size_value)

# -------------------------------------------------
# Player vs Bot / Food
# (FUNCTION NAME KEPT AS REQUESTED)
# -------------------------------------------------
func _on_eat_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Food"):
		_grow()
		body.queue_free()
		target = null
		get_node("../../Spowner")._on_food_eaten()

	if body.is_in_group("Player"):
		_resolve_player_collision(body)

func _resolve_player_collision(player: Node2D):
	var player_size: float = player.animated_sprite.scale.x
	var bot_size: float = sprite.scale.x

	if player_size > bot_size * 1.1:
		player.animated_sprite.scale *= 1.02
		Global.register_bot_kill()
		queue_free()


		# Check win condition safely
		await get_tree().process_frame
		if get_tree().get_nodes_in_group("bot").is_empty():
			player.show_win_screen()
	elif bot_size > player_size * 1.1:
		player.die()
