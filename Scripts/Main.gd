extends Node2D

export (Vector2) var MAP_SIZE = Vector2(32, 24)

onready var gun_scene = preload("res://Gun.tscn")

var level_timer = null
export (int) var TIMER = 3 * 60 # default to three minutes

func _ready():
	# create level timer
	level_timer = Timer.new()
	add_child(level_timer)
	
	level_timer.connect("timeout", self, "update_timer") 
	level_timer.set_one_shot(false)
	level_timer.set_wait_time(1.0)
	level_timer.start()
	
	# save map size (for easy access) 
	# NOTE => although it's probably better to make this local in every script?
	Global.MAP_SIZE = MAP_SIZE
	
	# instantiate all the weapons
	for i in range(5):
		var new_gun = gun_scene.instance()
		new_gun.set_position( Vector2(rand_range(0,MAP_SIZE.x*32), rand_range(0,MAP_SIZE.y*32)) )
		
		# add gun to the tree
		add_child(new_gun)
		
		# initialize variables (gun type, sprite frame, etc.)
		new_gun.initialize(i)
	
	# initialize the audio player
	$AudioStreamPlayer0.stream = pick_random_track()
	$AudioStreamPlayer0.play()

func pick_random_track():
	var rand_num = randi() % 5
	
	return load("res://SoundTrack/loop_" + str(rand_num) + ".wav")

func _on_AudioStreamPlayer0_finished():
	$AudioStreamPlayer0.stream = pick_random_track()
	$AudioStreamPlayer0.play()
	
	if rand_range(0,1) >= 0.5:
		$AudioStreamPlayer1.stream = pick_random_track()
		$AudioStreamPlayer1.play()

func update_timer():
	TIMER -= 1
	
	# DISPLAY LATEST VALUE
	# convert value (in SECONDS) to string (with MINUTES:SECONDS)
	var minutes = "%02d" % floor(TIMER / 60)
	var seconds = "%02d" % floor(TIMER % 60)
	var text = minutes + ":" + seconds
	
	$Interface/Control/Timer.set_text("%s" % text)

	# TO DO: Play ticking clock music when nearing the end (loop is exactly 8 seconds)
	# TO DO: Actually place a script on the control node that listens for user input

	# IF TIME RUNS OUT, PAUSE GAME AND DISPLAY GAME_OVER SCREEN
	if TIMER <= 0.0:
		end_game(true)

func end_game(did_we_win):
	$PauseScreen/Control.set_visible(true)
	get_tree().paused = true
	
	# change text/color based on results
	var result_text = $PauseScreen/Control/MarginContainer/CenterContainer/VBoxContainer/Result
	if not did_we_win:
		result_text.set_text("You lost ...")
		result_text.modulate = Color(1.0, 0.0, 0.0)
	else:
		result_text.set_text("You won!")
		result_text.modulate = Color(0.5, 1.0, 0.0)
		