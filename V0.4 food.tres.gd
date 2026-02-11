extends StaticBody2D

@export var animation_name: String = "blue"  # Set your animation name
@onready var animated_sprite = $AnimatedSprite2D  # Reference to the sprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Food")  # Now the bot can detect it
	# Play the animation continuously
	animated_sprite.play(animation_name)
	# Make sure the animation loops (this is usually set in the editor but can also be done in code)
	animated_sprite.animation = animation_name
# Connect the signal to detect when the player collides with food

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
