extends Control

var scene_map := {
	1: "res://battlefield.tscn",
	2: "res://battlefield2.tscn",
	3: "res://battlefield3.tscn"
}

func _ready():
	visible = false


func _on_button_pressed():
	get_tree().paused = false

	# 1️⃣ Увеличиваем сложность
	Global.difficulty += 1
	print("New difficulty:", Global.difficulty)

	# 2️⃣ Выбираем новую сцену (не текущую)
	var available_scenes: Array[String] = []

	for scene_path in scene_map.values():
		if scene_path != Global.current_scene_path:
			available_scenes.append(scene_path)

	if available_scenes.is_empty():
		push_error("No available scenes to switch to!")
		return

	var next_scene: String = available_scenes.pick_random()

	# 3️⃣ Сохраняем текущую сцену
	Global.current_scene_path = next_scene
	
	print("Loading next battlefield:", next_scene)

	# 4️⃣ Загружаем новую карту
	get_tree().change_scene_to_file(next_scene)
