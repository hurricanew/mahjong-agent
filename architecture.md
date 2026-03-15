# Architecture: Mahjong Wonders — Playable Prototype

> **Prototype Goal:** A fully playable Mahjong Solitaire game running in Godot 4.x (2D mode) with correct "free tile" logic, matching engine, and minimal UI — built as fast as possible.

---

## 1. Project Structure

```
MahjongMiracle/
├── project.godot
├── scenes/
│   ├── Main.tscn            # Root scene entry point
│   ├── Board.tscn           # Board container + tile spawner
│   ├── Tile.tscn            # Individual tile prefab
│   ├── UI.tscn              # HUD: top/bottom bars
│   └── GameOver.tscn        # Win / Fail overlay
├── scripts/
│   ├── Main.gd              # Scene loader, game lifecycle
│   ├── Board.gd             # Grid state, tile spawning, Z-sort
│   ├── Tile.gd              # Tile data, input, visual states
│   ├── GameLogic.gd         # is_tile_free(), match logic, shuffle
│   ├── TileLayout.gd        # Turtle layout: hardcoded (x,y,z) positions
│   ├── TileTypes.gd         # Autoload: enum + matching rules
│   └── UI.gd                # Score, level, hint, shuffle counters
├── assets/
│   ├── tiles/               # Placeholder tile sprites (generated or temp)
│   ├── bg/                  # Background image
│   └── audio/               # SFX placeholders
└── autoloads/
    └── GameState.gd         # Autoload: score, level, match_count
```

---

## 2. Data Model

### 2.1 Tile Object (`Tile.gd`)
```gdscript
var tile_type: int          # enum TileTypes (Bamboo1..9, Chars1..9, Dots1..9, Winds×4, Dragons×3, Flowers×4, Seasons×4)
var grid_pos: Vector3i      # (x, y, z) — grid coordinates
var is_selectable: bool     # updated every state change
var is_matched: bool        # true = removed from board
```

### 2.2 Grid (`Board.gd`)
```gdscript
# Sparse dictionary for O(1) lookups:
var grid: Dictionary = {}   # Vector3i -> Tile node
```

### 2.3 Global State (`GameState.gd` — Autoload)
```gdscript
var score: int = 0
var level: int = 1
var hint_uses: int = 3
var shuffle_uses: int = 3
```

---

## 3. Scene Graph

```
Main (Node2D)
└── Board (Node2D)          ← Board.gd; contains all Tile instances
    └── [Tile] × 144        ← Tile.tscn instances, Y-sorted
└── UI (CanvasLayer)
    ├── TopBar              ← Level | Score | MatchCount
    └── BottomBar           ← Shuffle (3) | Hint (3)
└── GameOver (CanvasLayer)  ← shown on win/fail
```

All Tile nodes live under `Board` with **YSort** enabled — Godot handles draw order automatically based on Y position.

---

## 4. Core Algorithms

### 4.1 `is_tile_free(tile: Tile) -> bool` (`GameLogic.gd`)
```
1. TOP CHECK — blocked if any tile at (x±0.5, y±0.5, z+1) overlaps this tile's footprint.
   Practically: check tiles at z+1 where |dx| < 1 AND |dy| < 1.
2. SIDE CHECK — at same z, check column x-1 and column x+1.
   Left  blocked: grid[Vector3i(x-1, y, z)] exists.
   Right blocked: grid[Vector3i(x+1, y, z)] exists.
   Free if left_blocked == false OR right_blocked == false.
Returns true only if BOTH conditions pass.
```

### 4.2 `find_matches() -> Array[Array]` (`GameLogic.gd`)
```
Collect all free tiles → group by match_key (tile_type, with Flower/Season wildcards).
Return pairs from groups of size ≥ 2.
```

### 4.3 `check_victory() -> String` (`GameLogic.gd`)
```
If grid.is_empty()          → "WIN"
If find_matches().is_empty() → "FAIL"
Else                         → "CONTINUE"
```

### 4.4 Shuffle (`Board.gd`)
```
1. Collect all remaining (non-matched) tile_types into a list.
2. Shuffle list (randomize()).
3. Re-assign tile_types to tiles in original grid positions.
4. Recompute is_selectable for all tiles.
5. If still no matches → re-shuffle (max 10 attempts).
```

---

## 5. Turtle Layout (`TileLayout.gd`)

The classic 144-tile "Turtle" formation is hardcoded as an array of `Vector3i` positions. This is the fastest approach for the prototype — no procedural generation needed.

