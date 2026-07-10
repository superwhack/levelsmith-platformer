extends Node2D

# Our exported managers for easy access
@export var editorManager : Node2D;
@export var entityManager : Node2D;
@export var tileManager : Node2D;

# references to UI elements
@export var tileSwitch : HBoxContainer;
@export var propertyMenu : Panel;

# reference to preview tile map
@export var previewTile : TileMapLayer;

# Variables that tools will utilize
var currentObjectRotation : int;
var isBackground : bool = false;
var currentTool :  Global.Tool = Global.Tool.BRUSH;
var boxBrushState : Global.BoxBrushState = Global.BoxBrushState.INACTIVE

# The previously selected tile before dragging
var prevBrushObject : int = -1;
var prevRotation : int = 0;
var prevIsBackground : bool = false;
var prevPosition : Vector2;
var brushObject : int = 0;

# A timer to differentiate between click and holding click
const POSITION_DIFFERENCE = .75;
var previousClickPos : Vector2;

# If the user starts a click on a UI element.
var clickOnUI : bool = false;

var firstBoxCorner : Vector2;
var secondBoxCorner : Vector2;
var isPainting : bool;
var isErasing : bool;
var isMoving : bool;
var isCopying : bool = false;
# This is needed so there is no chance of drop_entity running twice (which can happen due to the awai process_frame inside of it)
var justMoved : bool = false;

## A frame-by-frame process
## delta: time since previous frame
func _process(_delta: float) -> void:
	# Return early if clicking on UI as there is nothing to process
	if (clickOnUI):
		return;
	if (Input.is_action_just_pressed("left-click")):
		previousClickPos = editorManager.currentMousePosition;
	elif (Input.is_action_just_released("left-click")):
		previousClickPos = Vector2(0, 0);
		isMoving = false;
	
	if (boxBrushState == Global.BoxBrushState.PLACE || boxBrushState == Global.BoxBrushState.DELETE):
		secondBoxCorner = editorManager.currentMousePosition;

## One of the first input handles to run, catches if the user clicked on a UI element.
## event: the captured input event
func _input(event: InputEvent) -> void:
	# Check viewport if the user is hovering over a UI element
	if (event.is_action_pressed("left-click")):
		clickOnUI = get_viewport().gui_get_hovered_control() != null;
	# When released, the bool gets reset no matter what.
	elif (event.is_action_released("left-click")):
		clickOnUI = false;

