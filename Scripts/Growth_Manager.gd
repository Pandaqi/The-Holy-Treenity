extends Node2D

var growth_timer

onready var cellular_automata = get_node("/root/Node2D/CellularAutomata/Control/ColorRect")

# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize timer
	growth_timer = Timer.new()
	add_child(growth_timer)
	
	growth_timer.connect("timeout", self, "grow") 
	growth_timer.set_one_shot(false)
	growth_timer.set_wait_time(0.5)
	growth_timer.start()

func grow():
	# loop through all objects that should grow
	for obj in get_tree().get_nodes_in_group("GrowingObjects"):
		
		# check how fast we should grow
		# (based on water level)
		var water_level = cellular_automata.check_water_level( obj.get_position() )
		var growth_speed = 1.05 + water_level * 0.35
		
		# if there's not enough carbon, we shrink again
		# TO DO
		
		# increase the sprite size
		var old_scale = obj.get_node("Sprite").get_scale()
		var new_scale = clamp(old_scale.x * growth_speed, 0.0, 1.0)
		obj.get_node("Sprite").set_scale( new_scale * Vector2(1,1) )
		
		# increase collision shape size
		var col_shape = obj.get_node("CollisionShape2D")
		var old_extents = col_shape.shape.get_extents()
		col_shape.shape.set_extents(old_extents * growth_speed)
		
		var new_pos = col_shape.get_position() 
		new_pos.x = (old_extents.x * growth_speed)
		
		col_shape.set_position( new_pos )
		
		# if we're at maximum scale, remove us from the growing objects group
		if new_scale >= 1:
			obj.remove_from_group("GrowingObjects")
