# Task: Mahjong Wonders — Prototype Build Checklist

> **Strategy:** Each milestone has an immediate, human-testable condition. Never move to the next step until the current test passes. Shortest feedback loop wins.

---

## Milestone 0 — Project Foundation
- [x] Create Godot 4.x project in this folder (`project.godot`)
- [x] Set up folder structure: `scenes/`, `scripts/`, `assets/`, `autoloads/`
- [x] Add `GameState.gd` autoload (score, level, hint_uses, shuffle_uses)
- [x] Add `TileTypes.gd` autoload (enum of all 42 tile types + match key logic)

**✅ Test:** Open project in Godot 4. Run `Main.tscn` — Output panel should print `M0 PASS — project foundation ready.`

---

## Milestone 1 — Grid Logic (Headless, No Visuals)
- [x] `TileLayout.gd` — hardcode all 144 Turtle `Vector3i` positions
- [x] `GameLogic.gd` — `is_tile_free(pos, grid)` function
- [x] `GameLogic.gd` — `find_matches(grid)` returns list of valid pairs
- [x] `GameLogic.gd` — `check_victory(grid)` returns `"WIN"` / `"FAIL"` / `"CONTINUE"`
- [x] Write a test script `test_logic.gd` that runs as a scene
- [x] Register `TileLayout` and `GameLogic` as autoloads in `project.godot`

**✅ Test:** Run `test_logic.gd` — prints `"is_free PASS"`, `"matches PASS"` to console. No scene needed.

---

## Milestone 2 — Tiles on Screen
- [x] `Tile.tscn` with placeholder ColorRect + Label sprites
- [x] `Board.gd` spawn + screen position mapping + z_index
- [x] Dim non-free tiles (modulate alpha 0.5)

**✅ Test:** Run scene — 144 coloured rectangles appear in Turtle formation. Stacking looks correct (no wrong overlaps).

---

## Milestone 3 — Click & Match
- [x] `Tile.gd` — handle `_input_event`, emit `tile_clicked(self)` signal
- [x] `Board.gd` — selection state machine (IDLE → SELECT_FIRST → match/deselect)
- [x] Highlight selected tile (yellow modulate)
- [x] On match: tween scale to 0 → `queue_free()`, remove from grid dict
- [x] On mismatch: swap selection to new tile

> ✅ Implemented inside `Board.gd` + `Tile.gd` during M2.

**✅ Test:** Click two matching free tiles — they disappear. Click a blocked tile — nothing happens. Click two non-matching free tiles — second becomes selected.

---

## Milestone 4 — Game Loop
- [x] `GameLogic.check_victory()` called after every match (done in `Board.gd`)
- [x] Win overlay (`GameOver.tscn`) shown when all tiles cleared
- [x] Fail overlay shown when no pairs remain
- [x] Score increments +100 per match (done via `GameState`)

**✅ Test:** Manually remove all pairs (or use hint spam) → Win screen appears. Force a no-match state → Fail screen appears.

---

## Milestone 5 — UI Bars
- [ ] `UI.tscn` — CanvasLayer with TopBar + BottomBar
- [ ] TopBar: Level label, Score label, Match Count label (updates after each match)
- [ ] BottomBar: Hint button (3 uses) + Shuffle button (3 uses)
- [ ] Hint: highlights a valid pair, decrements counter, disables at 0
- [ ] Shuffle: redistributes tile types in-place, re-evaluates free tiles

**✅ Test:** Score ticks up on each match. Hint highlights a real pair. After 3 hints, button is greyed out. Shuffle reorders tiles and match count updates.

---

## Milestone 6 — Agent (Phase 1 Wiring)
- [ ] `AgentClient.gd` autoload — `build_board_json(grid)` serialises board state
- [ ] `AgentClient.gd` — `request_move()` calls Gemini Flash 2.0 REST endpoint
- [ ] Parse response JSON → extract `chosen_pair` + `final_reasoning`
- [ ] Emit `move_suggested(pair_a_id, pair_b_id, reasoning_text)` signal
- [ ] Wire signal to Board: highlight pair + print reasoning to a debug label

**✅ Test:** Press "Agent Hint" button → after ~1s, two tiles highlight and reasoning text appears (e.g. "Chose unblock_deep because…"). Works with `greedy` strategy first.

---

## Milestone 7 — Polish (Pre-Demo)
- [ ] Swap ColorRect placeholders → real tile sprites (generated via Gemini image)
- [ ] Add background image (Zen Garden)
- [ ] Basic SFX: clack on match, soft chime on hint
- [ ] Mobile export test (iOS or Android)

**✅ Test:** Game looks presentable in a screen recording. Runs at 60fps on device.

---

## Backlog (Month 2+)
- [ ] Full multi-strategy agent reasoning (unblock_deep, safe_play, stack_clear)
- [ ] Agent reasoning shown in Hint button UI (replaces simple pair highlight)
- [ ] Auto-solve / Demo mode
- [ ] AdMob integration
- [ ] Multiple levels / layouts
- [ ] Win-rate telemetry for difficulty tuning
