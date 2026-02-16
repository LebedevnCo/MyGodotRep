extends Node2D

@export var multiplayer_player_scene: PackedScene

@rpc("authority", "call_local")
func spawn_player(peer_id: int):
	if multiplayer_player_scene == null:
		print("No multiplayer player assigned!")
		return

	var player = multiplayer_player_scene.instantiate()

	get_tree().current_scene.add_child(player)
	player.global_position = global_position

	# 🔹 Assign authority to that peer
	player.set_multiplayer_authority(peer_id)

	print("Spawned player for peer:", peer_id)
