extends Node2D

var growth_timer

onready var cellular_automata = get_node("/root/Node2D/CellularAutomata/Control/ColorRect")
onready var tilemap = get_node("/root/Node2D/TileMap")

var param = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize timer
	growth_timer = Timer.new()
	add_child(growth_timer)
	
	growth_timer.connect("timeout", self, "grow") 
	growth_timer.set_one_shot(false)
	growth_timer.set_wait_time(0.5)
	growth_timer.start()
	
	param = get_node("/root/Node2D").simulation_parameters

func get_safe_position(pos):
	var temp = tilemap.world_to_map( pos )
	temp.x = int(temp.x) % int(Global.MAP_SIZE.x)
	temp.y = int(temp.y) % int(Global.MAP_SIZE.y)
	
	return temp

func grow():
	# loop through all objects that should grow
	for obj in get_tree().get_nodes_in_group("GrowingObjects"):
		
		# check how fast we should grow
		# (based on water level)
		var transformed_position = obj.get_position() + obj.get_transform().x * obj.get_node("Sprite").get_scale().x * 32
		var true_position = get_safe_position( transformed_position )
		var my_cell = cellular_automata.last_known_grid[true_position.y][true_position.x]
		
		var water_level = 0.0
		if my_cell.size() != 0:
			water_level = my_cell[2]
			
			if water_level == null:
				water_level = 0.0
		
		var growth_speed = param.tree_default_growth_speed + water_level * param.tree_water_growth_factor
		
		# if the object is on fire, keep updating the position of the fire particle
		if obj.is_on_fire():
			obj.fire_effect.set_position( obj.get_fire_position() )
		
		# if there's not enough carbon, we shrink again
		# NOTE: Decided not to do this: it wasn't fun and made the game way too hard
#		if my_cell.size() != 0:
#			var carbon_level = (1.0 - my_cell[0])
#
#			if carbon_level < 0.1:
#				growth_speed = 1.00 - (1.0 - carbon_level) * 0.1
		
		# increase the sprite size
		var old_scale = obj.get_node("Sprite").get_scale()
		var new_scale = clamp(old_scale.x * growth_speed, 0.0, 1.0)
		obj.get_node("Sprite").set_scale( new_scale * Vector2(1,1) )
		
		# increase collision shape size
		var col_shape = obj.get_node("CollisionShape2D")
		var old_extents = col_shape.shape.get_extents()
		var new_extents = old_extents * growth_speed
		new_extents.x = clamp(new_extents.x, 0.0, 64.0)
		new_extents.y = clamp(new_extents.y, 0.0, 32.0)
		col_shape.shape.set_extents( new_extents )
		
		# offset collision shape correctly
		var new_pos = col_shape.get_position() 
		new_pos.x = new_extents.x
		col_shape.set_position( new_pos )
		
		# if we're at maximum scale, remove us from the growing objects group
		if new_scale >= 1:
			obj.remove_from_group("GrowingObjects")
