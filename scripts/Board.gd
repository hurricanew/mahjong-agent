extends Node2D

## Board.gd — Spawns all 144 tiles, manages the grid dictionary, and coordinates game flow.

# ── Constants ──────────────────────────────────────────
const TILE_SCENE   := preload("res://scenes/Tile.tscn")
const TileScript   := preload("res://scripts/Tile.gd")  # needed to access VisualState enum

# Tile pixel size — 72-tile Mini Turtle on 720×1280 portrait (90° CW rotated).
#
#   Grid Y: 0..7 (8 rows)  → screen X: TILE_H = 720 ÷ 8 = 90px
#   Grid X: -2..12 (8 positions) → screen Y: TILE_W = 1088 ÷ 8 = 136px
#
# Tile visual: (TILE_H-2) wide × (TILE_W-2) tall = 88 × 134 px (portrait tile).
const TILE_W    := 136.0
const TILE_H    := 90.0
const STACK_OFF := Vector2(-10.0, 8.0)  # per Z layer (depth illusion)

# ── State ──────────────────────────────────────────────
## grid: Vector3i → Tile node (sparse; removed on match)
var grid: Dictionary = {}
## tile_types: Vector3i → TileTypes.Type int
var tile_types: Dictionary = {}

signal match_made(pair_a: Vector3i, pair_b: Vector3i)
signal board_state_changed(status: String)   # "WIN", "FAIL", "CONTINUE"


func _ready() -> void:
	_spawn_tiles()


# ─────────────────────────────────────────────────────
#  Spawn
# ─────────────────────────────────────────────────────
func _spawn_tiles() -> void:
	var positions: Array = TileLayout.get_positions()

	# Build and shuffle a 144-tile type pool
	var pool: Array = TileTypes.build_tile_pool()
	pool.shuffle()

	# Instantiate one Tile per position
	for i in range(positions.size()):
		var gpos: Vector3i = positions[i]
		var t_type: int    = pool[i]

		var tile: Node2D = TILE_SCENE.instantiate()
		add_child(tile)

		# Store in grid
		grid[gpos]       = tile
		tile_types[gpos] = t_type

		# Wire up position, z-index, and data
		tile.position = _grid_to_screen(gpos)
		tile.z_index  = _z_index_for(gpos)
		tile.setup(t_type, gpos)

		# Connect click signal
		tile.tile_clicked.connect(_on_tile_clicked)

	# Initial selectability pass
	_refresh_all_selectability()


# ─────────────────────────────────────────────────────
#  Coordinate mapping
# ─────────────────────────────────────────────────────
func _grid_to_screen(gpos: Vector3i) -> Vector2:
	# 90° CW rotation. Grid Y (0..7) → screen X; Grid X (-2..12) → screen Y.
	var sx: float = (7.0 - float(gpos.y)) * TILE_H
	var sy: float = float(gpos.x + 2) * (TILE_W * 0.5)
	return Vector2(sx, sy) + STACK_OFF * float(gpos.z)


func _z_index_for(gpos: Vector3i) -> int:
	# After rotation: higher gpos.x is further DOWN screen ("in front"); z on top.
	return gpos.z * 1000 + gpos.x * 10 + gpos.y


# ─────────────────────────────────────────────────────
#  Selectability
# ─────────────────────────────────────────────────────
func _refresh_all_selectability() -> void:
	for gpos in grid.keys():
		var tile: Node2D = grid[gpos]
		var free := GameLogic.is_tile_free(gpos, grid)
		tile.is_selectable = free
		tile.set_visual_state(
			TileScript.VisualState.IDLE if free else TileScript.VisualState.NOT_FREE
		)


# ─────────────────────────────────────────────────────
#  Selection state machine
# ─────────────────────────────────────────────────────
var _selected_pos: Vector3i = Vector3i(-999, -999, -999)
var _has_selection: bool    = false


func _on_tile_clicked(tile: Node2D) -> void:
	var gpos: Vector3i = tile.grid_pos

	# Ignore blocked tiles
	if not tile.is_selectable:
		return

	if not _has_selection:
		# First selection
		_select(gpos)
	else:
		if gpos == _selected_pos:
			# Deselect same tile
			_deselect()
		elif TileTypes.can_match(tile_types[_selected_pos], tile_types[gpos]):
			# Match!
			_do_match(_selected_pos, gpos)
		else:
			# Swap selection to new tile
			_deselect()
			_select(gpos)


func _select(gpos: Vector3i) -> void:
	_selected_pos = gpos
	_has_selection = true
	grid[gpos].set_visual_state(TileScript.VisualState.SELECTED)


func _deselect() -> void:
	if _has_selection and grid.has(_selected_pos):
		var was_free := GameLogic.is_tile_free(_selected_pos, grid)
		grid[_selected_pos].set_visual_state(
			TileScript.VisualState.IDLE if was_free else TileScript.VisualState.NOT_FREE
		)
	_has_selection = false


func _do_match(pos_a: Vector3i, pos_b: Vector3i) -> void:
	_has_selection = false

	# Play match animation on both tiles
	grid[pos_a].set_visual_state(TileScript.VisualState.MATCHED)
	grid[pos_b].set_visual_state(TileScript.VisualState.MATCHED)

	# Remove from grid immediately (so future is_free checks are correct)
	grid.erase(pos_a)
	grid.erase(pos_b)
	tile_types.erase(pos_a)
	tile_types.erase(pos_b)

	# Update score
	GameState.add_score(100)

	# Refresh all remaining tiles
	_refresh_all_selectability()

	# Check victory
	var status := GameLogic.check_victory(grid, tile_types)
	match_made.emit(pos_a, pos_b)
	board_state_changed.emit(status)


# ─────────────────────────────────────────────────────
#  Public API (called by UI buttons)
# ─────────────────────────────────────────────────────
func get_hint_pair() -> Array:
	var pairs := GameLogic.find_matches(grid, tile_types)
	if pairs.is_empty():
		return []
	return pairs[0]  # [Vector3i_a, Vector3i_b]


func highlight_pair(pair: Array) -> void:
	for gpos in pair:
		if grid.has(gpos):
			grid[gpos].set_visual_state(TileScript.VisualState.SELECTED)


func do_shuffle() -> void:
	GameLogic.shuffle_board(grid, tile_types)
	# Re-apply types to tile nodes
	for gpos in grid.keys():
		grid[gpos].setup(tile_types[gpos], gpos)
	_refresh_all_selectability()
