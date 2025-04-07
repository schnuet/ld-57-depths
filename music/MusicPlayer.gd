extends Node

@onready var players = get_children() as Array[AudioStreamPlayer];
@onready var current_player = null;

const VOLUME_MAX = -14;

func _ready():
	for player in players:
		player.volume_db = -60;
		var stream = player.stream;
		stream.loop = true;
	
func play_music(music_name: String):
	# prevent stopping music if it is playing already:
	if current_player and current_player.name == music_name:
		return;
	
	fade_to(music_name);

func stop_music():
	if current_player:
		current_player.stop();

func fade_to(music_name):
	if current_player and current_player.name == music_name:
		return;
	
	if current_player:
		fade_out(current_player.name);
	
	fade_in(music_name);
	
	current_player = get_player(music_name);
	
func fade_in(music_name: String):
	var time = 0.5;
	var tween = get_tree().create_tween();
	var player = get_player(music_name);
	player.play();
	if player:
		# fade out current player
		tween.tween_property(player, "volume_db", VOLUME_MAX, time);

func fade_out(music_name: String):
	var time = 0.5;
	var tween = get_tree().create_tween();
	var player = get_player(music_name);
	if player:
		# fade out current player
		tween.tween_property(player, "volume_db", -40, time);

func get_player(music_name: String) -> AudioStreamPlayer:
	return get_node(music_name);


# If loops don't work, use this event listener as workaround:
func _on_audio_stream_player_finished() -> void:
	current_player.play(0);

#func play_music(music_name:String):
#	if current_music_name == music_name:
#		return;
#
#	stop();
#
#	current_music_name = music_name;
#	stream = music_streams.get(current_music_name);
#
#	play();
#
#func register_stream(stream_path:String, music_name:String):
#	music_streams[music_name] = load(stream_path);
