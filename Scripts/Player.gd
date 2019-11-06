extends RigidBody2D

# Player variables for connecting device (controller, keyboard, etc.) to player
var control_table = {}
var control_num = -1
var player_num = -1

# Player variables for movement
var VELOCITY = Vector2.ZERO
var MOVE_SPEED = 100
var JUMP_SPEED = 500
var MAX_SPEED = 250

var last_known_movement = Vector2.ZERO

# Bullet scenes
onready var log_bullet = preload("res://Bullets/Log.tscn")
onready var sapling_bullet = preload("res://Bullets/Sapling.tscn")
onready var water_bullet = preload("res://Bullets/Water.tscn")
onready var fire_bolt = preload("res://Bullets/FireBolt.tscn")

# Scenes we will need often
onready var tilemap = get_node("/root/Node2D/TileMap")
onready var my_interface = get_node("Interface")

# Player variables for the environment => what kills you and what doesn't?
var HEALTH = 1.0
var OXYGEN = 1.0
var HEAT = 0.5
var THIRST = 1.0

var OXYGEN_MINIMUM = 0.25
var HEAT_MINUMUM = 0.25
var HEAT_MAXIMUM = 0.75
var THIRST_MINIMUM = 0.25

var cur_water = 0.0

# Player variables for its GUNS/BULLETS
var CUR_WEAPON = -1
var cur_weapon_obj = null

var SAPLINGS = 0
var AVAILABLE_WATER = 0.0

var last_shot = 0.0


var bodies_to_attract = []
var guns_in_range = []

