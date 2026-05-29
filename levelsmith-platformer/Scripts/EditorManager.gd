extends Node2D

# Tool-based variables
var currentTool := Global.Tool.BRUSH;
var brushTile : int;
var changesMade := true;
var validationCheck := false;
var selectedTile : TileData;
var painting : bool = false;
var erasing : bool = false;

# References to grid TileMapLayer child nodes
var tileSet: TileMapLayer;
var gridLines: TileMapLayer;
var previewTileMap: TileMapLayer;

# Reference to TileSwitch for transparency
var tileSwitch: HBoxContainer;

# Mouse position variables
var currentMousePosition: Vector2;
var prevMousePosition: Vector2;

# Box brush variables and enum
enum BoxBrushState {
	INACTIVE,
	CREATE,
	DELETE
}
var boxBrushState: BoxBrushState = BoxBrushState.INACTIVE;
var firstCornerClick: Vector2;
var secondCornerClick: Vector2;

# Flag for placeable areas
var isPlaceable: bool = true;

# Player spawnpoint. Set when placing the entity.
var playerSpawnPosition: Vector2 = Vector2(-1, -1);

## Runs once when the script is ready.
## Set up any reference variables here.
func _ready() -> void:
	
	tileSet = get_child(0);
	gridLines = get_child(1);
	previewTileMap = get_child(2);
	
	tileSwitch = get_child(3).get_child(1).get_child(1);
	tileSwitch.cursorSelected(currentTool == Global.Tool.CURSOR);
	
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
	
	update_preview_tile(currentMousePosition, prevMousePosition);
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED);
	get_tree().set_group("Enemy", "process_mode", Node.PROCESS_MODE_DISABLED);
	
	# save the mouse position to the previous frame
	prevMousePosition = currentMousePosition;

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
				
			if painting: place_tile(currentMousePosition);
			elif erasing: delete_tile(currentMousePosition);
		Global.Tool.BOX_BRUSH:
			if (event.is_action_pressed("left-click") && boxBrushState == BoxBrushState.INACTIVE):
				firstCornerClick = currentMousePosition;
				boxBrushState = BoxBrushState.CREATE;
			elif (event.is_action_pressed("right-click") && boxBrushState == BoxBrushState.INACTIVE):
				firstCornerClick = currentMousePosition;
				boxBrushState = BoxBrushState.DELETE;
				
			if (event.is_action_released("left-click") || event.is_action_released("right-click")):
				secondCornerClick = currentMousePosition;
				box_edit(firstCornerClick, secondCornerClick);
				
		Global.Tool.CURSOR:
			if (event.is_action_pressed("left-click")):
				place_entity(currentMousePosition);
			if (event.is_action_pressed("right-click")):
				delete_entity(currentMousePosition);
	
	if event.is_action_pressed("brush-tool"):
		change_tool(Global.Tool.BRUSH);
		tileSwitch.cursorSelected(false);

	elif event.is_action_pressed("box-brush-tool"):
		change_tool(Global.Tool.BOX_BRUSH);
		tileSwitch.cursorSelected(false);

	if event.is_action_pressed("cursor-tool"):
		change_tool(Global.Tool.CURSOR);
		tileSwitch.cursorSelected(true);
		
	elif event.is_action_pressed("first-select"):
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

## Places down the current brush tile at the clicked position.
## clickPosition: Where the mouse is during the click.
func place_tile(clickPosition: Vector2) -> void:
	if (check_out_of_bounds(clickPosition)): return;
	# If the tool is the cursor, don't overwrite any placement
	if (currentTool == Global.Tool.CURSOR && tileSet.get_cell_source_id(clickPosition) != -1):
		return;
	# If the cell is already of the same type, or if the cell is occupied by an entity, don't overwrite
	if (tileSet.get_cell_source_id(clickPosition) == brushTile || tileSet.get_cell_source_id(clickPosition) > 5): 
		return;
	tileSet.erase_cell(clickPosition);
	tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO);
func getSpawn() -> Vector2:
	return playerSpawnPosition;

## Places down the current brush entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func place_entity(clickPosition: Vector2) -> void:
	if (!isPlaceable): return;
	
	if (tileSet.get_cell_source_id(clickPosition) == brushTile || (tileSet.get_cell_source_id(clickPosition) < Global.TileType.size() && tileSet.get_cell_source_id(clickPosition) >= 0)): 
		return;
	
	if (tileSet.get_cell_source_id(clickPosition) == Global.EntityType.PLAYER && brushTile != Global.EntityType.PLAYER):
		playerSpawnPosition = Vector2(-1, -1);

	if (brushTile == Global.EntityType.PLAYER && playerSpawnPosition == Vector2(-1,-1)):
		playerSpawnPosition = clickPosition;
		tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO, 1);
	elif (brushTile == Global.EntityType.PATROLLING):
		tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO, 1);
	else:
		tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO);

## Deletes a tile at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_tile (clickPosition: Vector2) -> void:
	if (currentTool == Global.Tool.CURSOR || tileSet.get_cell_source_id(clickPosition) > 5 || check_out_of_bounds(clickPosition)):
		return;
	tileSet.erase_cell(clickPosition);

## Deletes an entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_entity (clickPosition: Vector2) -> void:
	if (currentTool != Global.Tool.CURSOR && tileSet.get_cell_source_id(clickPosition) > 5):
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
		BoxBrushState.CREATE:
			# 1 is added to max to be inclusive
			for i in abs(secondCorner.y - firstCorner.y) + 1:
				for j in abs(secondCorner.x - firstCorner.x) + 1:
					place_tile(topLeft + Vector2(j, i));
		BoxBrushState.DELETE:
			for i in abs(secondCorner.y - firstCorner.y) + 1:
				for j in abs(secondCorner.x - firstCorner.x) + 1:
					delete_tile(topLeft + Vector2(j, i));
	
	boxBrushState = BoxBrushState.INACTIVE;

## Change the currently selected tile/entity if possible
## tile: the tile/entity to try and change to
func update_brush_tile(tile: int) -> void:
	if currentTool == Global.Tool.CURSOR && tile >= Global.TileType.size():
		brushTile = tile;
	elif currentTool != Global.Tool.CURSOR && tile < Global.TileType.size():
		brushTile = tile;

## Hooks the preview tile to the mouse position and moves it when necessary
## mousePosition: Where the mouse currently is in grid coordinates
## prevPosition: Where the mouse previously was in grid coordinates
func update_preview_tile(mousePosition: Vector2, prevPosition: Vector2) -> void:
	if (brushTile >= 8):
		previewTileMap.set_cell(mousePosition, brushTile, Vector2i.ZERO, 2);
	else:
		previewTileMap.set_cell(mousePosition, brushTile, Vector2i.ZERO);
	
	# Preview tile will appear red if not in a placeable area.
	previewTileMap.modulate = Color(1, 1, 1, 0.5) if isPlaceable else Color(1, 0, 0, 0.5)
	
	if (mousePosition != prevPosition): 
		previewTileMap.erase_cell(prevPosition);

## Change the selected tool to the clicked on tool, adjusting the selected tile if needed.
## tool: The tool to change to
func change_tool(tool: Global.Tool) -> void:
	if currentTool == tool:
		return;
	
	currentTool = tool;
	
	tileSwitch.cursorSelected(currentTool == Global.Tool.CURSOR);
	if (currentTool != Global.Tool.CURSOR):
		update_brush_tile(Global.TileType.SOLID);
	else:
		update_brush_tile(Global.EntityType.SLOPE);
	print("Current Tool: ", currentTool);

	
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
