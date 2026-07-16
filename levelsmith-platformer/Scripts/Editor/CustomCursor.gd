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
	COPYING,
	INVALID
}
var selectorState : SelectorState = SelectorState.DEFAULT;

# instantiated sprites
var selectorFrame : Sprite2D;
var entityHighlight : Sprite2D;

# Default cursor
var uiCursor : Texture2D = preload("res://Assets/Sprites/UI/Cursors/CursorDefault.PNG");

# Brush icons
var brushIcon : Texture2D = preload("res://Assets/Sprites/UI/Cursors/CursorBrush.PNG");
var brushInvalid : Texture2D = preload("res://Assets/Sprites/UI/Cursors/CursorBrushBlocked.PNG");

# Box Brush icons
var boxBrushIcon : Texture2D = preload("res://Assets/Sprites/UI/Cursors/CursorBox.PNG");
var boxBrushInvalid : Texture2D = preload("res://Assets/Sprites/UI/Cursors/CursorBoxBlocked.PNG");

# Cursor Tool icons
var cursorIcon : Texture2D = preload("res://Assets/Sprites/UI/Cursors/CursorPoint.PNG");
var cursorInvalid : Texture2D = preload("res://Assets/Sprites/UI/Cursors/CursorPointBlocked.PNG");
var cursorMove : Texture2D = preload("res://Assets/Sprites/UI/Cursors/CursorGrab.PNG");
var cursorMoveInvalid : Texture2D = preload("res://Assets/Sprites/UI/Cursors/CursorGrabBlocked.PNG");
var cursorEdit : Texture2D = preload("res://Assets/Sprites/UI/Cursors/CursorHand.PNG");
var cursorEditInvalid : Texture2D = preload("res://Assets/Sprites/UI/Cursors/CursorHandBlocked.PNG");

# Selector Frame
var selectorFrameSprite : Texture2D = preload("res://Assets/Sprites/UI/SelectorFrame.png");
var selectorFrameDashed : Texture2D = preload("res://Assets/Sprites/UI/SelectorFrameDashed.png");

# mouse position reference  (always updated)
var currentMousePosition : Vector2;

# editing check for yellow state
var isEditing : bool;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Instantiates the selector frame
	selectorFrame = Sprite2D.new();
	selectorFrame.texture = selectorFrameSprite;
	add_child(selectorFrame);
	
	entityHighlight = Sprite2D.new();
	entityHighlight.modulate = Color.YELLOW;
	entityHighlight.texture = selectorFrameDashed;
	add_child(entityHighlight);
	entityHighlight.hide();
	
	# Set the custom mouse cursor
	Input.set_custom_mouse_cursor(uiCursor);
	entityManager.propertyMenu.hidden.connect(entityHighlight.hide);

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# If global state is not in edit, set to cursor icon and bail out
	if (masterManager.state != Global.State.EDIT || editorManager.masterManager.propertyMenu.visible):
		Input.set_custom_mouse_cursor(uiCursor);
		return;
	# Set the current mouse position and place the selector frame and invalid sprite to the correct locations
	currentMousePosition = editorManager.currentMousePosition;
	selectorFrame.global_position = currentMousePosition * Global.TILE_SIZE + Vector2(Global.TILE_SIZE / 2.0, Global.TILE_SIZE / 2.0);
	
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
			selectorFrame.modulate = Color(0, 1, 1);
		SelectorState.COPYING:
			selectorFrame.modulate = Color(1, 0, 1);
		SelectorState.INVALID:
			selectorFrame.modulate = Color(1, 1, 1, 0);
	
	var hoveredControl = get_viewport().gui_get_hovered_control();
	# For the entity-prop dropdown, it is a window, not a gui control.
	var popup = editorManager.toolManager.tileSwitch.entityPropDropdown.get_popup().visible;
	print(popup)
	if (hoveredControl != null || popup):
		Input.set_custom_mouse_cursor(uiCursor);
	else:
		match (toolManager.currentTool):
			Global.Tool.BRUSH:
				Input.set_custom_mouse_cursor(brushIcon if editorManager.isPlaceable else brushInvalid);
			Global.Tool.BOX_BRUSH:
				Input.set_custom_mouse_cursor(boxBrushIcon if editorManager.isPlaceable else boxBrushInvalid);
			Global.Tool.CURSOR:
				if (toolManager.isMoving):
					Input.set_custom_mouse_cursor(cursorMove if editorManager.isPlaceable else cursorMoveInvalid);
				elif (isEditing):
					Input.set_custom_mouse_cursor(cursorEdit if editorManager.isPlaceable else cursorEditInvalid);
				else:
					Input.set_custom_mouse_cursor(cursorIcon if editorManager.isPlaceable else cursorInvalid);
	
## Shows the selector frame.
func show_selector_frame() -> void:
	selectorFrame.show();

## Hides the selector frame.
func hide_selector_frame() -> void:
	selectorFrame.hide();
	
	if (selectorState == SelectorState.COPYING):
		entityHighlight.show();

## Updates the state of the selector frame in accordance with other actions.
func update_selector_state() -> void:
	if (!editorManager.isPlaceable): selectorState = SelectorState.INVALID;
	elif (toolManager.isErasing): selectorState = SelectorState.ERASING;
	elif (entityManager.duplicatingResource): 
		selectorState = SelectorState.COPYING;
		entityHighlight.show();
	elif (isEditing): selectorState = SelectorState.EDITING; 
	elif (toolManager.isMoving && toolManager.prevBrushObject >= 0): 
		selectorState = SelectorState.MOVING;
		entityHighlight.hide();
	else: selectorState = SelectorState.DEFAULT;

## Moves the entity highlighter to the selected entity and displays it
## entityPosition: Where the selected entity is
func highlight_selected_entity(entityPosition: Vector2) -> void:
	entityHighlight.position = entityPosition * Global.TILE_SIZE + Vector2(Global.TILE_SIZE / 2.0, Global.TILE_SIZE / 2.0);
	entityHighlight.show();
