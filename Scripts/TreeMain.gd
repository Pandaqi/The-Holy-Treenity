extends StaticBody2D

var on_fire = false
var fire_scene = preload("res://Effects/Fire.tscn")
var fire_effect = null

var sapling_scene = preload("res://Bullets/SaplingStatic.tscn")
var sapling_timer = null
var time_between_saplings = Vector2(20.0, 50.0)
var param = {}

var HEALTH = 1.0

func _ready():
	# set some parameters, grabbing the parameter object from the main node
	param = get_node("/root/Node2D").simulation_parameters
	time_between_saplings = Vector2(param.tree_min_seed_time, param.tree_max_seed_time)

func drop_sapling():
	# drop actual sapling (which you can pick up with the player)
	var new_sapling = sapling_scene.instance()
	
	# disallow collision with its own tree
	# new_sapling.add_collision_exception_with(self)
	
	# place sapling at center position, slight displaced
	new_sapling.transform.origin = get_transformed_position() + Vector2(rand_range(0.2, -0.2), rand_range(0.2, -0.2))
	
	# add sapling to the world
	get_node("/root/Node2D").call_deferred("add_child", new_sapling)
	
	print("Tree should drop a sapling")
	
	# set new wait time
	if sapling_timer != null:
		sapling_timer.set_wait_time(rand_range(time_between_saplings.x, time_between_saplings.y))

func damage(dh, good_damage = false):
	HEALTH += dh
	
	if HEALTH <= 0:
		if fire_effect != null:
			fire_effect.queue_free()
			fire_effect = null
		
		if good_damage:
			# if we died by chopping ("good damage"), drop saplings!
			var rand_num = randi() % param.tree_seed_drop_amount + 1
			for i in range(rand_num):
				drop_sapling()
		
		optional_death_calls()
		
		queue_free()

func optional_death_calls():
	pass

func get_oxygen_level():
	return param.tree_oxygen_expelled

func is_on_fire():
	return on_fire

func get_transformed_position():
	return ( get_position() + transform[0] * get_node("Sprite").get_scale().x * 32 )

func get_fire_position():
	return Vector2(get_node("Sprite").get_scale().x * 32, 0)

func start_fire():
	# if we're already on fire, don't start a new one
	if on_fire:
		return
	
	fire_effect = fire_scene.instance()
	fire_effect.set_position( get_fire_position() )
	add_child(fire_effect)
	
	on_fire = true

func extinguish_fire():
	fire_effect.queue_free()
	fire_effect = null
	
	# reset damage => just a bit nicer to the player
	HEALTH = 1.0
	
	on_fire = false