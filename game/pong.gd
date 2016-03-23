extends Node2D

const PAD_SPEED = 300 # For digital controls
const IMPULSE_LIMIT = 0.1

var DEBUG_mouse_nocap = Globals.get("debug/mouse_nocap")

onready var tree = get_tree()

onready var screen_size = get_viewport_rect().size

onready var left_pad = get_node("left_pad")
onready var right_pad = get_node("right_pad")
onready var ball = null
onready var pad_size = left_pad.get_node('pad_sprite').get_texture().get_size() # TODO: Check sizes for pads individually

onready var scoreboard = get_node("scoreboard")

onready var p_ai_controller = PadAIController.new({left_pad: LeftPadActions})
var swalls = load('levels/test/short_lived_spawned_walls.tscn')
onready var ball_spawner = get_node("ball_spawner")

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
	if not DEBUG_mouse_nocap:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ball_spawner.spawn_ball()
	set_fixed_process(true)
	set_process_input(true)

func process_pad_move(pad, delta_y):
	pad.move(Vector2(0, delta_y))

func process_pad_mode_up(pad, delta):
	process_pad_move(pad, -PAD_SPEED*delta)

func process_pad_mode_down(pad, delta):
	process_pad_move(pad, PAD_SPEED*delta)

func toggle_check(ev):
	return ev.is_pressed() and not ev.is_echo()

func spawn_walls(pos_v, id):
	if not has_node("spawned_walls_" + id):
		var swalls_i = swalls.instance()
		swalls_i.set_name("spawned_walls_" + id)
		swalls_i.set_pos(pos_v)
		add_child(swalls_i)

func _input(ev):
	# Mouse-controlled movement
	if (ev.type==InputEvent.MOUSE_MOTION):
		var move_v = Vector2(0, ev.relative_y)
		tree.call_group(0, "mouse_controlled_pads", "move", move_v)
	elif(ev.is_action("left_special_1") and toggle_check(ev)):
		spawn_walls(Vector2(320-80, left_pad.get_pos().y), 'left')
	elif(ev.is_action("right_special_1") and toggle_check(ev)):
		spawn_walls(Vector2(320+80, right_pad.get_pos().y), 'right')

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
	var ball_pos = tree.get_nodes_in_group("balls")[0].get_pos() + ball_spawner.get_pos()

	var left_rect = Rect2(left_pad.get_pos() - pad_size/2, pad_size)
	var right_rect = Rect2(right_pad.get_pos() - pad_size/2, pad_size)

	p_ai_controller.update_pads(ball_pos, pad_size)
	process_keys(delta)

func rebound_ball_with_pad(ball, pad, rebound_dir):
	var y_impulse = pad.get_travel().y
	var x_impulse = abs(y_impulse) * rebound_dir
	var impulse_v = Vector2(clamp(x_impulse, -IMPULSE_LIMIT, IMPULSE_LIMIT), clamp(y_impulse, -IMPULSE_LIMIT, IMPULSE_LIMIT))
	ball.apply_impulse(pad.get_pos(), impulse_v)

func _on_ball_body_enter(body, ball):
	if body.get_name() == 'left_goal_wall':
		scoreboard.increment_right_score()
		ball.queue_free()
		ball_spawner.spawn_ball()
	elif body.get_name() == 'right_goal_wall':
		scoreboard.increment_left_score()
		ball.queue_free()
		ball_spawner.spawn_ball()
	elif body.is_in_group("pads"):
		rebound_ball_with_pad(ball, body, bool(body.get_pos().x < ball.get_pos().x))