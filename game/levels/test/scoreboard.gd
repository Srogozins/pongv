extends Node2D

onready var left_score = get_node("left_score")
onready var right_score = get_node("right_score")

func _increment_score(score_node):
	score_node.set_text(str(int(left_score.get_text()) +1))

func increment_left_score():
	_increment_score(left_score)

func increment_right_score():
	_increment_score(right_score)

func reset_score():
	left_score.set_text(str(0))
	right_score.set_text(str(0))