extends Control

@onready var grid_container: GridContainer = %GridContainer
@onready var score_label: Label = %ScoreLabel
@onready var best_score_label: Label = %BestScoreLabel
@onready var game_over_overlay: ColorRect = %GameOverOverlay
@onready var final_score_label: Label = %FinalScoreLabel
@onready var highest_tile_label: Label = %HighestTileLabel
@onready var restart_button: Button = %RestartButton
@onready var title_label: Label = %TitleLabel
@onready var game_state_label: Label = %GameStateLabel

const TILE_SCENE := preload("res://scenes/tile.tscn")
var tile_nodes: Array = []  # 2D array [row][col]

func _ready():
	# Connect signals from autoload GameManager
	GameManager.board_updated.connect(_on_board_updated)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.tile_created.connect(_on_tile_created)
	
	# Connect restart button
	restart_button.pressed.connect(_on_restart_pressed)
	
	# Create tile nodes in the grid
	_create_tile_grid()
	
	# Start game (autoload GameManager already calls this, but we call it fresh)
	GameManager.start_new_game()
	_update_board()

func _create_tile_grid() -> void:
	tile_nodes.clear()
	for r in range(4):
		tile_nodes.append([])
		for c in range(4):
			var tile = TILE_SCENE.instantiate()
			tile.row = r
			tile.col = c
			grid_container.add_child(tile)
			tile_nodes[r].append(tile)

func _on_board_updated() -> void:
	_update_board()

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)
	best_score_label.text = "Best: " + str(GameManager.best_score)

func _update_board() -> void:
	var grid_data = GameManager.grid
	for r in range(4):
		for c in range(4):
			var val = grid_data[r][c]
			if r < tile_nodes.size() and c < tile_nodes[r].size():
				var tile_node = tile_nodes[r][c]
				if tile_node:
					tile_node.set_value(val)

func _on_tile_created(value: int, row: int, col: int) -> void:
	if row >= 0 and row < 4 and col >= 0 and col < 4:
		if row < tile_nodes.size() and col < tile_nodes[row].size():
			var tile_node = tile_nodes[row][col]
			if tile_node:
				tile_node.animate_appear()

func _on_game_over(final_score: int, highest_tile: int) -> void:
	final_score_label.text = "Score: " + str(final_score)
	highest_tile_label.text = "Highest Tile: " + str(highest_tile)
	
	if highest_tile >= 2048:
		game_state_label.text = "You Win!"
	else:
		game_state_label.text = "Game Over"
	
	# Animate overlay
	game_over_overlay.modulate = Color(0, 0, 0, 0)
	game_over_overlay.show()
	var tween = create_tween()
	tween.tween_property(game_over_overlay, "modulate", Color(0, 0, 0, 0.7), 0.3)

func _on_restart_pressed() -> void:
	game_over_overlay.hide()
	GameManager.start_new_game()
	_update_board()

func _input(event: InputEvent) -> void:
	# Pass input to GameManager for swipe detection
	GameManager._input(event)
