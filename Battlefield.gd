extends Node2D
var game_over := false
@onready var local_camera: Camera2D = $LocalCamera
@onready var canvas: CanvasLayer = $CanvasLayer

func _ready():
	if not Global.is_multiplayer:
		$LocalCamera.enabled = false
		$CanvasLayer.visible = false

	if Global.is_multiplayer:

		# 🔥 Remove ALL solo players immediately
		for child in get_children():
			if child.name == "Player":
				child.queue_free()

	# Continue normal setup
	_connect_existing_bots()

	if Global.is_multiplayer and multiplayer.is_server():

		multiplayer.peer_connected.connect(_on_peer_connected)

		# Spawn host
		var host_id = multiplayer.get_unique_id()
		$PlayerSpawner.spawn_player.rpc(host_id)

		# Spawn already connected peers
		for id in multiplayer.get_peers():
			$PlayerSpawner.spawn_player.rpc(id)
	

	_connect_existing_bots()
	print("Children at start:", get_children())

func _on_peer_connected(id):
	print("Peer connected:", id)
	$PlayerSpawner.spawn_player.rpc(id)
	
func _process(delta):
	
	if game_over:
		return

	_check_game_state()

	# 🔵 Multiplayer camera follow
	if Global.is_multiplayer:
		_update_camera_follow()
		update_ui()
		if Input.is_action_just_pressed("zoom_out"):
			local_camera.zoom *= 0.5
			local_camera.zoom.x = clamp(local_camera.zoom.x, 0.2, 4.0)
			local_camera.zoom.y = clamp(local_camera.zoom.y, 0.2, 4.0)

		if Input.is_action_just_pressed("zoom_in"):
			local_camera.zoom *= 2
			local_camera.zoom.x = clamp(local_camera.zoom.x, 0.2, 4.0)
			local_camera.zoom.y = clamp(local_camera.zoom.y, 0.2, 4.0)
		
	
	
		
func _check_game_state():
	var players = get_tree().get_nodes_in_group("Player")
	var bots = get_tree().get_nodes_in_group("bot")

	# Lose condition
	if players.is_empty():
		_end_game(false)
		return

	# Win condition (no bots left)
	if bots.is_empty():
		_end_game(true)
		return

	# Win condition (any player size >= 200)
	for player in players:
		var size = int(round(player.animated_sprite.scale.x * 100))
		if size >= 200:
			_end_game(true)
			return

func _end_game(is_win: bool):

	game_over = true

	if is_win:
		Global.difficulty += 1
		print("Difficulty increased to:", Global.difficulty)

	if Global.is_multiplayer:
		# Multiplayer → Battlefield UI
		if is_win:
			show_win_screen()
		else:
			show_lose_screen()
	else:
		# Solo → Let player handle its own UI
		for player in get_tree().get_nodes_in_group("Player"):
			if is_win:
				player.show_win_screen()
			else:
				player.show_lose_screen()

	get_tree().paused = true

func spawn_multiplayer():
	if multiplayer.is_server():
		var host_id = multiplayer.get_unique_id()
		$PlayerSpawner.spawn_player.rpc(host_id)

func _connect_existing_bots():
	for bot in get_tree().get_nodes_in_group("bot"):
		if bot.has_signal("bot_grew"):
			bot.bot_grew.connect(_on_bot_grew)

func _on_bot_grew(size_value: int):
	_notify_players(size_value)

func _notify_players(size_value: int):
	if Global.is_multiplayer:
		$CanvasLayer/SizeLabel2.text = "Last bot size: " + str(size_value)
	
func _update_camera_follow():

	var my_id = multiplayer.get_unique_id()

	for player in get_tree().get_nodes_in_group("Player"):
		if player.get_multiplayer_authority() == my_id:
			$LocalCamera.global_position = player.global_position
			return

func update_ui():

	if not Global.is_multiplayer:
		return

	var my_id = multiplayer.get_unique_id()

	for player in get_tree().get_nodes_in_group("Player"):
		if player.get_multiplayer_authority() == my_id:

			var player_size: int = int(round(player.animated_sprite.scale.x * 100))
			var bot_count: int = get_tree().get_nodes_in_group("bot").size()

			var role := ""

			if multiplayer.is_server():
				role = "Host"
			else:
				role = "Player"

			$CanvasLayer/SizeLabel.text = role + " (" + str(player_size) + ") | Bots: " + str(bot_count) + " | Score: " + str(Global.score)
			return

func show_win_screen():
	$CanvasLayer/WinScreen.visible = true
	$CanvasLayer/WinScreen/Label2.text = "Score: " + str(Global.score)
	get_tree().paused = true


func show_lose_screen():
	$CanvasLayer/LoseScreen.visible = true
	$CanvasLayer/LoseScreen/Label2.text = "Score: " + str(Global.score)
