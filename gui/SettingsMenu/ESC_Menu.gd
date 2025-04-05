extends Control


func _ready():
	pass # Replace with function body.


func _process(_delta):
	# Open the ESC menu when the ESC key is pressed
	if Input.is_action_just_released("ui_menu"):
		$EscapeMenu.visible = not $EscapeMenu.visible
