extends "res://Scripts/TreeMain.gd"

func _ready():
	# Initialize timer
	sapling_timer = Timer.new()
	add_child(sapling_timer)
	
	sapling_timer.connect("timeout", self, "drop_sapling") 
	sapling_timer.set_one_shot(false)
	sapling_timer.set_wait_time(rand_range(time_between_saplings.x, time_between_saplings.y))
	sapling_timer.start()
	
	# Place tree at random z-index
	# (so player walks in front of it sometimes, and behind it at other times)
	#  => Player z-index = 3
	#  => Tilemap z-index = 5
	z_index = randi() % 3 + 2



