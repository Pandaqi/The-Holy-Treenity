extends RigidBody2D

func _integrate_forces(state):
	# Check for collisions
	for i in range(state.get_contact_count()):
		var contact_pos = state.get_contact_local_position(i)
		var contact_body =  state.get_contact_collider_object(i) 
		var contact_normal  = state.get_contact_local_normal(i) 
	
		# If we find something, try to start a tree
		react_to_collision( contact_pos, contact_normal, contact_body )
	
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

func react_to_collision(pos, normal, body):
	pass