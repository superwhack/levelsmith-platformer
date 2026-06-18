extends Panel

@export var closeButton: Button;

## Runs when the node is first created
func _ready() -> void:
	closeButton.pressed.connect(close_popup);

## Closes popup/clears from stack
func close_popup() -> void:
	queue_free();
	# Additional functionality can be added below
