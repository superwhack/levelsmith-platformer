extends Node2D

## Managers and tile map for easy access.
@export var editorManager : Node2D;
@export var toolManager : Node2D;
@export var tileMap : TileMapLayer;

@onready var brushObject = toolManager.brushObject;

## Runs every frame. Ensures the brush object is always up to date.
func _process(_delta : float) -> void:
	brushObject = toolManager.brushObject;

## Places down the current brush tile at the clicked position.
## clickPosition: Where the mouse is during the click.
func place_tile(clickPosition : Vector2) -> void:
	editorManager.unsavedChanges = true;
	editorManager.isValidated = false;
	
	var clickedTileId : int = tileMap.get_cell_source_id(clickPosition);
	
	# Skipping checks:
	# Placing on an entity or bedrock (Any id above the tile count)
	# Placing on the same tile if it's not a slope
	# Placing on slopes with the same rotation
	# Placing out of bounds
	if (clickedTileId >= editorManager.tileCount || 
	(clickedTileId != Global.TileType.SLOPE && clickedTileId == brushObject) || 
	(clickedTileId == Global.TileType.SLOPE && brushObject == Global.TileType.SLOPE && tileMap.get_cell_alternative_tile(clickPosition) == toolManager.currentObjectRotation) || 
	editorManager.check_out_of_bounds(clickPosition)): 
		return;
	
	# Plays the sound effect if using the brush (box brush would cause repetition)
	if (toolManager.currentTool != Global.Tool.BOX_BRUSH):
		AudioManager.play_UI_effect("TilePlace");
	
	if (brushObject == Global.TileType.SLOPE):
		tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, toolManager.currentObjectRotation);
	else:
		tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO);

## Deletes a tile at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_tile(clickPosition : Vector2) -> void:
	editorManager.unsavedChanges = true;
	editorManager.isValidated = false;
	
	var clickedObjectId : int = tileMap.get_cell_source_id(clickPosition);
	
	if (clickedObjectId >= editorManager.tileCount 
	|| editorManager.check_out_of_bounds(clickPosition)):
		return;
	if (toolManager.currentTool != Global.Tool.BOX_BRUSH && clickedObjectId >= 0):
		AudioManager.play_UI_effect("TileDelete");
	
	tileMap.erase_cell(clickPosition);

## Places all tiles in a box.
## firstCorner: The corner where the mouse was clicked
## secondCorner: The corner where the mouse was released
func box_place(firstCorner : Vector2, secondCorner : Vector2) -> void:
	editorManager.unsavedChanges = true;
	editorManager.isValidated = false;
	
	# Find the coordinate of the top left corner of the box.
	var topLeft : Vector2 = Vector2(
		min(firstCorner.x, secondCorner.x), 
		min(firstCorner.y, secondCorner.y));
	
	AudioManager.play_UI_effect("TilePlace");
	
	# Loop through the box and create all tiles. 1 is added to the max to be inclusive.
	for i in abs(secondCorner.y - firstCorner.y) + 1:
		for j in abs(secondCorner.x - firstCorner.x) + 1:
			place_tile(topLeft + Vector2(j, i));
	
	toolManager.disable_box_brush();

## Deletes all tiles in a box.
## firstCorner: The corner where the mouse was clicked
## secondCorner: The corner where the mouse was released
func box_delete(firstCorner : Vector2, secondCorner : Vector2) -> void:
	editorManager.unsavedChanges = true;
	editorManager.isValidated = false;
	
	# Find the coordinate of the top left corner of the box.
	var topLeft : Vector2 = Vector2(
		min(firstCorner.x, secondCorner.x), 
		min(firstCorner.y, secondCorner.y));
	
	AudioManager.play_UI_effect("TileDelete");
	
	# Loop through the box and delete all tiles. 1 is added to max to be inclusive.
	for i in abs(secondCorner.y - firstCorner.y) + 1:
		for j in abs(secondCorner.x - firstCorner.x) + 1:
			delete_tile(topLeft + Vector2(j, i));
	
	toolManager.disable_box_brush();
	editorManager.previewTileMap.clear();
