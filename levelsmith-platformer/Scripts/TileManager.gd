extends Node2D

## Managers and tileset for easy access.
@export var editorManager : Node2D;
@export var toolManager : Node2D;
@export var tileSet : TileMapLayer;


## Places down the current brush tile at the clicked position.
## clickPosition: Where the mouse is during the click.
func place_tile(clickPosition: Vector2) -> void:
	editorManager.validationCheck = false;
	if (editorManager.check_out_of_bounds(clickPosition)): return;
	# If the tool is the cursor, don't overwrite any placement
	if (toolManager.currentTool == Global.Tool.CURSOR && tileSet.get_cell_source_id(clickPosition) != -1):
		return;
	# If the cell is already of the same type, or if the cell is occupied by an entity, don't overwrite
	if (tileSet.get_cell_source_id(clickPosition) == toolManager.brushObject 
	|| tileSet.get_cell_source_id(clickPosition) >= editorManager.tileCount): 
		return;
	tileSet.erase_cell(clickPosition);
	if (toolManager.brushObject != Global.TileType.ONEWAY):
		tileSet.set_cell(clickPosition, toolManager.brushObject, Vector2i.ZERO, toolManager.currentObjectRotation);
	else:
		tileSet.set_cell(clickPosition, toolManager.brushObject, Vector2i.ZERO);
		
## Deletes a tile at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_tile (clickPosition: Vector2) -> void:
	editorManager.validationCheck = false;
	if (toolManager.currentTool == Global.Tool.CURSOR 
	|| tileSet.get_cell_source_id(clickPosition) >= editorManager.tileCount 
	|| editorManager.check_out_of_bounds(clickPosition)):
		return;
	tileSet.erase_cell(clickPosition);
	
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
func box_edit(firstCorner: Vector2, secondCorner: Vector2) -> void:
	# Find the coordinate of the top left corner of the box.
	var topLeft: Vector2 = Vector2(
		min(firstCorner.x, secondCorner.x), 
		min(firstCorner.y, secondCorner.y));
	
	# The deletion. 1 is added to max to be inclusive.
	for i in abs(secondCorner.y - firstCorner.y) + 1:
		for j in abs(secondCorner.x - firstCorner.x) + 1:
			delete_tile(topLeft + Vector2(j, i));
	
	toolManager.disable_box_brush();
	
