extends Node2D

onready var button_scene = preload("res://Interface/LevelButton.tscn")

var TIMER = 180 # just to make audio scene compatible, this timer does nothing else
var button_list = []

func _ready():
	# dynamically populate the InputMap
	# (this way, I don't need to input it all myself, and it's highly dynamic - I can change this at any time
	populate_input_map()
	
	# cache level select node
	var level_select_node = $CanvasLayer/Control/VBoxContainer/LevelSelect/VBoxContainer/HBoxContainer
	var number_of_levels = 5
	
	for i in range(number_of_levels):
		# instantiate new button
		var new_button = button_scene.instance()
		
		# set the right text
		new_button.set_text(str(i))
		
		# connect a signal
		# (and give the button number as the argument)
		new_button.connect("pressed", self, "button_pressed", [i])
		
		# disable buttons if there are no players
		if Global.player_count <= 0:
			new_button.disabled = true
		
		# add button to list (for easy reference later)
		button_list.append(new_button)
		
		# add it to the right container
		level_select_node.add_child(new_button)

func _input(ev):
	if Global.player_count >= 1:
		for btn in button_list:
			btn.disabled = false

func key_event(scancode):
	var event = InputEventKey.new()
	event.device = 0
	event.scancode = scancode
	
	return event

func con_event(scancode, device_num, motion, motion_dir):
	var event
	
	if motion:
		event = InputEventJoypadMotion.new()
		event.device = device_num
		event.axis = scancode
		event.axis_value = motion_dir
	
	else:
		event = InputEventJoypadButton.new()
		event.device = device_num
		event.button_index = scancode
	
	return event

# LINK: https://www.gotut.net/godot-key-bindings-tutorial/
# (explains rebinding input)

# LINK: https://gitlab.com/Pandaqi/Terrible-Tower-Troubles/blob/master/Scripts/MenuGUI.gd
# (my own code from my previous game, which had reconfigurable controls)

func populate_input_map():
	var actions = ["left", "up", "right", "down", "jump", "shoot"]
	var motion_directions = [-1, -1, 1, 1]
	
	var keys = {
		"keyboard1": [key_event(KEY_LEFT), key_event(KEY_UP), key_event(KEY_RIGHT), key_event(KEY_DOWN), key_event(KEY_SPACE), key_event(KEY_SHIFT)],
		"keyboard2": [key_event(KEY_A), key_event(KEY_W), key_event(KEY_D), key_event(KEY_S), key_event(KEY_T), key_event(KEY_Y)],
		"controller": [JOY_AXIS_0, JOY_AXIS_1, JOY_AXIS_0, JOY_AXIS_1, JOY_BUTTON_0, JOY_BUTTON_1]
	}
	
	# add first keyboard player
	var counter = 0
	for val in keys["keyboard1"]:
		var action_name = actions[counter] + "-1"
		
		if not InputMap.has_action(action_name): InputMap.add_action(action_name)
		InputMap.action_add_event(action_name, val)
		counter += 1
	
	# add second keyboard player
	counter = 0
	for val in keys["keyboard2"]:
		var action_name = actions[counter] + "-2"
		
		if not InputMap.has_action(action_name): InputMap.add_action(action_name)
		InputMap.action_add_event(action_name, val)
		counter += 1
	
	# add controller players
	# for each player ...
	for i in range(4):
		# loop through all the actions
		for cur_action in range(actions.size()):
			var motion = false
			var motion_dir = 0
			if cur_action < 4:
				motion_dir = motion_directions[cur_action]
				motion = true
			
			var action_name = actions[cur_action] + str(i)
			
			# add the right action, with the right name, at the right place
			if not InputMap.has_action(action_name): InputMap.add_action(action_name)
			InputMap.action_add_event(action_name, con_event(keys["controller"][cur_action], i, motion, motion_dir))

func button_pressed(num):
	print("Pressed button ", num)
	
	get_tree().change_scene("res://Levels/LevelSkeleton.tscn")
	
	# load the correct level
	#get_tree().change_scene("res://Levels/Level" + str(num) + ".tscn")

func _on_Fullscreen_pressed():
	OS.window_fullscreen = !OS.window_fullscreen
