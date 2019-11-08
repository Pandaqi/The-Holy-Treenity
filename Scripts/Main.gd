extends Node2D

export (Vector2) var MAP_SIZE = Vector2(32, 24)

onready var gun_scene = preload("res://Gun.tscn")
onready var player_scene = preload("res://Player.tscn")

var level_timer = null
export (int) var TIMER = 3 * 60 # default to three minutes

var players_alive = 1 # Is automatically set to number of players in the game

export (PoolVector2Array) var player_positions = [Vector2(10,10), Vector2(10,10), Vector2(10,10), Vector2(10,10)]
export (PoolVector2Array) var weapon_positions = [Vector2(16,7), Vector2(7,4), Vector2(16,7), Vector2(7,4), Vector2(29,15)]

var i_size = Vector2(300, 200)
var interface_occlusions = [
	Rect2(0,0, i_size.x, i_size.y),
	Rect2(1024-i_size.x, 0, i_size.x, i_size.y),
	Rect2(0, 768-i_size.y, i_size.x, i_size.y),
	Rect2(1024-i_size.x, 768-i_size.y, i_size.x, i_size.y)
	]

###
# SIMULATION VARIABLES
#
# All these variables are used (somewhere) in the environment simulation
# I expose these to the editor, so I can quickly see and set all parameters, which makes balancing the game easier
#
###

export (Dictionary) var simulation_parameters = {
	# PLAYER
	"player_oxygen_taken": 0.15,
	"player_heat_expelled": 0.125,
	"player_drink_factor": 1.0,
	"player_drown_level": 0.75,
	
	"player_oxygen_minimum": 0.15,
	"player_heat_minimum": 0.15,
	"player_heat_maximum": 0.85,
	"player_water_minimum": 0.15,
	
	# FIRES
	"fire_oxygen_taken": -0.2,
	"fire_heat_expelled": 0.2,
	
	"fire_start_heat": 0.6,
	"fire_start_water": 0.4,
	"fire_stop_heat": 0.6,
	"fire_stop_water": 0.6,
	
	"fire_tree_damage": -0.01,
	
	# WATER GUN
	"water_gun_suck_amount": 0.2,
	"water_gun_shoot_amount": 1.0,
	
	# FIRE BOLTS
	"firebolt_heat_expelled": 0.75,
	
	# TREES
	"tree_oxygen_expelled": 0.8,
	"tree_default_growth_speed": 1.05,
	"tree_water_growth_factor": 0.35,
	
	"tree_seed_drop_amount": 3, # how many seeds a tree drops IF CHOPPED
	"tree_min_seed_time": 20, # minimum amount of time between trees dropping seeds
	"tree_max_seed_time": 50, # maximum amount of time between trees droppin seeds
	
	# SIMULATION
	"rain_threshold_factor": 20.0,
	"raindrop_mass": 0.005,
	"rain_delay": 10,
	
	"water_evaporation_factor": 10.0,
	"water_freeze_point": 0.3,
	"water_melt_point": 0.3,
	"water_needed_for_freezing": 0.5,
	
	"gas_exchange_rate": 0.1, # how quickly different heat/oxygen levels will try to equalize
	"heat_floor": 0.35,    # oxygen levels above this release heat, below this they hold onto heat
	"heat_retention_rate": 0.01, # how quickly heat is released/added (based on oxygen level alone)
}

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
		new_gun.set_position( weapon_positions[i] * 32 )
		
		# add gun to the tree
		add_child(new_gun)
		
		# initialize variables (gun type, sprite frame, etc.)
		new_gun.initialize(i)
	
	# now start the tutorial
	if has_node("Tutorial"):
		get_node("Tutorial").start_tutorial()

func _process(delta):
	# Check if any player is behind an interface => if so, hide it
	var hide_interface = [false, false, false, false]
	
	# Go through all players ...
	for player in get_tree().get_nodes_in_group("Players"):
		# Go through all interfaces ...
		for i in range(4):
			var occ = interface_occlusions[i]
			
			# CHeck if player position is within interface bounding box
			if check_point_in_rect(occ, player.get_position() ):
				hide_interface[i] = true
			else:
				hide_interface[i] = false
	
	# Once the results are in, go through all interfaces again and finally hide/show them
	var counter = 0
	for interface in get_tree().get_nodes_in_group("PlayerInterfaces"):
		if hide_interface[counter]:
			interface.modulate.a = 0.2
		else:
			interface.modulate.a = 1.0
		counter += 1

func check_point_in_rect(rect, point):
	if point.x > rect.position.x and point.x < rect.position.x+rect.size.x and point.y > rect.position.y and point.y < rect.position.y+rect.size.y:
		return true
	return false

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
	$PauseScreen/Control.game_over = true
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
		