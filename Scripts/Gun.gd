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
	
	if should_enable != null:
		state.set_linear_velocity(Vector2.ZERO)
		
		var xform = state.get_transform()
		xform.origin = should_enable + Vector2.UP * 50
		state.set_transform( xform )
		
		disabled = false
		
		get_node("CollisionShape2D").call_deferred("set_disabled", false)
		get_node("Sprite").set_visible(true)
		
		should_enable = null

func disable():
	disabled = true
	
	set_linear_velocity(Vector2.ZERO)
	
	get_node("CollisionShape2D").disabled = true
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
	
	