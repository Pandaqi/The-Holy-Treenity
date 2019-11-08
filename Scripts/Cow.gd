extends "res://Scripts/BulletMain.gd"

var walk_timer = null
var walk_dir = 0

func _ready():
	# Initialize timer
	walk_timer = Timer.new()
	add_child(walk_timer)
	
	walk_timer.connect("timeout", self, "switch_walk_dir") 
	walk_timer.set_one_shot(false)
	walk_timer.set_wait_time(rand_range(5.0, 10.0))
	walk_timer.start()
	
	# Start in a random direction
	switch_walk_dir()

func switch_walk_dir():
	if walk_dir == 0:
		walk_dir = sign(rand_range(-1,1))
	else:
		walk_dir *= -1
		
		if rand_range(0,1) <= 0.5:
			walk_dir = 0
	
	if walk_dir < 0:
		get_node("Sprite").scale.x = -0.5
	else:
		get_node("Sprite").scale.x = 0.5

func _integrate_forces(state):
	# walk in the direction we've chosen
	# (but maintain Y-velocity to get gravity and stuff working)
	var old_vel = state.get_linear_velocity()
	old_vel.x = (old_vel.x + walk_dir)
	if abs(old_vel.x) > 100:
		old_vel.x = sign(old_vel.x) * 100.0
	
	state.set_linear_velocity(old_vel)
	
	# call _integrate_forces on parent script (BulletMain.gd, mostly handles level wrapping)
	._integrate_forces(state)
