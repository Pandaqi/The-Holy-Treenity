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

var PLAYER_SCALE = 0.75

var last_known_movement = Vector2(1,0)

# Bullet scenes
onready var log_bullet = preload("res://Bullets/Log.tscn")
onready var sapling_bullet = preload("res://Bullets/Sapling.tscn")
onready var water_bullet = preload("res://Bullets/Water.tscn")
onready var fire_bolt = preload("res://Bullets/FireBolt.tscn")

# Scenes we will need often
onready var tilemap = get_node("/root/Node2D/TileMap")
onready var my_interface = get_node("Interface")

onready var ca = get_node("/root/Node2D/CellularAutomata/Control/ColorRect")

# Player variables for the environment => what kills you and what doesn't?
var HEALTH = 1.0
var OXYGEN = 1.0
var HEAT = 0.5
var THIRST = 1.0
var cur_water = 0.0

# Player variables for its GUNS/BULLETS
var CUR_WEAPON = -1
var cur_weapon_obj = null

var SAPLINGS = 0
var AVAILABLE_WATER = 0.0

export (int) var starting_saplings = 5

var last_shot = 0.0
var weapon_swap = false
var constant_shooting_weapons = [1,3,4]


var bodies_to_attract = []
var guns_in_range = []

var interface_positions = [Vector2(0,0), Vector2(1024,0), Vector2(0, 768), Vector2(1024,768)]
var interface_flips = [Vector2(1,1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
var player_colors = [Color(1,0.5,0.5), Color(0.5,0.5,1), Color(1,0.5,1), Color(0.5, 1, 1)]

var dead = false

var param = {}


func _ready():
	# trick to automatically set our default saplings
	update_saplings(starting_saplings)

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
	my_interface.get_node("PlayerLabel").set_scale( 0.5 * my_flips )
	my_interface.get_node("PlayerLabel").frame = player_num
	
	# and flip the icons
	var icons = ["HP_Icon", "Oxygen_Icon", "Heat_Icon", "Thirst_Icon"]
	for icon in icons:
		var cur_node = my_interface.get_node(icon)
		var old_scale = cur_node.get_scale()
		cur_node.set_scale( Vector2(old_scale.x * my_flips.x, old_scale.y * my_flips.y) )
	
	# color the player label in the interface
	my_interface.get_node("PlayerLabel").modulate = player_colors[player_num]
	
	# set outline shader to the correct color
	var dup_shader = get_node("WeaponIcon").material.duplicate(true)
	dup_shader.set_shader_param("outline_color", player_colors[player_num].darkened(0.3))
	get_node("WeaponIcon").material = dup_shader
	
	# set frame + color for player label
	get_node("PlayerLabel").frame = player_num
	get_node("PlayerLabel").modulate = player_colors[player_num]
	
	# Grab simulation parameters from main node
	param = get_node("/root/Node2D").simulation_parameters

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
			if dist_to_gun < 40:
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

func equip_weapon(gun, swap = false):
	# If we HAVE a current weapon ...
	if not swap and cur_weapon_obj != null:
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
		get_node("PlayerLabel").set_visible(false)
		
		# Disable the gun object (visibility and collision shape)
		gun.disable()
	else:
		CUR_WEAPON = -1
		cur_weapon_obj = null
		
		get_node("WeaponIcon").set_visible(false)
		get_node("PlayerLabel").set_visible(true)


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
	var interpolation_factor = 0.99
	OXYGEN = OXYGEN * interpolation_factor + val[0] * (1.0 - interpolation_factor)
	
	# if our current tile is almost completely filled with water
	# we're considered to be "drowning"
	cur_water = val[2]
	if cur_water == null: cur_water = 0.0
	if cur_water >= param.player_drown_level:
		OXYGEN = 0.0
	
	cur_oxygen = OXYGEN
	if cur_oxygen < param.player_oxygen_minimum:
		damage += (param.player_oxygen_minimum - cur_oxygen) * 0.1 * delta
		play_meter_anim("OxygenLevels", true)
	else:
		play_meter_anim("OxygenLevels", false)
	
	###
	# HEAT
	###
	# Transfer heat between us and the environment
	interpolation_factor = 0.99
	HEAT = HEAT * interpolation_factor + val[1] * (1.0 - interpolation_factor)
	
	# Check if our current heat should damage us
	var cur_heat = HEAT
	if cur_heat < param.player_heat_minimum:
		damage += 0.01 * delta
		play_meter_anim("HeatLevels", true)
	elif cur_heat > param.player_heat_maximum:
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
		cur_thirst += (param.player_drink_factor*cur_water + 0.1) * delta
		
		# don't drink more than we need/can have!
		if THIRST + cur_thirst > 1.0:
			cur_thirst = 1.0 - THIRST
		
		# and of course, use a saved impulse to change water in the CA system
		ca.saved_impulses.append( [ get_position(), cur_thirst, 2] )
	
	update_thirst(cur_thirst)
	
	if THIRST < param.player_water_minimum:
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
	resize_meter("OxygenLevels", OXYGEN) # update oxygen meter
	resize_meter("HeatLevels", HEAT) # update heat meter

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
	
	# if we're running out of health, give feedback to player
	if HEALTH <= 0.2:
		get_node("AnimationPlayer").play("Almost Dying")
	
	# if we have no health left, die!
	if HEALTH <= 0.0:
		# set this player to inactive
		dead = true
		
		# remove ourselves from the player group
		remove_from_group("Players")
		
		# play death sound effect
		play_sound("death_sound")
		
		# throw out our weapon
		equip_weapon(null)
		
		# play an animation to show we died
		get_node("AnimationPlayer").stop()
		get_node("SpritesheetPlayer").play("Dying")
		
		# TO DO: Also add particles??

func death_animation_done():
	# inform the game that a player died
	get_node("/root/Node2D").player_died()
	
	# grey out the interface
	# and stop any animations that might be running
	my_interface.modulate = Color(0.4, 0.4, 0.4)
	play_meter_anim("OxygenLevels", false)
	play_meter_anim("HeatLevels", false)
	play_meter_anim("ThirstLevels", false)

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
		
		# TO DO: Create a sort of slow motion effect??
		
		# Some guns shoot constantly: water gun, fire bolt gun, and the axe (it "chops" constantly)
		# For those guns, we run a timer to make sure there's some delay between "shots"
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
		
		# Save our last known velocity, but only if we actually moved
		if VELOCITY.length() > 0.1:
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
	if bodies_below_us.size() > 1:
		# ... allow jumping
		if Input.is_action_just_released( get_action("jump") ):
			play_sound("jump")
			
			VELOCITY += Vector2(0, -JUMP_SPEED)
	
		for body in bodies_below_us:
			if body == self:
				continue
			
			# if we haven't just swapped ...
			# and we're standing on a player ...
			# after falling down ...
			# that counts as a weapon swap
			elif not weapon_swap:
				if body.is_in_group("Players") and abs(VELOCITY.y) >= 0:
					swap_weapons(body)
					break
			
			# if the body is ice, well, remember we're standing on ice
			elif body.is_in_group("FreezedBlocks"):
				standing_on_ice = true
	else:
		weapon_swap = false
	
	# DAMPING
	var damp_factor = 0.6
	if standing_on_ice: damp_factor = 0.99
	VELOCITY.x *= damp_factor
	
	# Check if we should play movement sound effects/animations
	var sound_to_play = null
	var animation_to_play = "Idle"
	
	# if we have the axe AND we're pressing the chopchop button
	if CUR_WEAPON == 4 and Input.is_action_pressed( get_action("shoot") ):
		animation_to_play = "Chopping"
		
	# if we're standing on ice, play the ice sound
	if standing_on_ice:
		sound_to_play = "ice_running"
	
	# if we're in the air ...
	# yeah ... we hit ourselves with the area, that's why there's always a single body
	# still need to find a cleaner way to solve this in Godot
	elif bodies_below_us.size() <= 1:
		
		# if we're in the air, play no sound?
		sound_to_play = null
		
		# play the "floating/jumping" animation
		animation_to_play = "Jumping"
	
	# if we're on the ground and making some speed ...
	elif abs(VELOCITY.x) > 30:
		animation_to_play = "Running"
		if cur_water > 0.1:
			sound_to_play = "puddle_running"
		else:
			sound_to_play = "dirt_running"
	
	# make player face the right direction
	if VELOCITY.x > 0:
		get_node("Sprite").set_scale( Vector2(-1,1) * PLAYER_SCALE )
	else:
		get_node("Sprite").set_scale( Vector2(1,1) * PLAYER_SCALE)
	
	play_footstep_sound(sound_to_play)
	play_anim(animation_to_play)
	
	# Finally, set the velocity we calculated
	state.set_linear_velocity(VELOCITY)
	
	# Wrap around the world
	level_wrap(state)

func level_wrap(state):
	# LEVEL WRAPPING
	var xform = state.get_transform()
	var cur_pos = xform.origin
	
	# Wrap values => if there WAS a change, update position
	# (We also add the map size, because fmod doesn't work with negative floats)
	var wrap_x = fmod(cur_pos.x + Global.MAP_SIZE.x*32, Global.MAP_SIZE.x*32)
	var wrap_y = fmod(cur_pos.y + Global.MAP_SIZE.y*32, Global.MAP_SIZE.y*32)
	
	# for safety: make sure we never get NaN values or anything outside of level bounds
	if wrap_x < 0 or wrap_x >= Global.MAP_SIZE.x * 32:
		wrap_x = cur_pos.x
	
	if wrap_y < 0 or wrap_y >= Global.MAP_SIZE.y * 32:
		wrap_y = cur_pos.y
	
	if Vector2(wrap_x - cur_pos.x, wrap_y - cur_pos.y).length() > 0.1:
		xform.origin = Vector2(wrap_x, wrap_y)
		state.set_transform( xform )

func play_anim(anim_name):
	if anim_name == null:
		$SpritesheetPlayer.stop()
		return
	
	$SpritesheetPlayer.play(anim_name)

func swap_weapons(body):
	var other_weapon = body.cur_weapon_obj
	
	# give MY weapon to the other player
	body.equip_weapon(cur_weapon_obj, true)
	
	# and now equip THEIR weapon, which we saved
	equip_weapon(other_weapon, true)
	
	weapon_swap = true

func shoot(dir):
	# If we don't have a weapon, we can't shoot!
	if CUR_WEAPON < 0:
		return
	
	# if we're not aiming, use the last direction we walked into
	if dir == Vector2.ZERO:
		dir = last_known_movement
	
	# if direction is still zero, return
	if dir == Vector2.ZERO:
		print("ERROR! Direction was zero!")
		return
	
	# normalize the shooting dir
	dir = dir.normalized()
	
	# start variable for new bullet
	var new_bullet = null
	var impulse_speed = 300
	
	# reset the last shot variable
	last_shot = 0.2
	
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
		
		# update our water level
		update_water_gun(-1.0 * param.water_gun_shoot_amount)
	
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
		var player_size = 25
		new_bullet.set_position( get_position() + dir * player_size)
		
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
				body.damage(-0.35, true)
			
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
