extends Node2D

@export var enabled: bool = true
@export var grid_size: int = 64  # Size of each grid square
@export var grid_color: Color = Color(0.7, 0.7, 0.7)  # Gray color for the grid
@export var ground_color: Color = Color(0.2, 0.6, 0.2)  # Green color for the ground (natural)

@export var ground_width: float = 2000  # Set a fixed ground width (e.g., 2000 units)
@export var ground_height: float = 1400  # Set a fixed ground height (e.g., 1400 units)

func _draw():
	# Draw the ground (background) first (fixed size)
	draw_rect(Rect2(Vector2(-ground_width / 2, -ground_height / 2), Vector2(ground_width, ground_height)), ground_color)

	# Calculate the number of columns and rows to draw grid lines within the fixed ground size
	var cols = int(ground_width / grid_size)  # Number of columns based on fixed ground width
	var rows = int(ground_height / grid_size)  # Number of rows based on fixed ground height

	# Draw vertical lines for the grid
	for i in range(-cols, cols):
		draw_line(Vector2(i * grid_size, -ground_height / 2), Vector2(i * grid_size, ground_height / 2), grid_color, 1)

	# Draw horizontal lines for the grid
	for j in range(-rows, rows):
		draw_line(Vector2(-ground_width / 2, j * grid_size), Vector2(ground_width / 2, j * grid_size), grid_color, 1)
