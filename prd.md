# PRD: Mahjong Wonders (MVP)

## 1. Product Vision
**Mahjong Wonders** is a 2.5D tile-matching solitaire game designed for high performance on mobile devices and web browsers. It utilizes a "stacked sprite" approach to simulate 3D depth in a 2D engine, offering a zen-like experience with zero marketing pressure.

* **Primary Goal:** Publish to the App Store within 6 months.
* **Revenue Target:** $100 USD/month via ads.
* **Target Audience:** Casual puzzle gamers seeking a "Zen" aesthetic.

---

## 2. Core Game Mechanics (Standard Solitaire)
The game must strictly adhere to the traditional "Turtle" formation rules:
* **The Set:** **72 tiles** for prototype (standard 144 planned for v1.0). Suits, Winds, Dragons, Flowers, Seasons — 2 copies per type.
* **Selection Logic (The "Free" Rule):** A tile is selectable only if:
    1.  **Top is Clear:** No tile exists on a higher Z-layer that even partially overlaps the current tile.
    2.  **Side is Clear:** At the current Z-layer, the tile has either its **LEFT** side OR its **RIGHT** side completely open (no adjacent tile on at least one long edge).
* **Tile Rules:** max 4 tiles of same type can be placed in game, no more than 2 tiles of same pattern can be placed on top of each other.
* **Matching Rules:** Identical pairs match. Special matches: Any Flower matches any Flower; any Season matches any Season.
* **Top Bar:** Top Bar has **Level**, counting levels completed. **Score**, 100 points per pair and **Match Count** (number of pairs available to match).
* **Bottom Bar:** Top Bar has **Shuffle**, shuffle existing tiles and **hint** (highlight a pair of tiles that can be matched). Both has default of 3 times.

* **Win State:** All 144 tiles are removed.
* **Tiles total:** Prototype uses **72 tiles** (2 copies of each type). Standard 144-tile game planned for v1.0.
* **Fail State:** No legal matching pairs remain "free" on the board.

---

## 3. Technical Stack
* **Engine:** Godot 4.x (2D Engine Mode).
* **Language:** GDScript.
* **IDE:** Antigravity (AI-assisted/Spec-driven workflows).
* **Rendering Strategy:** Isometric 2.5D. Tiles are 2D sprites with "baked-in" shadows and side-thickness art to simulate a 3D view.
* **Viewport:** Portrait **720×1280** (matches common mobile phones, e.g. iPhone 14 / Samsung S-series). `window/stretch/mode = canvas_items` + `aspect = expand` scales cleanly to all screen sizes.
* **Tile Sizing:** The tile pile must fill the full screen width. `TILE_W = viewport_width ÷ 16` (16 tile columns in the Turtle formation); `TILE_H` scales proportionally for a portrait tile aspect ratio. Tile size may vary ±5px per device.

---

## 4. Data Architecture & Grid System
The board is represented as a 3D Coordinate Grid **(x, y, z)** to facilitate logic and AI testing:
* **Unit Size:** 1.0 x 1.0 x 1.0 (normalized).
* **Mapping:** * **x, y:** Horizontal/Vertical position on the 2D plane.
    * **z:** The vertical stack layer (Layer 0 is the table).
* **Tile Object:** Stores `tile_type`, `grid_position`, `is_selectable`, and `is_matched`.

---

## 5. Functional Requirements
### A. Selection & Matching Engine
* **`is_tile_free(target_tile)`**: A query function that checks adjacent indices in the 3D grid to validate selection.
* **`check_victory_condition()`**: Scans remaining tiles to determine if any valid matches are available.
* **`generate_solvable_deal(positions)`**: Every game must be generated using a reverse-construction algorithm that guarantees the board is completable. Randomly assigning tile types to positions is **not acceptable** — the deal must be built by finding a valid removal sequence first, then assigning types. This applies to both the initial deal and any mid-game shuffle.

### B. Visual Interaction
* **Z-Sorting:** Automate Y-sorting and Z-index assignment based on the $(x, y, z)$ coordinates to ensure correct sprite overlapping.
* **Feedback:** Visual "selection glow" and a haptic/audio "clack" on match.
* **Shuffle Mechanic:** Randomized redistribution of remaining tiles if the `check_victory_condition` returns false.

### C. Monetization & Ads
* **AdMob Integration:** 

---

## 6. AI Asset Generation Pipeline

