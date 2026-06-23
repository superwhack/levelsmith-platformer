extends Node2D

## Managers and tile maps for easy access.
@export var editorManager: Node2D;
@export var toolManager: Node2D;
@export var tileMap : TileMapLayer;
@export var previewTile: TileMapLayer;

@onready var brushObject = toolManager.brushObject;

func _process(_delta: float) -> void:
	brushObject = toolManager.brushObject;

## Places down the current brush tile at the clicked position.
## clickPosition: Where the mouse is during the click.
func place_tile(clickPosition: Vector2) -> void:
	editorManager.isValidated = false;
	if (editorManager.check_out_of_bounds(clickPosition)): return;
	
	var clickedTileId = tileMap.get_cell_source_id(clickPosition);
	
	# If the cell is already of the same type (excluding slopes), or if the cell is occupied by an entity, don't overwrite
	if ((clickedTileId != Global.TileType.SLOPE && clickedTileId == brushObject) 
	|| clickedTileId > editorManager.tileCount || clickedTileId == Global.BEDROCK_TILE): 
		return;
	
	if (brushObject == Global.TileType.SLOPE):
		tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, toolManager.currentObjectRotation);
	else:
		tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO);

## Deletes a tile at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_tile (clickPosition: Vector2) -> void:
	editorManager.isValidated = false;
	if (toolManager.currentTool == Global.Tool.CURSOR 
	|| tileMap.get_cell_source_id(clickPosition) >= editorManager.tileCount 
	|| editorManager.check_out_of_bounds(clickPosition)):
		return;
	
	tileMap.erase_cell(clickPosition);

## Places all tiles in a box.
## firstCorner: The corner where the mouse was clicked
## secondCorner: The corner where the mouse was released
func box_place(firstCorner: Vector2, secondCorner: Vector2) -> void:
	# Find the coordinate of the top left corner of the box.
	var topLeft: Vector2 = Vector2(
		min(firstCorner.x, secondCorner.x), 
		min(firstCorner.y, secondCorner.y));
	
	# The creation. 1 is added to max to be inclusive.
	for i in abs(secondCorner.y - firstCorner.y) + 1:
		for j in abs(secondCorner.x - firstCorner.x) + 1:
			place_tile(topLeft + Vector2(j, i));
	
	toolManager.disable_box_brush();

## Deletes all tiles in a box.
## firstCorner: The corner where the mouse was clicked
## secondCorner: The corner where the mouse was released
func box_delete(firstCorner: Vector2, secondCorner: Vector2) -> void:
	# Find the coordinate of the top left corner of the box.
	var topLeft: Vector2 = Vector2(
		min(firstCorner.x, secondCorner.x), 
		min(firstCorner.y, secondCorner.y));
	
	# The deletion. 1 is added to max to be inclusive.
	for i in abs(secondCorner.y - firstCorner.y) + 1:
		for j in abs(secondCorner.x - firstCorner.x) + 1:
			delete_tile(topLeft + Vector2(j, i));
	
	toolManager.disable_box_brush();
	previewTile.clear();
