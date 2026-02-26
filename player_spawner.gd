extends Node2D

@export var multiplayer_player_scene: PackedScene

@rpc("authority", "call_local")
func spawn_player(peer_id: int):
	if multiplayer_player_scene == null:
		print("No multiplayer player assigned!")
		return

	# If already exists (important when reconnecting / restarting)
	var existing := get_tree().current_scene.get_node_or_null("MP_%d" % peer_id)
	if existing:
		existing.queue_free()

	var player = multiplayer_player_scene.instantiate()

	# ✅ Deterministic name across all peers → RPC paths match
	player.name = "MP_%d" % peer_id

	get_tree().current_scene.add_child(player)
	player.global_position = global_position

	# server simulates everyone
	player.set_multiplayer_authority(1)
	player.owner_peer_id = peer_id
	
	if multiplayer.is_server():
		Global.server_ensure_color(peer_id)
		Global.broadcast_player_colors() # force refresh for new scene

	print("Spawned player:", player.name,
		" local_peer=", multiplayer.get_unique_id(),
		" owner_peer_id=", player.owner_peer_id,
		" authority=", player.get_multiplayer_authority())
