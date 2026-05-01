extends Node

signal board_updated
signal game_over(final_score: int, highest_tile: int)
signal score_changed(new_score: int)
signal tile_merged(value: int, row: int, col: int)
signal tile_created(value: int, row: int, col: int)

enum Direction { UP, DOWN, LEFT, RIGHT }

const GRID_SIZE := 4
const WIN_VALUE := 2048

var grid: Array = []  # 2D array [row][col]
var score: int = 0 : set = _set_score
var best_score: int = 0
var win_target := WIN_VALUE
var game_active: bool = false

# Swipe tracking
var _swipe_start_pos: Vector2 = Vector2.ZERO
var _swipe_started: bool = false
var _swipe_min_distance: float = 30.0

func _ready() -> void:
	_initialize_grid()
	_load_best_score()
	start_new_game()

func _initialize_grid() -> void:
	grid.clear()
	for r in range(GRID_SIZE):
		grid.append([])
		for c in range(GRID_SIZE):
			grid[r].append(0)

func start_new_game() -> void:
	_initialize_grid()
	score = 0
	game_active = true
	win_target = WIN_VALUE
	add_random_tile()
	add_random_tile()
	emit_signal("board_updated")

func _set_score(val: int) -> void:
	score = val
	emit_signal("score_changed", score)
	if score > best_score:
		best_score = score
		_save_best_score()

func add_random_tile() -> void:
	var empty_cells := []
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if grid[r][c] == 0:
				empty_cells.append(Vector2i(r, c))
	
	if empty_cells.is_empty():
		return
	
	var cell = empty_cells[randi() % empty_cells.size()]
	var val = spawn_cell_value()
	grid[cell.x][cell.y] = val
	emit_signal("tile_created", val, cell.x, cell.y)

static func spawn_cell_value() -> int:
	return 2 if randf() < 0.9 else 4

func move(direction: String) -> bool:
	if not game_active:
		return false
	
	var dir: Direction
	match direction:
		"up":
			dir = Direction.UP
		"down":
			dir = Direction.DOWN
		"left":
			dir = Direction.LEFT
		"right":
			dir = Direction.RIGHT
		_:
			return false
	
	var moved = false
	var score_gained := 0
	
	match dir:
		Direction.UP:
			for c in range(GRID_SIZE):
				var result = _slide_and_merge_column(c, true)
				if result[0]:
					moved = true
					score_gained += result[1]
		
		Direction.DOWN:
			for c in range(GRID_SIZE):
				var result = _slide_and_merge_column(c, false)
				if result[0]:
					moved = true
					score_gained += result[1]
		
		Direction.LEFT:
			for r in range(GRID_SIZE):
				var result = _slide_and_merge_row(r, true)
				if result[0]:
					moved = true
					score_gained += result[1]
		
		Direction.RIGHT:
			for r in range(GRID_SIZE):
				var result = _slide_and_merge_row(r, false)
				if result[0]:
					moved = true
					score_gained += result[1]
	
	if moved:
		score += score_gained
		add_random_tile()
		emit_signal("board_updated")
		
		# Check win
		if _check_win():
			game_active = false
			emit_signal("game_over", score, get_highest_tile())
		
		# Check game over
		if game_active and is_game_over():
			game_active = false
			emit_signal("game_over", score, get_highest_tile())
	
	return moved

func _slide_and_merge_column(col: int, upward: bool) -> Array:
	var moved = false
	var score_gained = 0
	
	# Extract column values
	var values := []
	for r in range(GRID_SIZE):
		values.append(grid[r][col])
	
	# Slide and merge
	var result = _slide_and_merge_array(values, upward)
	
	# Write back
	for r in range(GRID_SIZE):
		if upward:
			grid[r][col] = result[0][r]
		else:
			grid[r][col] = result[0][r]
	
	moved = result[1]
	score_gained = result[2]
	
	return [moved, score_gained]

func _slide_and_merge_row(row: int, leftward: bool) -> Array:
	var moved = false
	var score_gained = 0
	
	# Extract row values
	var values := []
	for c in range(GRID_SIZE):
		values.append(grid[row][c])
	
	# Slide and merge
	var result = _slide_and_merge_array(values, leftward)
	
	# Write back
	for c in range(GRID_SIZE):
		if leftward:
			grid[row][c] = result[0][c]
		else:
			grid[row][c] = result[0][c]
	
	moved = result[1]
	score_gained = result[2]
	
	return [moved, score_gained]

func _slide_and_merge_array(arr: Array, forward: bool) -> Array:
	var moved = false
	var score_gained = 0
	
	# Extract non-zero values (always in natural order 0,1,2,3)
	var tiles := []
	for i in range(GRID_SIZE):
		if arr[i] != 0:
			tiles.append(arr[i])
	
	# Merge adjacent equal values (left to right)
	var merged_tiles := []
	var i := 0
	while i < tiles.size():
		if i + 1 < tiles.size() and tiles[i] == tiles[i + 1]:
			var merged_val = tiles[i] * 2
			merged_tiles.append(merged_val)
			score_gained += merged_val
			i += 2
		else:
			merged_tiles.append(tiles[i])
			i += 1
	
	# Pad with zeros on the appropriate side
	var result_arr := []
	var zero_count = GRID_SIZE - merged_tiles.size()
	
	for j in range(GRID_SIZE):
		if forward:
			# Left: tiles packed to the left
			result_arr.append(merged_tiles[j] if j < merged_tiles.size() else 0)
		else:
			# Right: tiles packed to the right
			result_arr.append(0 if j < zero_count else merged_tiles[j - zero_count])
	
	# Check if anything moved
	for j in range(GRID_SIZE):
		if arr[j] != result_arr[j]:
			moved = true
			break
	
	return [result_arr, moved, score_gained]

func is_game_over() -> bool:
	# Check for empty cells
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if grid[r][c] == 0:
				return false
	
	# Check for possible merges horizontally
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE - 1):
			if grid[r][c] == grid[r][c + 1]:
				return false
	
	# Check for possible merges vertically
	for r in range(GRID_SIZE - 1):
		for c in range(GRID_SIZE):
			if grid[r][c] == grid[r + 1][c]:
				return false
	
	return true

func _check_win() -> bool:
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if grid[r][c] >= win_target:
				return true
	return false

func get_highest_tile() -> int:
	var highest = 0
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if grid[r][c] > highest:
				highest = grid[r][c]
	return highest

func get_empty_cell_count() -> int:
	var count = 0
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if grid[r][c] == 0:
				count += 1
	return count

# --- Swipe Detection via _input ---

func _input(event: InputEvent) -> void:
	if not game_active:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start_pos = event.position
			_swipe_started = true
		else:
			if _swipe_started:
				_handle_swipe_end(event.position)
				_swipe_started = false
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_swipe_start_pos = event.position
			_swipe_started = true
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _swipe_started:
				_handle_swipe_end(event.position)
				_swipe_started = false

func _handle_swipe_end(end_pos: Vector2) -> void:
	var diff = end_pos - _swipe_start_pos
	var len_sq = diff.length_squared()
	
	if len_sq < _swipe_min_distance * _swipe_min_distance:
		return
	
	if abs(diff.x) > abs(diff.y):
		if diff.x > 0:
			move("right")
		else:
			move("left")
	else:
		if diff.y > 0:
			move("down")
		else:
			move("up")

# --- Persistence ---
const SAVE_FILE := "user://2048_best.save"

func _save_best_score() -> void:
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(best_score)

func _load_best_score() -> void:
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			best_score = file.get_var() as int
			if best_score == null:
				best_score = 0