## Input manager for any clicks or key presses that aren't on UI elements
## event: The key input being read.
func _unhandled_input(event: InputEvent) -> void:
	# Return early if clicking on UI, to fix key release issues.
	if (clickOnUI):
		return;
	
	if editorManager.returnClick && !Input.is_action_just_pressed("right-click"):
		if (Input.is_action_just_released("left-click") || Input.is_action_just_pressed("left-click")):
			editorManager.returnClick = false;
			
		if (currentTool != Global.Tool.BRUSH):
			return;
			
	match (currentTool):
		Global.Tool.BRUSH:
			if (event.is_action_pressed("left-click")):
				isPainting = true;
			elif (event.is_action_released("left-click")):
				isPainting = false;
				
			if (event.is_action_pressed("right-click")):
				isErasing = true;
			elif (event.is_action_released("right-click")):
				isErasing = false;
				
			if (isPainting): 
				tileManager.place_tile(editorManager.currentMousePosition);
			elif (isErasing):
				tileManager.delete_tile(editorManager.currentMousePosition);
				
		Global.Tool.BOX_BRUSH:
			match (boxBrushState):
				Global.BoxBrushState.INACTIVE, Global.BoxBrushState.PLACE_CONFIRM, Global.BoxBrushState.DELETE_CONFIRM:
					if (event.is_action_pressed("ui_accept") && boxBrushState != Global.BoxBrushState.INACTIVE):
						if (boxBrushState == Global.BoxBrushState.PLACE_CONFIRM):
							tileManager.box_place(firstBoxCorner, secondBoxCorner);
						elif (boxBrushState == Global.BoxBrushState.DELETE_CONFIRM):
							tileManager.box_delete(firstBoxCorner, secondBoxCorner);
					
					if (event.is_action_pressed("left-click")):
						firstBoxCorner = editorManager.currentMousePosition;
						secondBoxCorner = editorManager.currentMousePosition;
						boxBrushState = Global.BoxBrushState.PLACE;
					elif (event.is_action_pressed("right-click")):
						firstBoxCorner = editorManager.currentMousePosition;
						secondBoxCorner = editorManager.currentMousePosition;
						boxBrushState = Global.BoxBrushState.DELETE;
				
				Global.BoxBrushState.PLACE:
					if (event.is_action_released("left-click")):
						boxBrushState = Global.BoxBrushState.PLACE_CONFIRM;
				
				Global.BoxBrushState.DELETE:
					if (event.is_action_released("right-click")):
						boxBrushState = Global.BoxBrushState.DELETE_CONFIRM;
				
		Global.Tool.CURSOR:
			var currentCell = entityManager.tileMap.get_cell_source_id(editorManager.currentMousePosition);
			var previousCell = entityManager.tileMap.get_cell_source_id(previousClickPos);
			if (previousClickPos != Vector2(0,0) && !isMoving):
				justMoved = false;
				# If the cursor moves a certain distance away from the last click, start moving
				isMoving = previousClickPos.distance_to(editorManager.currentMousePosition) > POSITION_DIFFERENCE && previousCell != -1;
			if (event.is_action_released("left-click") && prevBrushObject == -1):
				if (entityManager.duplicatingResource != null && Input.is_action_pressed("copy")):
					entityManager.duplicatingResource = null;
				# If the clicked cell is an entity and the click was short, edit its properties
				elif (currentCell > Global.EntityType.GOAL && currentCell < Global.EntityType.PROP1 && !isMoving && currentCell != Global.EntityType.COIN):
					if Input.is_action_pressed("copy") && previousCell != -1 && currentCell != Global.EntityType.PLAYER:
						entityManager.duplicate_entity(editorManager.currentMousePosition);
					else:
						entityManager.duplicatingResource = null;
						entityManager.edit_properties(editorManager.currentMousePosition);
				# Otherwise, place the entity
				else:
					entityManager.place_entity(editorManager.currentMousePosition);
			elif (event.is_action_pressed("right-click")):
				entityManager.delete_entity(editorManager.currentMousePosition);
			
			# If left click is being held, pick up the current tile unless it's empty air.
			if (isMoving && prevBrushObject == -1 && previousCell != -1) && previousCell >= editorManager.tileCount && previousCell < Global.BEDROCK_TILE:
				entityManager.move_entity(previousClickPos);
			# If the tile is empty, then treat click and drag like a normal place (once the drag is release)
			elif (isMoving && prevBrushObject == -1):
				prevBrushObject = -2;
				prevPosition = Vector2(-1, -1);
			# Once the mouse click is released, drop the tile and reset to the previously selected tile brush
			elif (!isMoving && prevBrushObject != -1 && !justMoved):
				entityManager.drop_entity();
				isCopying = false;
				justMoved = true;

## Change the currently selected tile/entity if possible
## tile: the tile/entity to try and change to
func update_brush_object(objectId: int) -> void:
	entityManager.duplicatingResource = null;
	if (isMoving): return;
	
	if (currentTool == Global.Tool.CURSOR && objectId >= editorManager.tileCount):
		brushObject = objectId;
	elif (currentTool != Global.Tool.CURSOR && objectId < editorManager.tileCount):
		brushObject = objectId;

## Change the selected tool to the clicked on tool, adjusting the selected tile if needed.
## tool: The tool to change to
func change_tool(tool: Global.Tool) -> void:
	if (currentTool == tool):
		return;

	editorManager.returnClick = false;
	reset_tool_states();
	currentObjectRotation = 0;
	entityManager.duplicatingResource = null;

	if (currentTool == Global.Tool.CURSOR):
		brushObject = Global.TileType.SOLID;
	elif (tool == Global.Tool.CURSOR):
		brushObject = Global.EntityType.PROP1 if tileSwitch.entityPropDropdown.get_selected_id() == 1 else Global.EntityType.GOAL;

	if (currentTool == Global.Tool.BOX_BRUSH): 
		disable_box_brush();
	currentTool = tool;
	
	if (currentTool != Global.Tool.CURSOR):
		tileSwitch.display_tiles(true);
		tileSwitch.display_entities(false);
	else:
		tileSwitch.display_tiles(false);
		tileSwitch.display_entities(true);

	propertyMenu.close();
	previewTile.clear();
	
	
## Deactivates the box brush.
func disable_box_brush() -> void:
	boxBrushState = Global.BoxBrushState.INACTIVE;
	
## Rotate currently selected object
## Uses Alternative tiles 
func rotate_object() -> void:
	currentObjectRotation += 1;
	if (currentObjectRotation > 3): 
		currentObjectRotation = 0;
	
## Reset tool states 
func reset_tool_states() -> void:
	isPainting = false;
	isErasing = false;
	# isMoving is not neccesary.
