extends RigidBody2D

onready var static_tree = preload("res://Bullets/TreeStatic.tscn")

func _integrate_forces(state):
	# Check for collisions
	for i in range(state.get_contact_count()):
		var contact_pos = state.get_contact_local_position(i)
		var contact_body =  state.get_contact_collider_object(i) 
		var contact_normal  = state.get_contact_local_normal(i) 
	
		# If we find something, try to start a tree
		start_tree( contact_pos, contact_normal, contact_body )
	
	level_wrap(state)

func level_wrap(state):
	# LEVEL WRAPPING
	var xform = state.get_transform()
	var cur_pos = xform.origin
	
	# Wrap values => if there WAS a change, update position
	# (We also add the map size, because fmod doesn't work with negative floats)
	var wrap_x = fmod(cur_pos.x + Global.MAP_SIZE.x*32, Global.MAP_SIZE.x*32)
	var wrap_y = fmod(cur_pos.y + Global.MAP_SIZE.y*32, Global.MAP_SIZE.y*32)
	if Vector2(wrap_x - cur_pos.x, wrap_y - cur_pos.y).length() > 0.1:
		xform.origin = Vector2(wrap_x, wrap_y)
		state.set_transform( xform )

func start_tree(pos, normal, body):
	# if we're not hitting the tilemap, get out of here
	if not body is TileMap:
		return
	
	print("Sapling hit something")
	
	# Replace it with a STATIC body, with the same size/position/rotation
	var static_body = static_tree.instance()
	
	static_body.set_position( pos )
	
	# Get collision normal, use it to calculate how the body should rotate
	var rotation_from_normal = acos(normal.dot(Vector2(1,0)))
	static_body.set_rotation(-rotation_from_normal)
	
	# Give this body a unique shape to scale
	var unique_shape = RectangleShape2D.new()
	unique_shape.set_extents(Vector2(5, 2.5))
	static_body.get_node("CollisionShape2D").shape = unique_shape
	
	# Offset shape and sprite properly
	static_body.get_node("CollisionShape2D").set_position(Vector2(2.5, 0))
	static_body.get_node("Sprite").offset = Vector2(0, -32)
	
	# add static body to the tree
	get_node("/root/Node2D").call_deferred("add_child", static_body)
	
	# finally, remove this bullet
	self.queue_free()