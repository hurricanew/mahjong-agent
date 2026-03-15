extends Node

## test_logic.gd — Headless test runner for M1.
## Set this as the Main Scene temporarily to verify core logic.
## Expected output in the Godot Output panel:
##   [TEST] is_free: PASS
##   [TEST] matches: PASS
##   [TEST] victory:WIN: PASS
##   [TEST] victory:FAIL: PASS
##   [TEST] victory:CONTINUE: PASS
##   [TEST] shuffle: PASS
##   ✅ M1 PASS — all logic tests passed!


func _ready() -> void:
	var passed := 0
	var failed := 0

	# Helper to report results
	var assert_true := func(condition: bool, label: String) -> void:
		if condition:
			print("[TEST] %s: PASS" % label)
			passed += 1
		else:
			push_error("[TEST] %s: FAIL ❌" % label)
			failed += 1

	# ── Build a minimal test grid ────────────────────────────────────────
	# Lay out a tiny 3-tile scenario manually:
	#
	#  Layer 0:  [A at (0,0,0)]  [B at (2,0,0)]  [C at (4,0,0)]
	#
	# A is free (left edge, right neighbor B)  → left open
	# B is blocked (A on left, C on right)     → neither side open
	# C is free (right edge, left neighbor B)  → right open

	var grid: Dictionary = {}
	var tile_types: Dictionary = {}

	grid[Vector3i(0, 0, 0)] = true
	grid[Vector3i(2, 0, 0)] = true
	grid[Vector3i(4, 0, 0)] = true

	# All same type so they match
	tile_types[Vector3i(0, 0, 0)] = TileTypes.Type.BAMBOO_1
	tile_types[Vector3i(2, 0, 0)] = TileTypes.Type.BAMBOO_1
	tile_types[Vector3i(4, 0, 0)] = TileTypes.Type.BAMBOO_1

	# ── Test: is_tile_free ──────────────────────────────────────────────
	var a_free := GameLogic.is_tile_free(Vector3i(0, 0, 0), grid)  # leftmost → free
	var b_free := GameLogic.is_tile_free(Vector3i(2, 0, 0), grid)  # middle → blocked
	var c_free := GameLogic.is_tile_free(Vector3i(4, 0, 0), grid)  # rightmost → free
	assert_true.call(a_free and not b_free and c_free, "is_free")

	# ── Test: find_matches ─────────────────────────────────────────────
	# Only A and C are free, and both are BAMBOO_1 → should return 1 pair
	var pairs := GameLogic.find_matches(grid, tile_types)
	assert_true.call(pairs.size() == 1, "matches")

	# ── Test: check_victory WIN ────────────────────────────────────────
	var empty_grid: Dictionary = {}
	var empty_types: Dictionary = {}
	assert_true.call(GameLogic.check_victory(empty_grid, empty_types) == "WIN", "victory:WIN")

	# ── Test: check_victory FAIL ───────────────────────────────────────
	# Two tiles of different types, both free → no pairs → FAIL
	var fail_grid: Dictionary = {}
	var fail_types: Dictionary = {}
	fail_grid[Vector3i(0, 0, 0)] = true
	fail_grid[Vector3i(2, 0, 0)] = true
	fail_types[Vector3i(0, 0, 0)] = TileTypes.Type.BAMBOO_1
	fail_types[Vector3i(2, 0, 0)] = TileTypes.Type.CHAR_1
	assert_true.call(GameLogic.check_victory(fail_grid, fail_types) == "FAIL", "victory:FAIL")

	# ── Test: check_victory CONTINUE ──────────────────────────────────
	# Our original 3-tile grid has a valid pair → CONTINUE
	assert_true.call(GameLogic.check_victory(grid, tile_types) == "CONTINUE", "victory:CONTINUE")

	# ── Test: Flower wildcard matching ─────────────────────────────────
	var flower_grid: Dictionary = {}
	var flower_types: Dictionary = {}
	flower_grid[Vector3i(0, 0, 0)] = true
	flower_grid[Vector3i(2, 0, 0)] = true
	flower_types[Vector3i(0, 0, 0)] = TileTypes.Type.FLOWER_PLUM
	flower_types[Vector3i(2, 0, 0)] = TileTypes.Type.FLOWER_ORCHID
	var flower_pairs := GameLogic.find_matches(flower_grid, flower_types)
	assert_true.call(flower_pairs.size() == 1, "flower_wildcard")

	# ── Test: Season wildcard matching ─────────────────────────────────
	var season_grid: Dictionary = {}
	var season_types: Dictionary = {}
	season_grid[Vector3i(0, 0, 0)] = true
	season_grid[Vector3i(2, 0, 0)] = true
	season_types[Vector3i(0, 0, 0)] = TileTypes.Type.SEASON_SPRING
	season_types[Vector3i(2, 0, 0)] = TileTypes.Type.SEASON_AUTUMN
	var season_pairs := GameLogic.find_matches(season_grid, season_types)
	assert_true.call(season_pairs.size() == 1, "season_wildcard")

	# ── Test: Top blocking ─────────────────────────────────────────────
	# Place a tile directly above A at (0,0,1) → A should now be blocked
	var top_grid := grid.duplicate()
	top_grid[Vector3i(0, 0, 1)] = true  # sits on top of A
	var a_blocked := not GameLogic.is_tile_free(Vector3i(0, 0, 0), top_grid)
	assert_true.call(a_blocked, "top_block")

	# ── Test: TileLayout count ─────────────────────────────────────────
	var layout := TileLayout.get_positions()
	assert_true.call(layout.size() == 72, "layout_count")

	# ── Test: Tile pool count ──────────────────────────────────────────
	var pool := TileTypes.build_tile_pool()
	assert_true.call(pool.size() == 72, "pool_count")

	# ── Test: shuffle finds a valid deal ──────────────────────────────
	var sh_grid: Dictionary = grid.duplicate()
	var sh_types: Dictionary = tile_types.duplicate()
	var shuffled := GameLogic.shuffle_board(sh_grid, sh_types)
	assert_true.call(shuffled, "shuffle")

	# ── Summary ────────────────────────────────────────────────────────
	print("─────────────────────────────────")
	if failed == 0:
		print("✅ M1 PASS — all %d tests passed!" % passed)
	else:
		push_error("❌ M1 FAIL — %d/%d tests failed." % [failed, passed + failed])

	# Auto-quit so you can run it from the CLI too
	# get_tree().quit()  # Uncomment if running headlessly via CLI
