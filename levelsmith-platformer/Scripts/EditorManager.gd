extends Node2D

# Tool-based variables
var currentTool := Global.Tool.BRUSH;
var brushTile : int;
var selectedTile : TileData;

# References to grid TileMapLayer child nodes
var tileSet: TileMapLayer;
var gridLines: TileMapLayer;
var previewTile: TileMapLayer;

# Player spawnpoint. Set when placing the object.
var playerSpawnPosition: Vector2 = Vector2(-1, -1);

## Runs once when the script is ready.
## Set up any reference variables here.
func _ready() -> void:
	tileSet = get_child(0);
	gridLines = get_child(1);
	previewTile = get_child(2);
	
	brushTile = Global.TileType.DEATH;

## Runs every frame during the editing state
## delta: how much time has passed
func _process(_delta: float) -> void:
	pass

## Inputs related to clicking on the tile map (for now?)
func _unhandled_input(event):
	if event.is_action_pressed("left-click"):
		place_tile(get_global_mouse_position());

	if event.is_action_pressed("right-click"):
		delete_tile(get_global_mouse_position());
		
## Inputs related to the GUI
func _gui_input(event):
	# Switch current tool based on user keyboard input
	match event:
		"brush-tool":
			change_tool(Global.Tool.BRUSH);
		"box-brush-tool":
			change_tool(Global.Tool.BOX_BRUSH);
		"cursor-tool":
			change_tool(Global.Tool.CURSOR);

## Places down the current brushing tile at the clicked position.
## position: Where the mouse is during the click.
func place_tile(clickPosition: Vector2) -> void:
	var tilePosition: Vector2 = tileSet.local_to_map(tileSet.to_local(clickPosition));
	if (tileSet.get_cell_source_id(tilePosition) == brushTile): return;
	
	tileSet.erase_cell(tilePosition);
	tileSet.set_cell(tilePosition, brushTile, Vector2i.ZERO);

func place_object(clickPosition: Vector2) -> void:
	print("a");

## Deletes a tile at the clicked position
## position: Where the mouse during the click.
func delete_tile(clickPosition: Vector2) -> void:
	var tilePosition: Vector2 = tileSet.local_to_map(tileSet.to_local(clickPosition));
	tileSet.erase_cell(tilePosition);

func select_tile(clickPosition: Vector2) -> void:
	print("a");

func box_edit(firstCorner: Vector2, secondCorner: Vector2) -> void:
	print("a");

func move_tile() -> void:
	print("a");

func update_brush_tile(tileId: int) -> void:
	print("a");

func toggle_grid_lines() -> void:
	print("a");

# Change the selected tool to the clicked on tool.
func change_tool(tool: Global.Tool) -> void:
	if currentTool == tool:
		return;
	
	currentTool = tool;
	
	print("Current Tool: ", currentTool);
	
	
	
	
