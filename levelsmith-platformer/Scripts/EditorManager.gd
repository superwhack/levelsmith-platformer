extends Node2D

# Tool-based variables
var currentTool := Global.Tool.BRUSH;
var brushTile : int;
var validationCheck := false;
var painting : bool = false;
var erasing : bool = false;

# References to grid TileMapLayer child nodes
@export var tileSet: TileMapLayer;
@export var gridLines: TileMapLayer;
@export var previewTileMap: TileMapLayer;

# Reference to selector image
@export var selector: Sprite2D;

# Reference to TileSwitch for transparency
@export var tileSwitch: HBoxContainer;
@export var toolSwitch: HBoxContainer;

# Reference to PropertyMenu for editing properties
@export var propertyMenu: Panel;

# Play button
@export var playButton: Button;

# Mouse position variables
var currentMousePosition: Vector2;
var prevMousePosition: Vector2;

var currentHotbarState : Global.HotbarState;

# Mouse assets
var cursorToolImage = load('res://Assets/Sprites/UI/cursor.png');
var brushToolImage = load('res://Assets/Sprites/UI/paintBrush.png');
var boxToolImage = load('res://Assets/Sprites/UI/boxBrush.png');
var invalidPlaceImage = load('res://Assets/Sprites/UI/no.png');
var uiHoverImage = load('res://Assets/Sprites/UI/cursor.png');

# A timer to differentiate between click and holding click
const holdTimeCap = .15;
var holdTimer := holdTimeCap;
# Previously selected tile before dragging.
var prevTile := -1;

var tileRotation := 0;

# Box brush variables and enum
enum BoxBrushState {
	INACTIVE,
	CREATE,
	DELETE,
	CREATE_CONFIRM,
	DELETE_CONFIRM
}
var boxBrushState: BoxBrushState = BoxBrushState.INACTIVE;
var firstCornerClick: Vector2;
var secondCornerClick: Vector2;

# Flag for placeable areas
var isPlaceable: bool = true;

# Player spawnpoint. Set when placing the entity.
var playerSpawnPosition: Vector2 = Vector2(-1, -1);

# Stores the number of tiles made
var tileCount := Global.TileType.size();

## Runs once when the script is ready.
## Set up any reference variables here.
func _ready() -> void:
	# Assign self reference to UI
	tileSwitch.editorManager = self;
	toolSwitch.editorManager = self;
	
	Input.set_custom_mouse_cursor(brushToolImage);
	
	brushTile = Global.TileType.SOLID;
	
	fill_grid_lines();
	
	print("Level Height:", get_parent().worldSize.y);
	print("Level Width:", get_parent().worldSize.x);


## Runs every frame during the editing state
## _delta: how much time has passed
func _process(_delta: float) -> void:
	# record the position of the mouse on this frame
	currentMousePosition = get_grid_mouse_position(get_global_mouse_position());
	
	isPlaceable = !check_out_of_bounds(currentMousePosition);
	if (currentTool == Global.Tool.BRUSH && tileSet.get_cell_source_id(currentMousePosition) >= tileCount): isPlaceable = false; 
	if (currentTool == Global.Tool.CURSOR && tileSet.get_cell_source_id(currentMousePosition) < tileCount && tileSet.get_cell_source_id(currentMousePosition) >= 0): isPlaceable = false; 
	
	if (Input.is_action_pressed("left-click")):
		holdTimer -= _delta;
	elif (Input.is_action_just_released("left-click")):
		holdTimer = holdTimeCap;
	
	if (holdTimer > 0 && (boxBrushState != BoxBrushState.CREATE_CONFIRM && boxBrushState != BoxBrushState.DELETE_CONFIRM)):
		update_preview_tile(currentMousePosition, prevMousePosition);
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED);
	get_tree().set_group("Enemy", "process_mode", Node.PROCESS_MODE_DISABLED);
	
	if (boxBrushState == BoxBrushState.CREATE || boxBrushState == BoxBrushState.DELETE):
		secondCornerClick = currentMousePosition;
		update_box_preview(firstCornerClick, secondCornerClick);
	playButton.modulate = Color(1, 1, 1, float(playerSpawnPosition != Vector2(-1, -1)) / 2 + .5);
	
	# save the mouse position to the previous frame
	prevMousePosition = currentMousePosition;
	update_selector();

