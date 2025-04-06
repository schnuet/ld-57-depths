extends ProgressBar

@export var health: Health;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if health == null:
		queue_free();
		return;
	
	max_value = health.max;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if health == null:
		return
	
	value = health.current;
