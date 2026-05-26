extends Node2D

# Tool-based variables
var currentTool := Global.Tool.BRUSH;
var brushTile : int;
var selectedTile : TileData;

# References to grid TileMapLayer child nodes
var tileSet: TileMapLayer;
var gridLines: TileMapLayer;
var previewTileMap: TileMapLayer;

# Mouse position variables
var currentMousePosition: Vector2;
var prevMousePosition: Vector2;

# Player spawnpoint. Set when placing the object.
var playerSpawnPosition: Vector2 = Vector2(-1, -1);

## Runs once when the script is ready.
## Set up any reference variables here.
func _ready() -> void:
	tileSet = get_child(0);
	gridLines = get_child(1);
	previewTileMap = get_child(2);
	
	brushTile = Global.TileType.SOLID;

## Runs every frame during the editing state
## delta: how much time has passed
func _process(_delta: float) -> void:
	# record the position of the mouse on this frame
	currentMousePosition = get_grid_mouse_position(get_global_mouse_position());
	
	update_preview_tile(currentMousePosition, prevMousePosition);
	
	if (Input.is_action_pressed("left-click")):
		place_tile(currentMousePosition);
		
	if (Input.is_action_pressed("right-click")):
		delete_tile(currentMousePosition);
	
	# save the mouse position to the previous frame
	prevMousePosition = currentMousePosition;

## Places down the current brushing tile at the clicked position.
## position: Where the mouse is during the click.
func place_tile(clickPosition: Vector2) -> void:
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

func update_brush_tile(tileId: int) -> void:
	print("a");


func update_preview_tile(mousePosition: Vector2, prevMousePosition: Vector2) -> void:
	previewTileMap.set_cell(mousePosition, brushTile, Vector2i.ZERO);
	
	if (mousePosition != prevMousePosition): 
		previewTileMap.erase_cell(prevMousePosition);

# Change the selected tool to the clicked on tool.
func change_tool(tool: Global.Tool) -> void:
	currentTool = tool;

## Converts the mouse's position into grid coordinates.
## mousePosition: Where the cursor currently is in world space.
## returns: The grid-coordinate equivalent of the position.
func get_grid_mouse_position(mousePosition: Vector2) -> Vector2:
	return tileSet.local_to_map(tileSet.to_local(mousePosition));
