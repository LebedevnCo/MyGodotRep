extends Node

# -------------------------
# 🎮 Состояние игры (сессия)
# -------------------------
var is_multiplayer := false
# Текущая сложность
var difficulty: int = 1

# Количество убитых ботов за сессию
var bots_killed: int = 0

# Общий счёт
var score: int = 0

# Текущая сцена (battlefield)
var current_scene_path: String = ""

# -------------------------
# 📊 Логика подсчёта
# -------------------------

func register_bot_kill():
	bots_killed += 1
	_update_score()

func _update_score():
	score = difficulty * bots_killed
	print ("score: ", score)

# -------------------------
# 🔄 Управление сессией
# -------------------------

func next_level():
	difficulty += 1
	_update_score()

func reset_session():
	bots_killed = 0
	score = 0
	current_scene_path = ""
