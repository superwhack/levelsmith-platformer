extends CanvasLayer

# 
@export var messageTitle: Label;
@export var messageBody: Label;
@export var messageCloseButton: Button;

# Stack of messages
var popUpStack = [];

func _init(title: String, body: String) -> void:
	messageTitle.text = title;
	messageBody.text = body;
	
	# Get node 
	
	# Unsure if call is needed here or not
	#open();
	pass

func open() -> void:
	pass
	
func close_message_button_pressed() -> void:
	pass
