extends "res://Scripts/TreeMain.gd"

func get_oxygen_level():
	return 0.0

func get_fire_position():
	return Vector2.ZERO

func optional_death_calls():
	# Upon death, the log should release the blockage it created
	var ca = get_node("/root/Node2D/CellularAutomata/Control/ColorRect")
	ca.saved_impulses.append( [ get_position(), null, false] )
