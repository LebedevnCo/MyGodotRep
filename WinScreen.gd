extends Control

var scene_map := {
	1: "res://battlefield.tscn",
	2: "res://battlefield2.tscn",
	3: "res://battlefield3.tscn"
}
var _sent_request := false

func _ready():
	visible = false

func _on_button_pressed():
	if Global.is_multiplayer and not multiplayer.is_server():
		$Button.visible = false
		return
	# Prevent double-click spam
	if _sent_request:
		return
	_sent_request = true
	
	# Always unpause locally (UI responsiveness)
	get_tree().paused = false
	
	if Global.is_multiplayer:
		if multiplayer.is_server():
			# Host presses continue -> run locally on server
			request_continue()
		else:
			# Client presses continue -> request server
			request_continue.rpc_id(1)
	else:
		_continue_solo()

func _continue_solo():
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

func _pick_next_scene() -> String:
	var available_scenes: Array[String] = []

	for scene_path in scene_map.values():
		if scene_path != Global.current_scene_path:
			available_scenes.append(scene_path)

	if available_scenes.is_empty():
		push_error("No available scenes to switch to!")
		return ""

	return available_scenes.pick_random()
	
@rpc("any_peer")
func request_continue():
	# This runs on the server because we rpc_id(1), but keep it safe:
	if not multiplayer.is_server():
		return

	# Server chooses the next scene using the SAME logic as solo
	var next_scene := _pick_next_scene()
	if next_scene.is_empty():
		return

	# Server updates session state
	Global.next_level()
	Global.current_scene_path = next_scene

	print("[SERVER] Loading next battlefield:", next_scene, " difficulty=", Global.difficulty)

	# Tell battlefield to load it for everyone
	var battlefield := get_tree().current_scene
	if battlefield and battlefield.has_method("load_next_battlefield"):
		battlefield.load_next_battlefield.rpc(next_scene, Global.difficulty)
