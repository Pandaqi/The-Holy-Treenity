extends Sprite

var tile_pos
onready var ca = get_node("/root/Node2D/CellularAutomata/Control/ColorRect")

export (NodePath) var connected_door = null

export (int) var SWITCH_TYPE = 0
var switch_colors = [Color(1.0, 0.5, 0.0), Color(1.0, 0.5, 1.0)]

func _ready():
	# cache our position within the tilemap
	tile_pos = get_node("/root/Node2D/TileMap").world_to_map(get_position())
	
	# cache our connected door (essentially, convert NodePath to actual Node)
	connected_door = get_node(connected_door)

func check_surroundings():
	# WATER PRESSURE SWITCH
	if SWITCH_TYPE == 0:
	
		# check the tile above this one
		var ind_above = int(tile_pos.y - 1) % int(Global.MAP_SIZE.y)
		var cell_above = ca.last_known_grid[ind_above][tile_pos.x]
		
		# if it has full water ...
		if cell_above.size() > 0 and cell_above[2] != null:
			if cell_above[2] >= 0.5:
				# ... update switch
				change_switch(true)
				return
	
	# HEAT SWITCH
	elif SWITCH_TYPE == 1:
		var cell = ca.last_known_grid[tile_pos.y][tile_pos.x]
		
		if cell.size() > 0 and cell != null:
			if cell[1] >= 0.6:
				change_switch(true)
				return
	
	# otherwise, if nothing happened, keep the switch closed
	change_switch(false)

func change_switch(enabled):
	if enabled:
		modulate = Color(0.0, 1.0, 0.0)
		
		connected_door.set_visible(false)
		connected_door.get_node("CollisionShape2D").disabled = true
	else:
		modulate = switch_colors[SWITCH_TYPE]
		
		connected_door.set_visible(true)
		connected_door.get_node("CollisionShape2D").disabled = false
