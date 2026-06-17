extends Node2D

# Our exported managers for easy access
@export var editorManager: Node2D;
@export var entityManager: Node2D;
@export var tileManager: Node2D;

# references to UI elements
@export var tileSwitch: HBoxContainer;
@export var propertyMenu: Panel;

# reference to preview tile map
@export var previewTile: TileMapLayer;

# Vars that tools will utilize
var currentObjectRotation: int;
var currentTool:  Global.Tool = Global.Tool.BRUSH;
var boxBrushState: Global.BoxBrushState = Global.BoxBrushState.INACTIVE

# The previously selected tile before dragging
var prevEntity : int = -1;
var prevRotation : int = 0;
var prevPosition: Vector2;
var brushObject: int = 0;

# A timer to differentiate between click and holding click
const holdTimeCap = .15;
var holdTimer := holdTimeCap;

var firstBoxCorner : Vector2;
var secondBoxCorner : Vector2;
var isPainting : bool;
var isErasing : bool;
var isMoving : bool;

func _process(_delta: float):
	if (Input.is_action_pressed("left-click")):
		holdTimer -= _delta;
	elif (Input.is_action_just_released("left-click")):
		holdTimer = holdTimeCap;
	
	
	if (boxBrushState == Global.BoxBrushState.PLACE || boxBrushState == Global.BoxBrushState.DELETE):
		secondBoxCorner = editorManager.currentMousePosition;
	

## Input manager for any clicks or key presses that aren't on UI elements
## event: The key input being read.
func _unhandled_input(event: InputEvent) -> void:	
	if editorManager.returnClick :
		if (Input.is_action_just_released("left-click")):
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
				
			if isPainting: 
				tileManager.place_tile(editorManager.currentMousePosition);
			elif isErasing:
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
			if (event.is_action_released("left-click") && prevEntity == -1):
				# If the clicked cell is an entity and the click was short, edit its properties
				if (entityManager.tileSet.get_cell_source_id(editorManager.currentMousePosition) > Global.EntityType.GOAL && holdTimer > -.5):
					entityManager.edit_properties(editorManager.currentMousePosition);
				# Otherwise, place the entity
				else:
					entityManager.place_entity(editorManager.currentMousePosition);
			elif (event.is_action_pressed("right-click")):
				entityManager.delete_entity(editorManager.currentMousePosition);
			
			# If left click is being held, pick up the current tile unless it's empty air.
			if (holdTimer < 0 && prevEntity == -1 && entityManager.tileSet.get_cell_source_id(editorManager.currentMousePosition) != -1) && entityManager.tileSet.get_cell_source_id(editorManager.currentMousePosition) >= editorManager.tileCount:
				entityManager.move_entity();
			# If the tile is empty, then treat click and drag like a normal place (once the drag is release)
			elif (holdTimer < 0 && prevEntity == -1):
				prevEntity = -2;
			# Once the mouse click is released, drop the tile and reset to the previously selected tile brush
			elif (holdTimer == holdTimeCap && prevEntity != -1):
				entityManager.drop_entity();

## Change the currently selected tile/entity if possible
## tile: the tile/entity to try and change to
func update_brush_object(objectId: int) -> void:
	if isMoving: return;
	
	if currentTool == Global.Tool.CURSOR && objectId >= editorManager.tileCount:
		brushObject = objectId;
	elif currentTool != Global.Tool.CURSOR && objectId < editorManager.tileCount:
		brushObject = objectId;

## Change the selected tool to the clicked on tool, adjusting the selected tile if needed.
## tool: The tool to change to
func change_tool(tool: Global.Tool) -> void:
	if currentTool == tool:
		return;
	editorManager.returnClick = false;
	reset_tool_states();

	if (currentTool == Global.Tool.CURSOR):
		brushObject = Global.TileType.SOLID;
	elif (tool == Global.Tool.CURSOR):
		brushObject = Global.EntityType.GOAL;
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
	return;
	match currentTool:
		Global.Tool.CURSOR:
			update_brush_object(Global.EntityType.GOAL);
		Global.Tool.BOX_BRUSH:
			update_brush_object(Global.TileType.SOLID);
		Global.Tool.BRUSH:
			update_brush_object(Global.TileType.SOLID);
	print("Current Tool: ", currentTool);

## Deactivates the box brush.
func disable_box_brush() -> void:
	boxBrushState = Global.BoxBrushState.INACTIVE;
	
## Rotate currently selected object
## NOTE: SceneCollection rotations work most likely by selecting the scene and rotating it, you can't spawn it rotated
func rotate_object() -> void:
	match currentObjectRotation:
		0:
			currentObjectRotation = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H;
		TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H:
			currentObjectRotation = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V;
		TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V:
			currentObjectRotation = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V;
		_:
			currentObjectRotation = 0;
	
## Reset tool states 
func reset_tool_states() -> void:
	isPainting = false;
	isErasing = false;
	# isMoving is not neccesary.
