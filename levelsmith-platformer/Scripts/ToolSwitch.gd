extends HBoxContainer

# References to managers
@export var editorManager : Node2D;
@export var toolManager : Node2D;

func _on_brush_button_pressed() -> void:
	toolManager.change_tool(Global.Tool.BRUSH);
	editorManager.change_current_hotbar(Global.HotbarState.TILES);

func _on_box_brush_tool_button_pressed() -> void:
	toolManager.change_tool(Global.Tool.BOX_BRUSH);
	editorManager.change_current_hotbar(Global.HotbarState.TILES);

func _on_cursor_button_pressed() -> void:
	toolManager.change_tool(Global.Tool.CURSOR);
