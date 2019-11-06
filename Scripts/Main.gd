extends Node2D

export (Vector2) var MAP_SIZE = Vector2(32, 24)

onready var gun_scene = preload("res://Gun.tscn")
onready var player_scene = preload("res://Player.tscn")

var level_timer = null
export (int) var TIMER = 3 * 60 # default to three minutes

var players_alive = 1 # TO DO: set to number of players in the game

export (PoolVector2Array) var player_positions = [Vector2(10,10), Vector2(10,10), Vector2(10,10), Vector2(10,10)]

func _ready():
	# set correct player count
	players_alive = Global.player_count
	
	# instantiate players
	for i in range(players_alive):
		# instance new player scene
		var new_player = player_scene.instance()
		
		# set to right position
		new_player.set_position( 32 * player_positions[i] )
		
		# connect controller with player
		new_player.set_controller(i, Global.control_map[i])
		
		# add player to the tree
		add_child(new_player)
	
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
	


func update_timer():
	TIMER -= 1
	
	# DISPLAY LATEST VALUE
	# convert value (in SECONDS) to string (with MINUTES:SECONDS)
	var minutes = "%02d" % floor(TIMER / 60)
	var seconds = "%02d" % floor(TIMER % 60)
	var text = minutes + ":" + seconds
	
	$Interface/Control/Timer.set_text("%s" % text)
	
	# IF TIME RUNS OUT, PAUSE GAME AND DISPLAY GAME_OVER SCREEN
	if TIMER <= 0.0:
		end_game(true)

func player_died():
	players_alive -= 1
	
	# if no players left alive, end the game (and remember we lost)
	if players_alive <= 0:
		end_game(false)

func end_game(did_we_win):
	$PauseScreen/Control.set_visible(true)
	$CellularAutomata/Control/ColorRect/Semaphore.exit_thread = true
	
	get_tree().paused = true
	
	# change text/color based on results
	var result_text = $PauseScreen/Control/MarginContainer/CenterContainer/VBoxContainer/Result
	if not did_we_win:
		result_text.set_text("You lost ...")
		result_text.modulate = Color(1.0, 0.0, 0.0)
	else:
		result_text.set_text("You won!")
		result_text.modulate = Color(0.5, 1.0, 0.0)
		