extends HBoxContainer

# References to managers
@export var editorManager : Node2D;
@export var toolManager : Node2D;

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
	toolManager.change_tool(Global.Tool.BRUSH);
	editorManager.change_current_hotbar(Global.HotbarState.TILES);

## Swaps currently selected tool to the box brush
func swap_to_box_brush() -> void:
	toolManager.change_tool(Global.Tool.BOX_BRUSH);
	editorManager.change_current_hotbar(Global.HotbarState.TILES);

## Swaps currently selected tool to the cursor
func swap_to_cursor() -> void:
	toolManager.change_tool(Global.Tool.CURSOR);
	editorManager.change_current_hotbar(Global.HotbarState.ENTITIES);