```gdscript
# TileLayout.gd
const TURTLE: Array[Vector3i] = [
    # Layer 0 (z=0): ~74 tiles in rows
    Vector3i(0,0,0), Vector3i(1,0,0), ...
    # Layer 1 (z=1): ~36 tiles
    # Layer 2 (z=2): ~16 tiles
    # Layer 3 (z=3): ~4 tiles
    # Layer 4 (z=4): 1 tile (apex)
]
```

Tiles types are randomly assigned to positions ensuring:
- Exactly 4 copies of each standard type.
- Flower/Season tiles appear once each (4 Flowers + 4 Seasons = 8).
- Total = 144.

---

## 6. Rendering: Isometric 2.5D (Stacked Sprite)

Since Godot 2D is used, visual depth is simulated by:

| Layer | Effect |
|-------|--------|
| Shadow sprite (offset -y, low alpha) | Ambient occlusion feel |
| Side sprite (darker tint, offset +y) | Tile thickness illusion |
| Top face sprite | Main tile art |
| Highlight sprite | Selection glow (modulate alpha) |

**Screen Coordinate Mapping from Grid:**
```gdscript
func grid_to_screen(gp: Vector3i) -> Vector2:
    var TILE_W := 64.0
    var TILE_H := 72.0  # includes perspective skew
    var STACK_OFFSET := Vector2(-4, -8)  # per Z layer
    return Vector2(gp.x * TILE_W * 0.5, gp.y * TILE_H * 0.5) + STACK_OFFSET * gp.z
```

**Z-Index (draw order):**
```gdscript
z_index = gp.z * 100 + gp.y * 10 + gp.x
```
This ensures higher stacks and tiles further down screen are drawn on top.

---

## 7. Tile Visual States

| State | Visual |
|-------|--------|
| `IDLE` | Normal sprite |
| `SELECTED` | Glow modulate (yellow tint) |
| `NOT_FREE` | Slightly darkened (alpha 0.6) |
| `MATCHED` | Tween scale to 0 → `queue_free()` |

---

## 8. Game Loop (State Machine in `Main.gd`)

```
IDLE
  │ player clicks free tile → SELECT_FIRST
SELECT_FIRST
  │ player clicks same tile    → IDLE (deselect)
  │ player clicks another free tile:
      match?   → MATCH (remove pair, check victory)
      no match? → SELECT_FIRST (swap selection)
MATCH
  │ → check_victory()
      WIN  → show Win screen
      FAIL → show Fail screen (offer shuffle)
      CONTINUE → IDLE
```

---

## 9. UI Wiring

### Top Bar
- **Level** ← `GameState.level`
- **Score** ← `GameState.score` (+ 100 per match)
- **Match Count** ← `len(find_matches())`, updated after every match

### Bottom Bar
- **Hint** — calls `find_matches()[0]`, highlights the pair; decrements `hint_uses`
- **Shuffle** — calls shuffle; decrements `shuffle_uses`; both buttons disabled at 0

---

## 10. Prototype Build Order (Fastest Path)

| Step | Task | Output |
|------|------|--------|
| 1 | Godot project setup, folder structure | `project.godot` |
| 2 | `TileTypes.gd` enum + matching rules | Autoload |
| 3 | `TileLayout.gd` hardcoded Turtle positions | 144 Vector3i array |
| 4 | `Board.gd` + `GameLogic.gd` (grid, is_free, match) | Pure logic, testable headlessly |
| 5 | `Tile.tscn` with placeholder ColorRect sprites | Visible tiles |
| 6 | `Board.gd` spawning + screen position mapping | Tiles appear on screen |
| 7 | Click input + selection logic + match tween | Interactive game |
| 8 | `UI.tscn` top/bottom bars | Score, Hint, Shuffle |
| 9 | Win/Fail overlay | Full game loop |
| 10 | Swap ColorRect placeholders → real sprites | Polish |

> **Prototype Definition of Done:** Steps 1–9 complete. A human can start a game, match all tiles, and see a win screen.

---

## 11. Out of Scope for Prototype

- AdMob / monetization
- Real tile art (use colored `ColorRect` labels instead)
- Music / SFX (silent is fine)
- Mobile export
- Multiple levels / difficulty
- Undo button

These ship in Month 2+ per the roadmap.

---

## 12. Key Godot 4 APIs Used

| Need | API |
|------|-----|
| Tile scene instances | `PackedScene.instantiate()` |
| Y-sort draw order | `Node2D` with `z_index` set manually |
| Tweening match removal | `create_tween().tween_property()` |
| Node signals | `tile.pressed.connect(...)` |
| Autoloads | `GameState`, `TileTypes` in Project Settings |
| Random shuffle | `array.shuffle()` |
