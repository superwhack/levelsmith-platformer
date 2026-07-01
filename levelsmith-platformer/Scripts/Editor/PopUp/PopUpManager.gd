extends CanvasLayer

# TODO Functionality for stack exists, but is commented out until further clarification/dev

# Popup templates
const ERROR_TEMPLATE : PackedScene = preload("res://Scenes/UI/ErrorPopUpTemplate.tscn");
const HOVER_TEMPLATE : PackedScene = preload("res://Scenes/UI/HoverPopUpTemplate.tscn")

var currentPopUp : Panel;

# Stack of messages (possible future addition if needed, would need to change some behavior)
#const POP_UP_STACK = [];

## Set the layer
func _ready() -> void:
	layer = 5;

## Creates an error popup with customizable content
## title: Title of error
## body: Body content of error
func create_error_popup(title : String = "Error", body : String = "An error has occurred") -> void:
	if (currentPopUp != null):
		currentPopUp.set_body_text("\n - " + body) ;
		return;
	var newPopUp: Panel = ERROR_TEMPLATE.instantiate();
	
	newPopUp.set_title(title);
	newPopUp.set_body_text(" - " + body);
	
	#POP_UP_STACK.append(newPopUp);
	add_child(newPopUp);
	currentPopUp = newPopUp;

## Creates an error popup that contains multiple errors
## title: Title of error
## body: Body content of error as an array
func create_multi_error_popup(title : String = "Error", body : Array[String] = []) -> void:
	# If there's only one body string, create a single popup
	if (body.size()) == 1:
		return create_error_popup(title, body[0]);
		
	var newPopUp : Panel = ERROR_TEMPLATE.instantiate();
	
	newPopUp.set_title(title);
	
	# Assemble the body text before adding it to the popup
	var bodyText : String = "";
	for messageNum in range(0, body.size()):
		bodyText += " - " + body[messageNum];
		if (messageNum != body.size() - 1):
			bodyText += "\n"
	newPopUp.set_body_text(bodyText);
	
	add_child(newPopUp);
	currentPopUp = newPopUp;
	

## Creates a popup for resetting the specific given asset. 
func create_reset_asset_popup(callback : Callable, asset : String = "asset") -> void:
	var newPopUp : Panel = ERROR_TEMPLATE.instantiate();
	
	newPopUp.set_title("RESET ALL ASSETS");
	newPopUp.set_body_text("This will RESET ALL ASSETS to default. All custom assets will be lost.");
	newPopUp.set_confirm_callback(callback);
	newPopUp.closeButton.text = "Cancel";
	add_child(newPopUp);
	currentPopUp = newPopUp;
	
## Creates a popup for resetting the specific given asset. 
func create_reset_image_popup(callback : Callable, asset : String = "asset") -> void:
	var newPopUp : Panel = ERROR_TEMPLATE.instantiate();
	
	newPopUp.set_title("RESET SELECTED ASSET");
	newPopUp.set_body_text("This will [color=#e74937]RESET[/color] your custom " + asset + " asset to its default. The current asset will be lost.");
	newPopUp.set_confirm_callback(callback);
	newPopUp.closeButton.text = "Cancel";
	add_child(newPopUp);
	currentPopUp = newPopUp;


## Simply kills all its children
func clear_all_popups() -> void:
	for child in get_children():
		child.queue_free();

	
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
	
