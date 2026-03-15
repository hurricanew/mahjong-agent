extends Node

## TileLayout.gd — 72-tile "Mini Turtle" formation.
## Layer 0: 44 tiles | Layer 1: 16 | Layer 2: 8 | Layer 3: 4 | Total: 72
##
## Grid convention: (col, row, z). Columns are even integers (tile footprint = 2 wide).
## Y axis: 0..7 (8 rows) → maps to SCREEN X after 90° CW rotation.
## X axis: -2..12 (8 tile positions) → maps to SCREEN Y after 90° CW rotation.

const POSITIONS: Array = [

	# ── Layer 0 (z=0) — 44 tiles ──────────────────────────────────────────

	# Row 0 — 2 cap tiles
	Vector3i(4, 0, 0), Vector3i(8, 0, 0),

	# Row 1 — 6 tiles
	Vector3i(0, 1, 0), Vector3i(2, 1, 0), Vector3i(4, 1, 0),
	Vector3i(6, 1, 0), Vector3i(8, 1, 0), Vector3i(10, 1, 0),

	# Row 2 — 6 tiles
	Vector3i(0, 2, 0), Vector3i(2, 2, 0), Vector3i(4, 2, 0),
	Vector3i(6, 2, 0), Vector3i(8, 2, 0), Vector3i(10, 2, 0),

	# Row 3 — 8 tiles (with left and right wings)
	Vector3i(-2, 3, 0), Vector3i(0, 3, 0), Vector3i(2, 3, 0), Vector3i(4, 3, 0),
	Vector3i(6, 3, 0),  Vector3i(8, 3, 0), Vector3i(10, 3, 0), Vector3i(12, 3, 0),

	# Row 4 — 8 tiles (with left and right wings)
	Vector3i(-2, 4, 0), Vector3i(0, 4, 0), Vector3i(2, 4, 0), Vector3i(4, 4, 0),
	Vector3i(6, 4, 0),  Vector3i(8, 4, 0), Vector3i(10, 4, 0), Vector3i(12, 4, 0),

	# Row 5 — 6 tiles
	Vector3i(0, 5, 0), Vector3i(2, 5, 0), Vector3i(4, 5, 0),
	Vector3i(6, 5, 0), Vector3i(8, 5, 0), Vector3i(10, 5, 0),

	# Row 6 — 6 tiles
	Vector3i(0, 6, 0), Vector3i(2, 6, 0), Vector3i(4, 6, 0),
	Vector3i(6, 6, 0), Vector3i(8, 6, 0), Vector3i(10, 6, 0),

	# Row 7 — 2 cap tiles
	Vector3i(4, 7, 0), Vector3i(8, 7, 0),

	# ── Layer 1 (z=1) — 16 tiles ──────────────────────────────────────────

	Vector3i(2, 2, 1), Vector3i(4, 2, 1), Vector3i(6, 2, 1), Vector3i(8, 2, 1),
	Vector3i(2, 3, 1), Vector3i(4, 3, 1), Vector3i(6, 3, 1), Vector3i(8, 3, 1),
	Vector3i(2, 4, 1), Vector3i(4, 4, 1), Vector3i(6, 4, 1), Vector3i(8, 4, 1),
	Vector3i(2, 5, 1), Vector3i(4, 5, 1), Vector3i(6, 5, 1), Vector3i(8, 5, 1),

	# ── Layer 2 (z=2) — 8 tiles ───────────────────────────────────────────

	Vector3i(4, 2, 2), Vector3i(6, 2, 2),
	Vector3i(4, 3, 2), Vector3i(6, 3, 2),
	Vector3i(4, 4, 2), Vector3i(6, 4, 2),
	Vector3i(4, 5, 2), Vector3i(6, 5, 2),

	# ── Layer 3 (z=3) — 4 tiles (apex) ───────────────────────────────────

	Vector3i(4, 3, 3), Vector3i(6, 3, 3),
	Vector3i(4, 4, 3), Vector3i(6, 4, 3),
]


static func get_positions() -> Array:
	var positions: Array = POSITIONS.duplicate()
	assert(positions.size() == 72,
		"Mini Turtle layout must have exactly 72 positions. Got: %d" % positions.size())
	return positions
