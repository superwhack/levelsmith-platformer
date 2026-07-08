extends TileMapLayer

# Node references
@export var editorManager : Node2D;
@export var toolManager : Node2D;
@export var tileMap : TileMapLayer;

# Current brushing object (pulled from tool manager)
var brushObject : int;

var currentMousePosition : Vector2;
var prevMousePosition : Vector2;



## Runs every frame during the editing state.
## _delta: how much time has passed since the previous frame
func _process(_delta: float) -> void:
	brushObject = toolManager.brushObject;
	currentMousePosition = editorManager.currentMousePosition;
	
	match (toolManager.currentTool):
		Global.Tool.BOX_BRUSH:
			if (toolManager.boxBrushState == Global.BoxBrushState.INACTIVE):
				update_preview_object(currentMousePosition, prevMousePosition, brushObject, !editorManager.isPlaceable);
			else:
				update_box_preview(toolManager.firstBoxCorner, toolManager.secondBoxCorner);
		_:
			update_preview_object(currentMousePosition, prevMousePosition, brushObject, !editorManager.isPlaceable);
	
	prevMousePosition = currentMousePosition;

## Hooks the preview tile to the mouse position and moves it when necessary
## mousePosition: Where the mouse currently is in grid coordinates
## prevPosition: Where the mouse previously was in grid coordinates
func update_preview_object(mousePosition: Vector2, prevPosition: Vector2, previewObject: int = brushObject, isRed: bool = false) -> void:
	if (mousePosition != prevPosition): clear();
	
	if !toolManager.isMoving && (tileMap.get_cell_source_id(mousePosition) >= editorManager.tileCount && previewObject >= editorManager.tileCount):
		clear();
		return;
	
	## NOTE: Prop 1 is assumed to be the first prop, and everything after it is a prop/rotatable.
	if (previewObject == Global.ERASING_TILE):
		set_cell(mousePosition, previewObject, Vector2i.ZERO);
	elif (previewObject >= Global.EntityType.PROP1 && previewObject <= Global.EntityType.PROP6):
		set_cell(mousePosition, previewObject, Vector2i.ZERO, toolManager.currentObjectRotation + (4 if toolManager.isBackground else 0));
	elif (previewObject == Global.TileType.SLOPE):
		# Add 4 to the alternative ID to use red unplaceable slopes.
		var alternativeId : int = toolManager.currentObjectRotation + (4 if isRed else 0);
		set_cell(mousePosition, previewObject, Vector2i.ZERO, alternativeId);
	elif (previewObject >= editorManager.tileCount):
		set_cell(mousePosition, previewObject, Vector2i.ZERO, 2);
	else:
		set_cell(mousePosition, previewObject, Vector2i.ZERO, isRed);
	
	## Set modulate: Affects the entire node for entities.
	if (toolManager.isMoving): modulate = Color(1, 1, 1);
	elif (previewObject >= editorManager.tileCount): 
			modulate = Color(1, 0, 0, 0.5) if isRed else Color(1, 1, 1, 0.5);
	else:
		modulate = Color(1, 1, 1, 0.5);

## Draws preview tiles across a grid area
## firstCorner: The starting corner to use for the box.
## secondCorner: The opposite corner to use for the box.
func update_box_preview(firstCorner: Vector2, secondCorner: Vector2) -> void:
	# Find the coordinate of the top left corner of the box.
	var topLeft : Vector2 = Vector2(
		min(firstCorner.x, secondCorner.x), 
		min(firstCorner.y, secondCorner.y));
	
	clear();
	for i in abs(secondCorner.y - firstCorner.y) + 1:
		for j in abs(secondCorner.x - firstCorner.x) + 1:
			var currentCell : Vector2 = topLeft + Vector2(j, i);
			#Skip entities
			if (tileMap.get_cell_source_id(currentCell) >= editorManager.tileCount): continue;
			
			# Will appear red when deleting tiles and use standard colors otherwise.
			if (toolManager.boxBrushState == Global.BoxBrushState.DELETE || 
			toolManager.boxBrushState == Global.BoxBrushState.DELETE_CONFIRM):
				update_preview_object(currentCell, currentCell, Global.ERASING_TILE, true);
			else: 
				update_preview_object(currentCell, currentCell, brushObject, editorManager.check_out_of_bounds(currentCell));
