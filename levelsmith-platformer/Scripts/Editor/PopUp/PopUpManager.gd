extends CanvasLayer

# TODO Functionality for stack exists, but is commented out until further clarification/dev

# Popup templates
const ERROR_TEMPLATE: PackedScene = preload("res://Scenes/UI/ErrorPopUpTemplate.tscn");

# Stack of messages (possible future addition if needed, would need to change some behavior)
#const POP_UP_STACK = [];

## Set the layer
func _ready() -> void:
	self.layer = 5;

## Creates an error popup with customizable content
## title: Title of error
## body: Body content of error
func create_error_popup(title: String = "Error", body: String = "An error has occurred") -> void:
	var newPopUp: Panel = ERROR_TEMPLATE.instantiate();
	
	# Add desired content to popup
	# WARNING I wonder if there is a better way to do this
	var popUpTitle: Label = newPopUp.find_child("Title");
	var popUpBody: RichTextLabel = newPopUp.find_child("Body");
	popUpTitle.text = title;
	popUpBody.text = body;
	
	# Add popup to scene and stack
	#POP_UP_STACK.append(newPopUp);
	add_child(newPopUp);
	
## Removes specific popup from popup stack
## item: Panel being removed from stack
#func removePopUpFromStack(item: Panel) -> void:
	##var itemIndex: int = POP_UP_STACK.find(item);
	#POP_UP_STACK.erase(item);
	#print("Removed item from stack");

## Clears popup stack of all items/panels	
#func clearPopUpStack() -> void:
	#POP_UP_STACK.clear();
	#print("Stack cleared");
	
