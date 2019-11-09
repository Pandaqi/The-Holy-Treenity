extends Control

var hint_texts = [
"When the average temperature rises, more water evaporates, but clouds can also hold more water before it starts to rain.",
"Players emit heat, so don't stay in the same spot for too long!",
"Players lower oxygen levels (by breathing), but trees increase oxygen levels",
"Whenever something turns on fire, try shooting water at it or lowering the temperature around it",
"When a spot has water and is sufficiently cold, it will become an ice block. You can break it by using the axe, or heating the environment.",
"Players need a comfortable temperature: too cold or too hot will both do damage!",
"Players need oxygen to survive. If there's not enough in the air around them, they take damage",
"Players need water to survive. Fortunately, you automatically drink if you stand in a pool of water (that is large enough).",
"If you stay underwater too long, you will drown.",
"Where there's more carbondioxide in the air (and thus less oxygen), the environment will hold onto heat. When the air is filled with oxygen, heat quickly disappears.",
"Trees grow faster if there's lots of water nearby. In that case, they're also immune to fires.",
"Trees will drop saplings from time to time. Collect these by walking past them, so you can plant even more trees later!",
"You can never get health back, so be careful with your actions, and always check your oxygen/heat/water levels!",
"When playing multiplayer, you can swap weapons by jumping on top of each other.",
"Water evaporates faster if heat rises, but you can also use it to cool down a certain area of the level",
"When you shoot logs, they become static once they hit something. From that moment, they are seen as part of the level, and oxygen/heat/water can't pass through!",
"Using the axe weapon, you can chop trees and logs, and receive seeds as a reward. You might also be able to chop other things ...",
"Without enough carbon, the climate allows lots of heat to escape. This means it automatically gets too cold during the level, unless you do something about it.",
"Everytime you start a level, the climate parameters are slightly randomized, to make each level feel a bit different. (And because climate is somewhat unpredictable.)",
"To survive the game, always think of the holy treenity: keep moving to escape heat, keep planting trees, and keep drinking water"]

func _ready():
	var rand_text = hint_texts[ randi() % hint_texts.size() ]
	var rand_num = randi() % 100 + 1
	
	$MarginContainer/VBoxContainer/CenterContainer/Label.set_text("Game Tip #" + str(rand_num) + ": " + rand_text)

func _input(ev):
	if Input.is_action_pressed("ui_accept"):
		load_level()

func load_level():
	# load the correct level
	var level_num = Global.get_level()
	
	# TO DO: Remove this once I have proper levels
	#get_tree().change_scene("res://Levels/LevelSkeleton.tscn")
	
	get_tree().change_scene("res://Levels/Level" + str(level_num) + ".tscn")
