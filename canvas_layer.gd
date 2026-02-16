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
	get_tree().change_scene_to_file("res://startmenu.tscn")
