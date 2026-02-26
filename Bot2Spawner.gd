# Bot1Spawner.gd
extends Node2D

@export var bot_scene: PackedScene
@export var net_spawner_path: NodePath = "../MultiplayerSpawner"

@export var ground_tilemap_path: NodePath = "../GroundTileMap"
@export var ground_layer: int = 0
@export var dynamic_path: NodePath = "../Dynamic"

@export var player_block_rect_size: Vector2 = Vector2(300, 300)

var ground: TileMap
var dynamic_parent: Node2D
var valid_cells: Array[Vector2i] = []

func _ready() -> void:
	if not multiplayer.is_server():
		return

	ground = get_node(ground_tilemap_path) as TileMap
	dynamic_parent = get_node(dynamic_path) as Node2D
	var spawner := get_node(net_spawner_path) as MultiplayerSpawner

	_cache_ground_cells()

	print("[Bot1Spawner] ready. multiplayer=", Global.is_multiplayer, " server=", multiplayer.is_server())
	print("[Bot1Spawner] valid_cells=", valid_cells.size())

	var difficulty := int(Global.difficulty)
	var bot_to_spawn := (difficulty - 1)

	spawner.spawn_path = dynamic_parent.get_path()

	for i in range(bot_to_spawn):
		var world_pos: Vector2
		
		while true:
				var cell: Vector2i = valid_cells.pick_random()
				world_pos = ground.to_global(ground.map_to_local(cell))
				if not _is_blocked_by_players(world_pos):
					break

		var bot := bot_scene.instantiate() as Node2D

		# IMPORTANT: parent first (like FoodSpawner), then apply global pos
		dynamic_parent.add_child(bot, true)
		bot.set_deferred("global_position", world_pos)

		# Replicate spawn (your existing method)
		spawner.spawn(bot)

		print("[Bot1Spawner] spawning at global=", world_pos,
			" Dynamic.global=", dynamic_parent.global_position,
			" Dynamic.transform=", dynamic_parent.global_transform)

func _cache_ground_cells() -> void:
	valid_cells.clear()
	for cell: Vector2i in ground.get_used_cells(ground_layer):
		valid_cells.append(cell)

	if valid_cells.is_empty():
		push_error("Bot1Spawner: no ground cells found!")

func _is_blocked_by_players(pos: Vector2) -> bool:
	var half := player_block_rect_size * 0.5
	var players := get_tree().get_nodes_in_group("Player")

	for p in players:
		if p is Node2D:
			var pp := (p as Node2D).global_position
			if abs(pos.x - pp.x) <= half.x and abs(pos.y - pp.y) <= half.y:
				return true

	return false
