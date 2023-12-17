extends "res://Scripts/BulletMain.gd"

var my_type = -1
var disabled = false

var should_enable = null

var TIMER = 0.0

func initialize(i):
	# save gun type
	my_type = i
	
	# Set weapon to correct frame
	get_node("Sprite").frame = i

func _integrate_forces(state):
	# call inherited function
	._integrate_forces(state)
	
	# if we should enable the gun again ...
	if should_enable != null:
		# place it back into the world
		state.set_linear_velocity(Vector2.ZERO)
		
		var xform = state.get_transform()
		xform.origin = should_enable
		state.set_transform( xform )
		
		var rand_vector = Vector2(rand_range(-1,1), rand_range(-1,1)).normalized()
		state.apply_central_impulse(rand_vector * 150)
		
		# set it to be enabled
		disabled = false
		
		# reset stuff
		get_node("Sprite").set_scale( Vector2(1,1) )
		TIMER = 0.0
		
		# display everything again
		get_node("Sprite").set_visible(true)
		
		# reset enable memory
		should_enable = null

func disable():
	disabled = true
	
	set_linear_velocity(Vector2.ZERO)
	
	get_node("Sprite").set_visible(false)

func enable(pos):
	should_enable = pos

func is_disabled():
	return disabled

func increase_timer(delta):
	TIMER += delta
	
	get_node("Sprite").set_scale( (1.0 - TIMER) * Vector2(1,1))

func times_up():
	return (TIMER >= 0.4)
	
func reset_timer():
	TIMER = 0.0
	
	get_node("Sprite").set_scale(Vector2(1,1))
	
	
