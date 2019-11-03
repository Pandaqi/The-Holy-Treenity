###
# OLD CODE FOR SPREADING WATER
###


#if should_spread:
#	# STEP 2: Spread water in the HORIZONTAL direction (check left/right neighbours)
#	var left_cell = old_grid[y][ind_left]
#	var right_cell = old_grid[y][ind_right]
#
#	var room_left = 0
#	var room_right = 0
#
#	if left_cell.size() > 0:
#		left_cell = left_cell[2]
#		room_left = 8 - left_cell
#	else:
#		left_cell = -1
#		room_left = 0
#
#	if right_cell.size() > 0:
#		right_cell = right_cell[2]
#		room_right = 8 - right_cell
#	else:
#		right_cell = -1
#		room_right = 0
#
#	# If both sides have no room, we're done
#	if room_right == 0 and room_left == 0:
#		continue
#
#
#	# If only right has room
#	if room_right > 0 and room_left == 0:
#		# Move half the different to the right
#		var half_diff = floor( (cur_val + right_cell) * 0.5 )
#		var remainder = (cur_val + right_cell) - half_diff*2
#
#		# If there's actually something to move (the other side is NOT higher than us
#		if half_diff > 0:
#			grid[y][x][2] -= half_diff
#			grid[y][ind_right][2] += half_diff + remainder
#
#	# If only left has room
#	elif room_left > 0 and room_right == 0:
#		# Move half the different to the right
#		var half_diff = floor( (cur_val + left_cell) * 0.5 )
#		var remainder = (cur_val + left_cell) - half_diff*2
#
#		# If there's actually something to move (the other side is NOT higher than us
#		if half_diff > 0:
#			grid[y][x][2] -= half_diff 
#			grid[y][ind_left][2] += half_diff + remainder
#
#	# Otherwise, spread the water evenly
#	else:
#		var average = floor( (left_cell + right_cell + cur_val) * (1/3) )
#
#		grid[y][ind_left][2] = average
#		grid[y][x][2] = average
#		grid[y][ind_right][2] = average
#
#		var remainder = (left_cell + right_cell + cur_val) - average*3
#		grid[y][x][2] += remainder



###
# New, old water code
###

# WATER needs some special code
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			# for this cell, loop through neighbours ...
			var cur_cell = Vector2(x,y)
			
			# if this thing is impenetrable, continue
			if old_grid[y][x].size() <= 0:
				continue
			
			var cur_val = old_grid[y][x][2]
			
			# if there's no water here, continue
			if cur_val <= 0:
				continue
			
			# Cache the positions left/right/below
			var ind_left = (x - 1) % int(MAP_SIZE.x)
			var ind_below = (y + 1) % int(MAP_SIZE.y)
			var ind_right = (x + 1) % int(MAP_SIZE.x)
			var ind_above = (y - 1) % int(MAP_SIZE.y)
			
			# STEP 1: Check if there's pressure (too much water in this cell)
			if cur_val > 8.0:
				var cell_above = old_grid[ind_above][x]
				var diff = cur_val - 8.0

				# if a cell exists above us, add the difference to that cell
				if cell_above.size() > 0:
					grid[ind_above][x][2] += diff
					
					grid[y][x] = 8.0
					cur_val = 8.0

				# TO DO: If we can't push upwards, we must push sideways
				
			
			# STEP 1: Check cell below
			var cell_below = old_grid[ind_below][x]
			var should_check_below = true
			
			if cell_below.size() > 0:
				cell_below = cell_below[2]
			else:
				should_check_below = false
			
			# If it is 
			#  => Not impenetrable
			#  => And it can hold all our water
			# add the water and empty ourselves!
			if should_check_below:
				if (cell_below + cur_val) <= 8.0:
					grid[ind_below][x][2] = cell_below + cur_val
					grid[y][x][2] = 0.0
					
					cur_val = 0.0
				else:
					# If not, add as much water as we can ...
					var room_left = 8.0 - cell_below
					
					grid[ind_below][x][2] += room_left
					grid[y][x][2] -= room_left
					
					cur_val = grid[y][x][2] # also keep track of the current value here
					
					if cur_val < 0:
						print("Below 0 because of DOWN MOVEMENT")
			
			# if any water remains ...
			if cur_val > 0:
				var we_are_done = false
				var left_cell = old_grid[y][ind_left]
				if left_cell.size() > 0:
					left_cell = left_cell[2]
				else:
					left_cell = -1
					
				var right_cell = old_grid[y][ind_right]
				if right_cell.size() > 0:
					right_cell = right_cell[2]
				else:
					right_cell = -1
				
				while not we_are_done:
					var left_done = false

					# if we're done (impenetrable cell or cell is already higher), save that info
					if left_cell == -1 or left_cell >= cur_val:
						left_done = true
					else:
						var rand_val = rand_range(0.1, 0.9)
						
						var max_possible_val = min(8.0 - left_cell, cur_val)
						if rand_val > max_possible_val:
							rand_val = max_possible_val
							left_done = true
						
						# if we're not done, move water
						grid[y][ind_left][2] += rand_val
						grid[y][x][2] -= rand_val
						
						left_cell += rand_val
						cur_val = grid[y][x][2]
						
						if cur_val < 0:
							print("Below 0 because of LEFT MOVEMENT || Max val: ", max_possible_val)

					if cur_val <= 0:
						break
					
					var right_done = false
					# if we're done (impenetrable cell or cell is already higher), save that info
					if right_cell == -1 or right_cell >= cur_val:
						right_done = true
					else:
						# if we're not done, move water
						var rand_val = rand_range(0.1, 0.9)
						
						var max_possible_val = min(8.0 - right_cell, cur_val)
						if rand_val > max_possible_val:
							rand_val = max_possible_val
							right_done = true
						
						grid[y][ind_right][2] += rand_val
						grid[y][x][2] -= rand_val
						
						right_cell += rand_val
						cur_val = grid[y][x][2]
						
						if cur_val < 0:
							print("Below 0 because of RIGHT MOVEMENT || Max val: ", max_possible_val)
					
					we_are_done = (left_done and right_done) or (cur_val <= 0)
			
			# for safety (and against imprecisions?) clamp the value
			if cur_val != grid[y][x][2]:
				print(cur_val, " || ", grid[y][x][2])
			
			grid[y][x][2] = clamp(cur_val, 0.0, 8.0)



