extends Node2D

# References to other scripts
@export var editorManager : Node2D;
@export var toolManager : Node2D;
@export var entityManager : Node2D;
@export var masterManager : Node2D;

# State of the selector frame
enum SelectorState {
	DEFAULT,
	ERASING,
	EDITING,
	MOVING,
	INVALID
}
var selectorState : SelectorState = SelectorState.DEFAULT;

# instantiated sprites
var invalidSprite : Sprite2D;
var selectorFrame : Sprite2D;

# Image variables
var brushIcon : Texture2D = preload("res://Assets/Sprites/UI/Brush.png");
var boxBrushIcon : Texture2D = preload("res://Assets/Sprites/UI/BoxBrush.png");
var cursorIcon : Texture2D = preload("res://Assets/Sprites/UI/Cursor.png");
var selectorFrameSprite : Texture2D = preload("res://Assets/Sprites/UI/SelectorFrame.png");
var invalidIcon : Texture2D = preload("res://Assets/Sprites/UI/Invalid.png"); 
var uiCursor : Texture2D = cursorIcon;

# mouse position reference  (always updated)
var currentMousePosition : Vector2;

# editing check for yellow state
var isEditing : bool;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Instantiate and hide the invalid sprite
	invalidSprite = Sprite2D.new();
	invalidSprite.texture = invalidIcon;
	add_child(invalidSprite);
	invalidSprite.hide();
	
	# Instantiates the selector frame
	selectorFrame = Sprite2D.new();
	selectorFrame.texture = selectorFrameSprite;
	add_child(selectorFrame);
	
	# Set the custom mouse cursor
	Input.set_custom_mouse_cursor(cursorIcon);

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# If global state is not in edit, set to cursor icon and bail out
	if (masterManager.state != Global.State.EDIT):
		Input.set_custom_mouse_cursor(cursorIcon);
		return;
	# Set the current mouse position and place the selector frame and invalid sprite to the correct locations
	currentMousePosition = editorManager.currentMousePosition;
	selectorFrame.global_position = currentMousePosition * Global.TILE_SIZE + Vector2(Global.TILE_SIZE / 2.0, Global.TILE_SIZE / 2.0);
	invalidSprite.global_position = get_global_mouse_position();
	
	isEditing = toolManager.currentTool == Global.Tool.CURSOR && editorManager.tileMap.get_cell_source_id(editorManager.currentMousePosition) >= editorManager.tileCount;
	
	update_selector_state();
	# Set the color of the selector frame based on the current action
	match (selectorState):
		SelectorState.DEFAULT:
			selectorFrame.modulate = Color(1, 1, 1);
		SelectorState.ERASING:
			selectorFrame.modulate = Color(1, 0, 0);
		SelectorState.EDITING:
			selectorFrame.modulate = Color(1, 1, 0);
		SelectorState.MOVING:
			if toolManager.prevBrushObject > -1:
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
	elif (isEditing): selectorState = SelectorState.EDITING; 
	elif (toolManager.isMoving): selectorState = SelectorState.MOVING;
	else: selectorState = SelectorState.DEFAULT;
