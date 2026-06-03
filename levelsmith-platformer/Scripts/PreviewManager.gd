extends TileMapLayer

# Node references
@export var editorManager: Node2D;
@export var toolManager: Node2D;
@export var tileSet: TileMapLayer;

# Current brushing object (pulled from tool manager)
var brushObject: int;

## Runs every frame during the editing state.
## _delta: how much time has passed since the previous frame
func _process(_delta: float) -> void:
	brushObject = editorManager.brushObject;
	
	if (toolManager.isMoving): return;
	
	match (toolManager.currentTool):
		Global.Tool.BOX_BRUSH:
			match (toolManager.boxBrushState):
				Global.BoxBrushState.INACTIVE:
					update_preview_object(editorManager.currentMousePosition, editorManager.prevMousePosition, editorManager.isPlaceable);
				_: 
					update_box_preview(toolManager.firstBoxCorner, toolManager.secondBoxCorner);
		_:
			update_preview_object(editorManager.currentMousePosition, editorManager.prevMousePosition, editorManager.isPlaceable);
	pass

## Hooks the preview tile to the mouse position and moves it when necessary
## mousePosition: Where the mouse currently is in grid coordinates
## prevPosition: Where the mouse previously was in grid coordinates
func update_preview_object(mousePosition: Vector2, prevPosition: Vector2, isRed: bool = false) -> void:
	## NOTE: Prop 1 is assumed to be the first prop, and everything after it is a prop/rotatable.
	if (brushObject >= Global.EntityType.PROP1 || brushObject == Global.TileType.SLOPE):
		set_cell(mousePosition, brushObject, Vector2i.ZERO, toolManager.currentObjectRotation);
	elif (brushObject >= editorManager.tileCount):
		set_cell(mousePosition, brushObject, Vector2i.ZERO, 2);
	else:
		set_cell(mousePosition, brushObject, Vector2i.ZERO);
	
	modulate = Color(1, 0, 0, 0.5) if isRed else Color(1, 1, 1, 0.5);
	
	if (mousePosition != prevPosition): clear();

## Draws preview tiles across a grid area
## firstCorner: The starting corner to use for the box.
## secondCorner: The opposite corner to use for the box.
func update_box_preview(firstCorner: Vector2, secondCorner: Vector2) -> void:
	# Find the coordinate of the top left corner of the box.
	var topLeft: Vector2 = Vector2(
		min(firstCorner.x, secondCorner.x), 
		min(firstCorner.y, secondCorner.y));
	
	clear();
	for i in abs(secondCorner.y - firstCorner.y) + 1:
		for j in abs(secondCorner.x - firstCorner.x) + 1:
			# Will appear red when deleting tiles and use standard colors otherwise.
			var currentCell: Vector2 = topLeft + Vector2(j, i)
			if (tileSet.get_cell_source_id(currentCell) < editorManager.tileCount):
				update_preview_object(currentCell, currentCell, toolManager.boxBrushState == Global.BoxBrushState.DELETE);