## Update the selector and cursor in accordance to current location and ability to place tiles
func update_selector() -> void:
	selector.position = currentMousePosition * 128 + Vector2(64, 64);
	var hoverTile = tileSet.get_cell_source_id(currentMousePosition);
	
	# WARNING: potential issues with elif chain interfering with mouse cursor image swap
	if(get_viewport().gui_get_hovered_control()):
		Input.set_custom_mouse_cursor(uiHoverImage);
		selector.modulate = Color(0, 0, 0, 0);
	elif ((hoverTile >= tileCount && brushTile < tileCount) || (hoverTile < tileCount && hoverTile > -1 && brushTile >= tileCount) || check_out_of_bounds(currentMousePosition)):
		Input.set_custom_mouse_cursor(invalidPlaceImage);
		selector.modulate = Color(0, 0, 0, 0);
	elif (prevTile > -1 && Input.is_action_pressed("click")):
		selector.modulate = Color(0, 1, 1, 1);
	elif (erasing):
		selector.modulate = Color(1, 0, 0, 1);
	else:
		selector.modulate = Color(1, 1, 1, 1);
		match(currentTool):
			Global.Tool.CURSOR:
				Input.set_custom_mouse_cursor(cursorToolImage);
			Global.Tool.BRUSH:
				Input.set_custom_mouse_cursor(brushToolImage);
			Global.Tool.BOX_BRUSH:
				Input.set_custom_mouse_cursor(boxToolImage);

## Input manager for any clicks or key presses that aren't on UI elements
## event: The key input being read.
func _unhandled_input(event: InputEvent) -> void:	
	match (currentTool):
		Global.Tool.BRUSH:
			if (event.is_action_pressed("left-click")):
				painting = true;
			elif (event.is_action_released("left-click")):
				painting = false;
				
			if (event.is_action_pressed("right-click")):
				erasing = true;
			elif (event.is_action_released("right-click")):
				erasing = false;
				
			if painting: 
				place_tile(currentMousePosition);
			elif erasing:
				delete_tile(currentMousePosition);
		Global.Tool.BOX_BRUSH:
			match (boxBrushState):
				BoxBrushState.INACTIVE, BoxBrushState.CREATE_CONFIRM, BoxBrushState.DELETE_CONFIRM:
					if (event.is_action_pressed("jump") && boxBrushState != BoxBrushState.INACTIVE):
						box_edit(firstCornerClick, secondCornerClick);
					
					if (event.is_action_pressed("left-click")):
						firstCornerClick = currentMousePosition;
						boxBrushState = BoxBrushState.CREATE;
					elif (event.is_action_pressed("right-click")):
						firstCornerClick = currentMousePosition;
						boxBrushState = BoxBrushState.DELETE;
				
				BoxBrushState.CREATE:
					if (event.is_action_released("left-click")):
						boxBrushState = BoxBrushState.CREATE_CONFIRM;
				
				BoxBrushState.DELETE:
					if (event.is_action_released("right-click")):
						boxBrushState = BoxBrushState.DELETE_CONFIRM;
				
		Global.Tool.CURSOR:
			if (event.is_action_released("left-click") && prevTile == -1):
				# If the clicked cell is an entity and the click was short, edit its properties
				if (tileSet.get_cell_source_id(currentMousePosition) >= 6 && holdTimer > -.5):
					edit_properties(currentMousePosition);
				# Otherwise, place the entity
				else:
					place_entity(currentMousePosition);
			elif (event.is_action_pressed("right-click")):
				delete_entity(currentMousePosition);
			
			# If left click is being held, pick up the current tile unless it's empty air.
			if (holdTimer < 0 && prevTile == -1 && tileSet.get_cell_source_id(currentMousePosition) != -1) && tileSet.get_cell_source_id(currentMousePosition) >= tileCount:
				# NOTE: THIS COMMENT BREAKS IT, BUT WE STILL SHOULD SAVE ROTATIONS SOMEWHERE
				#tileRotation = tileSet.get_cell_alternative_tile(currentMousePosition);
				# Await is needed to it has time to update selectedTile
				prevTile = brushTile;
				await get_tree().process_frame;
				brushTile = tileSet.get_cell_source_id(currentMousePosition);
				if (brushTile == Global.EntityType.PLAYER):
					playerSpawnPosition = Vector2(-1, -1);
				previewTileMap.modulate = Color(1, 1, 1, 1);
				tileSet.erase_cell(currentMousePosition);
			# If the tile is empty, then treat click and drag like a normal place (once the drag is release)
			elif (holdTimer < 0 && prevTile == -1):
				prevTile = -2;
			# If an entity is currently picked up and click is still being held, update the previewmap to look like the tile's being dragged around
			elif (holdTimer < 0):
				previewTileMap.clear();
				# If the condition for prevTile = -2 above has happened, just handle previews normally
				if (prevTile == -2):
					update_preview_tile(currentMousePosition, prevMousePosition);
				# Otherwise handle the previews but wil no transparency on the tile map
				else:
					if (brushTile >= tileCount):
						previewTileMap.set_cell(currentMousePosition, brushTile, Vector2i.ZERO, 2);
					elif (brushTile != Global.TileType.ONEWAY):
						previewTileMap.set_cell(currentMousePosition, brushTile, Vector2i.ZERO, tileRotation);
					else:
						previewTileMap.set_cell(currentMousePosition, brushTile, Vector2i.ZERO);
			# Once the mouse click is released, drop the tile and reset to the previously selected tile brush
			elif (holdTimer == holdTimeCap && prevTile != -1):
				drop_tile();
	if event.is_action_pressed("rotate"):
		rotate_tile();
	
	if event.is_action_pressed("brush-tool"):
		if (prevTile != -1):
			drop_tile();
		change_tool(Global.Tool.BRUSH);
		change_current_hotbar(Global.HotbarState.TILES);

	elif event.is_action_pressed("box-brush-tool"):
		if (prevTile != -1):
			drop_tile();
		change_tool(Global.Tool.BOX_BRUSH);
		change_current_hotbar(Global.HotbarState.TILES);

	elif event.is_action_pressed("cursor-tool"):
		change_tool(Global.Tool.CURSOR);
		
	# Tile/Entity hotkeys
	match(currentHotbarState):
		Global.HotbarState.TILES:
			if event.is_action_pressed("first-select"):
				update_brush_tile(Global.TileType.SOLID);
			elif event.is_action_pressed("second-select"):
				update_brush_tile(Global.TileType.ONEWAY);
			elif event.is_action_pressed("third-select"):
				update_brush_tile(Global.TileType.DEATH);
			elif event.is_action_pressed("fourth-select"):
				update_brush_tile(Global.TileType.ICE);
			elif event.is_action_pressed("fifth-select"):
				update_brush_tile(Global.TileType.STICKY);
			elif event.is_action_pressed("sixth-select"):
				update_brush_tile(Global.TileType.BOUNCE);
			elif event.is_action_pressed("seventh-select"):
				update_brush_tile(Global.TileType.SLOPE);
		Global.HotbarState.ENTITIES:
			if event.is_action_pressed("first-select"):
				update_brush_tile(Global.EntityType.GOAL);
			elif event.is_action_pressed("second-select"):
				update_brush_tile(Global.EntityType.PLAYER);
			elif event.is_action_pressed("third-select"):
				update_brush_tile(Global.EntityType.PATROLLING);
		Global.HotbarState.PROPS:
			if event.is_action_pressed("first-select"):
				update_brush_tile(Global.EntityType.PROP1);
			elif event.is_action_pressed("second-select"):
				update_brush_tile(Global.EntityType.PROP2);
			elif event.is_action_pressed("third-select"):
				update_brush_tile(Global.EntityType.PROP3);
			elif event.is_action_pressed("fourth-select"):
				update_brush_tile(Global.EntityType.PROP4);
			elif event.is_action_pressed("fifth-select"):
				update_brush_tile(Global.EntityType.PROP5);

