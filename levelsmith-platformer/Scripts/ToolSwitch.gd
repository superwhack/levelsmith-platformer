extends HBoxContainer

@onready var editorManager : Node2D = get_parent().get_parent().get_parent();

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

## Called every frame. 
## delta: time elapsed since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_brush_tool_button_pressed() -> void:
	editorManager.change_tool(Global.Tool.BRUSH);

func _on_box_brush_tool_button_pressed() -> void:
	editorManager.change_tool(Global.Tool.BOX_BRUSH);

func _on_cursor_button_pressed() -> void:
	editorManager.change_tool(Global.Tool.CURSOR);
