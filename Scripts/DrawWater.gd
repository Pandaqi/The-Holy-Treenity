extends Node2D

var grid = []
var MAP_SIZE

func _draw():
	if grid.size() == 0:
		return
	
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			if grid[y][x].size() == 0:
				continue
			
			var val = grid[y][x][2]
			var ice_block = false
			
			# if it's an ice block, do nothing
			if val == null: 
				continue
			
			# floating point precision errors => better give ourselves some margin
			elif val <= 0:
				continue
			
			# Draw rectangle
			# At right position, with blue color, and right height 
			# (anchor it to the bottom, that's why we do (y+1)*32 - height)
			
			# Normal tile => transparent, blue-ish color + dynamic height
			var col = Color(0.5, 0.5, 1, 0.5)
			var height = min(val, 1.0) * 32
			var waterfall_drawn = false

			# If this tile is NOT full ...
			# Check if block above has water, if so, always set to full water
			#  => this is what creates the waterfalls
			var val_above = grid[ int(y - 1) % int(MAP_SIZE.y) ][x]
			
			if val < 1.0:
				if val_above.size() > 0 and val_above[2] != null:
					if val_above[2] > 0:
						height = 32
						col = Color(0.5, 0.5, 1, 0.2)
						waterfall_drawn = true

			var rect = Rect2(Vector2(x * 32, (y+1) * 32 - height), Vector2(32, height))
			draw_rect(rect, col)
			
			# if we've drawn a waterfall ...
			if waterfall_drawn:
				var val_below = grid[ int(y + 1) % int(MAP_SIZE.y) ][x]
				
				# but this tile has SOLID ground below it ...
				if val_below.size() == 0 or val_below[2] == null:
					# draw the actual water again!
					col = Color(0.5, 0.5, 1, 0.5)
					height = min(val, 1.0) * 32
					
					rect = Rect2(Vector2(x * 32, (y+1) * 32 - height), Vector2(32, height))
					draw_rect(rect, col)

func draw_water(grid, MAP_SIZE):
	self.grid = grid
	self.MAP_SIZE = MAP_SIZE
	
	self.update()