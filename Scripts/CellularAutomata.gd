extends Node

var generation_timer

onready var tilemap = get_node("/root/Node2D/TileMap")

func _ready():
	# Initialize timer
	generation_timer = Timer.new()
	add_child(generation_timer)
	
	generation_timer.connect("timeout",self,"new_generation") 
	generation_timer.set_one_shot(false)
	generation_timer.set_wait_time(0.5)
	generation_timer.start()

func new_generation():
	# players add pressure, for now
	var impulses = []
	for obj in get_tree().get_nodes_in_group("OxygenGivers"):
		impulses.append( [tilemap.world_to_map(obj.get_position()), 0.2] )
	
	for obj in get_tree().get_nodes_in_group("OxygenTakers"):
		impulses.append( [tilemap.world_to_map(obj.get_position()), -0.2] )
	
	get_node("Semaphore").calculate_new_grid(impulses)

func update_texture(grid, MAP_SIZE):
	# Display the grid inside a texture
	# Create an Image
	var texture = Image.new()
	texture.create(MAP_SIZE.x, MAP_SIZE.y , Image.FORMAT_RGB8, 0)
	texture.lock()
	
	# Fill the texture with the right values for each grid cell
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var val = grid[y][x]
			
			if val < 0:
				val = 0
			
			texture.set_pixel(x, y, Color(val, val, val))
	
	texture.unlock()
	
	# Convert Image to ImageTexture
	var image_tex = ImageTexture.new()
	image_tex.create_from_image(texture)
	
	# Hand texture to the shader
	self.material.set_shader_param("grid_tex", image_tex)
	
	# Add texture to the sprite
#	var sprite = get_node("Sprite")
#	sprite.set_texture(image_tex)
