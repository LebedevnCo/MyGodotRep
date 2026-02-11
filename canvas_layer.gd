extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_pause_button_pressed() -> void:
	get_tree().paused = !get_tree().paused  # Toggle pause state
	# Change button text
	if get_tree().paused:$PauseButton.text = " ▶"
	else: $PauseButton.text = "⏸"


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()  # Перезапустить сцену при нажатии кнопки


func _on_settings_button_pressed() -> void:
	get_tree().quit()  # This will close the game
