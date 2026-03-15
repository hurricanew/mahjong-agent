extends Node2D

## Main.gd — Root scene. Wires Board and GameOver overlay.

@onready var board:     Node2D     = $Board
@onready var game_over: CanvasLayer = $GameOver


func _ready() -> void:
	board.board_state_changed.connect(_on_board_state_changed)


func _on_board_state_changed(status: String) -> void:
	if status == "WIN" or status == "FAIL":
		# Small delay so the last match tween can finish before the overlay appears
		await get_tree().create_timer(0.4).timeout
		game_over.show_result(status)
