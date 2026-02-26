extends Node2D

@export var food_scene: PackedScene
@export var max_food_count: int = 10
@export var ground_tilemap_path: NodePath = "../GroundTileMap"
@export var ground_layer: int = 0
@export var dynamic_path: NodePath = "../Dynamic"
@export var net_spawner_path: NodePath = "../MultiplayerSpawner"

@onready var timer: Timer = $Timer

var ground: TileMap
var valid_cells: Array[Vector2i] = []
var current_food_count: int = 0
var dynamic_parent: Node2D
var net_spawner: MultiplayerSpawner
func _ready() -> void:
		
	ground = get_node(ground_tilemap_path) as TileMap
	dynamic_parent = get_node(dynamic_path) as Node2D

	_cache_ground_cells()

	print("[FoodSpawner] ready. multiplayer=", Global.is_multiplayer, " server=", multiplayer.is_server())
	print("[FoodSpawner] valid_cells=", valid_cells.size())

	if Global.is_multiplayer:
		net_spawner = get_node_or_null(net_spawner_path) as MultiplayerSpawner
		if net_spawner == null:
			push_error("FoodSpawner: MultiplayerSpawner not found at path: %s" % str(net_spawner_path))
			return

		# IMPORTANT: use the RENAMED function here
		net_spawner.spawn_function = Callable(self, "_spawn_food_from_net")

		# Clients must NOT run the timer
		if not multiplayer.is_server():
			timer.stop()
			return

	# Solo OR server starts the timer
	timer.start()


func _cache_ground_cells() -> void:
	valid_cells.clear()
	for cell in ground.get_used_cells(ground_layer):
		valid_cells.append(cell)

	if valid_cells.is_empty():
		push_error("FoodSpawner: no ground cells found!")


func _on_timer_timeout() -> void:
	if Global.is_multiplayer and multiplayer.is_server() and net_spawner == null:
		push_warning("FoodSpawner: timer fired but net_spawner is null. Check net_spawner_path/exported value.")
		return
	if current_food_count >= max_food_count:
		return
	if valid_cells.is_empty():
		return

	var cell: Vector2i = valid_cells.pick_random()
	var world_pos: Vector2 = ground.to_global(ground.map_to_local(cell))

	if not Global.is_multiplayer:
		_spawn_food_local(world_pos)
	else:
		if multiplayer.is_server():
			# This Dictionary is correct now
			net_spawner.spawn({ "pos": world_pos })
	
	print("[FoodSpawner] spawning at global=", world_pos,
	" Dynamic.global=", dynamic_parent.global_position,
	" Dynamic.transform=", dynamic_parent.global_transform)

	current_food_count += 1


func _on_food_eaten() -> void:
	current_food_count = max(0, current_food_count - 1)


# SOLO ONLY: local parenting
func _spawn_food_local(world_pos: Vector2) -> void:
	var food := food_scene.instantiate()
	dynamic_parent.add_child(food)
	food.global_position = world_pos


# MULTIPLAYER ONLY: called by MultiplayerSpawner on EVERY peer.
# Do NOT add_child() here. MultiplayerSpawner parents it under Spawn Path.
func _spawn_food_from_net(data: Variant) -> Node:
	var food := food_scene.instantiate()
	print("[FoodSpawner] net spawn data pos=", data.get("pos", null),
	" Dynamic.global=", dynamic_parent.global_position)

	if typeof(data) == TYPE_DICTIONARY and data.has("pos"):
		# IMPORTANT: apply after MultiplayerSpawner has parented it
		food.set_deferred("global_position", data["pos"])

	return food
