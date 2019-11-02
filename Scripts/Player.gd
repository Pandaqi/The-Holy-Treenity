extends RigidBody2D

var control_table = {}
var control_num = -1
var player_num = -1

var VELOCITY = Vector2.ZERO
var MOVE_SPEED = 100
var JUMP_SPEED = 400

var MAX_SPEED = 200

onready var tree_bullet = preload("res://Bullets/Tree.tscn")

func _ready():
	set_controller(0, -1)

func set_controller(player_num, device_num):
	self.control_num = device_num
	self.player_num = player_num
	
	var actions = ["right", "left", "up", "down", "jump", "shoot"]
	for action in actions:
		 control_table[action] = action + str(control_num)
	
#	# Get player color from Global script
#	var my_col = Global.player_colors[player_num]
#	$TerrainCircle.modulate = my_col 
#	player_label.self_modulate = my_col
#
#	player_label.set_frame( player_num )

func get_action(action):
	return control_table[action]

func _integrate_forces(state):
	# Get input (full 360 degrees
	var horizontal = Input.get_action_strength( get_action("right") ) - Input.get_action_strength( get_action("left") )
	var vertical = Input.get_action_strength( get_action("down") ) - Input.get_action_strength( get_action("up") )
	
	# Movement: left + right
	var movement = Vector2(horizontal, vertical) * MOVE_SPEED
	
	VELOCITY = state.get_linear_velocity()
	
	# If we're holding the SHOOTING button ...
	if Input.is_action_pressed( get_action("shoot") ):
		# ... our input is redirected to aiming
		pass
	else:
		# Add our speed (horizontally)
		# But if we're over maximum speed, reduce!
		VELOCITY += Vector2(movement.x, 0)
		if abs(VELOCITY.x) > MAX_SPEED:
			VELOCITY.x = sign(VELOCITY.x) * MAX_SPEED
	
	# But if we just RELEASED the SHOOTING button ...
	if Input.is_action_just_released( get_action("shoot") ):
		# ... shoot in the direction we're aiming
		shoot(movement)
	
	# If we are standing on SOMETHING ...
	if $Area2D.get_overlapping_bodies().size() > 0:
		# ... allow jumping
		if Input.is_action_just_released( get_action("jump") ):
			VELOCITY += Vector2(0, -JUMP_SPEED)
	
	# DAMPING
	VELOCITY.x *= 0.6
	
	# Finally, set the velocity we calculated
	state.set_linear_velocity(VELOCITY)

func shoot(dir):
	# if we're not aiming, use the direction we're currently facing
	if dir == Vector2.ZERO:
		dir = transform[0]
	
	# create a new tree
	var new_tree = tree_bullet.instance()
	
	# rotate it to face the direction it's flying in
	var angle = acos( dir.normalized().dot(Vector2(1,0)) )
	new_tree.set_rotation(-angle)
	
	# position it just outside of our player rectangle
	var tree_size = new_tree.get_node("CollisionShape2D").shape.extents.x * 2
	var player_size = 30
	
	# TO DO: Take velocity into account
	#  => If we're going in the same direction, spawn the thing a little further
	#  => If we're going in the opposite direction, spawn it a little back
	
	# BUG:
	# Shooting sideways generates the wrong angles?
	
	new_tree.set_position( get_position() + dir.normalized() * (tree_size + player_size))
	
	# add impulse to tree
	new_tree.apply_central_impulse(dir * 10)
	
	# finally, add tree to the world
	get_node("/root/Node2D").call_deferred("add_child", new_tree)
