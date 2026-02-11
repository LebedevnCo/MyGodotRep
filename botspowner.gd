extends Node2D

@export var bot1_scene: PackedScene
@export var bot2_scene: PackedScene

@export var ground_tilemap_path: NodePath = "../GroundTileMap"
@export var ground_layer: int = 0

var ground: TileMap
var valid_cells: Array[Vector2i] = []

# -------------------------------------------------
# Init
# -------------------------------------------------
func _ready():
	ground = get_node(ground_tilemap_path) as TileMap
	print("Used cells:", ground.get_used_cells(ground_layer).size())
	if ground == null:
		push_error("BotSpawner: GroundTileMap not found")
		return

	_cache_ground_cells()

	var pair_count: int = max(int(Global.difficulty) - 1, 0)
	print("BotSpawner: spawning", pair_count, "pairs of bots")

	_spawn_bot_pairs(pair_count)

# -------------------------------------------------
# Cache ground cells
# -------------------------------------------------
func _cache_ground_cells():
	valid_cells.clear()

	for cell: Vector2i in ground.get_used_cells(ground_layer):
		valid_cells.append(cell)

	if valid_cells.is_empty():
		push_warning("BotSpawner: no ground cells found!")

# -------------------------------------------------
# Spawn bot pairs
# -------------------------------------------------
func _spawn_bot_pairs(pair_count: int):
	for pair_index in range(pair_count):
		_spawn_single_bot(bot1_scene, "BOT1", pair_index)
		_spawn_single_bot(bot2_scene, "BOT2", pair_index)

# -------------------------------------------------
# Spawn one bot
# -------------------------------------------------
func _spawn_single_bot(bot_scene: PackedScene, bot_name: String, pair_index: int):
	if bot_scene == null:
		push_error("BotSpawner: " + bot_name + " scene is NULL")
		return

	if valid_cells.is_empty():
		push_warning("BotSpawner: no valid cells to spawn bots")
		return

	var cell: Vector2i = valid_cells.pick_random()
	var local_pos: Vector2 = ground.map_to_local(cell)
	var world_pos: Vector2 = ground.to_global(local_pos)

	var bot: Node2D = bot_scene.instantiate()
	bot.global_position = world_pos
	add_child(bot)

	print(
		"Spawned", bot_name,
		"| pair:", pair_index,
		"| cell:", cell,
		"| world_pos:", world_pos
	)
