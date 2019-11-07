extends StaticBody2D

var on_fire = false
var fire_scene = preload("res://Effects/Fire.tscn")
var fire_effect = null

var sapling_scene = preload("res://Bullets/SaplingStatic.tscn")
var sapling_timer = null
var time_between_saplings = Vector2(10.0, 40.0)

var HEALTH = 1.0

func drop_sapling():
	# drop actual sapling (which you can pick up with the player)
	var new_sapling = sapling_scene.instance()
	
	# place sapling at center position, slight displaced
	new_sapling.transform.origin = get_transformed_position() + Vector2(rand_range(0.2, -0.2), rand_range(0.2, -0.2))
	
	# add sapling to the world
	get_node("/root/Node2D").call_deferred("add_child", new_sapling)
	
	print("Tree should drop a sapling")
	
	# set new wait time
	if sapling_timer != null:
		sapling_timer.set_wait_time(rand_range(time_between_saplings.x, time_between_saplings.y))

func damage(dh):
	HEALTH += dh
	
	if HEALTH <= 0:
		if fire_effect != null:
			fire_effect.queue_free()
		else:
			# if we didn't die by fire, drop saplings!
			var rand_num = randi() % 4 + 1
			for i in range(rand_num):
				drop_sapling()
		
		queue_free()

func get_oxygen_level():
	return 0.8

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