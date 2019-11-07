extends Node

# Variables for controlling the separate thread (on which the algorithm runs)
var counter = 0
var mutex
var semaphore
var thread
var exit_thread = false

# Variables for storing the grid and world map
var grid = []
var MAP_SIZE

# Variables for the algorithm itself (like how often it updates per second)
var UPDATE_SPEED = 1.0

# Water properties
var MaxMass = 1.0 # The normal, un-pressurized mass of a full water cell
var MaxCompress = 0.02 # How much excess water a cell can store, compared to the cell above it
var MinMass = 0.0001  # Ignore cells that are almost dry
var MinFlow = 0.01 # ?? Every time we flow water, flow at least this value
var MaxSpeed = 1.0 # ??

var water_in_sky = 10.0 # start with a LOT of water
var water_evaporated = 0.0
var raining = false

var freezed_blocks = []

var average_temp = 0.0

var param = {}

# The thread will start here.
func _ready():
	
	# Grab simulation parameters from the main node
	param = get_node("/root/Node2D").simulation_parameters
	
	MAP_SIZE = Global.MAP_SIZE
	
	###
	# Grid creation
	###
	
	randomize()
	
	# Create a random 2D grid (values between 0 and 1)
	grid.resize(MAP_SIZE.y)
	
	var tilemap = get_node("/root/Node2D/TileMap")
	
	for y in range(MAP_SIZE.y):
		grid[y] = []
		grid[y].resize(MAP_SIZE.x)
		for x in range(MAP_SIZE.x):
			# What do these values mean?
			#  Index 0 =  oxygen levels (the inverse is the carbon level)
			#  Index 1 =  temperature levels
			#  Index 2 =  water levels
			grid[y][x] = [rand_range(0.3,0.6), rand_range(0.3,0.6), 0]
			
			# Check if there is a block on this tile
			if tilemap.get_cell(x, y) > -1:
				# If so, make this block impenetrable
				grid[y][x] = []
	
	###
	# Thread stuff
	###
	
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	exit_thread = false
	
	thread = Thread.new()
	thread.start(self, "_thread_function")
	
	###
	# Perform single grid calculation
	### 
	calculate_new_grid([])

func _thread_function(userdata):
	while true:
		semaphore.wait() # Wait until posted.
	
		###
		# Thread stuff
		###
		
		mutex.lock()
		var should_exit = exit_thread # Protect with Mutex.
		mutex.unlock()
	
		if should_exit:
			break
		
		###
		# Grid calculation stuff
		###
		
		mutex.lock()
		
		# Perform grid calculations
		new_generation()
		
		mutex.unlock()
		
		mutex.lock()
		manage_rain()
		mutex.unlock()

		# Return grid
		mutex.lock()
		get_parent().update_texture(grid, MAP_SIZE, raining, freezed_blocks)
		
		mutex.unlock()
	
		###
		# Counter (this is really just for debugging, and for learning how threads worked in the first place)
		###
		mutex.lock()
		counter += 1 # Increment counter, protect with Mutex.
		mutex.unlock()

func manage_rain():
	# Check if it should start raining
	water_in_sky += water_evaporated
	var rain_threshold = param.rain_threshold_factor * average_temp

	if not raining and water_in_sky > rain_threshold:
		raining = true
	elif raining and water_in_sky < 0.0:
		water_in_sky = 0.0
		raining = false

func calculate_new_grid(impulses):
	# Do something with changes given to us
	
	var gas_bounds = [Vector2(0.0, 1.0), Vector2(0.0, 1.0), Vector2(0, 8)]
	
	# For each impulse, set pressure to 1.0
	for imp in impulses:
		var cell = imp[0] # get the cell we should update
		var change = imp[1] * UPDATE_SPEED # get the impulse, multiply it by the rate at which the automata is updated
		var gas_type = imp[2] # get the gas type to update
		
		var cur_val = grid[cell.y][cell.x]
		
		if cur_val.size() > 0 and (gas_type != 2 or cur_val[2] != null):
			grid[cell.y][cell.x][gas_type] = clamp(cur_val[gas_type] + change, gas_bounds[gas_type].x, gas_bounds[gas_type].y)
	
	semaphore.post() # tell thread to update

