extends CanvasLayer

## GameOver.gd — Win / Fail overlay.
## Shown by Main.gd when board_state_changed emits "WIN" or "FAIL".

@onready var result_label:  Label  = $Panel/VBox/ResultLabel
@onready var score_label:   Label  = $Panel/VBox/ScoreLabel
@onready var restart_btn:   Button = $Panel/VBox/RestartButton


func _ready() -> void:
	visible = false
	restart_btn.pressed.connect(_on_restart)


func show_result(status: String) -> void:
	if status == "WIN":
		result_label.text = "🎉 You Win!"
		result_label.modulate = Color(0.3, 1.0, 0.5)
	else:
		result_label.text = "💀 No Moves Left"
		result_label.modulate = Color(1.0, 0.4, 0.4)

	score_label.text = "Score: %d" % GameState.score
	visible = true


func _on_restart() -> void:
	GameState.reset()
	get_tree().reload_current_scene()
