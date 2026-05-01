#!/usr/bin/env -S godot4 --headless -s
extends SceneTree

# Simple test runner for GameManager unit tests
# Run with: godot4 --headless -s test/run_tests.gd

func _init():
	print("=== 2048 Game Manager Tests ===\n")
	
	var script = load("res://scripts/game_manager.gd")
	
	var tests_passed = 0
	var tests_failed = 0
	var test_methods = [
		"test_new_game_creates_two_tiles",
		"test_new_game_tiles_are_2_or_4",
		"test_spawn_cell_value",
		"test_move_left_basic",
		"test_move_left_merges",
		"test_move_right_merges",
		"test_move_up_merges",
		"test_move_down_merges",
		"test_no_move_possible",
		"test_move_still_possible",
		"test_merge_still_possible",
		"test_score_increases_on_merge",
		"test_2048_win_detection",
		"test_no_false_win",
		"test_get_highest_tile",
		"test_get_empty_cell_count",
		"test_double_merge_correct",
		"test_add_random_tile",
		"test_game_over_after_full_board",
		"test_no_move_on_empty_board"
	]
	
	for method_name in test_methods:
		var gm = script.new()
		gm._initialize_grid()
		root.add_child(gm)
		
		if _run_test(gm, method_name):
			tests_passed += 1
		else:
			tests_failed += 1
		
		root.remove_child(gm)
		gm.queue_free()
	
	print("\n=== Results: ", tests_passed, " passed, ", tests_failed, " failed ===")
	quit(tests_failed)

func _run_test(gm, test_name: String) -> bool:
	var result = _execute_test(gm, test_name)
	if result[0]:
		print("  PASS: ", test_name)
		return true
	else:
		print("  FAIL: ", test_name, " - ", result[1])
		return false

func _execute_test(gm, test_name: String) -> Array:
	match test_name:
		"test_new_game_creates_two_tiles": return _test_new_game_creates_two_tiles(gm)
		"test_new_game_tiles_are_2_or_4": return _test_new_game_tiles_are_2_or_4(gm)
		"test_spawn_cell_value": return _test_spawn_cell_value(gm)
		"test_move_left_basic": return _test_move_left_basic(gm)
		"test_move_left_merges": return _test_move_left_merges(gm)
		"test_move_right_merges": return _test_move_right_merges(gm)
		"test_move_up_merges": return _test_move_up_merges(gm)
		"test_move_down_merges": return _test_move_down_merges(gm)
		"test_no_move_possible": return _test_no_move_possible(gm)
		"test_move_still_possible": return _test_move_still_possible(gm)
		"test_merge_still_possible": return _test_merge_still_possible(gm)
		"test_score_increases_on_merge": return _test_score_increases_on_merge(gm)
		"test_2048_win_detection": return _test_2048_win_detection(gm)
		"test_no_false_win": return _test_no_false_win(gm)
		"test_get_highest_tile": return _test_get_highest_tile(gm)
		"test_get_empty_cell_count": return _test_get_empty_cell_count(gm)
		"test_double_merge_correct": return _test_double_merge_correct(gm)
		"test_add_random_tile": return _test_add_random_tile(gm)
		"test_game_over_after_full_board": return _test_game_over_after_full_board(gm)
		"test_no_move_on_empty_board": return _test_no_move_on_empty_board(gm)
		_: return [false, "Unknown test: " + test_name]

# ----- Assertion helpers -----
func _assert_eq(val, expected, msg: String) -> Array:
	return [true, ""] if val == expected else [false, msg + " - expected " + str(expected) + ", got " + str(val)]

func _assert_true(val, msg: String) -> Array:
	return [true, ""] if val else [false, msg]

func _assert_false(val, msg: String) -> Array:
	return [true, ""] if not val else [false, msg]

func _assert_gt(val, threshold, msg: String) -> Array:
	return [true, ""] if val > threshold else [false, msg + " - " + str(val) + " not > " + str(threshold)]

# ----- Individual Tests -----
func _test_new_game_creates_two_tiles(gm) -> Array:
	gm.start_new_game()
	var tile_count = 0
	for r in range(4):
		for c in range(4):
			if gm.grid[r][c] != 0:
				tile_count += 1
	return _assert_eq(tile_count, 2, "New game should have exactly 2 tiles")

func _test_new_game_tiles_are_2_or_4(gm) -> Array:
	gm.start_new_game()
	for r in range(4):
		for c in range(4):
			var val = gm.grid[r][c]
			if val != 0 and val != 2 and val != 4:
				return [false, "Tile value " + str(val) + " is not 2 or 4"]
	return [true, ""]

func _test_spawn_cell_value(gm) -> Array:
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
			return [false, "spawn_cell_value returned " + str(val)]
	var r1 = _assert_gt(two_count, 800, "2 should appear ~90%")
	if not r1[0]: return r1
	return _assert_gt(four_count, 50, "4 should appear ~10%")

