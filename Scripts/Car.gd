extends "res://Scripts/BulletMain.gd"

var walk_dir

func _ready():
	# pick a random direction (zero is not allowed)
	walk_dir = sign(rand_range(-1, 1))
	
	# flip sprite based on direction
	if walk_dir < 0:
		get_node("Sprite").scale.x *= -1

		# change light positions
		# NOTE: Eventually decided to disable the lights
		var old_front_pos = get_node("FrontLight").get_position()
		get_node("FrontLight").set_position(get_node("BackLight").get_position())
		get_node("BackLight").set_position(old_front_pos)


func _integrate_forces(state):
	# walk in the direction we've chosen
	# (but maintain Y-velocity to get gravity and stuff working)
	var old_vel = state.get_linear_velocity()
	old_vel.x = (old_vel.x + walk_dir * 5)
	if abs(old_vel.x) > 100:
		old_vel.x = sign(old_vel.x) * 100.0
	
	state.set_linear_velocity(old_vel)
	
	# loop through overlapping bodies
	var bodies = $Area2D.get_overlapping_bodies()
	for body in bodies:
		# if it's a log or a tree, quikckly deal damage
		if body.is_in_group("Logs") or body.is_in_group("Trees"):
			body.damage(-0.1)
	
	# call _integrate_forces on parent script (BulletMain.gd, mostly handles level wrapping)
	._integrate_forces(state)