## Changes current hotbar state (used for hotkeys)
## newState: Global.HotbarState
func change_current_hotbar(newState: Global.HotbarState):
	currentHotbarState = newState;

## Drop the tile currently selected, to be used with dragging tiles and entities with the cursor
func drop_tile() -> void:
	previewTileMap.clear();
	if (brushTile < tileCount):
		place_tile(currentMousePosition);
	else:
		place_entity(currentMousePosition);
	if (prevTile != -2):
		brushTile = prevTile;
	prevTile = -1;
	
## Places down the current brush tile at the clicked position.
## clickPosition: Where the mouse is during the click.
func place_tile(clickPosition: Vector2) -> void:
	validationCheck = false;
	if (check_out_of_bounds(clickPosition)): return;
	# If the tool is the cursor, don't overwrite any placement
	if (currentTool == Global.Tool.CURSOR && tileSet.get_cell_source_id(clickPosition) != -1):
		return;
	# If the cell is already of the same type, or if the cell is occupied by an entity, don't overwrite
	if (tileSet.get_cell_source_id(clickPosition) == brushTile || tileSet.get_cell_source_id(clickPosition) >= tileCount): 
		return;
	tileSet.erase_cell(clickPosition);
	if (brushTile != Global.TileType.ONEWAY):
		tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO, tileRotation);
	else:
		tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO);
		
