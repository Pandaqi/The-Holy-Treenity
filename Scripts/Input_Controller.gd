extends Control

func _ready():
	set_GUI_texts(1)

func _input(event):
	# if ANY joypad button is pressed ...
	if event is InputEventJoypadButton:
		var device_num = event.get_device()
		
		# register the device
		# (the Global script checks if it was already registered)
		var play_num = Global.register_device(device_num)
		
		# if the device was new, and has a correct number ...
		if play_num > -1:
			update_device_info(play_num, true)
	
	# if ANY key is pressed ...
	elif event is InputEventKey:
		
		# ENTER is for the first keyboard
		if event.scancode == KEY_ENTER:
			var play_num = Global.register_device(-1)
			
			if play_num > -1:
				update_device_info(play_num, false)
		
		# A is for the second keyboard
		# NOTE: THe second keyboard may only be registered once the FIRST has already been registerd
		elif event.scancode == KEY_A:
			var kb_reg = Global.get_registered_keyboards()
			
			if kb_reg == 1:
				var play_num = Global.register_device(-2)
				if play_num > -1:
					update_device_info(play_num, false)

func update_device_info(play_num, controller = true):
	# FIRST, update the info for this specific device
	# update the GUI
	var my_gui = get_node("TextureRect" + str(play_num))
	
	# modulate texture rectangle
	my_gui.modulate = Global.player_colors[(play_num - 1)]
	
	# update text
	var temp_str = "[center]Player " + str(play_num)
	
	if controller:
		temp_str += " (controller)"
	else:
		temp_str += " (keyboard)"
	
	temp_str += "[/center]"
	
	my_gui.get_node("Text").bbcode_text = temp_str
	
	# Finally, go through all the other GUIs and update their text
	set_GUI_texts(play_num + 1)

func set_GUI_texts(play_num):
	# Go through all the other GUIs and update their text
	for i in range(play_num, 5):
		var temp_gui = get_node("TextureRect" + str(i))
		
		# If this GUI already has a player assigned, show that!
		if i <= Global.player_count:
			var device_num = Global.control_map[(i - 1)]
			
			# modulate texture rectangle
			temp_gui.modulate = Global.player_colors[(i - 1)]
			
			# update text
			var temp_str = "[center]Player " + str(i)
			var controller = (device_num >= 0)
			
			if controller:
				temp_str += " (controller)"
			else:
				temp_str += " (keyboard)"
			
			temp_str += "[/center]"
			
			temp_gui.get_node("Text").bbcode_text = temp_str
		else:
		# Otherwise, show the options that are available
			var temp_str = "Press any button (controller)"
			
			var kb_reg = Global.get_registered_keyboards()
			if kb_reg < 2:
				if kb_reg == 0:
					temp_str += " or ENTER (keyboard)"
				elif kb_reg == 1:
					temp_str += " or A (keyboard)"
			
			temp_str += ""
			
			temp_gui.get_node("Text").bbcode_text = temp_str