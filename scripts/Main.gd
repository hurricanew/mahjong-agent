extends Node2D

## Main.gd — Root scene. Wires Board signals to game lifecycle.

@onready var board: Node2D = $Board


func _ready() -> void:
	board.board_state_changed.connect(_on_board_state_changed)
	print("[Main] Game started. Board spawning 144 tiles...")


func _on_board_state_changed(status: String) -> void:
	match status:
		"WIN":
			print("[Main] 🎉 WIN!")
			# TODO M4: show Win overlay
		"FAIL":
			print("[Main] 💀 FAIL — no moves left.")
			# TODO M4: show Fail overlay
		"CONTINUE":
			pass  # game goes on
