extends Node2D

const START_BALL_SPEED = 150
const START_BALL_DIRECTION = Vector2(-1, 0)
const PAD_SPEED = 300 # For digital controls

var DEBUG_mouse_nocap = Globals.get("debug/mouse_nocap")

var ball_speed = START_BALL_SPEED
var ball_direction = START_BALL_DIRECTION
var screen_size
var pad_size
var mouse_controlled

var left_pad
var right_pad
var ball

var left_score
var right_score

var p_ai_controller = null

class LeftPadActions:
	static func move_up():
		if Input.is_action_pressed("left_move_up"):
			Input.action_release("left_move_up")
		if not Input.is_action_pressed("left_move_down"):
			Input.action_press("left_move_down")

	static func move_down():
		if Input.is_action_pressed("left_move_down"):
			Input.action_release("left_move_down")
		if not Input.is_action_pressed("left_move_up"):
			Input.action_press("left_move_up")

class RightPadActions:
	static func move_up():
		if Input.is_action_pressed("right_move_up"):
			Input.action_release("right_move_up")
		if not Input.is_action_pressed("right_move_down"):
			Input.action_press("right_move_down")

	static func move_down():
		if Input.is_action_pressed("right_move_down"):
			Input.action_release("right_move_down")
		if not Input.is_action_pressed("right_move_up"):
			Input.action_press("right_move_up")


class PadAIController:
	var pads2actions = {}
	func _init(p2a):
		self.pads2actions = p2a

	func update_pads(ball_pos, pad_size):
		for p in pads2actions.keys():
			var pad_rect = Rect2(p.get_pos() - pad_size/2, pad_size)
			if pad_rect.end.y < ball_pos.y:
				self.pads2actions[p].move_up()
			elif pad_rect.pos.y > ball_pos.y:
				self.pads2actions[p].move_down()

func _ready():
	left_pad = get_node("left_pad")
	right_pad = get_node("right_pad")
	ball = get_node("ball")

	screen_size = get_viewport_rect().size
	pad_size = left_pad.get_texture().get_size() # TODO: Check sizes for pads individually

	if not DEBUG_mouse_nocap:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_controlled = [right_pad]
	p_ai_controller = PadAIController.new({left_pad: LeftPadActions})

	left_score = get_node("scoreboard/left_score")
	right_score = get_node("scoreboard/right_score")

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
	var ball_pos = ball.get_pos()
	var left_rect = Rect2(left_pad.get_pos() - pad_size/2, pad_size)
	var right_rect = Rect2(right_pad.get_pos() - pad_size/2, pad_size)
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
	# TODO: Refactor ball reset
	if (ball_pos.x < 0):
		right_score.set_text(str(int(right_score.get_text()) +1))
		ball_pos = screen_size * 0.5 # move to screen center
		ball_speed = 150
		ball_direction = Vector2(-1,0)
	if (ball_pos.x > screen_size.x):
		left_score.set_text(str(int(left_score.get_text()) +1))
		ball_pos = screen_size * 0.5 # move to screen center
		ball_speed = 150
		ball_direction = Vector2(-1,0)

	ball.set_pos(ball_pos)
	p_ai_controller.update_pads(ball_pos, pad_size)
	process_keys(delta)
