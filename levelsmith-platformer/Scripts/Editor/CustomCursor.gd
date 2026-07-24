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
	DUPLICATING,
	INVALID
}
var selectorState : SelectorState = SelectorState.DEFAULT;

# Cursor texture is saved, to prevent updates every frame.
var currentCursorTexture : Texture2D = null;

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
	change_cursor(uiCursor);
	entityManager.propertyMenu.hidden.connect(entityHighlight.hide);

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Custom cursor always appears like the UI cursor in the property menu or in non-edit states.
	if (editorManager.masterManager.state != Global.State.EDIT || editorManager.masterManager.propertyMenu.visible):
		change_cursor(uiCursor);
		return;
	
	# Hide the entity highlighter when not in the edit state or not using the cursor.
	if (editorManager.masterManager.state != Global.State.EDIT || toolManager.currentTool != Global.Tool.CURSOR):
		hide_entity_highlight();
	
	# Set the current mouse position and place the selector frame to the correct location
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
		SelectorState.DUPLICATING:
			selectorFrame.modulate = Color(1, 0, 1);
		SelectorState.INVALID:
			selectorFrame.modulate = Color(1, 1, 1, 0);
	
	var hoveredControl = get_viewport().gui_get_hovered_control();
	# For the entity-prop dropdown, it is a window, not a gui control.
	var popup = editorManager.toolManager.tileSwitch.entityPropDropdown.get_popup().visible;
	
	if (hoveredControl != null || popup):
		change_cursor(uiCursor);
	else:
		match (toolManager.currentTool):
			Global.Tool.BRUSH:
				change_cursor(brushIcon if editorManager.isPlaceable else brushInvalid);
			Global.Tool.BOX_BRUSH:
				change_cursor(boxBrushIcon if editorManager.isPlaceable else boxBrushInvalid);
			Global.Tool.CURSOR:
				if (toolManager.isMoving):
					change_cursor(cursorMove if editorManager.isPlaceable else cursorMoveInvalid);
				elif (isEditing):
					change_cursor(cursorEdit if editorManager.isPlaceable else cursorEditInvalid);
				else:
					change_cursor(cursorIcon if editorManager.isPlaceable else cursorInvalid);


## Shows the selector frame.
func show_selector_frame() -> void:
	selectorFrame.show();

## Hides the selector frame. Shows the entity highlight if duplicating.
func hide_selector_frame() -> void:
	selectorFrame.hide();
	
	if (selectorState == SelectorState.DUPLICATING):
		entityHighlight.show();

## Shows the entity highlight.
func show_entity_highlight() -> void:
	entityHighlight.show();
	
## Hides the entity highlight.
func hide_entity_highlight() -> void:
	entityHighlight.hide();

## Updates the state of the selector frame in accordance with other actions.
func update_selector_state() -> void:
	if (editorManager.isScreenshotting):
		return;
		
	if (!editorManager.isPlaceable): selectorState = SelectorState.INVALID;
	elif (toolManager.isErasing): selectorState = SelectorState.ERASING;
	elif (entityManager.duplicatingResource): 
		selectorState = SelectorState.DUPLICATING;
		entityHighlight.show();
	elif (isEditing): selectorState = SelectorState.EDITING; 
	elif (toolManager.isMoving && toolManager.prevBrushObject >= 0): 
		selectorState = SelectorState.MOVING;
		entityHighlight.hide();
	else: selectorState = SelectorState.DEFAULT;

## Moves the entity highlighter to the selected entity and displays it
## entityPosition: Where the selected entity is
func highlight_selected_entity(entityPosition : Vector2) -> void:
	entityHighlight.position = entityPosition * Global.TILE_SIZE + Vector2(Global.TILE_SIZE / 2.0, Global.TILE_SIZE / 2.0);
	entityHighlight.show();
	
## Setting the cursor every frame can break on web builds. This helps prevent glitchy custom cursors.
func change_cursor(newCursor: Texture2D) -> void:
	if (currentCursorTexture != newCursor):
		currentCursorTexture = newCursor;
		Input.set_custom_mouse_cursor(newCursor);
