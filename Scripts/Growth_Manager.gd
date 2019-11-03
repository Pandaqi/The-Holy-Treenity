extends Node2D

var growth_timer

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
		
		var growth_speed = 1.05
		
		# increase the sprite size
		var old_scale = obj.get_node("Sprite").get_scale()
		obj.get_node("Sprite").set_scale( old_scale * growth_speed)
		
		# increase collision shape size
		var old_extents = obj.get_node("CollisionShape2D").shape.get_extents()
		obj.get_node("CollisionShape2D").shape.set_extents(old_extents * growth_speed)
		
		# offset these so that the anchor is at the right position
		var offset = obj.get_meta("anchor_offset")
		var half_growth = (old_scale * growth_speed)
		obj.get_node("CollisionShape2D").set_position( offset * half_growth )
		obj.get_node("Sprite").set_position( offset * half_growth)
		
		# if we're at maximum scale, remove us from the growing objects group
		if old_scale.x >= 2:
			obj.remove_from_group("GrowingObjects")
