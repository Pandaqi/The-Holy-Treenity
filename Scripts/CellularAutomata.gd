extends Node

var generation_timer

onready var tilemap = get_node("/root/Node2D/TileMap")

func _ready():
	# Initialize timer
	generation_timer = Timer.new()
	add_child(generation_timer)
	
	generation_timer.connect("timeout",self,"new_generation") 
	generation_timer.set_one_shot(false)
	generation_timer.set_wait_time(0.2)
	generation_timer.start()

func new_generation():
	# this is where we add new impulses to the system => trees give oxygen, players take it, etc.
	
	###
	# Giving/taking oxygen and carbon
	###
	var impulses = []
	for obj in get_tree().get_nodes_in_group("OxygenGivers"):
		var true_position = obj.get_position() + obj.get_meta("anchor_offset") * obj.get_node("Sprite").get_scale()
		true_position = tilemap.world_to_map(true_position)
		
		impulses.append( [true_position, 0.1, 0] )
	
	for obj in get_tree().get_nodes_in_group("OxygenTakers"):
		var true_position = tilemap.world_to_map( obj.get_position() )
		
		impulses.append( [true_position, -0.2, 0] )
	
	###
	# Giving/taking heat
	###
	for obj in get_tree().get_nodes_in_group("WarmthGivers"):
		var true_position = tilemap.world_to_map( obj.get_position() )
		
		impulses.append( [true_position, 0.2, 1] )
		impulses.append( [true_position, 0.2, 2] )
	
	get_node("Semaphore").calculate_new_grid(impulses)

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
				new_color = Color(val[0], val[0], val[0])
			
			texture.set_pixel(x, y, new_color)
	
	texture.unlock()
	
	# Convert Image to ImageTexture
	var image_tex = ImageTexture.new()
	image_tex.create_from_image(texture)
	
	# Hand texture to the shader
	self.material.set_shader_param("grid_tex", image_tex)
	
	###
	# WATER
	###
	
	# Also ask the water node to draw the water
	get_node("/root/Node2D/DrawWater").draw_water(grid, MAP_SIZE)
	
	# Add texture to the sprite
#	var sprite = get_node("Sprite")
#	sprite.set_texture(image_tex)
