extends Node2D

var water_in_sky = 0
var raining = false

func add_evaporated_water(w):
	# if it's already raining, ignore this
	if raining:
		return
	
	# increment evaporated water
	water_in_sky += w
	
	print(water_in_sky)
	
	# if this value is above our rain threshold
	if water_in_sky > 1.0:
		raining = true
		
		print("Make it rain!")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
