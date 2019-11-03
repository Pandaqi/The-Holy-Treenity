extends Node

var counter = 0
var mutex
var semaphore
var thread
var exit_thread = false

var grid = []
export (Vector2) var MAP_SIZE = Vector2(32, 32)

# The thread will start here.
func _ready():
	
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
			grid[y][x] = rand_range(0,1)
			
			# Check if there is a block on this tile
			if tilemap.get_cell(x, y) > -1:
				grid[y][x] = -1
	
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
		
		# Perform grid calculations
		new_generation()
		
		# Return grid
		get_parent().update_texture(grid, MAP_SIZE)
	
		###
		# Thread stuff (... is the counter really necessary? What's it for?)
		###
		
		mutex.lock()
		var should_exit = exit_thread # Protect with Mutex.
		mutex.unlock()
	
		if should_exit:
			break
	
		mutex.lock()
		counter += 1 # Increment counter, protect with Mutex.
		mutex.unlock()

func calculate_new_grid(impulses):
	# TO DO: Do something with changes given to us
	
	# For each impulse, set pressure to 1.0
	for imp in impulses:
		var cell = imp[0]
		var change = imp[1]
		var cur_val = grid[cell.y][cell.x]
		
		grid[cell.y][cell.x] = clamp(cur_val + change, 0.0, 1.0)
	
	semaphore.post() # tell thread to update

func new_generation():
	# create copy of the previous generation
	var old_grid = grid.duplicate(true)
	
	# create new generation for cellular automata
	# loop through all cells ...
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			# for this cell, loop through neighbours ...
			var cur_cell = Vector2(x,y)
			var old_val = old_grid[y][x]
			var cur_val = old_grid[y][x]
			
			# if we're impenetrable, don't consider us
			if cur_val < 0:
				continue
			
			for a in range(-1,2):
				for b in range(-1,2):
					if a == 0 and b == 0:
						continue
					
					# get neighbour cell
					var neighbour = cur_cell + Vector2(a,b)
					
					# wrap values around the edges
					if neighbour.x >= MAP_SIZE.x: neighbour.x -= MAP_SIZE.x
					if neighbour.x < 0: neighbour.x += MAP_SIZE.x
					if neighbour.y >= MAP_SIZE.y: neighbour.y -= MAP_SIZE.y
					if neighbour.y < 0: neighbour.y += MAP_SIZE.y
					
					# get value that belongs to this neighbour
					var neighbour_val = old_grid[neighbour.y][neighbour.x]
					
					# if this neighbour is impenetrable, don't consider it
					if neighbour_val < 0:
						continue
					
					# get the pressure difference between cells					
					#  => if the other cell has lower pressure, we should remove some of our own
					#  => if the other cel has higher pressure, we should add something to our own
					# NOTE: we must make sure that we remove/add the same value on both sides
					cur_val += 0.1 * (neighbour_val - old_val)
			
			# clamp the value between 0 and 1
			cur_val = clamp(cur_val, 0.0, 1.0) 
			
			# finally add the new value into the NEW grid
			grid[y][x] = cur_val

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

