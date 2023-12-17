extends "res://Scripts/BulletMain.gd"

onready var ca = get_node("/root/Node2D/CellularAutomata/Control/ColorRect")

func react_to_collision(pos, normal, body):
	# don't hit other fire bolts
	if body.is_in_group("FireBolts"):
		return
	
	# always remove ourselves, no matter what else we hit
	self.queue_free()
	
	# if we're hitting something that could get on fire
	if body.is_in_group("OxygenGivers"):
		# make it go on fire!
		body.start_fire()
	
	# if we're hitting a player
	elif body.is_in_group("Players"):
		# increase heat to maximum!
		body.HEAT = 1.0
	
	# if we're hitting a freezed block
	elif body.is_in_group("FreezedBlocks"):
		# unfreeze it (by heating it to maximum
		ca.saved_impulses.append( [ body.get_position(), 1.0, 1] )
	
	# otherwise, nothing special happens
	
	print("Fire bolt hit something")
