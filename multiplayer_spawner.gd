extends MultiplayerSpawner

# Put the .tscn path here
@export var food_scene_path: String = "res://Food.tscn"


func _ready() -> void:
	_register(food_scene_path)
	


func _register(path: String) -> void:
	if path.is_empty():
		return
	add_spawnable_scene(path)
	print("[FoodNetSpawner] Registered spawnable:", path)