var interface_positions = [Vector2(0,0), Vector2(1024,0), Vector2(0, 768), Vector2(1024,768)]
var interface_flips = [Vector2(1,1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]

var dead = false


func _ready():
	# trick to automatically set our default saplings
	update_saplings(10)

	# move/save our interface
	remove_child(my_interface)
	get_node("/root/Node2D/Interface").add_child(my_interface)

	# and set/update all our meters
	my_interface.get_node("HP/Sprite").modulate = Color(1.0, 0.0, 0.0)
	my_interface.get_node("OxygenLevels/Sprite").modulate = Color(0.0, 1.0, 1.0)
	my_interface.get_node("HeatLevels/Sprite").modulate = Color(1.0, 0.0, 1.0)
	my_interface.get_node("ThirstLevels/Sprite").modulate = Color(0.0, 0.0, 1.0)
	
	# update position of our interface
	my_interface.set_position( interface_positions[player_num] )
	
	# flip it, so everything is still displayed correcetly
	var my_flips = interface_flips[player_num]
	var cur_scale = my_interface.get_scale()
	my_interface.set_scale( Vector2(cur_scale.x * my_flips.x, cur_scale.y * my_flips.y) )
	
	# but flip the counter back, so it's still readable
	my_interface.get_node("SaplingCounter").set_scale( my_flips )

func set_controller(player_num, device_num):
	self.control_num = device_num
	self.player_num = player_num
	
	var actions = ["right", "left", "up", "down", "jump", "shoot"]
	for action in actions:
		 control_table[action] = action + str(device_num)
	
#	# Get player color from Global script
#	var my_col = Global.player_colors[player_num]
#	$TerrainCircle.modulate = my_col 
#	player_label.self_modulate = my_col
#
#	player_label.set_frame( player_num )

func _physics_process(delta):
	if dead:
		return
	
	# attract any bodies we want to attract
	for body in bodies_to_attract:
		var vec_to_player = transform.origin - body.transform.origin
		var dist_to_player = vec_to_player.length()
		var area_radius = 80.0 + 5.0 # some margin
		
		# reverse vector length based on distance to player 
		#  => the closer you get, the faster you're attracted
		body.apply_central_impulse(vec_to_player.normalized() * (area_radius - dist_to_player))
		
		# if we're close enough, collect this sapling!
		if dist_to_player < 20:
			# increment variable that keeps track of the number of saplings we have
			update_saplings(1)
			
			# play the sound effect
			play_sound("pickup")
			
			# delete this sapling from the world
			body.queue_free()
	
	# if we're not going at a high speed ... (we're staying relatively still)
	if abs(get_linear_velocity().x) < MAX_SPEED * 0.5:
		# switch guns if needed 
		for gun in guns_in_range:
			# if this gun is disabled (for whatever reason, but probably in use by another player)
			if gun.is_disabled():
				continue
			
			# otherwise, check distance to gun
			# if below the gun collision radius (30px), consider it within range
			var dist_to_gun = (transform.origin - gun.transform.origin).length()
			if dist_to_gun < 30:
				# increase the gun timer
				gun.increase_timer(delta)
				
				# if we've waited long enough, equip the gun!
				if gun.times_up():
					# equip the gun!
					equip_weapon(gun)
			else:
				gun.reset_timer()
	
	# poll the value of the cellular automata at this position
	var last_grid = get_node("/root/Node2D/CellularAutomata/Control/ColorRect").last_known_grid
	
	# if the grid exists ...
	if last_grid != null:
		# get the value at the player position
		var grid_pos = tilemap.world_to_map( get_position() )
		
		var wrap_x = int(grid_pos.x) % int(Global.MAP_SIZE.x)
		var wrap_y = int(grid_pos.y) % int(Global.MAP_SIZE.y)
		
		var val = last_grid[wrap_y][wrap_x]
		
		# using these values from the environment, update our statistics (oxygen, heat, water, etc.)
		check_environment(delta, val)

func equip_weapon(gun):
	# If we HAVE a current weapon ...
	if cur_weapon_obj != null:
		# ... throw it out (at the right position)
		cur_weapon_obj.enable( transform.origin )
	
	# Always play powerup sound
	play_sound("powerup")
	
	# And always reset last_shot
	last_shot = 0.0
	
	if gun != null:
		# set variables to right object and type
		CUR_WEAPON = gun.my_type
		cur_weapon_obj = gun
		
		# Display icon over our head
		get_node("WeaponIcon").frame = CUR_WEAPON
		get_node("WeaponIcon").set_visible(true)
		
		# Disable the gun object (visibility and collision shape)
		gun.disable()
	else:
		CUR_WEAPON = -1
		cur_weapon_obj = null
		
		get_node("WeaponIcon").set_visible(false)


func check_environment(delta, val):
	if val.size() == 0:
		return
	
	###
	# Check if our health should be reduced
	#
	# That should happen in these cases:
	#  => Too little oxygen in the air
	#  => Too little oxygen because we're drowning
	#  => Too hot
	#  => Too cold
	###
	var damage = 0
	
	var cur_oxygen = val[0]
	
	###
	# OXYGEN
	###
	# Transfer oxygen between us and the environment
	var interpolation_factor = 0.8
	OXYGEN = OXYGEN * interpolation_factor + val[0] * (1.0 - interpolation_factor)
	
	# if our current tile is almost completely filled with water
	# we're considered to be "drowning"
	cur_water = val[2]
	if cur_water == null: cur_water = 0.0
	if cur_water >= 0.8:
		OXYGEN = 0.0
	
	cur_oxygen = OXYGEN
	if cur_oxygen < OXYGEN_MINIMUM:
		damage += (OXYGEN_MINIMUM - cur_oxygen) * 0.1 * delta
		play_meter_anim("OxygenLevels", true)
	else:
		play_meter_anim("OxygenLevels", false)
	
	###
	# HEAT
	###
	# Transfer heat between us and the environment
	interpolation_factor = 0.8
	HEAT = HEAT * interpolation_factor + val[1] * (1.0 - interpolation_factor)
	
	# Check if our current heat should damage us
	var cur_heat = HEAT
	if cur_heat < HEAT_MINUMUM:
		damage += 0.01 * delta
		play_meter_anim("HeatLevels", true)
	elif cur_heat > HEAT_MAXIMUM:
		damage += 0.01 * delta
		play_meter_anim("HeatLevels", true)
	else:
		play_meter_anim("HeatLevels", false)
	
	###
	# WATER
	###
	var cur_thirst = 0
	
	# We "lose" a little water every frame
	cur_thirst -= 0.1 * delta
	
	# But if we're standing in water, we automatically drink it, to balance it out
	if cur_water > 0:
		cur_thirst += (cur_water + 0.1) * delta
	
	update_thirst(cur_thirst)
	
	if THIRST < THIRST_MINIMUM:
		damage += 0.01 * delta
		play_meter_anim("ThirstLevels", true)
	else:
		play_meter_anim("ThirstLevels", false)
	
	###
	# HP
	###
	
	# if we have suffered damage, update
	if damage > 0:
		update_health(-damage)
	
	###
	# (Visually) update our meters
	# Health meter is updated separately whenever health changes, as that might happen outside of this function
	###
	resize_meter("OxygenLevels", cur_oxygen) # update oxygen meter
	resize_meter("HeatLevels", cur_heat) # update heat meter

func update_water_gun(dw):
	AVAILABLE_WATER += dw
	
	if AVAILABLE_WATER < 0:
		AVAILABLE_WATER = 0

func update_saplings(ds):
	SAPLINGS += ds
	
	my_interface.get_node("SaplingCounter/SaplingCounterLabel").set_text( str(SAPLINGS) )

func update_thirst(dt):
	THIRST += dt
	
	resize_meter("ThirstLevels", THIRST)

func update_health(dh):
	HEALTH += dh
	
	resize_meter("HP", HEALTH)
	
	# if we have no health left, die!
	if HEALTH <= 0:
		# set this player to inactive
		dead = true
		
		# inform the game that a player died
		get_node("/root/Node2D").player_died()
		
		# TO DO: play an animation/particle effect to show we died
		
		# TO DO: remove player from the world
		# self.queue_free()

func play_meter_anim(node_name, out_of_bounds):
	var cur_node = my_interface.get_node(node_name)
	
	if out_of_bounds:
		cur_node.get_node("AnimationPlayer").play("Running Out")
	else:
		cur_node.get_node("AnimationPlayer").play("Within Bounds")

func resize_meter(node_name, val):
	var cur_node = my_interface.get_node(node_name).get_node("Sprite")
	var interpolation_factor = 0.85
	var old_size = cur_node.region_rect.size.x
	var new_size = 500 * val
	
	var interpolated_size = old_size * interpolation_factor + new_size * (1.0 - interpolation_factor)
	interpolated_size = clamp(interpolated_size, 0.0, 500.0)
	
	cur_node.region_rect.size.x = interpolated_size

func get_action(action):
	return control_table[action]


func _integrate_forces(state):
	if dead:
		return
	
	# Get input (full 360 degrees)
	var horizontal = Input.get_action_strength( get_action("right") ) - Input.get_action_strength( get_action("left") )
	var vertical = Input.get_action_strength( get_action("down") ) - Input.get_action_strength( get_action("up") )
	
	# Movement: left + right
	var movement = Vector2(horizontal, vertical) * MOVE_SPEED
	var normalized_movement = movement.normalized()
	
	VELOCITY = state.get_linear_velocity()
	
	var aiming_arrow = get_node("AimingArrow")
	# If we're holding the SHOOTING button ...
	if Input.is_action_pressed( get_action("shoot") ):
		# ... our input is redirected to aiming
		
		# TO DO: Create a sort of slow motion effect
		
		# Some guns shoot constantly: water gun, fire bolt gun, and the axe (it "chops" constantly)
		# For those guns, we run a timer to make sure there's some delay between "shots"
		var constant_shooting_weapons = [1,3,4]
		if CUR_WEAPON in constant_shooting_weapons:
			if last_shot <= 0.0:
				shoot(movement)
			else:
				last_shot -= 0.016
		
		# Create arrow that shows where you're aiming
		if normalized_movement.length() == 0:
			normalized_movement = last_known_movement.normalized()
		
		aiming_arrow.set_visible(true)
		aiming_arrow.transform[0] = normalized_movement
		aiming_arrow.transform[1] = Vector2(-normalized_movement.y, normalized_movement.x)
	else:
		# Add our speed (horizontally)
		# But if we're over maximum speed, reduce!
		VELOCITY += Vector2(movement.x, 0)
		if abs(VELOCITY.x) > MAX_SPEED:
			VELOCITY.x = sign(VELOCITY.x) * MAX_SPEED
			
		last_known_movement = VELOCITY
		
		# Hide the aiming arrow
		aiming_arrow.set_visible(false)
	
	# But if we just RELEASED the SHOOTING button ...
	if Input.is_action_just_released( get_action("shoot") ):
		# ... shoot in the direction we're aiming
		shoot(movement)
	
	# Save which body/bodies are below us
	var bodies_below_us = $Area2D.get_overlapping_bodies()
	
	# If we are standing on SOMETHING ...
	var standing_on_ice = false
	if bodies_below_us.size() > 0:
		# ... allow jumping
		if Input.is_action_just_released( get_action("jump") ):
			play_sound("jump")
			
			VELOCITY += Vector2(0, -JUMP_SPEED)
	
		for body in bodies_below_us:
			if body.is_in_group("FreezedBlocks"):
				standing_on_ice = true
				break
	
	# DAMPING
	var damp_factor = 0.6
	if standing_on_ice: damp_factor = 0.99
	VELOCITY.x *= damp_factor
	
	# Check if we should play movement sound effects/animations
	var sound_to_play = null
	
	# if we're in the air, play no sound?
	if standing_on_ice:
		sound_to_play = "ice_running"
	elif bodies_below_us.size() == 0:
		sound_to_play = null
	elif abs(VELOCITY.x) > 50:
		if cur_water > 0.1:
			sound_to_play = "puddle_running"
		else:
			sound_to_play = "dirt_running"
	
	play_footstep_sound(sound_to_play)
	
	# Finally, set the velocity we calculated
	state.set_linear_velocity(VELOCITY)
	
	level_wrap(state)

func level_wrap(state):
	# LEVEL WRAPPING
	var xform = state.get_transform()
	var cur_pos = xform.origin
	
	# Wrap values => if there WAS a change, update position
	# (We also add the map size, because fmod doesn't work with negative floats)
	var wrap_x = fmod(cur_pos.x + Global.MAP_SIZE.x*32, Global.MAP_SIZE.x*32)
	var wrap_y = fmod(cur_pos.y + Global.MAP_SIZE.y*32, Global.MAP_SIZE.y*32)
	if Vector2(wrap_x - cur_pos.x, wrap_y - cur_pos.y).length() > 0.1:
		xform.origin = Vector2(wrap_x, wrap_y)
		state.set_transform( xform )
	

func shoot(dir):
	# If we don't have a weapon, we can't shoot!
	if CUR_WEAPON < 0:
		return
	
	# if we're not aiming, use the last direction we walked into
	if dir == Vector2.ZERO:
		dir = last_known_movement
	
	# normalize the shooting dir
	dir = dir.normalized()
	
	# start variable for new bullet
	var new_bullet = null
	var impulse_speed = 300
	
	# reset the last shot variable
	last_shot = 0.4
	
	###
	# SAPLING BULLET
	###
	if CUR_WEAPON == 0:
		# If we don't have saplings to shoot, don't do anything!
		if SAPLINGS <= 0:
			return
		
		new_bullet = sapling_bullet.instance()
		
		new_bullet.transform[0] = dir
		new_bullet.transform[1] = Vector2(-dir.y, dir.x)
		new_bullet.transform.origin = transform.origin
		
		new_bullet.add_collision_exception_with(self)
		
		# position it just outside of our player rectangle
#		var tree_size = new_bullet.get_node("CollisionShape2D").shape.height * 2
#		var player_size = 15
#
#		new_bullet.set_position( get_position() + dir * (tree_size + player_size))
		
		# add impulse to sapling
		new_bullet.apply_central_impulse(dir * impulse_speed)
		
		# update our sapling counter
		update_saplings(-1)
	
	###
	# WATER GUN
	###
	elif CUR_WEAPON == 1:
		if AVAILABLE_WATER <= 0:
			return
		
		new_bullet = water_bullet.instance()
		
		new_bullet.transform[0] = dir
		new_bullet.transform[1] = Vector2(-dir.y, dir.x)
		new_bullet.transform.origin = transform.origin
		
		new_bullet.add_collision_exception_with(self)
		
		# add impulse to sapling
		new_bullet.apply_central_impulse(dir * impulse_speed)
		
		# update our sapling counter
		update_water_gun(-1.0)
	
	###
	# TREE/LOG BULLET
	###
	elif CUR_WEAPON == 2:
		# create a new bullet
		new_bullet = log_bullet.instance()
		
		# rotate it to face the direction it's flying in
		new_bullet.transform[0] = dir
		new_bullet.transform[1] = Vector2(-dir.y, dir.x)
		new_bullet.transform.origin = transform.origin
		
		# position it just outside of our player rectangle
		# TO DO: Make this better 
		# => perhaps create collision exception with player, only for the first few seconds?
		var tree_size = new_bullet.get_node("CollisionShape2D").shape.extents.x * 2
		var player_size = 15
		
		new_bullet.set_position( get_position() + dir * (tree_size + player_size))
		
		# add impulse to log
		new_bullet.apply_central_impulse(dir * impulse_speed)
	
	###
	# FIRE BOLT BULLET
	###
	elif CUR_WEAPON == 3:
		# create a new bullet
		new_bullet = fire_bolt.instance()
		
		# don't allow it to hit ourselves
		new_bullet.add_collision_exception_with(self)
		
		# position it
		new_bullet.transform.origin = transform.origin
		
		# add impulse to bolt
		new_bullet.apply_central_impulse(dir * impulse_speed * 2)
	
	###
	# AXE
	###
	elif CUR_WEAPON == 4:
		var ca = get_node("/root/Node2D/CellularAutomata/Control/ColorRect")
		
		# loop through all bodies we are touching
		# TO DO: Only affect bodies in the direction we're aiming?
		var bodies = $AttractArea.get_overlapping_bodies()
		for body in bodies:
			# check if body is in the direction we're aiming
			# if not, don't consider it
			var diff_vec = (body.transform.origin - transform.origin).normalized()
			var dot = dir.dot(diff_vec)
			if abs(acos(dot)) > 0.5*PI:
				continue
			
			# if it's a tree or a log ...
			if body.is_in_group("OxygenGivers"):
				# ... damage it (until it will eventually break)
				body.damage(-0.35)
			
			# if it's an ice block ...
			elif body.is_in_group("FreezedBlocks"):
				# save an impulse that unfreezes this block
				# NOTE: This simply heats the block ... maybe there's a better way
				#       (like, un-null a value?)
				ca.saved_impulses.append( [ body.get_position(), 1.0, 1] )
				
	
	if new_bullet != null:
		# finally, add this particular bullet to the world
		get_node("/root/Node2D/TreesLayer").call_deferred("add_child", new_bullet)
	
	# play sound effect
	play_sound("shoot")

# What's the difference between play_sound and play_footstep_sound?
#  => play_sound will play any sound, overriding the previous sound, and randomly changing pitch
#  => play_footstep_sound will only play a new sound if it's not already playing, and doesn't change pitch

func play_footstep_sound(file_name):
	var player = $FootstepPlayer
	
	if file_name == null:
		player.stop()
		return
	
	if not player.is_playing():
		player.stream = load("res://Sound/" + str(file_name) + ".wav")
		# player.pitch_scale = rand_range(0.8, 1.2)
		player.play()

func play_sound(file_name):
	var player = $AudioPlayer
	
	player.stream = load("res://Sound/" + str(file_name) + ".wav")
	player.pitch_scale = rand_range(0.8, 1.2)
	player.play()

func _on_AttractArea_body_entered(body):
	if body.is_in_group("Saplings"):
		bodies_to_attract.append(body)
	elif body.is_in_group("Guns"):
		guns_in_range.append(body)

func _on_AttractArea_body_exited(body):
	if body.is_in_group("Saplings"):
		bodies_to_attract.erase(body)
	elif body.is_in_group("Guns"):
		guns_in_range.erase(body)
