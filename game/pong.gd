extends Node2D

const START_BALL_SPEED = 150
const START_BALL_DIRECTION = Vector2(-1, 0)
const PAD_SPEED = 300 # For digital controls

var DEBUG_mouse_nocap = Globals.get("debug/mouse_nocap")

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

func reset_ball(ball, screen_size):
	ball.call_deferred("set_linear_velocity", START_BALL_SPEED * START_BALL_DIRECTION)
	ball.call_deferred("set_pos",screen_size * 0.5) # move to screen center

func _ready():
	left_pad = get_node("left_pad")
	right_pad = get_node("right_pad")
	ball = get_node("ball")

	screen_size = get_viewport_rect().size
	pad_size = get_node('left_pad/left_pad_spr').get_texture().get_size() # TODO: Check sizes for pads individually

	if not DEBUG_mouse_nocap:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_controlled = [right_pad]
	p_ai_controller = PadAIController.new({left_pad: LeftPadActions})

	left_score = get_node("scoreboard/left_score")
	right_score = get_node("scoreboard/right_score")

	reset_ball(ball, screen_size)

	set_fixed_process(true)
	set_process_input(true)

func process_pad_move(pad, delta_y):
	pad.move(Vector2(0, delta_y))

func process_pad_mode_up(pad, delta):
	process_pad_move(pad, -PAD_SPEED*delta)

func process_pad_mode_down(pad, delta):
	process_pad_move(pad, PAD_SPEED*delta)

func _input(ev):
	# Mouse-controlled movement
	if (ev.type==InputEvent.MOUSE_MOTION):
		for pad in mouse_controlled:
			pad.move(Vector2(0, ev.relative_y))

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

func _fixed_process(delta):
	var ball_pos = ball.get_pos()
	var left_rect = Rect2(left_pad.get_pos() - pad_size/2, pad_size)
	var right_rect = Rect2(right_pad.get_pos() - pad_size/2, pad_size)

	p_ai_controller.update_pads(ball_pos, pad_size)
	process_keys(delta)

func _on_ball_body_enter(body):
	if body.get_name() == 'left_goal_wall':
		right_score.set_text(str(int(right_score.get_text()) +1))
		reset_ball(ball, screen_size)
	elif body.get_name() == 'right_goal_wall':
		left_score.set_text(str(int(left_score.get_text()) +1))
		reset_ball(ball, screen_size)