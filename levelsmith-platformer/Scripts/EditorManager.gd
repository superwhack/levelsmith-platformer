extends Node2D

# Tool-based variables
var currentTool := Global.Tool.BRUSH;
var brushTile : int;
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

# Flag for placeable areas
var isPlaceable: bool = true;

# Player spawnpoint. Set when placing the object.
var playerSpawnPosition: Vector2 = Vector2(-1, -1);

## Runs once when the script is ready.
## Set up any reference variables here.
func _ready() -> void:
	
	tileSet = get_child(0);
	gridLines = get_child(1);
	previewTileMap = get_child(2);
	
	tileSwitch = get_child(4).get_child(1);
	tileSwitch.cursorSelected(currentTool == Global.Tool.CURSOR);
	
	brushTile = Global.TileType.SOLID;

## Runs every frame during the editing state
## delta: how much time has passed
func _process(_delta: float) -> void:
	# record the position of the mouse on this frame
	currentMousePosition = get_grid_mouse_position(get_global_mouse_position());

	update_preview_tile(currentMousePosition, prevMousePosition);
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED);
	
	# save the mouse position to the previous frame
	prevMousePosition = currentMousePosition;
	
func _unhandled_input(event: InputEvent) -> void:

	if (event.is_action_pressed("left-click")):
		painting = true;
	elif (event.is_action_released("left-click")):
		painting = false;
		
	if (event.is_action_pressed("right-click")):
		erasing = true;
	elif (event.is_action_released("right-click")):
		erasing = false;
		
	# Paint if the brush is selected, click to place if cursor is
	if painting:
		if currentTool == Global.Tool.BRUSH:
			place_tile(currentMousePosition);
		elif currentTool == Global.Tool.CURSOR && event.is_action_pressed("left-click"):
			if (brushTile < 6):
				place_tile(currentMousePosition); 
			else:
				place_object(currentMousePosition); 
			
	# Drag erase if the brush is selected, click to remove if cursor is
	elif erasing:
		if currentTool == Global.Tool.BRUSH:
			delete_tile(currentMousePosition);
		elif currentTool == Global.Tool.CURSOR && event.is_action_pressed("right-click"):
			delete_tile(currentMousePosition); 
	
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

## Places down the current brushing tile at the clicked position.
## position: Where the mouse is during the click.
func place_tile(clickPosition: Vector2) -> void:
	# If the tool is the cursor, don't overwrite any placement
	if (currentTool == Global.Tool.CURSOR && tileSet.get_cell_source_id(clickPosition) != -1):
		return;
	# If the cell is already of the same type, or if the cell is occupied by an object, don't overwrite
	if (tileSet.get_cell_source_id(clickPosition) == brushTile || tileSet.get_cell_source_id(clickPosition) > 5): 
		return;
	tileSet.erase_cell(clickPosition);
	tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO);
func getSpawn() -> Vector2:
	return playerSpawnPosition;

func place_object(clickPosition: Vector2) -> void:
	if (currentTool == Global.Tool.CURSOR && tileSet.get_cell_source_id(clickPosition) != -1):
		return;
	if (tileSet.get_cell_source_id(clickPosition) == brushTile || tileSet.get_cell_source_id(clickPosition) > 5): 
		return;
	if (brushTile == 8 && playerSpawnPosition == Vector2(-1,-1)):
		playerSpawnPosition = clickPosition;
		tileSet.set_cell(clickPosition, 8, Vector2i.ZERO, 1);
	else:
		tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO);

## Deletes a tile at the clicked position.
## position: Where the mouse is during the click.
func delete_tile(clickPosition: Vector2) -> void:
	if (tileSet.get_cell_source_id(clickPosition) == 8):
		playerSpawnPosition = Vector2(-1, -1);
	tileSet.erase_cell(clickPosition);

func select_tile(clickPosition: Vector2) -> void:
	print("a");

func box_edit(firstCorner: Vector2, secondCorner: Vector2) -> void:
	print("a");

func move_tile() -> void:
	print("a");

## Changes the brush tile.
## tile: The tile source id to swap to
func update_brush_tile(tile: Global.TileType) -> void:
	brushTile = tile;

## Hooks the preview tile to the mouse position and moves it when necessary
## mousePosition: Where the mouse currently is in grid coordinates
## prevMousePosition: Where the mouse previously was in grid coordinates
func update_preview_tile(mousePosition: Vector2, prevMousePosition: Vector2) -> void:
	if (brushTile == 8):
		previewTileMap.set_cell(mousePosition, 8, Vector2i.ZERO, 2);
	else:
		previewTileMap.set_cell(mousePosition, brushTile, Vector2i.ZERO);
	
	# Preview tile will appear red if not in a placeable area.
	previewTileMap.modulate = Color(1, 1, 1, 0.5) if isPlaceable else Color(1, 0, 0, 0.5)
	
	if (mousePosition != prevMousePosition): 
		previewTileMap.erase_cell(prevMousePosition);

# Change the selected tool to the clicked on tool.
func change_tool(tool: Global.Tool) -> void:
	if currentTool == tool:
		return;
	
	currentTool = tool;
	
	tileSwitch.cursorSelected(currentTool == Global.Tool.CURSOR);
	if (brushTile > 5 && currentTool != Global.Tool.CURSOR):
		update_brush_tile(Global.TileType.SOLID);
	print("Current Tool: ", currentTool);
	
## Converts the mouse's position into grid coordinates.
## mousePosition: Where the cursor currently is in world space.
## returns: The grid-coordinate equivalent of the position.
func get_grid_mouse_position(mousePosition: Vector2) -> Vector2:
	return tileSet.local_to_map(tileSet.to_local(mousePosition));
