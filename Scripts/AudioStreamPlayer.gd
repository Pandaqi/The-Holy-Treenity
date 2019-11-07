extends AudioStreamPlayer
#
#var audio_files = [
#	preload("res://SoundTrack/loop_0.wav"),
#	preload("res://SoundTrack/loop_1.wav"),
#	preload("res://SoundTrack/loop_2.wav"),
#	preload("res://SoundTrack/loop_3.wav"),
#	preload("res://SoundTrack/loop_4.wav"),
#	preload("res://SoundTrack/ticking_clock.wav")
#	]

# Called when the node enters the scene tree for the first time.
func _ready():
	# initialize the audio player
	_on_AudioStreamPlayer_finished()

func pick_random_track():
	var rand_num = randi() % 5
	
	return load("res://Soundtrack/loop_" + str(rand_num) + ".wav")

func _on_AudioStreamPlayer_finished():
	# Play ticking clock music when nearing the end (loop is exactly 8 seconds, so use a multiple of 8)
	if get_node("/root/Node2D").TIMER <= 8 * 2:
		play_ticking_clock()
		return
	
	stream = pick_random_track()
	play()
	
	if rand_range(0,1) >= 0.5:
		$StreamExtra.stream = pick_random_track()
		$StreamExtra.play()

func play_ticking_clock():
	stream = load("res://Soundtrack/ticking_clock.wav")
	play()
	