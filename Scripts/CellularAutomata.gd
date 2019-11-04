extends Node

var generation_timer
var last_known_grid = null

onready var tilemap = get_node("/root/Node2D/TileMap")

func _ready():
	# Initialize timer
	generation_timer = Timer.new()
	add_child(generation_timer)
	
	generation_timer.connect("timeout",self,"new_generation") 
	generation_timer.set_one_shot(false)
	generation_timer.set_wait_time(0.2)
	generation_timer.start()
	
	# Call a function when the window resizes
	# TURNED OFF => Decided to use scaling from Godot itself, with black bars at the sides
	get_tree().get_root().connect("size_changed", self, "window_resize")
	
	# Set some settings on the algorithm thread
	get_node("Semaphore").UPDATE_SPEED = 0.2

func window_resize():
	print("Resizing: ", get_viewport().size)
	
	# Hand new size to the shader
	self.material.set_shader_param("screen_size", get_viewport().size)

func new_generation():
	# this is where we add new impulses to the system => trees give oxygen, players take it, etc.
	
	###
	# Giving/taking oxygen and carbon
	###
	var impulses = []
	for obj in get_tree().get_nodes_in_group("OxygenGivers"):
		
		var transformed_position = obj.get_position() + obj.get_transform().x * obj.get_node("Sprite").get_scale().x * 32
		
		var true_position = get_safe_position( transformed_position )
		
		impulses.append( [true_position, 0.4, 0] )
	
	for obj in get_tree().get_nodes_in_group("OxygenTakers"):
		var true_position = get_safe_position( obj.get_position() )
		
		impulses.append( [true_position, -0.3, 0] )
	
	###
	# Giving/taking heat
	###
	for obj in get_tree().get_nodes_in_group("WarmthGivers"):
		var true_position = get_safe_position( obj.get_position() )
		
		impulses.append( [true_position, 0.2, 1] )
		impulses.append( [true_position, 0.2, 2] )
	
	get_node("Semaphore").calculate_new_grid(impulses)

func get_safe_position(pos):
	var temp = tilemap.world_to_map( pos )
	temp.x = int(temp.x) % int(Global.MAP_SIZE.x)
	temp.y = int(temp.y) % int(Global.MAP_SIZE.y)
	
	return temp

func check_water_level(pos):
	var water_found = false
	var counter = 0
	
	# this just keeps checking tiles above us until we find the first non-impenetrable cell
	# (not necessarily the first tile with water)
	while not water_found:
		var temp_pos = get_safe_position(pos - counter*Vector2(0,32))
		var cur_val = last_known_grid[temp_pos.y][temp_pos.x]
		
		if cur_val.size() > 0:
			return cur_val[2]
			water_found = true
		
		counter += 1

func update_texture(grid, MAP_SIZE):

	# Display the grid inside a texture
	# Create an Image
	var texture = Image.new()
	texture.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGBA8)
	texture.lock()
	
	# Fill the texture with the right values for each grid cell
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var val = grid[y][x]
			
			var new_color = Color(0,0,0)
			if val.size() > 0:
				
				# blend RED and BLUE for the HEAT
				new_color = Color(0.0, 0.0, 1.0).linear_interpolate(Color(1.0, 0.0, 0.0), val[1])
			
				# change ALPHA based on oxygen level
				# Thicker = more carbon, less oxygen
				# ??? Perhaps we need a background to show this properly, and perhaps only change alpha at extremes
				new_color.a = (1.0 - val[0])
			
			texture.set_pixel(x, y, new_color)
	
	texture.unlock()
	
	# Convert Image to ImageTexture
	var image_tex = ImageTexture.new()
	image_tex.create_from_image(texture)
	
	# Hand texture to the shader
	self.material.set_shader_param("grid_tex", image_tex)
	
	# Save the grid values, so other nodes can use it
	last_known_grid = grid
	
	###
	# WATER
	###
	
	# Also ask the water node to draw the water
	get_node("/root/Node2D/DrawWater").draw_water(grid, MAP_SIZE)
	
	# Add texture to the sprite
#	var sprite = get_node("Sprite")
#	sprite.set_texture(image_tex)
