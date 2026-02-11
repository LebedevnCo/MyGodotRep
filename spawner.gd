extends Node2D

@export var food_scene: PackedScene
@export var max_food_count: int = 10
@export var ground_tilemap_path: NodePath ="../GroundTileMap"
@export var ground_layer: int = 0

var ground: TileMap
var valid_cells: Array[Vector2i] = []
var current_food_count: int = 0

func _ready():
	ground = get_node(ground_tilemap_path)
	_cache_ground_cells()

func _cache_ground_cells():
	valid_cells.clear()

	for cell in ground.get_used_cells(ground_layer):
		valid_cells.append(cell)

	if valid_cells.is_empty():
		push_error("FoodSpawner: no ground cells found!")

func _on_timer_timeout():
	if current_food_count >= max_food_count:
		return

	if valid_cells.is_empty():
		return

	var cell: Vector2i = valid_cells.pick_random()
	var world_pos: Vector2 = ground.map_to_local(cell)

	var food = food_scene.instantiate()
	food.global_position = world_pos

	add_child(food)
	current_food_count += 1

func _on_food_eaten():
	current_food_count -= 1
