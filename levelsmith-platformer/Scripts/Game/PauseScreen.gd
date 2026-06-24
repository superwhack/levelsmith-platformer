extends PanelContainer

# Reference to the game manager node.
@export var gameManager : Node2D;

## Runs every frame during the play state
## _delta: The amount of time that has passed
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") && gameManager.visible:
		gameManager.pause();
