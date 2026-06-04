extends Node2D

# References to other scripts
@export var tileSet: TileMapLayer;
@export var editorManager: Node2D;
@export var toolManager: Node2D;
@export var entityManager: Node2D;

# State of the selector frame
enum SelectorState {
	DEFAULT,
	ERASING,
	EDITING,
	MOVING,
	INVALID
}
var selectorState: SelectorState;

# Sprite variables
@export var selectorFrameSprite: Sprite2D;
@export var invalidIcon: Sprite2D;

# instantiated sprites
var invalidSprite: Sprite2D;
var selectorFrame: Sprite2D;

# Image variables
var brushIcon: Texture2D = load("res://Assets/Sprites/UI/Brush.png");
var boxBrushIcon: Texture2D = load("res://Assets/Sprites/UI/BoxBrush.png");
var cursorIcon: Texture2D = load("res://Assets/Sprites/UI/Cursor.png");
var uiCursor: Texture2D = cursorIcon;

# mouse position reference  (always updated)
var currentMousePosition: Vector2;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	invalidSprite = invalidIcon.instantiate();
	add_child(invalidSprite);
	invalidSprite.hide();
	
	selectorFrame = selectorFrameSprite.instantiate();
	add_child(selectorFrame);
	
	Input.set_custom_mouse_cursor(brushIcon);
	pass # Replace with function body.


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	currentMousePosition = editorManager.currentMousePosition;
	selectorFrame.global_position = currentMousePosition * Global.tileSize;
	invalidSprite.global_position = get_global_mouse_position();
	
	update_selector_state();
	match (selectorState):
		SelectorState.DEFAULT:
			selectorFrame.modulate = Color(1, 1, 1);
		SelectorState.ERASING:
			selectorFrame.modulate = Color(1, 0, 0);
		SelectorState.EDITING:
			selectorFrame.modulate = Color(1, 1, 0);
		SelectorState.MOVING:
			selectorFrame.modulate = Color(0, 1, 1);
		SelectorState.INVALID:
			selectorFrame.modulate = Color(1, 1, 1, 0);
	
	if (get_viewport().gui_get_hovered_control()):
		Input.set_custom_mouse_cursor(uiCursor);
	else:
		match (toolManager.currentTool):
			Global.Tool.BRUSH:
				Input.set_custom_mouse_cursor(brushIcon);
			Global.Tool.BOX_BRUSH:
				Input.set_custom_mouse_cursor(boxBrushIcon);
			Global.Tool.CURSOR:
				Input.set_custom_mouse_cursor(cursorIcon);
	invalidSprite.visible = !editorManager.isPlaceable;
	pass

## Updates the state of the selector frame in accordance with other actions.
func update_selector_state() -> void:
	if (!editorManager.isPlaceable): selectorState = SelectorState.INVALID;
	elif (toolManager.isErasing): selectorState = SelectorState.ERASING;
	elif (entityManager.isEditing): selectorState = SelectorState.EDITING; 
	elif (toolManager.isMoving): selectorState = SelectorState.MOVING;
	else: selectorState = SelectorState.DEFAULT;
