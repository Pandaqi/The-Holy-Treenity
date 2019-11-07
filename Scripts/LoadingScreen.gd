extends Control

var hint_texts = [
"When the average temperature rises, more water evaporates, but clouds can also hold more water before it starts to rain.",
"Players give off heat, so don't stay in the same spot for too long!",
"Players lower oxygen levels (by breathing), but trees increase oxygen levels",
"Whenever something turns on fire, try shooting water at it or lowering the temperature around it",
"When a spot has water and is sufficiently cold, it will become an ice block. You can break it by using the axe, or heating the environment.",
"Players need a comfortable temperature: too cold or too hit will both do damage!",
"Players need oxygen to survive. If there's not enough in the air around them, they take damage",
"Players need water to survive. Fortunately, you automatically drink if you stand in a pool of water.",
"If you stay underwater too long, you will drown.",
"Where there's more carbondioxide in the air (and thus less oxygen), the environment will hold onto heat. When the air is filled with oxygen, heat quickly disappears.",
"Trees grow faster if there's lots of water nearby. In that case, they're also immune to fires.",
"Trees will drop saplings from time to time. Collect these by walking past them, so you can plant even more trees later!",
"You can never get health back, so be careful with your actions, and always check your oxygen/heat/water levels!",
"When playing multiplayer, you can swap weapons by jumping on top of each other."]

func _ready():
	var rand_text = hint_texts[ randi() % hint_texts.size() ]
	
	$MarginContainer/VBoxContainer/CenterContainer/Label.set_text("Did you know? " + rand_text)

func _input(ev):
	if Input.is_action_pressed("ui_accept"):
		load_level()

func load_level():
	# load the correct level
	var level_num = Global.get_level()
	
	# TO DO: Remove this once I have proper levels
	get_tree().change_scene("res://Levels/LevelSkeleton.tscn")
	
	#get_tree().change_scene("res://Levels/Level" + str(level_num) + ".tscn")