## Get the player's spawn
## returns: player's current spawn
func getSpawn() -> Vector2:
	return playerSpawnPosition;

## Places down the current brush entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func place_entity(clickPosition: Vector2) -> void:
	validationCheck = false;
	if (!isPlaceable): return;
	
	if (tileSet.get_cell_source_id(clickPosition) == brushTile || (tileSet.get_cell_source_id(clickPosition) < tileCount && tileSet.get_cell_source_id(clickPosition) >= 0)): 
		return;
	
	if (tileSet.get_cell_source_id(clickPosition) == Global.EntityType.PLAYER && brushTile != Global.EntityType.PLAYER):
		playerSpawnPosition = Vector2(-1, -1);
	
	if (brushTile == Global.EntityType.PLAYER && playerSpawnPosition == Vector2(-1,-1)):
		playerSpawnPosition = clickPosition;
		tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO, 1);
	elif (brushTile == Global.EntityType.PLAYER):
		return;
	elif (brushTile >= tileCount):
		# If the tile is a prop, use rotation
		if (brushTile >= 12 && brushTile <= 17):
			tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO, tileRotation);
		else:
			tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO, 1);
	else:
		tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO, tileRotation);

## Deletes a tile at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_tile (clickPosition: Vector2) -> void:
	validationCheck = false;
	if (currentTool == Global.Tool.CURSOR || tileSet.get_cell_source_id(clickPosition) >= tileCount || check_out_of_bounds(clickPosition)):
		return;
	tileSet.erase_cell(clickPosition);

## Deletes an entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_entity (clickPosition: Vector2) -> void:
	validationCheck = false;
	if (currentTool != Global.Tool.CURSOR || (tileSet.get_cell_source_id(clickPosition) < tileCount)):
		return;
	if (tileSet.get_cell_source_id(clickPosition) == Global.EntityType.PLAYER):
		playerSpawnPosition = Vector2(-1, -1);
	tileSet.erase_cell(clickPosition);

## Places or deletes all tiles in a box.
## firstCorner: The corner where the mouse was clicked
## secondCorner: The corner where the mouse was released
func box_edit(firstCorner: Vector2, secondCorner: Vector2) -> void:
	# Find the coordinate of the top left corner of the box.
	var topLeft: Vector2 = Vector2(
		min(firstCorner.x, secondCorner.x), 
		min(firstCorner.y, secondCorner.y));
	
	match (boxBrushState):
		BoxBrushState.CREATE_CONFIRM:
			# 1 is added to max to be inclusive
			for i in abs(secondCorner.y - firstCorner.y) + 1:
				for j in abs(secondCorner.x - firstCorner.x) + 1:
					place_tile(topLeft + Vector2(j, i));
		BoxBrushState.DELETE_CONFIRM:
			for i in abs(secondCorner.y - firstCorner.y) + 1:
				for j in abs(secondCorner.x - firstCorner.x) + 1:
					delete_tile(topLeft + Vector2(j, i));
	
	disable_box_brush();
	previewTileMap.clear();

## Change the currently selected tile/entity if possible
## tile: the tile/entity to try and change to
func update_brush_tile(tile: int) -> void:
	if currentTool == Global.Tool.CURSOR && tile >= tileCount:
		brushTile = tile;
	elif currentTool != Global.Tool.CURSOR && tile < tileCount:
		brushTile = tile;

## Hooks the preview tile to the mouse position and moves it when necessary
## mousePosition: Where the mouse currently is in grid coordinates
## prevPosition: Where the mouse previously was in grid coordinates
func update_preview_tile(mousePosition: Vector2, prevPosition: Vector2, isRed: bool = false) -> void:
	if (brushTile >= tileCount):
		# If the tile is a prop, use rotation.
		if (brushTile >= 12 && brushTile <= 17):
			previewTileMap.set_cell(mousePosition, brushTile, Vector2i.ZERO, tileRotation);
		else:
			previewTileMap.set_cell(mousePosition, brushTile, Vector2i.ZERO, 2);
	elif (brushTile == Global.TileType.SLOPE):
		print("previewing tile:", brushTile)
		previewTileMap.set_cell(mousePosition, brushTile, Vector2i.ZERO, tileRotation);
	else:
		previewTileMap.set_cell(mousePosition, brushTile, Vector2i.ZERO);
	
	if (isRed): previewTileMap.modulate = Color(1, 0, 0, 0.5);
	# Preview tile will appear red if not in a placeable area.
	else: previewTileMap.modulate = Color(1, 1, 1, 0.5) if isPlaceable else Color(1, 0, 0, 0.5)	;
	
	if (mousePosition != prevPosition): previewTileMap.clear();

