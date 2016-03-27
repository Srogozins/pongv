extends Node2D
export var PAD_SPEED = 300 # TODO: Receive this from up top

export(String, "right_move_up", "left_move_up", "") var MOVE_UP_ACTION
export(String, "right_move_down", "left_move_down", "") var MOVE_DOWN_ACTION
export(String, "right_special_1", "left_special_1") var SPECIAL_1_ACTION
export(bool) var MOUSE_CONTROLLED
export(int) var SWALL_SPAWN_X

var swalls = load('levels/test/short_lived_spawned_walls.tscn')

func _ready():
	set_process_input(true)
	set_fixed_process(true)

func _pads_move(move_v):
	for pad in get_pads():
		pad.move(move_v)

func _switch_actions(old_action, new_action):
	if Input.is_action_pressed(old_action):
			Input.action_release(old_action)
	if not Input.is_action_pressed(new_action):
			Input.action_press(new_action)

func _spawn_walls(pos_v):
	if not has_node("spawned_walls"):
		var swalls_i = swalls.instance()
		swalls_i.set_name("spawned_walls")
		swalls_i.set_pos(pos_v)
		add_child(swalls_i)

func toggle_check(ev):
	return ev.is_pressed() and not ev.is_echo()

func _input(ev):
	# Mouse-controlled movement
	if MOUSE_CONTROLLED and (ev.type==InputEvent.MOUSE_MOTION):
		var delta_y = clamp(ev.relative_y, -PAD_SPEED, PAD_SPEED)
		_pads_move(Vector2(0, delta_y)) # TODO: Have this sync up with physics to prevent tunneling
	elif(ev.is_action(SPECIAL_1_ACTION) and toggle_check(ev)):
		_spawn_walls(Vector2(SWALL_SPAWN_X, get_pads()[0].get_pos().y))

func _process_keys(delta):
	# Pad movement
	if not MOVE_DOWN_ACTION.empty() and Input.is_action_pressed(MOVE_UP_ACTION):
		_pads_move(Vector2(0, -PAD_SPEED*delta))
	elif not MOVE_UP_ACTION.empty() and Input.is_action_pressed(MOVE_DOWN_ACTION):
		_pads_move(Vector2(0, PAD_SPEED*delta))

func _fixed_process(delta):
	_process_keys(delta)

func get_pads():
	var pads = []
	for child in get_children():
		if child.is_in_group("pads"):
			pads.append(child)
	return pads

func pads_move_down():
	_switch_actions(MOVE_UP_ACTION, MOVE_DOWN_ACTION)

func pads_move_up():
	_switch_actions(MOVE_DOWN_ACTION, MOVE_UP_ACTION)