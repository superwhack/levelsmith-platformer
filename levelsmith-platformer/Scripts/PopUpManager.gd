extends CanvasLayer

# TODO Functionality for stack exists, but is commented out until further clarification/dev

# Popup templates
var DebugTemplate = preload("res://Scenes/UI/ErrorPopUpTemplate.tscn");

# Stack of messages (possible future addition if needed, would need to change some behavior)
#const POP_UP_STACK = [];

## Creates a debug popup with customizable content
## title: Title of debug error
## body: Body content of debug error
func createDebugPopUp(title: String = "Error", body: String = "An error has occurred") -> void:
	var newPopUp = DebugTemplate.instantiate();
	
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
	
## Test function with sole purpose of creating example popUp outside of code
## Delete later
func createTestPopUp() -> void:
	createDebugPopUp("My awesome title", "Misc Body Text");

## Test function with sole purpose of creating generic example popUp outside of code
## Delete later
func createGenericTestPopUp() -> void:
	createDebugPopUp();