func new_generation():
	# create copy of the previous generation
	var old_grid = grid.duplicate(true)
	
	# initialize average temperature
	average_temp = 0.0
	var num_available_blocks = 0
	
	# create new generation for cellular automata
	# loop through all cells ...
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			# for this cell, loop through neighbours ...
			var cur_cell = Vector2(x,y)
			var old_val = old_grid[y][x].duplicate()
			var cur_val = old_grid[y][x].duplicate()
			
			# if we're impenetrable, don't consider us
			if cur_val.size() == 0:
				continue
				
			# remember this is a block that was available
			# (it wasn't static/impenetrable)
			num_available_blocks += 1
			
			# also add temperature to overall value
			average_temp += cur_val[1]
			
			# NOTE: It's VERY important that this goes before the rain code,
			#		otherwise frozen blocks also get rain and they aren't exactly -1 anymore
			# if we're FROZEN ...
			if cur_val[2] == null:
				# try to unfreeze
				# check if the heat is above the desired level
				if cur_val[1] > param.water_melt_point:
					# if so, reset to a full water block
					grid[y][x][2] = 1.0
			else:
				# if it's raining, 
				# add impulse to all tiles with a solid block below, as long as they aren't frozen
				# (it's better to do this inside this loop, instead of when we're already in the water loop)
				var ind_below = (y + 1) % int(MAP_SIZE.y)
				if raining:
					if old_grid[ind_below][x].size() == 0 or old_grid[ind_below][x][2] == null:
						var water_drop_mass = param.raindrop_mass
						
						grid[y][x][2] += water_drop_mass
						water_in_sky -= water_drop_mass
			
			for gas in range(2):
				# OXYGEN and HEAT have pretty default code:
				# Equally exchange/flow gases between yourself and neighbours
				for a in range(-1,2):
					for b in range(-1,2):
						if a == 0 and b == 0:
							continue
						
						# get neighbour cell
						var neighbour = cur_cell + Vector2(a,b)
						
						# wrap values around the edges
						neighbour.x = int(neighbour.x) % int(MAP_SIZE.x)
						neighbour.y = int(neighbour.y) % int(MAP_SIZE.y)
						
						# get value that belongs to this neighbour
						var neighbour_val = old_grid[neighbour.y][neighbour.x].duplicate()
						
						# if this neighbour is impenetrable, don't consider it
						if neighbour_val.size() == 0:
							continue
							
						# carbon/oxygen and heat spreads evenly
						if gas == 0 or gas == 1:
							# get the  difference between cells => use that to slowly equalize values
							# NOTE: we must make sure that we remove/add the same value on both sides
							cur_val[gas] += param.gas_exchange_rate * (neighbour_val[gas] - old_val[gas]) * UPDATE_SPEED
						
						# HOWEVER, heat is released if there's not enough carbon, and increased when there's too much carbon
						# This is an asymmetric operation: we only remove/add something from the system
						if gas == 1:
							var heat_floor = param.heat_floor
							var diff = (heat_floor - cur_val[0])
							cur_val[1] += diff * param.heat_retention_rate * UPDATE_SPEED
				
				# clamp the value between 0 and 1
				cur_val[gas] = clamp(cur_val[gas], 0.0, 1.0)
				
			# finally add the new value into the NEW grid
			grid[y][x][0] = cur_val[0]
			grid[y][x][1] = cur_val[1]
	
	average_temp = average_temp / num_available_blocks
	
	###
	#
	# WATER SIMULATION
	#
	###
	
	var flow = 0
	var remaining_mass = 0
	water_evaporated = 0.0
	
	freezed_blocks.clear()
	
	# Calculate and apply flow for each block
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			# skip impenetrable blocks
			if grid[y][x].size() == 0:
				continue
    
			# set flow and mass variables
			flow = 0
			remaining_mass = old_grid[y][x][2]
			
			if remaining_mass == null: continue
			
			if remaining_mass < 0:
				print("Mass < 0??? ", x, " || ", y)
	
			if remaining_mass == null:
				print("Mass is null??? ", x, " || ", y)
	
			# if we don't have water, continue!
			if remaining_mass <= 0: continue
	
			# cache the positions of our neighbours
			var ind_left = (x - 1) % int(MAP_SIZE.x)
			var ind_below = (y + 1) % int(MAP_SIZE.y)
			var ind_right = (x + 1) % int(MAP_SIZE.x)
			var ind_above = (y - 1) % int(MAP_SIZE.y)
	    
			###
			# Check block below
			###
			if old_grid[ind_below][x].size() > 0 and old_grid[ind_below][x][2] != null:
				flow = get_stable_state_b( remaining_mass + old_grid[ind_below][x][2] ) - old_grid[ind_below][x][2]
	     
				# ... doing this leads to a smoother flow
				if flow > MinFlow: flow *= 0.5
	
				# clamp flow
				flow = clamp( flow, 0, min(MaxSpeed, remaining_mass) )
	    
				# update values
				grid[y][x][2] -= flow
				grid[ind_below][x][2] += flow   
				remaining_mass -= flow
	    
			if remaining_mass <= 0: continue
	  
			###
			# Check block to the left
			# NOTE: Because we traverse the array TOP->BOTTOM, LEFT-> RIGHT
			#       it's possible that the left cell has been frozen in the mean time
			#       that's why we do an extra check on the new grid
			###
			if old_grid[y][ind_left].size() > 0 and old_grid[y][ind_left][2] != null and grid[y][ind_left][2] != null:
				# equalize the amount of water in this block and it's neighbour
				flow = (old_grid[y][x][2] - old_grid[y][ind_left][2]) * 0.25
	    
				if flow > MinFlow: flow *= 0.5
				flow = clamp(flow, 0, remaining_mass)
	       
				grid[y][x][2] -= flow
				grid[y][ind_left][2] += flow
				remaining_mass -= flow
	    
			if remaining_mass <= 0: continue
			
			###
			# Check block to the right
			###
			if old_grid[y][ind_right].size() > 0 and old_grid[y][ind_right][2] != null:
				# equalize the amount of water in this block and it's neighbour
				flow = (old_grid[y][x][2] - old_grid[y][ind_right][2]) * 0.25
	    
				if flow > MinFlow: flow *= 0.5
				flow = clamp(flow, 0, remaining_mass)
	       
				grid[y][x][2] -= flow
				grid[y][ind_right][2] += flow
				remaining_mass -= flow
	    
			if remaining_mass <= 0: continue
	
			###
			# Check block above
			#
			#   => Only compressed water flows upwards.
			###
			if old_grid[ind_above][x].size() > 0 and old_grid[ind_above][x][2] != null:
				flow = remaining_mass - get_stable_state_b( remaining_mass + old_grid[ind_above][x][2] )
	    
				if flow > MinFlow: flow *= 0.5
				flow = clamp( flow, 0, min(MaxSpeed, remaining_mass) )
		
				# update values
				grid[y][x][2] -= flow
				grid[ind_above][x][2] += flow   
				remaining_mass -= flow
			
			if remaining_mass <= 0: continue
			
			# If there's any water left, and it's not raining, check if it should ...
			#  => EVAPORATE (if heat is high enough)
			#  => or FREEZE (if heat below freezing point)
			# Get heat at this location
			var heat = old_grid[y][x][1]
			
			if not raining:
				# Evaporate proportional to the heat
				var water_to_evaporate = remaining_mass * heat * param.water_evaporation_factor
			
				# Update current tile, global evaporation number, and remaining_mass
				grid[y][x][2] -= water_to_evaporate
				water_evaporated += water_to_evaporate
				remaining_mass -= water_to_evaporate
			
			# NOTE: We don't freeze small amounts of water, just looks ugly and complicates the algorithms
			if remaining_mass <= param.water_needed_for_freezing: continue

			# If we're below freezing point ...
			if heat < param.water_freeze_point:
				# If we're on top of a static block (impenetrable or frozen)
				if old_grid[ind_below][x].size() == 0 or old_grid[ind_below][x][2] == null:
					# Set our (water) value to null
					grid[y][x][2] = null

					# Remember we freezed this block
					freezed_blocks.append(Vector2(x,y))

func get_stable_state_b ( total_mass ):
	if total_mass <= 1: 
		return 1
	elif total_mass < (2*MaxMass + MaxCompress):
		return (MaxMass*MaxMass + total_mass*MaxCompress)/(MaxMass + MaxCompress)
	else:
		return (total_mass + MaxCompress) * 0.5


func increment_counter():
	semaphore.post() # Make the thread process.

func get_counter():
	mutex.lock()
	
	# Copy counter, protect with Mutex.
	var counter_value = counter
	mutex.unlock()
	return counter_value

# Thread must be disposed (or "joined"), for portability.
func _exit_tree():
	# Set exit condition to true.
	mutex.lock()
	exit_thread = true # Protect with Mutex.
	mutex.unlock()
	
	# Unblock by posting.
	semaphore.post()
	
	# Wait until it exits.
	thread.wait_to_finish()
	
	# Print the counter.
	print("Counter is: ", counter)

