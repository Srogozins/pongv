extends Node2D

const START_BALL_SPEED = 150
const START_BALL_DIRECTION = Vector2(-1, 0)
const PAD_SPEED = 300 # For digital controls

var ball_speed = START_BALL_SPEED
var ball_direction = START_BALL_DIRECTION
var screen_size
var pad_size
var mouse_controlled
var left_pad
var right_pad


func _ready():
	screen_size = get_viewport_rect().size
	pad_size = get_node("left_pad").get_texture().get_size() # TODO: Check sizes for pads individually

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	left_pad = get_node("left_pad")
	right_pad = get_node("right_pad")
	mouse_controlled = [left_pad, right_pad]

	set_process(true)
	set_process_input(true)

func process_pad_move(pad, delta_y):
	var pad_pos = pad.get_pos()
	pad_pos.y = clamp(pad_pos.y + delta_y, 0, screen_size.y)
	pad.set_pos(pad_pos)

func process_pad_mode_up(pad, delta):
	process_pad_move(pad, -PAD_SPEED*delta)

func process_pad_mode_down(pad, delta):
	process_pad_move(pad, PAD_SPEED*delta)

func _input(ev):
	# Mouse-controlled movement
	if (ev.type==InputEvent.MOUSE_MOTION):
		for pad in mouse_controlled:
			var pad_pos = pad.get_pos()
			pad_pos.y += ev.relative_y
			pad_pos.y = clamp(pad_pos.y, 0, screen_size.y)
			pad.set_pos(pad_pos)


func process_keys(delta):
	# Pad movement
	if Input.is_action_pressed("left_move_up"):
		process_pad_move(left_pad, -PAD_SPEED*delta)
	if Input.is_action_pressed("left_move_down"):
		process_pad_move(left_pad, PAD_SPEED*delta)
	if Input.is_action_pressed("right_move_up"):
		process_pad_move(right_pad, -PAD_SPEED*delta)
	if Input.is_action_pressed("right_move_down"):
		process_pad_move(right_pad, PAD_SPEED*delta)

func _process(delta):
	var ball_pos = get_node("ball").get_pos()
	var left_rect = Rect2(get_node("left_pad").get_pos() - pad_size/2, pad_size)
	var right_rect = Rect2(get_node("right_pad").get_pos() - pad_size/2, pad_size)
	ball_pos += ball_direction*ball_speed*delta
	
	# Floor/Ceiling collision
	if ( (ball_pos.y<0 and ball_direction.y <0)
		or (ball_pos.y>screen_size.y and ball_direction.y>0)):
			ball_direction.y = -ball_direction.y
	
	# Pad collision
	if ((left_rect.has_point(ball_pos) and ball_direction.x < 0)
		or (right_rect.has_point(ball_pos) and ball_direction.x > 0)):
			ball_direction.x = -ball_direction.x
			ball_speed *= 1.1
			ball_direction.y = randf() * 2.0-1
			ball_direction = ball_direction.normalized()

	# Wall collision
	if (ball_pos.x < 0 or ball_pos.x > screen_size.x):
		ball_pos = screen_size * 0.5 # move to screen center
		ball_speed = 150
		ball_direction = Vector2(-1,0)
	
	get_node("ball").set_pos(ball_pos)
	process_keys(delta)
	
