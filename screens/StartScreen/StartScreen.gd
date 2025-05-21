extends Node2D

@onready var logo = $Logo;
@onready var black_overlay = $BlackOverlay;
@onready var start_button = $StartButton;

var switching: bool = false;

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
	
	#$IntroVideo.play();
	await $video_intro.finished;
	$video_intro.hide();

func _process(_delta):
	if Input.is_action_just_released("ui_accept") or Input.is_action_just_released("jump"):
		proceed();
	
func fade_in_logo():
	if (!is_instance_valid(logo)):
		return;
	var tween = create_tween().tween_property(logo, "modulate", Color.WHITE, 2);
	await tween.finished;
	
func fade_in_from_black():
	var tween = get_tree().create_tween().tween_property(black_overlay, "modulate", Color.TRANSPARENT, 2);
	await tween.finished;


func proceed():
	if $video_intro.is_playing():
		print("intro playing");
		$video_intro.stop();
		$video_intro.hide();
		return;
	
	if $video_fall.is_playing():
		print("fall playing");
		$video_fall.stop();
		black_overlay.show();
		black_overlay.modulate = Color.WHITE;
		SceneManager.change_scene("res://level design/LevelGenerator/LevelGenerator.tscn");
		return;
	
	if switching:
		print("switching");
		return;
	
	print("switch!");
	
	switching = true;
	$image.hide();
	start_button.hide();
	$video_fall.show();
	$video_fall.play();
	await $video_fall.finished;
	$video_fall.hide();
	
	SceneManager.change_scene("res://level design/LevelGenerator/LevelGenerator.tscn");

func _on_start_button_pressed():
	proceed();
