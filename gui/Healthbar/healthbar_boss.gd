extends CanvasLayer

var max = 100;
var value = 0;

@onready var progress = $Control/TextureProgressBar;

func _ready() -> void:
	var player = find_boss();
	if player:
		var player_health: Health = player.get_node("Health");
		value = player_health.current;
		max = player_health.max;
	
	progress.max_value = max;
	progress.value = value;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var player = find_boss();
	
	if player:
		var player_health: Health = player.get_node("Health");
		value = player_health.current;
		max = player_health.max;
	
	progress.max_value = max;
	var value_to_set = move_toward(progress.value, value, delta * 100);
	progress.set_value_no_signal(value_to_set);
	
func find_boss():
	var players = get_tree().get_nodes_in_group("boss");
	if players.size() == 0:
		return null;
	return players[0];



func hide_bar():
	var tween = get_tree().create_tween();
	tween.set_ease(Tween.EASE_OUT);
	tween.tween_property($Control, "modulate", Color.TRANSPARENT, 1);

func show_bar():
	$Control.show();
	var tween = get_tree().create_tween();
	tween.set_ease(Tween.EASE_OUT);
	tween.tween_property($Control, "modulate", Color.WHITE, 2);