func update_box_preview(firstCorner: Vector2, secondCorner: Vector2) -> void:
	# Find the coordinate of the top left corner of the box.
	var topLeft: Vector2 = Vector2(
		min(firstCorner.x, secondCorner.x), 
		min(firstCorner.y, secondCorner.y));
	
	previewTileMap.clear();
	for i in abs(secondCorner.y - firstCorner.y) + 1:
		for j in abs(secondCorner.x - firstCorner.x) + 1:
			# Will appear red when deleting tiles and use standard colors otherwise.
			var currentCell: Vector2 = topLeft + Vector2(j, i)
			if (not tileSet.get_cell_source_id(currentCell) >= tileCount):
				update_preview_tile(currentCell, currentCell, boxBrushState == BoxBrushState.DELETE);
	

## Change the selected tool to the clicked on tool, adjusting the selected tile if needed.
## tool: The tool to change to
func change_tool(tool: Global.Tool) -> void:
	if currentTool == tool:
		return;
	
	if (currentTool == Global.Tool.BOX_BRUSH): disable_box_brush();
	currentTool = tool;
	
	if (currentTool != Global.Tool.CURSOR):
		update_brush_tile(Global.TileType.SOLID);
		tileSwitch.display_tiles(true);
		tileSwitch.display_entities(false);
	else:
		update_brush_tile(Global.EntityType.GOAL);
		tileSwitch.display_tiles(false);
		tileSwitch.display_entities(true);
	previewTileMap.clear(); 
	propertyMenu.hide();
	
	match currentTool:
		Global.Tool.CURSOR:
			update_brush_tile(Global.EntityType.GOAL);
		Global.Tool.BOX_BRUSH:
			update_brush_tile(Global.TileType.SOLID);
		Global.Tool.BRUSH:
			update_brush_tile(Global.TileType.SOLID);
	print("Current Tool: ", currentTool);

## Deactivates the box brush.
func disable_box_brush() -> void:
	boxBrushState = BoxBrushState.INACTIVE;

## Rotate currently selected tile
## NOTE: SceneCollection rotations work most likely by selecting the scene and rotating it, you can't spawn it rotated
func rotate_tile() -> void:
	match tileRotation:
		0:
			tileRotation = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H;
		TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H:
			tileRotation = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V;
		TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V:
			tileRotation = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V;
		_:
			tileRotation = 0;
	
## Converts the mouse's position into grid coordinates.
## mousePosition: Where the cursor currently is in world space.
## returns: The grid-coordinate equivalent of the position.
func get_grid_mouse_position(mousePosition: Vector2) -> Vector2:
	return tileSet.local_to_map(tileSet.to_local(mousePosition));
	
## Checks if the mouse is currently outside of the world grid size
## mousePosition: Where the mouse is during this check 
## returns: True if the mouse is out of bounds
func check_out_of_bounds(mousePosition: Vector2i) -> bool:
	if (mousePosition.x < 0
	|| mousePosition.x > get_parent().worldSize.y
	|| mousePosition.y < 0
	|| mousePosition.y > get_parent().worldSize.x):
		return true;
	return false;
	
## Fills the grid with grid lines tiles
func fill_grid_lines() -> void:
	for height in range(0, get_parent().worldSize.y + 1):
		for width in range(0, get_parent().worldSize.x + 1):
			gridLines.set_cell(Vector2i(height, width), 1, Vector2i.ZERO);

## Return true if the player exists
## returns: True if the player exists in the grid
func player_exist() -> bool:
	return playerSpawnPosition != Vector2(-1, -1);

## Open the property menu and set the selected entity
## clickPosition: position that the mouse has clicked at
func edit_properties(clickPosition: Vector2) -> void:
	propertyMenu.selectedEntity = get_scene_at_cell(clickPosition);
	propertyMenu.show();

## Retrieves a reference to the scene at a specific cell in the tile set
## gridPosition: position of the cell being checked
## returns: the node at the cell if there is one, null otherwise
func get_scene_at_cell(gridPosition: Vector2i) -> Node2D:
	# The global position of the target cell that is clicked
	var targetGlobalPos = tileSet.map_to_local(gridPosition) + tileSet.global_position;
	# Iterate through each node in the tileset, if any have the same global position return it
	for node in tileSet.get_children():
		if node.global_position == targetGlobalPos:
			return node;
	return null;
