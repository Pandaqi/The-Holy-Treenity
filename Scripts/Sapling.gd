extends "res://Scripts/BulletMain.gd"

onready var static_tree = preload("res://Bullets/TreeStatic.tscn")

func react_to_collision(pos, normal, body):
	# if we're not hitting the tilemap, get out of here
	if not body is TileMap:
		return
	
	print("Sapling hit something")
	
	# Replace it with a STATIC body, with the same size/position/rotation
	var static_body = static_tree.instance()
	
	# Set transform (for rotation and position)
	# Get collision normal, use it to calculate how the body should rotate
	static_body.transform[0] = normal
	static_body.transform[1] = Vector2(-normal.y, normal.x)
	static_body.transform.origin = pos
	
	# Give this body a unique shape to scale
	var unique_shape = RectangleShape2D.new()
	unique_shape.set_extents(Vector2(5, 2.5))
	static_body.get_node("CollisionShape2D").shape = unique_shape
	
	# Offset shape and sprite properly
	static_body.get_node("CollisionShape2D").set_position(Vector2(2.5, 0))
	static_body.get_node("Sprite").offset = Vector2(0, -32)
	
	# add static body to the tree
	get_node("/root/Node2D").call_deferred("add_child", static_body)
	
	# finally, remove this bullet
	self.queue_free()