extends Node2D

var base_pitches = {};

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for snd in get_children():
		base_pitches[snd.name] = snd.pitch_scale;

func play_sound(snd_id: String, randomize_pitch = 0):
	if not has_node(snd_id):
		print("SND ", snd_id, " doesnt exist");
		return
	var snd: AudioStreamPlayer = get_node(snd_id);
	if randomize_pitch != 0:
		var num = randf_range(-randomize_pitch, randomize_pitch);
		snd.pitch_scale = base_pitches[snd.name] + num;
	snd.play();
