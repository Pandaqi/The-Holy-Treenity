extends Control

var game_over = false

# Listen for user input (restart level or return to main menu?)
func _input(ev):
	# If the game isn't over, there is no pause screen, so don't do anything!
	if not game_over:
		return
	
	# If we press ENTER, restart the level
	if Input.is_action_just_released("ui_accept"):
		get_tree().reload_current_scene()
		get_tree().paused = false
	
	# If we press ESC, return to level select
	elif Input.is_action_just_released("ui_cancel"):
		get_tree().change_scene("res://MainMenu.tscn")
		get_tree().paused = false