func _test_move_left_basic(gm) -> Array:
	gm.start_new_game()
	gm.grid = [[2, 0, 4, 0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
	var moved = gm.move("left")
	var r1 = _assert_true(moved, "Move should report board changed")
	if not r1[0]: return r1
	var r2 = _assert_eq(gm.grid[0][0], 2, "First cell should be 2")
	if not r2[0]: return r2
	return _assert_eq(gm.grid[0][1], 4, "Second cell should be 4")

func _test_move_left_merges(gm) -> Array:
	gm.start_new_game()
	gm.grid = [[2, 2, 4, 8], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
	var moved = gm.move("left")
	var r1 = _assert_true(moved, "Move should report board changed")
	if not r1[0]: return r1
	var r2 = _assert_eq(gm.grid[0][0], 4, "First cell should be 4 (merged 2+2)")
	if not r2[0]: return r2
	return _assert_eq(gm.grid[0][1], 4, "Second cell should be 4")

func _test_move_right_merges(gm) -> Array:
	gm.start_new_game()
	gm.grid = [[2, 2, 4, 4], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
	var moved = gm.move("right")
	var r1 = _assert_true(moved, "Move should report board changed")
	if not r1[0]: return r1
	var r2 = _assert_eq(gm.grid[0][2], 4, "Third cell should be 4 (2+2 merged)")
	if not r2[0]: return r2
	return _assert_eq(gm.grid[0][3], 8, "Fourth cell should be 8 (4+4 merged)")

func _test_move_up_merges(gm) -> Array:
	gm.start_new_game()
	gm.grid = [[2,0,0,0], [2,0,0,0], [4,0,0,0], [8,0,0,0]]
	var moved = gm.move("up")
	var r1 = _assert_true(moved, "Move should report board changed")
	if not r1[0]: return r1
	return _assert_eq(gm.grid[0][0], 4, "Top cell should be 4 (2+2)")

func _test_move_down_merges(gm) -> Array:
	gm.start_new_game()
	gm.grid = [[0,2,0,0], [0,2,0,0], [0,4,0,0], [0,4,0,0]]
	var moved = gm.move("down")
	var r1 = _assert_true(moved, "Move should report board changed")
	if not r1[0]: return r1
	return _assert_eq(gm.grid[3][1], 8, "Bottom cell should be 8 (4+4)")

func _test_no_move_possible(gm) -> Array:
	gm.grid = [[2,4,8,16], [16,8,4,2], [2,4,8,16], [16,8,4,2]]
	return _assert_true(gm.is_game_over(), "No moves possible grid should be game over")

func _test_move_still_possible(gm) -> Array:
	gm.grid = [[2,4,8,16], [16,8,4,2], [2,4,8,16], [16,8,4,0]]
	return _assert_false(gm.is_game_over(), "Grid with empty cell should not be game over")

func _test_merge_still_possible(gm) -> Array:
	gm.grid = [[2,4,8,16], [16,8,4,2], [2,4,8,2], [16,8,4,2]]
	return _assert_false(gm.is_game_over(), "Grid with adjacent equal values should not be game over")

func _test_score_increases_on_merge(gm) -> Array:
	gm.start_new_game()
	var initial_score = gm.score
	gm.grid = [[2,2,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
	gm.move("left")
	return _assert_eq(gm.score, initial_score + 4, "Score should increase by 4")

func _test_2048_win_detection(gm) -> Array:
	gm.grid[0][0] = 2048
	return _assert_true(gm._check_win(), "Should detect 2048 tile as win")

func _test_no_false_win(gm) -> Array:
	gm.grid[0][0] = 1024
	return _assert_false(gm._check_win(), "1024 should not trigger win")

func _test_get_highest_tile(gm) -> Array:
	gm.grid[0][0] = 2
	gm.grid[1][1] = 64
	gm.grid[2][2] = 8
	return _assert_eq(gm.get_highest_tile(), 64, "Should return 64")

func _test_get_empty_cell_count(gm) -> Array:
	gm._initialize_grid()
	var r1 = _assert_eq(gm.get_empty_cell_count(), 16, "Empty grid should have 16")
	if not r1[0]: return r1
	gm.grid[0][0] = 2
	return _assert_eq(gm.get_empty_cell_count(), 15, "1 tile = 15 empty")

func _test_double_merge_correct(gm) -> Array:
	gm.start_new_game()
	gm.grid = [[4,4,8,8], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
	var moved = gm.move("left")
	var r1 = _assert_true(moved, "Move should report board changed")
	if not r1[0]: return r1
	var r2 = _assert_eq(gm.grid[0][0], 8, "4+4 -> 8")
	if not r2[0]: return r2
	var r3 = _assert_eq(gm.grid[0][1], 16, "8+8 -> 16")
	if not r3[0]: return r3
	return _assert_eq(gm.grid[0][2], 0, "3rd empty")

func _test_add_random_tile(gm) -> Array:
	gm._initialize_grid()
	gm.add_random_tile()
	return _assert_eq(gm.get_empty_cell_count(), 15, "One random tile fills one cell")

func _test_game_over_after_full_board(gm) -> Array:
	gm.grid = [[2,4,8,2], [4,8,2,4], [8,2,4,8], [2,4,8,2]]
	return _assert_true(gm.is_game_over(), "Full board no merges = game over")

func _test_no_move_on_empty_board(gm) -> Array:
	var moved = gm.move("left")
	return _assert_false(moved, "Moving on empty board should not change")
