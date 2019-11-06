extends "res://Scripts/TreeMain.gd"

func _ready():
	# Initialize timer
	sapling_timer = Timer.new()
	add_child(sapling_timer)
	
	sapling_timer.connect("timeout", self, "drop_sapling") 
	sapling_timer.set_one_shot(false)
	sapling_timer.set_wait_time(rand_range(time_between_saplings.x, time_between_saplings.y))
	sapling_timer.start()



