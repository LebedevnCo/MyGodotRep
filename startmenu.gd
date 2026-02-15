extends Control
#load screen
var splash: TextureRect



# UI elements
var shape_label: RichTextLabel
var difficulty_slider: Slider
var shape_slider: Slider

# Selected values
var selected_shape: String
var selected_scene_path: String = "res://battlefield.tscn"

# Mapping slider value → shape symbol
var shape_map = {
	1: "▭",  # Rectangle
	2: "△",  # Triangle
	3: "○"   # Circle
}

# Mapping slider value → scene
var scene_map = {
	1: "res://battlefield.tscn",
	2: "res://battlefield2.tscn",
	3: "res://battlefield3.tscn"
}

func _ready():
	Global.is_multiplayer = false
	#laodIP for multiplayer
	show_local_ip()
	multiplayer.connected_to_server.connect(_on_connected)
	#multiplayer.peer_connected.connect(_on_peer_connected)
	
	#laodscreen function
	splash = $TextureRect
	splash.show()

	await get_tree().create_timer(5.0).timeout
	splash.hide()
	
	# Get UI nodes
	shape_label = $VBoxContainer/ShapeLabel
	difficulty_slider = $VBoxContainer/DiffSlider
	shape_slider = $VBoxContainer/ShapeSlider

	# Initial state
	shape_slider.value = 1
	selected_shape = shape_map[1]
	selected_scene_path = scene_map[1]

	shape_label.bbcode_text = \
		"battlefield shape:\n[color=yellow]" + selected_shape + "[/color]"

	$VBoxContainer/DiffLabel.text = "Difficulty: " + str(int(difficulty_slider.value))

	print("Start menu ready")
	print("Default battlefield:", selected_scene_path)

# ---------- BUTTONS ----------

func _on_start_b_pressed() -> void:
	# Multiplayer mode
	if multiplayer.has_multiplayer_peer():
		
		# Only host can start
		if multiplayer.is_server():
			start_game.rpc(selected_scene_path, Global.difficulty)
	
	# Single player mode
	else:
		Global.is_multiplayer = false
		start_game(selected_scene_path, Global.difficulty)
	

@rpc("authority", "call_local")
func start_game(scene_path, difficulty):
	Global.difficulty = difficulty
	get_tree().change_scene_to_file(scene_path)

func _on_exit_b_pressed() -> void:
	get_tree().quit()

# ---------- SLIDERS ----------

func _on_shape_slider_drag_ended(value_changed: bool) -> void:
	var shape_index := int(shape_slider.value)

	selected_shape = shape_map[shape_index]
	selected_scene_path = scene_map[shape_index]

	shape_label.bbcode_text = \
		"battlefield shape:\n[color=yellow]" + selected_shape + "[/color]"

	print("Selected battlefield:", selected_scene_path)

func _on_diff_slider_drag_ended(value_changed: bool) -> void:
	var difficulty := int(difficulty_slider.value)
	$VBoxContainer/DiffLabel.text = "Difficulty: " + str(difficulty)

	Global.difficulty = difficulty
	print("Difficulty level:", difficulty)

func show_local_ip():
	var addresses = IP.get_local_addresses()
	
	for addr in addresses:
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			$VBoxContainer2/yIPLabel.text = "Your IP: " + addr
			return

func _on_host_b_pressed():
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(7777)
	
	if result != OK:
		return
		
	multiplayer.multiplayer_peer = peer
	Global.is_multiplayer = true
	$VBoxContainer2/yIPLabel.text = "Hosting... My ID: " + \
		str(multiplayer.get_unique_id())
	

func _on_join_b_pressed():
	var ip = $VBoxContainer2/LineEdit.text.strip_edges()
	
	if ip == "":
		return
		
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(ip, 7777)
	
	if result != OK:
		return
	
	Global.is_multiplayer = true
	multiplayer.multiplayer_peer = peer
	
	

func _on_connected():
	$VBoxContainer2/yIPLabel.text = "Connected! My ID: " + \
		str(multiplayer.get_unique_id())

#func _on_peer_connected(id):
	#$VBoxContainer2/yIPLabel.text = "Peer connected: " + str(id)
