extends "res://Scripts/BulletMain.gd"

onready var static_log = preload("res://Bullets/LogStatic.tscn")
var turned_static = false

func _ready():
	# create a unique collision shape for ourselves
	var my_col_shape = RectangleShape2D.new()
	my_col_shape.set_extents(Vector2(5, 2))
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
	# Also scale the sprite
	var old_scale = $CollisionShape2D.shape.get_extents()
	var scale_speed = 1.075
	if old_scale.x <= 32:
		$Sprite.set_scale( $Sprite.get_scale() * scale_speed)
		$CollisionShape2D.shape.set_extents(old_scale * scale_speed)
	
	._integrate_forces(state)

func react_to_collision(pos, normal, body):
	# if we're not hitting the tilemap
	if not (body is TileMap or body is StaticBody2D):
		return
	
	print("Log hit something")
	
	turned_static = true
	
	# remove the old log
	self.queue_free()
	
	# Replace it with a STATIC body, with the same size/position/rotation
	var static_body = static_log.instance()

	static_body.set_position( pos )
	static_body.set_rotation( get_rotation() )

	# copy shape + sprite settings from rigid body
	static_body.get_node("CollisionShape2D").shape = get_node("CollisionShape2D").shape
	static_body.get_node("Sprite").set_scale( get_node("Sprite").get_scale() )

	# offset these so that the anchor is at the right position
	var offset = (get_position() - pos).rotated(-get_rotation())

	static_body.get_node("CollisionShape2D").set_position( offset)
	static_body.get_node("Sprite").set_position( offset)

	# add static body to the tree
	get_node("/root/Node2D").call_deferred("add_child", static_body)

	###
	# OLD CODE
	#  => Fixed trees by creating a joint
	#  => Worked, but wasn't ideal
	###
	
#	# Create joint
#	var pin_joint = PinJoint2D.new()
#
#	pin_joint.set_position( pos )
#
#	pin_joint.set_node_a(self.get_path())
#	pin_joint.set_node_b(temp_body.get_path())
#	pin_joint.disable_collision = true
#	pin_joint.bias = 0.2
#
#	get_node("/root/Node2D").add_child(pin_joint)

func _on_Tree_body_entered(body):
	pass
	