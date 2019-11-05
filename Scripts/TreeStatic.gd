extends StaticBody2D

var on_fire = false
var fire_scene = preload("res://Effects/Fire.tscn")
var fire_effect = null

var sapling_scene = preload("res://Bullets/SaplingStatic.tscn")

var HEALTH = 1.0

var sapling_timer
var time_between_saplings = Vector2(5.0, 20.0)

func _ready():
	# Initialize timer
	sapling_timer = Timer.new()
	add_child(sapling_timer)
	
	sapling_timer.connect("timeout", self, "drop_sapling") 
	sapling_timer.set_one_shot(false)
	sapling_timer.set_wait_time(rand_range(time_between_saplings.x, time_between_saplings.y))
	sapling_timer.start()

func drop_sapling():
	# drop actual sapling (which you can pick up with the player)
	var new_sapling = sapling_scene.instance()
	
	# place sapling at center position, slight displaced
	new_sapling.transform.origin = get_transformed_position() + Vector2(rand_range(0.2, -0.2), rand_range(0.2, -0.2))
	
	# add sapling to the world
	get_node("/root/Node2D").call_deferred("add_child", new_sapling)
	
	print("Tree should drop a sapling")
	
	# set new wait time
	sapling_timer.set_wait_time(rand_range(time_between_saplings.x, time_between_saplings.y))

func damage(dh):
	HEALTH += dh
	
	if HEALTH <= 0:
		if fire_effect != null:
			fire_effect.queue_free()
		
		queue_free()

func is_on_fire():
	return on_fire

func get_transformed_position():
	return ( get_position() + get_transform().x * get_node("Sprite").get_scale().x * 32 )

func start_fire():
	fire_effect = fire_scene.instance()
	fire_effect.set_position( get_transformed_position() )
	get_node("/root/Node2D").add_child(fire_effect)
	
	on_fire = true

func extinguish_fire():
	fire_effect.queue_free()
	fire_effect = null
	
	on_fire = false

