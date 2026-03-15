extends Node

## TileTypes — canonical enum and matching rules for all 42 unique tile faces.
## 144 tiles total = 4 copies of most types, 1 copy each of Flowers/Seasons.

enum Type {
	# Bamboo (9 types × 4 = 36 tiles)
	BAMBOO_1, BAMBOO_2, BAMBOO_3, BAMBOO_4, BAMBOO_5,
	BAMBOO_6, BAMBOO_7, BAMBOO_8, BAMBOO_9,
	# Characters (9 types × 4 = 36 tiles)
	CHAR_1, CHAR_2, CHAR_3, CHAR_4, CHAR_5,
	CHAR_6, CHAR_7, CHAR_8, CHAR_9,
	# Dots (9 types × 4 = 36 tiles)
	DOT_1, DOT_2, DOT_3, DOT_4, DOT_5,
	DOT_6, DOT_7, DOT_8, DOT_9,
	# Winds (4 types × 4 = 16 tiles)
	WIND_EAST, WIND_SOUTH, WIND_WEST, WIND_NORTH,
	# Dragons (3 types × 4 = 12 tiles)
	DRAGON_RED, DRAGON_GREEN, DRAGON_WHITE,
	# Flowers (4 types × 1 each = 4 tiles — any Flower matches any Flower)
	FLOWER_PLUM, FLOWER_ORCHID, FLOWER_CHRYSANTHEMUM, FLOWER_BAMBOO,
	# Seasons (4 types × 1 each = 4 tiles — any Season matches any Season)
	SEASON_SPRING, SEASON_SUMMER, SEASON_AUTUMN, SEASON_WINTER,
}

# Suit groups for wildcard matching
const FLOWER_TYPES := [
	Type.FLOWER_PLUM, Type.FLOWER_ORCHID,
	Type.FLOWER_CHRYSANTHEMUM, Type.FLOWER_BAMBOO
]
const SEASON_TYPES := [
	Type.SEASON_SPRING, Type.SEASON_SUMMER,
	Type.SEASON_AUTUMN, Type.SEASON_WINTER
]

# Human-readable names (useful for debug labels and agent JSON)
const NAMES: Dictionary = {
	Type.BAMBOO_1: "bamboo_1", Type.BAMBOO_2: "bamboo_2", Type.BAMBOO_3: "bamboo_3",
	Type.BAMBOO_4: "bamboo_4", Type.BAMBOO_5: "bamboo_5", Type.BAMBOO_6: "bamboo_6",
	Type.BAMBOO_7: "bamboo_7", Type.BAMBOO_8: "bamboo_8", Type.BAMBOO_9: "bamboo_9",
	Type.CHAR_1: "char_1",   Type.CHAR_2: "char_2",   Type.CHAR_3: "char_3",
	Type.CHAR_4: "char_4",   Type.CHAR_5: "char_5",   Type.CHAR_6: "char_6",
	Type.CHAR_7: "char_7",   Type.CHAR_8: "char_8",   Type.CHAR_9: "char_9",
	Type.DOT_1: "dot_1",     Type.DOT_2: "dot_2",     Type.DOT_3: "dot_3",
	Type.DOT_4: "dot_4",     Type.DOT_5: "dot_5",     Type.DOT_6: "dot_6",
	Type.DOT_7: "dot_7",     Type.DOT_8: "dot_8",     Type.DOT_9: "dot_9",
	Type.WIND_EAST: "wind_east",   Type.WIND_SOUTH: "wind_south",
	Type.WIND_WEST: "wind_west",   Type.WIND_NORTH: "wind_north",
	Type.DRAGON_RED: "dragon_red", Type.DRAGON_GREEN: "dragon_green",
	Type.DRAGON_WHITE: "dragon_white",
	Type.FLOWER_PLUM: "flower_plum",         Type.FLOWER_ORCHID: "flower_orchid",
	Type.FLOWER_CHRYSANTHEMUM: "flower_chrysanthemum", Type.FLOWER_BAMBOO: "flower_bamboo",
	Type.SEASON_SPRING: "season_spring", Type.SEASON_SUMMER: "season_summer",
	Type.SEASON_AUTUMN: "season_autumn", Type.SEASON_WINTER: "season_winter",
}

# Color tints per suit (for ColorRect placeholders)
const SUIT_COLORS: Dictionary = {
	"bamboo":   Color(0.2, 0.6, 0.2),
	"char":     Color(0.8, 0.2, 0.2),
	"dot":      Color(0.2, 0.3, 0.8),
	"wind":     Color(0.6, 0.6, 0.6),
	"dragon":   Color(0.8, 0.6, 0.0),
	"flower":   Color(0.9, 0.4, 0.7),
	"season":   Color(0.4, 0.8, 0.8),
}


## Returns true if tile_a and tile_b are a legal match.
func can_match(a: Type, b: Type) -> bool:
	if a == b:
		return true
	# Any Flower matches any Flower
	if a in FLOWER_TYPES and b in FLOWER_TYPES:
		return true
	# Any Season matches any Season
	if a in SEASON_TYPES and b in SEASON_TYPES:
		return true
	return false


## Returns the match_key string used to group tiles for pair-finding.
## Flowers all share one key; Seasons all share one key; others use their name.
func match_key(t: Type) -> String:
	if t in FLOWER_TYPES:
		return "flower"
	if t in SEASON_TYPES:
		return "season"
	return NAMES[t]


## Returns the suit string for a given type (used for color coding).
func suit_of(t: Type) -> String:
	var name: String = NAMES[t]
	if name.begins_with("bamboo"):  return "bamboo"
	if name.begins_with("char"):    return "char"
	if name.begins_with("dot"):     return "dot"
	if name.begins_with("wind"):    return "wind"
	if name.begins_with("dragon"):  return "dragon"
	if name.begins_with("flower"):  return "flower"
	if name.begins_with("season"):  return "season"
	return "unknown"


## Builds the ordered tile pool for a 72-tile game.
## 2 copies of each standard type (34×2=68) + 2 flowers + 2 seasons = 72.
## Returns an Array[int] of Type values — shuffle before assigning to positions.
func build_tile_pool() -> Array:
	var pool: Array = []
	# Standard tiles: 2 copies each
	for t in range(Type.BAMBOO_1, Type.DRAGON_WHITE + 1):
		for _i in range(2):
			pool.append(t)
	# Flowers: 2 tiles (wildcard-match each other)
	pool.append(Type.FLOWER_PLUM)
	pool.append(Type.FLOWER_ORCHID)
	# Seasons: 2 tiles (wildcard-match each other)
	pool.append(Type.SEASON_SPRING)
	pool.append(Type.SEASON_SUMMER)
	# Count: 34 standard types × 2 = 68 + 2 flowers + 2 seasons = 72 ✓
	assert(pool.size() == 72, "Tile pool must be exactly 72. Got: %d" % pool.size())
	return pool
