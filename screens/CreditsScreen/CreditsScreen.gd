extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var video = $VideoStreamPlayer;
	video.play();
	await video.finished;
	
	$BackButton.show();

func _on_back_button_pressed():
	SceneManager.change_scene("res://screens/StartScreen/StartScreen.tscn");
