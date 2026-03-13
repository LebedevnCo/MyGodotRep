extends Node2D
var game_over := false
var _start_time_ms: int = 0
var game_state_enabled := false
var ready_peers: Dictionary = {}
var initial_spawn_done := false
@onready var local_camera: Camera2D = $LocalCamera
@onready var canvas: CanvasLayer = $CanvasLayer

# ------------------------------------------
# ✅ NEW: Server tells everyone to load map
# ------------------------------------------
@rpc("authority", "call_local")
func load_next_battlefield(scene_path: String, difficulty: int) -> void:
	Global.difficulty = difficulty
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)

# ------------------------------------------
# End screen broadcast (already OK)
# ------------------------------------------
@rpc("authority", "call_local")
func show_end_screen(is_win: bool) -> void:
	if is_win:
		show_win_screen()
	else:
		show_lose_screen()
	get_tree().paused = true

func _ready():
	_start_time_ms = Time.get_ticks_msec()

	if Global.is_multiplayer:

		# 🔥 Remove ALL solo players immediately
		for child in get_children():
			if child.name == "Player":
				child.queue_free()

	
	
	local_camera.make_current()
	
	
	if Global.is_multiplayer and multiplayer.is_server():
		if not multiplayer.peer_connected.is_connected(_on_peer_connected):
			multiplayer.peer_connected.connect(_on_peer_connected)
	

	# Continue normal setup
	_connect_existing_bots()
	print("Children at start:", get_children())
	
	_connect_existing_players()
	_mark_local_ready()
	
	if Global.is_multiplayer and multiplayer.is_server():
		_start_initial_spawn_checks()
	
	if not Global.is_multiplayer:
		game_state_enabled = true

func _on_peer_connected(id):
	print("[Battlefield] Peer connected:", id)

	# If someone joins while scene is already running,
	# server will try to spawn them on the timed checks,
	# and also immediately if they later send scene_ready().
	if multiplayer.is_server():
		_spawn_missing_player(id)
	
func _process(_delta):
	
	if game_over:
		return
	
	if not Global.is_multiplayer or multiplayer.is_server():
		_check_game_state()

	# 🔵 Multiplayer+ solo player camera follow
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
	if not game_state_enabled:
		return
	var players = get_tree().get_nodes_in_group("Player")
	var bots = get_tree().get_nodes_in_group("bot")

	# Lose condition
	if players.is_empty():
		_end_game(false)
		return

	# Win condition (no bots left)
	if bots.is_empty():
		# avoid instant win during initial spawn/replication window
		if Time.get_ticks_msec() - _start_time_ms < 2000:
			return
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

	# Multiplayer: server broadcasts end screen (no local scene changes here)
	if Global.is_multiplayer:
		show_end_screen.rpc(is_win)
		return

	# Solo: show correct screen
	if is_win:
		Global.difficulty += 1
		show_win_screen()
	else:
		Global.difficulty += 1
		show_lose_screen()
		

	get_tree().paused = true

func spawn_multiplayer():
	if multiplayer.is_server():
		var host_id = multiplayer.get_unique_id()
		$PlayerSpawner.spawn_player.rpc(host_id)

func _connect_existing_bots():
	for bot in get_tree().get_nodes_in_group("bot"):
		if bot.has_signal("bot_grew"):
			if not bot.bot_grew.is_connected(_on_bot_grew):
				bot.bot_grew.connect(_on_bot_grew)

func _on_bot_grew(size_value: int):
	_notify_players(size_value)

func _notify_players(size_value: int):
		if Global.is_multiplayer:
			_set_last_bot_size.rpc(size_value)
		else:
			_set_last_bot_size(size_value)

@rpc("authority", "call_local")
func _set_last_bot_size(size_value: int) -> void:
	$CanvasLayer/SizeLabel2.text = "Bot: " + str(size_value)
	
func _update_camera_follow():

	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		return
	# SOLO MODE
	if not Global.is_multiplayer:
		local_camera.global_position = players[0].global_position
		return
	# MULTIPLAYER MODE
	var my_id = multiplayer.get_unique_id()

	for player in players:
		# we identify "my" player by owner_peer_id (NOT authority)
		if player.owner_peer_id == my_id:
			$LocalCamera.global_position = player.global_position
			return

func update_ui():

	var players = get_tree().get_nodes_in_group("Player")

	if players.is_empty():
		return

	var target_player: Node2D = null

	# SOLO MODE
	if not Global.is_multiplayer:
		target_player = players[0]

	# MULTIPLAYER MODE
	else:
		var my_id = multiplayer.get_unique_id()

		for player in players:
			if player.owner_peer_id == my_id:
				target_player = player
				break

	if target_player == null:
		return

	var player_size: int = int(round(target_player.animated_sprite.scale.x * 100))
	var bot_count: int = get_tree().get_nodes_in_group("bot").size()

	var role := "Alex" 
	if Global.is_multiplayer:
		role = Global.get_player_color_name(target_player.owner_peer_id)
	
	$CanvasLayer/SizeLabel.text = role + " (" + str(player_size) + ") | Bots: " + str(bot_count) + " | Score: " + str(Global.score)+" |"+str(Global.difficulty)

