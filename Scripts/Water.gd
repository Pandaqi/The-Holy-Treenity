extends "res://Scripts/BulletMain.gd"

func react_to_collision(pos, normal, body):
	# if we're not hitting a tilemap or other static body, get out of here
	if not (body is TileMap or body is StaticBody2D):
		return
	
	# tell the Cellular Automata to apply an impulse on the next tick
	var ca = get_node("/root/Node2D/CellularAutomata/Control/ColorRect")
	ca.saved_impulses.append( [ get_position(), ca.param.water_gun_shoot_amount, 2 ] )
	
	# delete this body
	self.queue_free()
