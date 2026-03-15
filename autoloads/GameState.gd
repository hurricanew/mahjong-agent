extends Node

## Global game state — accessible from any script via GameState.score etc.

var score: int = 0
var level: int = 1
var hint_uses: int = 3
var shuffle_uses: int = 3

signal score_changed(new_score: int)
signal level_changed(new_level: int)
signal hints_changed(remaining: int)
signal shuffles_changed(remaining: int)


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func next_level() -> void:
	level += 1
	score = 0
	hint_uses = 3
	shuffle_uses = 3
	level_changed.emit(level)
	score_changed.emit(score)
	hints_changed.emit(hint_uses)
	shuffles_changed.emit(shuffle_uses)


func use_hint() -> bool:
	if hint_uses <= 0:
		return false
	hint_uses -= 1
	hints_changed.emit(hint_uses)
	return true


func use_shuffle() -> bool:
	if shuffle_uses <= 0:
		return false
	shuffle_uses -= 1
	shuffles_changed.emit(shuffle_uses)
	return true


func reset() -> void:
	score = 0
	level = 1
	hint_uses = 3
	shuffle_uses = 3
	score_changed.emit(score)
	level_changed.emit(level)
	hints_changed.emit(hint_uses)
	shuffles_changed.emit(shuffle_uses)
