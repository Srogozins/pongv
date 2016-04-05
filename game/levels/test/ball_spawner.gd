extends Position2D
export var START_BALL_SPEED = 150
export var START_BALL_DIRECTION = Vector2(-1, 0)

var s_ball = load('levels/test/ball.tscn')

func spawn_ball():
	var ball = s_ball.instance()
	ball.connect("body_enter", get_parent(), "_on_ball_body_enter", [ball])
	ball.call_deferred("set_linear_velocity", START_BALL_SPEED * START_BALL_DIRECTION)
	add_child(ball)

func get_balls():
	var balls = []
	for child in get_children():
		if child.is_in_group("balls"):
			balls.append(child)
	return balls