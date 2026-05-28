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
	
	brushTile = Global.TileType.SOLID;
	
	fill_grid_lines();
	
	print("Level Height:", get_parent().gridHeight);
	print("Level Width:", get_parent().gridWidth);


## Runs every frame during the editing state
## delta: how much time has passed
func _process(_delta: float) -> void:
	# record the position of the mouse on this frame
	currentMousePosition = get_grid_mouse_position(get_global_mouse_position());

	update_preview_tile(currentMousePosition, prevMousePosition);
	
	# save the mouse position to the previous frame
	prevMousePosition = currentMousePosition;
	
func _unhandled_input(event: InputEvent) -> void:

	if (event.is_action_pressed("left-click")):
		painting = true;
	if (event.is_action_released("left-click")):
		painting = false;
		
	if (event.is_action_pressed("right-click")):
		erasing = true;
	if (event.is_action_released("right-click")):
		erasing = false;
		
	if painting:
		place_tile(currentMousePosition);
	if erasing:
		delete_tile(currentMousePosition);
	
	
	
	if event.is_action_pressed("brush-tool"):
		change_tool(Global.Tool.BRUSH);

	elif event.is_action_pressed("box-brush-tool"):
		change_tool(Global.Tool.BOX_BRUSH);

	if event.is_action_pressed("cursor-tool"):
		change_tool(Global.Tool.CURSOR);
		
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
	# Returns early if mouse is outside of grid parameters
	if check_out_of_bounds():
		return;
	
	if (tileSet.get_cell_source_id(clickPosition) == brushTile): return;
	
	tileSet.erase_cell(clickPosition);
	tileSet.set_cell(clickPosition, brushTile, Vector2i.ZERO);

func place_object(clickPosition: Vector2) -> void:
	print("a");

## Deletes a tile at the clicked position.
## position: Where the mouse is during the click.
func delete_tile(clickPosition: Vector2) -> void:
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
	
	# Returns early if mouse is outside of grid parameters
	if check_out_of_bounds():
		return;
	
	
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
	
	print("Current Tool: ", currentTool);
	
## Converts the mouse's position into grid coordinates.
## mousePosition: Where the cursor currently is in world space.
## returns: The grid-coordinate equivalent of the position.
func get_grid_mouse_position(mousePosition: Vector2) -> Vector2:
	return tileSet.local_to_map(tileSet.to_local(mousePosition));
	
## Checks if the mouse is currently out of bounds
func check_out_of_bounds() -> bool:
	if (get_grid_mouse_position(get_global_mouse_position())[0] < 0
	|| get_grid_mouse_position(get_global_mouse_position())[0] > get_parent().gridHeight
	|| get_grid_mouse_position(get_global_mouse_position())[1] < 0
	|| get_grid_mouse_position(get_global_mouse_position())[1] > get_parent().gridWidth):
		return true;
	return false;
	
## Fills the grid with grid lines tiles
func fill_grid_lines() -> void:
	# TODO: The 0,0 position is within the walls of the scene, meaning -1 is
	# necessary until it is fixed
	for height in range(0, get_parent().gridHeight + 1):
		for width in range(0, get_parent().gridWidth + 1):
			gridLines.set_cell(Vector2i(height, width), 1, Vector2i.ZERO);
