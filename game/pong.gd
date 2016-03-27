extends Node2D

export var PAD_SPEED = 300 # For digital controls
export var IMPULSE_LIMIT = 0.1
onready var SCREEN_SIZE = get_viewport_rect().size

onready var DEBUG_MOUSE_NOCAP = Globals.get("debug/mouse_nocap")

onready var tree = get_tree()

onready var left_player = get_node("left_player")
onready var right_player = get_node("right_player")
onready var left_pad = left_player.get_pads()[0]
onready var right_pad = right_player.get_pads()[0]
onready var pad_size = left_pad.get_node('pad_sprite').get_texture().get_size() # TODO: Check sizes for pads individually

onready var scoreboard = get_node("scoreboard")

onready var p_ai_controller = PlayerAIController.new(left_player)
onready var ball_spawner = get_node("ball_spawner")

class PlayerAIController:
	var player = null
	func _init(player):
		self.player = player

	func update_pads(ball_pos, pad_size):
		# TODO: Intelligent handling of multiple ball trajectories with multiple pads
		for p in self.player.get_pads():
			var pad_rect = Rect2(p.get_pos() - pad_size/2, pad_size)
			if pad_rect.end.y < ball_pos.y:
				self.player.pads_move_down()
			elif pad_rect.pos.y > ball_pos.y:
				self.player.pads_move_up()

func _ready():
	if not DEBUG_MOUSE_NOCAP:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ball_spawner.spawn_ball()
	set_fixed_process(true)
	set_process_input(true)

func _fixed_process(delta):
	var ball_pos = tree.get_nodes_in_group("balls")[0].get_pos() + ball_spawner.get_pos()
	p_ai_controller.update_pads(ball_pos, pad_size)

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