func show_win_screen():
	$CanvasLayer/WinScreen.visible = true
	$CanvasLayer/WinScreen/Label.text = "Ух ты! Поздравляем!"
	$CanvasLayer/WinScreen/Label2.text = "Score: " + str(Global.score)
	get_tree().paused = true


func show_lose_screen():
	$CanvasLayer/WinScreen.visible = true
	$CanvasLayer/WinScreen/Label.text = "Вас сьели, как такое может быть?"
	$CanvasLayer/WinScreen/Label2.text = "Score: " + str(Global.score)
	Global.score = 0
	Global.bots_killed = 0
	Global.difficulty -= 1
	
func _connect_player_death(player: Node) -> void:
	if not player.has_signal("player_died"):
		return

	if not player.is_connected("player_died", Callable(self, "_on_player_died")):
		player.connect("player_died", Callable(self, "_on_player_died"))

func _connect_existing_players() -> void:
	for player in get_tree().get_nodes_in_group("Player"):
		_connect_player_death(player)
		
func _on_player_died(peer_id: int) -> void:
	var my_id := multiplayer.get_unique_id()

	# Only zoom if MY player died
	if not Global.is_multiplayer:
		_zoom_out_on_death()
		return

	if peer_id == my_id:
		_zoom_out_on_death()
		
@rpc("authority", "call_local")
func notify_player_died(peer_id: int) -> void:
	# Everyone receives this; only the dead player zooms locally
	print("[DeathNotify] peer_id=", peer_id, " local=", multiplayer.get_unique_id())
	if not Global.is_multiplayer:
		_zoom_out_on_death()
		return

	if peer_id == multiplayer.get_unique_id():
		_zoom_out_on_death()
		
func _zoom_out_on_death() -> void:
	var target_zoom := local_camera.zoom * 0.4
	local_camera.zoom.x = clamp(local_camera.zoom.x, 0.2, 4.0)
	local_camera.zoom.y = clamp(local_camera.zoom.y, 0.2, 4.0)
	var tween = create_tween()
	tween.tween_property(local_camera, "zoom", target_zoom, 0.2)

@rpc("any_peer")
func scene_ready(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	ready_peers[peer_id] = true
	print("[Battlefield] scene_ready from peer:", peer_id, " ready_count=", ready_peers.size())

	# If this peer is ready but has no player yet, spawn it now
	_spawn_missing_player(peer_id)

func _mark_local_ready() -> void:
	if not Global.is_multiplayer:
		game_state_enabled = true
		return

	var my_id := multiplayer.get_unique_id()

	if multiplayer.is_server():
		ready_peers[my_id] = true
		print("[Battlefield] host scene ready:", my_id)
	else:
		_send_scene_ready_delayed(my_id)


func _send_scene_ready_delayed(peer_id: int) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	print("[Battlefield] sending scene_ready from client:", peer_id)
	scene_ready.rpc_id(1, peer_id)
	
func _start_initial_spawn_checks() -> void:
	if not multiplayer.is_server():
		return
	if initial_spawn_done:
		return

	initial_spawn_done = true
	_initial_spawn_flow()

func _initial_spawn_flow() -> void:
	await get_tree().create_timer(1.0).timeout

	# First spawn attempt: host + all currently connected peers
	var host_id := multiplayer.get_unique_id()
	_spawn_missing_player(host_id)

	for id in multiplayer.get_peers():
		_spawn_missing_player(id)

	print("[Battlefield] initial player spawn attempt done")

	await get_tree().create_timer(2.0).timeout
	_check_missing_players_once("2s")

	await get_tree().create_timer(3.0).timeout
	_check_missing_players_once("5s")

	game_state_enabled = true
	print("[Battlefield] game state checks enabled")

func _spawn_missing_player(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	var node_name := "MP_%d" % peer_id
	var existing := get_tree().current_scene.get_node_or_null(node_name)
	if existing == null:
		print("[Battlefield] spawning missing player:", peer_id)
		$PlayerSpawner.spawn_player.rpc(peer_id)

func _check_missing_players_once(tag: String) -> void:
	if not multiplayer.is_server():
		return

	print("[Battlefield] missing-player check:", tag)

	var host_id := multiplayer.get_unique_id()
	_spawn_missing_player(host_id)

	for id in multiplayer.get_peers():
		_spawn_missing_player(id)
