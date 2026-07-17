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
	AudioManager.play_UI_effect("UISelection");
	toolManager.change_tool(Global.Tool.BRUSH);
	editorManager.change_current_hotbar(Global.HotbarState.TILES);
	brushButton.toggled;

## Swaps currently selected tool to the box brush
func swap_to_box_brush() -> void:
	AudioManager.play_UI_effect("UISelection");
	toolManager.change_tool(Global.Tool.BOX_BRUSH);
	editorManager.change_current_hotbar(Global.HotbarState.TILES);
	brushButton.toggled;
	
## Swaps currently selected tool to the cursor
func swap_to_cursor() -> void:
	AudioManager.play_UI_effect("UISelection");
	toolManager.change_tool(Global.Tool.CURSOR);
	var dropdownState = tileSwitch.entityPropDropdown.get_selected_id();
	editorManager.change_current_hotbar(dropdownState + 1);
	brushButton.toggled;
