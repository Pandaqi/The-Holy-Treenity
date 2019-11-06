extends Control

# Listen for user input (restart level or return to main menu?)
func _input(ev):
	# If the game isn't paused, there is no pause screen, so don't do anything!
	if not get_tree().paused:
		return
	
	# If we press ENTER, restart the level
	if Input.is_action_just_released("ui_accept"):
		get_tree().reload_current_scene()
		get_tree().paused = false
	
	# If we press ESC, return to level select
	elif Input.is_action_just_released("ui_cancel"):
		get_tree().change_scene("res://MainMenu.tscn")
		get_tree().paused = false
