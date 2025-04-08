extends Area2D

func _on_body_entered(_body: Node2D) -> void:
	var player = get_player();
	player.enabled = false;
	player.disable_hurtbox();
	
	$CanvasLayer/ColorRect.show();
	var tween = get_tree().create_tween();
	tween.set_ease(Tween.EASE_OUT);
	tween.tween_property($CanvasLayer/ColorRect, "modulate", Color.BLACK, 1);
	await tween.finished;
	
	Globals.level_counter += 1;
	MusicPlayer.stop_music();
	
	$CanvasLayer/video_fall.show();
	$CanvasLayer/video_fall.play();
	await $CanvasLayer/video_fall.finished;
	
	SceneManager.change_scene("res://level design/boss_scenes/boss_1.tscn");
	

func get_player():
	var players = get_tree().get_nodes_in_group("player");
	if players.size() == 0:
		return null;
	return players[0];
