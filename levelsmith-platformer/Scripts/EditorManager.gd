extends Node2D

# Possible tools to select	
var currentTool := Global.Tool.BRUSH;
var brushTile : TileData;
@export var tileSet: TileMapLayer;
@export var gridLines: TileMapLayer;
@export var previewTile: TileMapLayer;
var selectedTile: TileData;
var playerSpawnPosition: Vector2;

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("click"):
		var tilePos = tileSet.local_to_map(tileSet.to_local(get_global_mouse_position()));
		tileSet.set_cell(tilePos, -1);
		print(tilePos);

func place_tile(pos: Vector2) -> void:
	print("a");

func place_object(pos: Vector2) -> void:
	print("a");

func select_tile(pos: Vector2) -> void:
	print("a");

func box_edit(firstCorner: Vector2, secondCorner: Vector2) -> void:
	print("a");

func move_tile() -> void:
	print("a");

func update_brush_tile(tile: TileData) -> void:
	print("a");

func toggle_grid_lines() -> void:
	print("a");

# Change the selected tool to the clicked on tool.
func change_tool(tool: Global.Tool) -> void:
	currentTool = tool;


func _on_play_button_pressed() -> void:
	pass # Replace with function body.
