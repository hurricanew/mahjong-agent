extends Node

## GameLogic.gd — Pure game logic. No nodes, no visuals. Fully testable headlessly.
## All functions are static so they can be called without an instance.
##
## Grid convention (matches TileLayout.gd):
##   - Tile footprint in grid space: 2 columns wide × 1 row tall.
##   - A tile at Vector3i(x, y, z) occupies columns [x, x+1] and row [y].
##   - Adjacency on the LEFT means a tile at (x-2, y, z); RIGHT means (x+2, y, z).
##   - Above means z+1; a tile at (x', y', z+1) blocks if footprints overlap.


## ─────────────────────────────────────────────────────
##  is_tile_free
## ─────────────────────────────────────────────────────
## Returns true if the tile at `pos` can be selected.
##
## Rule 1 – TOP CLEAR:  No tile on layer z+1 whose 2-wide footprint overlaps.
## Rule 2 – SIDE CLEAR: At the same z, at least one of LEFT or RIGHT is open.
##
## `grid` is a Dictionary of { Vector3i -> anything (Tile node or true) }.
static func is_tile_free(pos: Vector3i, grid: Dictionary) -> bool:
	var x := pos.x
	var y := pos.y
	var z := pos.z

	# ── Rule 1: Top clear ────────────────────────────────────────────────
	# A tile at (ax, ay, z+1) blocks us if its 2-wide footprint overlaps ours.
	# Our footprint occupies columns x and x+1 at row y.
	# Their footprint occupies columns ax and ax+1 at row ay.
	# Overlap condition: ay == y AND ax ranges from x-1 to x+1.
	for dx in [-2, 0, 2]:
		var above := Vector3i(x + dx, y, z + 1)
		if grid.has(above):
			return false
	# Also check offset tiles (tiles placed 1 col to the side)
	for neighbor_x in [x - 1, x + 1]:
		var above := Vector3i(neighbor_x, y, z + 1)
		if grid.has(above):
			return false

	# ── Rule 2: Side clear ───────────────────────────────────────────────
	# LEFT blocked if a tile occupies (x-2, y, z)
	# RIGHT blocked if a tile occupies (x+2, y, z)
	var left_blocked  := grid.has(Vector3i(x - 2, y, z))
	var right_blocked := grid.has(Vector3i(x + 2, y, z))

	return (not left_blocked) or (not right_blocked)


## ─────────────────────────────────────────────────────
##  find_matches
## ─────────────────────────────────────────────────────
## Scans all free tiles and returns every valid matching pair.
## Returns: Array of [Vector3i_a, Vector3i_b] pairs.
##
## `grid`       : Dictionary { Vector3i -> tile_type (int) }
## `tile_types` : Dictionary { Vector3i -> TileTypes.Type } — the type of each tile
static func find_matches(grid: Dictionary, tile_types: Dictionary) -> Array:
	# Step 1: collect all free tile positions
	var free_tiles: Array = []
	for pos in grid.keys():
		if is_tile_free(pos, grid):
			free_tiles.append(pos)

	# Step 2: group by match_key
	var groups: Dictionary = {}   # match_key (String) -> Array[Vector3i]
	for pos in free_tiles:
		var t: int = tile_types.get(pos, -1)
		if t == -1:
			continue
		var key: String = TileTypes.match_key(t)
		if not groups.has(key):
			groups[key] = []
		groups[key].append(pos)

	# Step 3: emit pairs from groups of size ≥ 2
	var pairs: Array = []
	for key in groups:
		var group: Array = groups[key]
		# Enumerate all (i, j) pairs within the group
		for i in range(group.size()):
			for j in range(i + 1, group.size()):
				pairs.append([group[i], group[j]])

	return pairs


## ─────────────────────────────────────────────────────
##  check_victory
## ─────────────────────────────────────────────────────
## Returns "WIN", "FAIL", or "CONTINUE".
static func check_victory(grid: Dictionary, tile_types: Dictionary) -> String:
	if grid.is_empty():
		return "WIN"
	if find_matches(grid, tile_types).is_empty():
		return "FAIL"
	return "CONTINUE"


## ─────────────────────────────────────────────────────
##  shuffle_board
## ─────────────────────────────────────────────────────
## Redistributes tile types among remaining positions without changing positions.
## Modifies `tile_types` in place. Returns true if a valid shuffle was found.
##
## Attempts up to `max_tries` times to find a deal that has at least one match.
static func shuffle_board(grid: Dictionary, tile_types: Dictionary, max_tries: int = 10) -> bool:
	var positions: Array = grid.keys()
	var types: Array = []
	for pos in positions:
		types.append(tile_types[pos])

	for _attempt in range(max_tries):
		types.shuffle()
		# Re-assign shuffled types
		for i in range(positions.size()):
			tile_types[positions[i]] = types[i]
		# Check if there are now valid matches
		if not find_matches(grid, tile_types).is_empty():
			return true

	return false  # Could not find a valid shuffle — very unlikely
