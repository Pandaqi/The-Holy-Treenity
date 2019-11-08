extends Control

var game_over = false

# Listen for user input (restart level or return to main menu?)
func _input(ev):
	# If we press ESC, return to level select
	# (This is an easy way for me to allow players to "stop/break out of the game loop"
	#  without the need to implement a proper pause menu)
	if Input.is_action_just_released("ui_cancel"):
		get_tree().change_scene("res://MainMenu.tscn")
		get_tree().paused = false
	
	# If the game isn't over, there is no pause screen, so don't do anything else!
	if not game_over:
		return
	
	# If we press ENTER, restart the level
	if Input.is_action_just_released("ui_accept"):
		get_tree().reload_current_scene()
		get_tree().paused = false
	
	
