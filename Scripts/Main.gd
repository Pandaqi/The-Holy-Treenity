extends Node2D

export (Vector2) var MAP_SIZE = Vector2(32, 24)

func _ready():
	Global.MAP_SIZE = MAP_SIZE

