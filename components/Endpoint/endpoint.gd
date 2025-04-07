extends Area2D

func _on_body_entered(body: Node2D) -> void:
	Globals.level_counter += 1;
	
	SceneManager.change_scene("res://level design/boss_scenes/boss_1.tscn");
	
