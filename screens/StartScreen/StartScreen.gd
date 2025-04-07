extends Node2D

@onready var logo = $Logo;
@onready var black_overlay = $BlackOverlay;
@onready var start_button = $StartButton;

# Called when the node enters the scene tree for the first time.
func _ready():
	# prepare intro
	
	# hide the buttons
	#start_button.hide();
	#credits_button.hide();
	
	# show a black screen
	black_overlay.show();
	
	# make logo transparent
	#logo.modulate = Color.TRANSPARENT;

	#await Globals.wait(1);
	
	#fade_in_logo();
	#fade_in_from_black();
	
	#await Globals.wait(2);
	
	await get_tree().create_timer(2).timeout;
	black_overlay.hide();
	
	$video_intro.play();
	$snd_intro.play();
	
	#$IntroVideo.play();
	await $video_intro.finished;
	$video_intro.queue_free();
	
	start_button.show();

func _process(_delta):
	pass;
	
func fade_in_logo():
	if (!is_instance_valid(logo)):
		return;
	var tween = create_tween().tween_property(logo, "modulate", Color.WHITE, 2);
	await tween.finished;
	
func fade_in_from_black():
	var tween = get_tree().create_tween().tween_property(black_overlay, "modulate", Color.TRANSPARENT, 2);
	await tween.finished;

func _on_start_button_pressed():
	$StartButton.queue_free();
	$video_fall.show();
	$video_fall.play();
	await $video_fall.finished;
	
	SceneManager.change_scene("res://level design/LevelGenerator/LevelGenerator.tscn");

func _on_credits_button_pressed():
	SceneManager.change_scene("res://screens/CreditsScreen/CreditsScreen.tscn");
