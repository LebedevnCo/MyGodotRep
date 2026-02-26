# BotNetSpawner.gd
extends MultiplayerSpawner

@export var bot_scene_path := "res://bot_1.tscn"

func _ready() -> void:
	add_spawnable_scene(bot_scene_path)
	print("[Bot1NetSpawner] Registered:", bot_scene_path, " spawn_path=", spawn_path)
