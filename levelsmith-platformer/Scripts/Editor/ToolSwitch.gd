extends VBoxContainer

# References to managers
@export var editorManager : Node2D;
@export var toolManager : Node2D;
@export var tileSwitch : HBoxContainer;

# Button references for signal connections
@export var brushButton : Button;
@export var boxBrushButton : Button;
@export var cursorButton : Button;

## Runs when the node is first created. Used for connecting signals.
func _ready() -> void:
	brushButton.pressed.connect(swap_to_brush);
	boxBrushButton.pressed.connect(swap_to_box_brush);
	cursorButton.pressed.connect(swap_to_cursor);

## Swaps currently selected tool to the brush
func swap_to_brush() -> void:
	# Play ui sound effect
	AudioManager.play_UI_effect("UISelection");
	# Change the selected tool and hotbar
	toolManager.change_tool(Global.Tool.BRUSH);
	editorManager.change_current_hotbar(Global.HotbarState.TILES);
	if (!brushButton.button_pressed):
		brushButton.button_pressed = true;
	# Give focus to the brush button
	if (!brushButton.has_focus()):
		brushButton.grab_focus();

## Swaps currently selected tool to the box brush
func swap_to_box_brush() -> void:
	# Play ui sound effect
	AudioManager.play_UI_effect("UISelection");
	# Change the selected tool and hotbar
	toolManager.change_tool(Global.Tool.BOX_BRUSH);
	editorManager.change_current_hotbar(Global.HotbarState.TILES);
	if (!boxBrushButton.button_pressed):
		boxBrushButton.button_pressed = true;
	# Give focus to the box brush button
	if (!boxBrushButton.has_focus()):
		boxBrushButton.grab_focus();
	
## Swaps currently selected tool to the cursor
func swap_to_cursor() -> void:
	# Play ui sound effect
	AudioManager.play_UI_effect("UISelection");
	# Change the selected tool and hotbar
	toolManager.change_tool(Global.Tool.CURSOR);
	# Set the dropdown state to that of the currently selected item
	var dropdownState = tileSwitch.entityPropDropdown.get_selected_id();
	editorManager.change_current_hotbar(dropdownState + 1);
	if (!cursorButton.button_pressed):
		cursorButton.button_pressed = true;
		# Give focus to the cursor button
	if (!cursorButton.has_focus()):
		cursorButton.grab_focus();
