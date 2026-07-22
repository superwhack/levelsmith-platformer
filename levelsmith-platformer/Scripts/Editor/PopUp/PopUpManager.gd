extends CanvasLayer

# TODO Functionality for stack exists, but is commented out until further clarification/dev

# Popup templates
const ERROR_TEMPLATE : PackedScene = preload("res://Scenes/UI/ErrorPopUpTemplate.tscn");
const HOVER_TEMPLATE : PackedScene = preload("res://Scenes/UI/HoverPopUpTemplate.tscn");
const SAVE_TEMPLATE : PackedScene = preload("res://Scenes/UI/SavingPopUpTemplate.tscn")

# Current shown popup
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
	# If there is a current popup, set its body text
	if (currentPopUp != null):
		currentPopUp.set_body_text(" - " + body) ;
		return;
	# Create a new popup based on the error template
	var newPopUp: Panel = ERROR_TEMPLATE.instantiate();
	# Set the title and text of the new pop up
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
	# Create a new popup based on the error template
	var newPopUp : Panel = ERROR_TEMPLATE.instantiate();
	# Set the title of the new popup
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
## callback : Function called when reset is pressed
func create_reset_asset_popup(callback : Callable) -> void:
	# Create a new popup based on the error template
	var newPopUp : Panel = ERROR_TEMPLATE.instantiate();
	
	# Set the title and body text
	newPopUp.set_title("Reset All Assets");
	newPopUp.set_body_text("This will reset all assets to default. All custom assets will be lost.");
	newPopUp.set_reset_callback(callback);
	newPopUp.resetButton.show();
	newPopUp.closeButton.text = "Cancel";
	add_child(newPopUp);
	currentPopUp = newPopUp;

## Creates a popup for resetting the specific given asset. 
## callback : Function called when reset is pressed
## asset : The name of the asset that is being reset
func create_reset_image_popup(callback : Callable, asset : String = "asset") -> void:
	# Create a new popup based on the error template
	var newPopUp : Panel = ERROR_TEMPLATE.instantiate();
	
	# Set properties of the popup
	newPopUp.set_title("Reset Selected Asset");
	newPopUp.set_body_text("This will reset your custom " + asset + " asset to its default. The current asset will be lost.");
	newPopUp.set_reset_callback(callback);
	newPopUp.resetButton.show();
	newPopUp.closeButton.text = "Cancel";
	add_child(newPopUp);
	currentPopUp = newPopUp;

## Creates a popup for deleting a level
## callback : The function that will be called when deleted
## levelName : The name of the level being deleted
func create_delete_popup(callback: Callable, levelName : String = "LEVEL") -> void:
	# Create a new popup based on the error template
	var newPopUp : Panel = ERROR_TEMPLATE.instantiate();
	
	# Set properties of the popup
	newPopUp.set_title("Delete \"" + levelName + "\"?")
	newPopUp.set_body_text("You are about to delete your \"" + levelName + "\" level. Are you sure you wish to proceed?");
	newPopUp.set_reset_callback(callback);
	newPopUp.resetButton.show();
	newPopUp.resetButton.text = "Delete";
	newPopUp.closeButton.text = "Cancel";
	add_child(newPopUp);
	currentPopUp = newPopUp;

## When saving a level, create the initial popup
func create_save_popup() -> void:
	# Create a new poopup based on the save template
	var newPopUp : Panel = SAVE_TEMPLATE.instantiate();
	
	# Set the properties of the popup
	newPopUp.set_title("Saving...");
	newPopUp.set_panel_color(Color(1.00, 0.97, 0.67), Color.YELLOW)
	##newPopUp.separator2.hide();
	newPopUp.set_body_text("[color=black]Do not close while Saving.[/color]");
	##newPopUp.resetButton.hide();
	##newPopUp.closeButton.hide();
	newPopUp.self_modulate = Color(1, 1, 1, 0);
	
	add_child(newPopUp);
	currentPopUp = newPopUp;

## When a save has been completed, create a save complete popup
func create_save_complete_popup() -> void:
	# Create a popup based on the save template
	var newPopUp : Panel = SAVE_TEMPLATE.instantiate();
	
	# Set the properties of the popup
	newPopUp.set_title("Save Complete!");
	newPopUp.set_panel_color(Color(0.68, 0.93, 0.68), Color.GREEN);
	##newPopUp.separator2.hide();
	newPopUp.set_body_text("[color=black]Saving Complete.[/color]");
	##newPopUp.resetButton.hide();
	##newPopUp.closeButton.hide();
	newPopUp.self_modulate = Color(1, 1, 1, 0);
	
	add_child(newPopUp);
	currentPopUp = newPopUp;

## If there are unsaved changes, create a popup for user convenience.
## saveQuitCallback : Function that will be called if the player saves and quits
## noSaveQuitCallback : Function that will be called if the player does not save and quit
func create_unsaved_changes_popup(saveQuitCallback: Callable, noSaveQuitCallback: Callable) -> void:
	# Create a new popup based on the error template
	var newPopUp : Panel = ERROR_TEMPLATE.instantiate();
	
	# Set properties of the popup
	newPopUp.set_title("Unsaved Changes!");
	newPopUp.set_body_text("You have unsaved changes. Are you sure you want to return to the main menu without saving?");
	newPopUp.set_save_to_menu_callback(saveQuitCallback);
	newPopUp.no_save_to_menu_callback(noSaveQuitCallback);
	newPopUp.saveQuitButton.show();
	newPopUp.noSaveQuitButton.show();
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
	
