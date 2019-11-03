extends RigidBody2D

var turned_static = false

# onready var static_tree = preload("res://Bullets/TreeStatic.tscn")

func _ready():
	# create a unique collision shape for ourselves
	var my_col_shape = RectangleShape2D.new()
	my_col_shape.set_extents(Vector2(5, 2.5))
	$CollisionShape2D.shape = my_col_shape

func _integrate_forces(state):
	if turned_static:
		return
	
	var my_vec = state.transform[0]
	var target_vec = state.get_linear_velocity().normalized()
	
	# if we're moving in the opposite direction
	# we should "pretend" we're rotated 180 degrees
	# WAIT A MINUTE, we shouldn't have to do that if we rotate the tree correctly at the start!
#	if target_vec.x < 0:
#		my_vec.x *= -1
	
	# calculate angle between our current rotation and desired rotation (based on movement)
	var angle = acos( my_vec.dot(target_vec) )
	
	var perp_dot = my_vec.x*-target_vec.y + my_vec.y*target_vec.x
	var rotate_dir = 1
	if(perp_dot > 0):
		rotate_dir = -1

	# rotate the right amount
	state.set_angular_velocity(angle * rotate_dir)
	
	# Slowly scale the collision shape upwards
	# TO DO: Also scale the sprite
	var old_scale = $CollisionShape2D.shape.get_extents()
	var scale_speed = 1.1
	if old_scale.x <= 40:
		$Sprite.set_scale( $Sprite.get_scale() * scale_speed)
		$CollisionShape2D.shape.set_extents(old_scale * scale_speed)
	
	# Check for collisions
	if not turned_static:
		for i in range(state.get_contact_count()):
			var contact_pos = state.get_contact_local_position(i)

			fix_tree( contact_pos, state.get_contact_collider_object(i) )

func fix_tree(pos, body):
	print("Hit something")
	
	# TO DO:
	# Replace it with a STATIC body, with the same size
	
	# Quickly create a body to attach to
	var temp_body = StaticBody2D.new()
	
	temp_body.set_position(pos)
	get_node("/root/Node2D").add_child(temp_body)
	
	# Create joint
	var pin_joint = PinJoint2D.new()
	
	pin_joint.set_position( pos )
	
	pin_joint.set_node_a(self.get_path())
	pin_joint.set_node_b(temp_body.get_path())
	pin_joint.disable_collision = true
	pin_joint.bias = 0.2
	
	get_node("/root/Node2D").add_child(pin_joint)
	
	turned_static = true

func _on_Tree_body_entered(body):
	pass
	