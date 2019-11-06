extends Node

var MAP_SIZE = Vector2(32, 24)

var control_map = []
var player_count = 0
var player_colors = [Color(1,0.5,0.5), Color(0.5,0.5,1), Color(1,0.5,1), Color(0.5, 1, 1)]

func _ready():
	# Register event to monitor if joystick connected or disconnected
	Input.connect("joy_connection_changed",self,"joy_con_changed")

func get_registered_keyboards():
	if control_map.find(-2) < 0:
		if control_map.find(-1) < 0:
			return 0
		else:
			return 1
	else:
		return 2

func register_device(device_num):
	# if this device wasn't registered yet ...
	if control_map.find(device_num) < 0:
		# if we're already at max player count, always refuse
		if player_count == 4:
			return -1
		
		# save it, and link it to its player number
		control_map.append( device_num )
		
		player_count += 1
		
		# return the player count for this controller, so the GUI can handle it
		return player_count
	else:
		return -1