extends Node

signal player_colors_updated
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
# 🎨 Player colour identity
# -------------------------
const HOST_ID := 1

const COLOR_POOL := [
	{"name": "green",  "color": Color.GREEN},
	{"name": "yellow", "color": Color.YELLOW},
	{"name": "red",    "color": Color.RED},
	{"name": "black",  "color": Color.BLACK},
]

# peer_id -> index in COLOR_POOL (clients only); host handled separately
var player_color_index: Dictionary = {}   # { peer_id: int }
var player_join_order: Array[int] = []    # keeps stable assignment

func get_player_color(peer_id: int) -> Color:
	if peer_id == HOST_ID:
		return Color.WHITE
	if player_color_index.has(peer_id):
		return COLOR_POOL[int(player_color_index[peer_id])]["color"]
	# fallback if not assigned yet
	return Color.GRAY

func get_player_color_name(peer_id: int) -> String:
	if peer_id == HOST_ID:
		return "white"
	if player_color_index.has(peer_id):
		return str(COLOR_POOL[int(player_color_index[peer_id])]["name"])
	return "unknown"

# Server-only: ensure a stable colour index exists for this peer
func server_ensure_color(peer_id: int) -> void:
	if peer_id == HOST_ID:
		return
	if player_color_index.has(peer_id):
		return

	# stable “join order”
	player_join_order.append(peer_id)

	# assign next colour slot (max 4 clients)
	var idx := (player_join_order.size() - 1) % COLOR_POOL.size()
	player_color_index[peer_id] = idx

	# broadcast to all peers
	broadcast_player_colors()

func broadcast_player_colors() -> void:
	if not multiplayer.is_server():
		return
	set_player_colors.rpc(player_color_index)

@rpc("authority", "call_local")
func set_player_colors(map: Dictionary) -> void:
	# everyone stores the same mapping
	player_color_index = map.duplicate(true)
	emit_signal("player_colors_updated")

# -------------------------
# 📊 Логика подсчёта
# -------------------------

func register_bot_kill():
	bots_killed += 1
	_update_score()
	
	if is_multiplayer and multiplayer.is_server():
		sync_shared_score.rpc(bots_killed, score, difficulty)

	emit_signal("score_updated")

func _update_score():
	score = difficulty * bots_killed
	print ("score: ", score)

# -------------------------
# 🔄 Управление сессией
# -------------------------

func next_level():
	difficulty += 1
	_update_score()
	if is_multiplayer and multiplayer.is_server():
		sync_shared_score.rpc(bots_killed, score, difficulty)

	emit_signal("score_updated")

func reset_session():
	bots_killed = 0
	score = 0
	current_scene_path = ""
	player_color_index.clear()
	player_join_order.clear()
	emit_signal("player_colors_updated")
	emit_signal("score_updated")
	
@rpc("authority", "call_local")
func sync_shared_score(new_bots_killed: int, new_score: int, new_difficulty: int) -> void:
	bots_killed = new_bots_killed
	score = new_score
	difficulty = new_difficulty
	emit_signal("score_updated")
