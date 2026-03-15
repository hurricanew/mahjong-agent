extends Node2D

## Tile.gd — Individual tile node. Holds data and manages its own visual state.

# ── Data ──────────────────────────────────────────────
var tile_type: int = -1           # TileTypes.Type value
var grid_pos: Vector3i = Vector3i.ZERO
var is_selectable: bool = false

# ── Visual state ──────────────────────────────────────
enum VisualState { IDLE, SELECTED, NOT_FREE, MATCHED }
var _state: VisualState = VisualState.NOT_FREE

# ── Signals ───────────────────────────────────────────
signal tile_clicked(tile: Node2D)

# ── Child refs ────────────────────────────────────────
@onready var background: ColorRect = $Background
@onready var highlight: ColorRect  = $Highlight
@onready var type_label: Label     = $TypeLabel
@onready var layer_label: Label    = $LayerLabel


func _ready() -> void:
	# Enable input detection on the background rect
	background.gui_input.connect(_on_gui_input)


## Called by Board after setting tile_type and grid_pos.
func setup(p_type: int, p_grid_pos: Vector3i) -> void:
	tile_type = p_type
	grid_pos = p_grid_pos
	# Colour background by suit
	var suit := TileTypes.suit_of(tile_type)
	background.color = TileTypes.SUIT_COLORS.get(suit, Color.GRAY)
	# Labels
	type_label.text = _short_name(TileTypes.NAMES.get(tile_type, "?"))
	layer_label.text = "z%d" % grid_pos.z


func set_visual_state(new_state: VisualState) -> void:
	_state = new_state
	match new_state:
		VisualState.IDLE:
			modulate = Color(1, 1, 1, 1)
			highlight.visible = false
		VisualState.SELECTED:
			modulate = Color(1, 1, 1, 1)
			highlight.visible = true
		VisualState.NOT_FREE:
			modulate = Color(0.5, 0.5, 0.5, 0.7)
			highlight.visible = false
		VisualState.MATCHED:
			_play_match_tween()


func _play_match_tween() -> void:
	highlight.visible = false
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			tile_clicked.emit(self)


## Shortens "bamboo_3" → "BAM3", "wind_east" → "EAST", etc.
func _short_name(full: String) -> String:
	var parts := full.split("_")
	if parts.size() == 1:
		return full.substr(0, 4).to_upper()
	return parts[0].substr(0, 3).to_upper() + parts[1].substr(0, 1).to_upper()
