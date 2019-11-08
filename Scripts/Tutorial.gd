extends CanvasLayer

var cur_batch = -1
var tutorial_active = false

func _ready():
	# disable all children (which should all be tutorial batches)
	for child in get_children():
		child.hide()

func start_tutorial():
	# immediately pause the tree
	get_tree().paused = true
	
	# remember the tutorial is now happening
	tutorial_active = true
	
	# now load the first batch
	load_next_batch()

func load_next_batch():
	# If we HAVE a previous batch, hide it
	if has_node("Batch" + str(cur_batch)):
		get_node("Batch" + str(cur_batch)).hide()
	
	# Increment the counter
	cur_batch += 1
	
	# Now show the new batch, if it exists
	if has_node("Batch" + str(cur_batch)):
		get_node("Batch" + str(cur_batch)).show()
		
	# Otherwise, unpause and start the game!
	else:
		tutorial_active = false
		get_tree().paused = false

func _input(ev):
	if not tutorial_active:
		return
	
	if ev.is_action_pressed("ui_accept") and not ev.echo:
		load_next_batch()