### A. Visuals (Images)
* **Tile Textures:** Use **Nano Banana 2** (Gemini 3 Flash Image) to generate 42 unique tile faces. 
* **Base Sprite:** Generate a single, high-fidelity isometric "Blank Tile" base with baked-in ambient occlusion.
* **Environments:** 4K "Zen Garden" or "Mountain Temple" backgrounds.
* **UI reference:** [4K "Zen Garden" or "Mountain Temple" UI.](https://play.google.com/store/apps/details?id=com.nebula.mahjongtile&hl=en_AU)

### B. Audio (Music & SFX)
* **Background Music:** Utilize **Lyria 3** to generate 30-second, high-fidelity loops using traditional instruments (Guzheng, Flute).
* **Sound Effects:** AI-generated "Wood-on-Wood" clacking sounds for matches and soft chimes for UI feedback.

## 7. Roadmap: Month 1 (Prototype Phase)
* **Week 1:** Setup Godot 4.x project and create the base Isometric Tile Sprite template.
* **Week 2:** Implement the $(x, y, z)$ grid system and the 144-tile "Turtle" layout script.
* **Week 3:** Develop the `check_freedom` logic and core matching engine in GDScript.
* **Week 4:** Basic UI (Start Menu, Undo button, Win/Loss Screen) and mobile export test.

---

## 8. "Mahjong Master" Gameplay Agent

### 8.1 Overview
The **Mahjong Master** is an AI agent that plays or assists in the game by "looking" at the board state, evaluating multiple matching strategies, and producing a **reasoned move decision** — not just an answer, but an explanation of *why* that move was chosen.

**Use cases:**
* **Auto-solve / Demo Mode:** Agent plays the full game autonomously (useful for showcasing, testing layouts).
* **Hint System (Phase 2):** Replaces the basic hint button with an intelligent suggestion that explains its reasoning in natural language.
* **Difficulty Tuning Aid:** Agent win-rate data is used to validate that a given layout is solvable.

---

### 8.2 Agent Framework: **Google Gemini API (Direct) + GDScript HTTP Client**

**Recommended approach: Gemini Flash 2.0 with structured JSON output via REST.**

#### Why Gemini Flash (not LangChain / LangGraph / AutoGen)?
| Criterion | Gemini Flash Direct | LangChain/LangGraph | Rule-Based Minimax |
|---|---|---|---|
| Reasoning output (natural language "why") | ✅ Native | ✅ With overhead | ❌ No |
| Godot integration (HTTP only) | ✅ Simple REST | ⚠️ Needs Python bridge | ✅ GDScript only |
| Latency | ✅ ~300–800ms | ⚠️ Higher | ✅ <1ms |
| Strategy variety | ✅ Prompt-tunable | ✅ | ❌ Hard to vary |
| Already in PRD ecosystem | ✅ (Nano Banana 2, Lyria 3 = Gemini stack) | ❌ | ❌ |
| Cost at prototype scale | ✅ Free tier | ⚠️ Adds dependencies | ✅ Free |

**Verdict:** Use **Gemini Flash 2.0 REST API** called directly from Godot's `HTTPRequest` node. No Python server needed. Structured JSON output keeps parsing trivial.

---

### 8.3 Board State Interface (JSON Schema)

The game serialises its GDScript grid into a compact JSON payload sent to the agent:

```json
{
  "board": [
    {
      "id": "tile_042",
      "type": "bamboo_3",
      "suit": "bamboo",
      "value": 3,
      "grid_pos": [4, 6, 1],
      "is_free": true
    }
  ],
  "free_tiles": ["tile_042", "tile_017", "..."],
  "available_pairs": [
    { "a": "tile_042", "b": "tile_017", "type": "bamboo_3" }
  ],
  "tiles_remaining": 88,
  "shuffle_uses_left": 2,
  "hint_uses_left": 1
}
```

---

### 8.4 Agent Strategies (Prompt-Selectable)

The agent is prompted to evaluate moves through **one or more named strategies** and select the best:

| Strategy | Logic |
|---|---|
| **`unblock_deep`** | Prefer pairs that unblock the most new free tiles (maximise future options). |
| **`safe_play`** | Prefer pairs where both tiles have multiple matching partners still on the board (avoid stranding unique tiles). |
| **`stack_clear`** | Prefer pairs that contain tiles at high Z-layers first (clear the top of stacks). |
| **`greedy`** | Simply pick the first available valid pair (baseline / fast). |

---

### 8.5 Agent Output Schema

The agent returns structured JSON:

```json
{
  "chosen_pair": { "a": "tile_042", "b": "tile_017" },
  "strategy_used": "unblock_deep",
  "strategies_considered": [
    {
      "name": "unblock_deep",
      "score": 8,
      "reasoning": "Matching bamboo_3 at (4,6,1) and (2,6,1) unblocks 3 tiles on layer 0 that currently have no other free partners."
    },
    {
      "name": "safe_play",
      "score": 5,
      "reasoning": "The pair is safe — 2 other bamboo_3 tiles remain on the board."
    },
    {
      "name": "stack_clear",
      "score": 3,
      "reasoning": "These tiles are on layer 1, not the highest stack."
    }
  ],
  "final_reasoning": "Chose unblock_deep because clearing this pair immediately frees 3 otherwise-stranded tiles, improving overall solvability."
}
```

---

### 8.6 Godot Integration

```
Board.gd
  │ after every input event (or on hint press)
  └─► AgentClient.gd
        │ build_board_json() → JSON string
        │ HTTPRequest.request(GEMINI_API_URL, headers, body)
        └─► on response:
              parse JSON → highlight chosen_pair tiles
              display final_reasoning in HintLabel
```

**`AgentClient.gd`** is a lightweight singleton (autoload) that:
1. Serialises `Board.grid` → JSON.
2. Wraps JSON in a Gemini `generateContent` request with a system prompt defining strategies.
3. Parses the structured response and emits a `move_suggested(pair_a, pair_b, reasoning)` signal.

---

### 8.7 System Prompt Template

```
You are "Mahjong Master", an expert Mahjong Solitaire AI.
You will receive the current board state as JSON.
Evaluate ALL strategies listed below and score each 0–10.
Return ONLY valid JSON matching the output schema — no markdown.

Strategies: unblock_deep, safe_play, stack_clear, greedy.
Rules: Only pairs in available_pairs[] are legal moves.
Goal: Maximise the probability the game is solvable to completion.
```

---

### 8.8 Prototype Scope for Agent

* **Phase 1 (Month 1):** `AgentClient.gd` calls Gemini with `greedy` strategy only — used to validate the HTTP pipeline and JSON schema.
* **Phase 2 (Month 2):** Full multi-strategy reasoning, replace hint button output with `final_reasoning` text.
* **Phase 3 (Month 3+):** Auto-solve demo mode, win-rate telemetry, difficulty validation pipeline.