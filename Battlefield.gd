extends Node2D
var game_over := false
func _ready():

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

	# Show screen on ALL player nodes (even dead ones)
	for node in get_tree().get_nodes_in_group("AllPlayers"):
		if is_win:
			node.show_win_screen()
		else:
			node.show_lose_screen()

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
	for player in get_tree().get_nodes_in_group("Player"):
		if player.has_method("on_bot_size_update"):
			player.on_bot_size_update(size_value)
	

	
