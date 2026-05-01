# Unit tests for GameManager
# Run with GUT (Godot Unit Test) addon or: godot4 --headless -s test/run_tests.gd

extends GutTest

func before_each():
	var script = load("res://scripts/game_manager.gd")
	var gm = script.new()
	gm._initialize_grid()
	add_child_autoqfree(gm)
	return gm

func test_new_game_creates_two_tiles():
	var gm = before_each()
	gm.start_new_game()
	var tile_count = 0
	for r in range(4):
		for c in range(4):
			if gm.grid[r][c] != 0:
				tile_count += 1
	assert_eq(tile_count, 2, "New game should have exactly 2 tiles")

func test_new_game_tiles_are_2_or_4():
	var gm = before_each()
	gm.start_new_game()
	for r in range(4):
		for c in range(4):
			var val = gm.grid[r][c]
			if val != 0:
				assert_between(val, 2, 5, "Tiles should be 2 or 4")

func test_spawn_cell_value():
	var two_count = 0
	var four_count = 0
	var script = load("res://scripts/game_manager.gd")
	for i in range(1000):
		var val = script.spawn_cell_value()
		if val == 2:
			two_count += 1
		elif val == 4:
			four_count += 1
		else:
			fail("spawn_cell_value should return 2 or 4 - got " + str(val))
	assert_gt(two_count, 800, "2 should appear ~90% (got " + str(two_count) + ")")
	assert_gt(four_count, 50, "4 should appear ~10% (got " + str(four_count) + ")")

func test_move_left_merges():
	var gm = before_each()
	gm.start_new_game()
	gm.grid = [[2, 2, 4, 8], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
	var moved = gm.move("left")
	assert_true(moved, "Move should report that board changed")
	assert_eq(gm.grid[0][0], 4, "First cell should be 4 (merged 2+2)")
	assert_eq(gm.grid[0][1], 4, "Second cell should be 4 (unmerged)")
	assert_eq(gm.grid[0][2], 8, "Third cell should be 8")

func test_move_right_merges():
	var gm = before_each()
	gm.start_new_game()
	gm.grid = [[2, 2, 4, 4], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
	var moved = gm.move("right")
	assert_true(moved, "Move should report that board changed")
	assert_eq(gm.grid[0][2], 4, "Third cell should be 4 (2+2 merged)")
	assert_eq(gm.grid[0][3], 8, "Fourth cell should be 8 (4+4 merged)")

func test_move_up_merges():
	var gm = before_each()
	gm.start_new_game()
	gm.grid = [[2,0,0,0], [2,0,0,0], [4,0,0,0], [8,0,0,0]]
	var moved = gm.move("up")
	assert_true(moved, "Move should report that board changed")
	assert_eq(gm.grid[0][0], 4, "Top cell should be 4 (2+2)")

func test_move_down_merges():
	var gm = before_each()
	gm.start_new_game()
	gm.grid = [[0,2,0,0], [0,2,0,0], [0,4,0,0], [0,4,0,0]]
	var moved = gm.move("down")
	assert_true(moved, "Move should report that board changed")
	assert_eq(gm.grid[3][1], 8, "Bottom cell should be 8 (4+4)")

func test_no_move_possible():
	var gm = before_each()
	gm.grid = [[2,4,8,16], [16,8,4,2], [2,4,8,16], [16,8,4,2]]
	assert_true(gm.is_game_over(), "Grid with no merges and no empty cells should be game over")

func test_move_still_possible():
	var gm = before_each()
	gm.grid = [[2,4,8,16], [16,8,4,2], [2,4,8,16], [16,8,4,0]]
	assert_false(gm.is_game_over(), "Grid with an empty cell should not be game over")

func test_merge_still_possible():
	var gm = before_each()
	gm.grid = [[2,4,8,16], [16,8,4,2], [2,4,8,2], [16,8,4,2]]
	assert_false(gm.is_game_over(), "Grid with adjacent equal values should not be game over")

func test_score_increases_on_merge():
	var gm = before_each()
	gm.start_new_game()
	var initial_score = gm.score
	gm.grid = [[2,2,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
	gm.move("left")
	assert_eq(gm.score, initial_score + 4, "Score should increase by merged value (4)")

func test_2048_win_detection():
	var gm = before_each()
	gm.grid[0][0] = 2048
	assert_true(gm._check_win(), "Should detect 2048 tile as win")

func test_no_false_win():
	var gm = before_each()
	gm.grid[0][0] = 1024
	assert_false(gm._check_win(), "1024 should not trigger win")

func test_get_highest_tile():
	var gm = before_each()
	gm.grid[0][0] = 2
	gm.grid[1][1] = 64
	gm.grid[2][2] = 8
	assert_eq(gm.get_highest_tile(), 64, "Should return 64 as highest tile")

func test_get_empty_cell_count():
	var gm = before_each()
	gm._initialize_grid()
	assert_eq(gm.get_empty_cell_count(), 16, "Empty grid should have 16 empty cells")
	gm.grid[0][0] = 2
	assert_eq(gm.get_empty_cell_count(), 15, "Grid with 1 tile should have 15 empty cells")

func test_double_merge_correct():
	var gm = before_each()
	gm.start_new_game()
	gm.grid = [[4,4,8,8], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
	var moved = gm.move("left")
	assert_true(moved)
	assert_eq(gm.grid[0][0], 8, "First pair 4+4 should merge to 8")
	assert_eq(gm.grid[0][1], 16, "Second pair 8+8 should merge to 16")
	assert_eq(gm.grid[0][2], 0, "Third cell should be empty")
	assert_eq(gm.grid[0][3], 0, "Fourth cell should be empty")

func test_add_random_tile():
	var gm = before_each()
	gm._initialize_grid()
	gm.add_random_tile()
	assert_eq(gm.get_empty_cell_count(), 15, "One random tile should reduce to 15")

func test_game_over_after_full_board():
	var gm = before_each()
	gm.grid = [[2,4,8,2], [4,8,2,4], [8,2,4,8], [2,4,8,2]]
	assert_true(gm.is_game_over(), "Full board with no adjacent equal values should be game over")
