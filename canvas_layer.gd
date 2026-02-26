extends CanvasLayer

@onready var pause_button: Button = $PauseButton

@export var pause_icon: Texture2D
@export var play_icon: Texture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_pause_button_pressed() -> void:
	get_tree().paused = !get_tree().paused

	if get_tree().paused:
		pause_button.icon = play_icon
	else:
		pause_button.icon = pause_icon


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()  # Перезапустить сцену при нажатии кнопки


func _on_settings_button_pressed() -> void:

	get_tree().paused = false

	# 1️⃣ Disconnect multiplayer completely
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		# ✅ Force singleplayer multiplayer API into "local server" mode
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		

	# 2️⃣ Reset global state
	Global.reset_session()
	Global.is_multiplayer = false
	Global.difficulty = 1
	Global.bots_killed = 0
	Global.score = 0

	# 3️⃣ Go back to start menu
	get_tree().change_scene_to_file("res://startmenu.tscn")
