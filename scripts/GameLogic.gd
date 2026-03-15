extends Node

## GameLogic.gd — Pure game logic. No nodes, no visuals. Fully testable headlessly.
## All functions are static so they can be called without an instance.
##
## Grid convention (matches TileLayout.gd):
##   - A tile at Vector3i(x, y, z).
##   - After 90 CW visual rotation: grid-Y maps to screen-X, grid-X maps to screen-Y.
##   - "Visual left/right" neighbours are at y-1 and y+1 in grid space.
##   - "Directly above" means the same (x,y) on layer z+1 (no staggering).


## is_tile_free
## Returns true if the tile at `pos` can be selected.
## Rule 1 - TOP CLEAR: No tile at the exact same (x,y) on layer z+1.
## Rule 2 - SIDE CLEAR: At least one of y-1 or y+1 at same (x,z) is empty.
static func is_tile_free(pos: Vector3i, grid: Dictionary) -> bool:
	var x := pos.x
	var y := pos.y
	var z := pos.z

	# Rule 1: Top clear — only same (x,y) position at z+1 physically covers this tile.
	# (No layer staggering in our layout, so dx offsets are NOT needed.)
	if grid.has(Vector3i(x, y, z + 1)):
		return false

	# Rule 2: Side clear — after 90 CW rotation, visual sides are y-1 and y+1.
	var left_blocked  := grid.has(Vector3i(x, y - 1, z))
	var right_blocked := grid.has(Vector3i(x, y + 1, z))

	return (not left_blocked) or (not right_blocked)


## find_matches
## Scans all free tiles and returns every valid matching pair.
## Returns: Array of [Vector3i_a, Vector3i_b] pairs.
static func find_matches(grid: Dictionary, tile_types: Dictionary) -> Array:
	var free_tiles: Array = []
	for pos in grid.keys():
		if is_tile_free(pos, grid):
			free_tiles.append(pos)

	var groups: Dictionary = {}
	for pos in free_tiles:
		var t: int = tile_types.get(pos, -1)
		if t == -1:
			continue
		var key: String = TileTypes.match_key(t)
		if not groups.has(key):
			groups[key] = []
		groups[key].append(pos)

	var pairs: Array = []
	for key in groups:
		var group: Array = groups[key]
		for i in range(group.size()):
			for j in range(i + 1, group.size()):
				pairs.append([group[i], group[j]])

	return pairs


## check_victory
## Returns "WIN", "FAIL", or "CONTINUE".
static func check_victory(grid: Dictionary, tile_types: Dictionary) -> String:
	if grid.is_empty():
		return "WIN"
	if find_matches(grid, tile_types).is_empty():
		return "FAIL"
	return "CONTINUE"


## generate_solvable_deal
## Guarantees the layout is solvable by building it in REVERSE:
##   1. Start with all positions "occupied" in a temp grid.
##   2. Repeatedly find free tiles, pick 2 at random, record as a removal pair.
##   3. Remove both from the temp grid and repeat until empty.
##   4. Assign tile types to pairs from a shuffled pool.
## Because we built a complete valid removal sequence, the player can always
## follow it (or any equivalent) to clear the board.
static func generate_solvable_deal(positions: Array, tile_types_out: Dictionary,
		max_tries: int = 200) -> bool:
	assert(positions.size() % 2 == 0, "Position count must be even for pairing.")

	for _attempt in range(max_tries):
		var remaining: Array = positions.duplicate()
		remaining.shuffle()
		var solution_pairs: Array = []
		var stuck := false

		while remaining.size() >= 2:
			var temp_grid: Dictionary = {}
			for p: Vector3i in remaining:
				temp_grid[p] = true

			var free: Array = []
			for p: Vector3i in remaining:
				if is_tile_free(p, temp_grid):
					free.append(p)

			if free.size() < 2:
				stuck = true
				break

			free.shuffle()
			var a: Vector3i = free[0]
			var b: Vector3i = free[1]
			solution_pairs.append([a, b])
			remaining.erase(a)
			remaining.erase(b)

		if stuck:
			continue

		var pool: Array = TileTypes.build_tile_pool()
		pool.shuffle()
		tile_types_out.clear()
		for i in range(solution_pairs.size()):
			var t: int = pool[i]
			tile_types_out[solution_pairs[i][0]] = t
			tile_types_out[solution_pairs[i][1]] = t
		return true

	push_error("generate_solvable_deal: could not find solvable layout in %d tries." % max_tries)
	return false


## shuffle_board
## Uses generate_solvable_deal on remaining positions so the shuffled
## state is also guaranteed solvable.
static func shuffle_board(grid: Dictionary, tile_types: Dictionary,
		max_tries: int = 200) -> bool:
	var positions: Array = grid.keys()
	var new_types: Dictionary = {}
	if generate_solvable_deal(positions, new_types, max_tries):
		for pos in positions:
			tile_types[pos] = new_types[pos]
		return true
	return false
