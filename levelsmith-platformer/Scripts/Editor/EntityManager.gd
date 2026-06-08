extends Node2D

## Managers and tileset for easy access.
@export var editorManager : Node2D;
@export var toolManager : Node2D;
@export var tileSet : TileMapLayer;

# Reference to PropertyMenu for editing properties
@export var propertyMenu: Panel;

var goalCount: int = 0;
@onready var brushObject: int = toolManager.brushObject;

func _process(_delta: float) -> void:
	editorManager.goalExists = goalCount > 0;
	brushObject = toolManager.brushObject;

## Places down the current brush entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func place_entity(clickPosition: Vector2) -> void:
	editorManager.isValidated = false;
	if (!editorManager.isPlaceable): return;
	
	var clickedTileId: int = tileSet.get_cell_source_id(clickPosition);
	
	if (clickedTileId == brushObject 
	|| (clickedTileId < editorManager.tileCount 
	&& clickedTileId >= 0)): 
		return;
	
	if (tileSet.get_cell_source_id(clickPosition) == Global.EntityType.PLAYER 
	&& brushObject != Global.EntityType.PLAYER):
		editorManager.playerExists = false;
	
	if (brushObject == Global.EntityType.PLAYER):
		if (editorManager.playerExists): return;
		
		editorManager.playerExists = true;
		tileSet.set_cell(clickPosition, brushObject, Vector2i.ZERO, 1);
	else:
		# If the tile is a prop, use rotation
		if (brushObject >= Global.EntityType.PROP1):
			tileSet.set_cell(clickPosition, brushObject, Vector2i.ZERO, toolManager.currentObjectRotation);
		else:
			tileSet.set_cell(clickPosition, brushObject, Vector2i.ZERO, 1);
	
	if (brushObject == Global.EntityType.GOAL): goalCount += 1;

## Deletes an entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_entity (clickPosition: Vector2) -> void:
	editorManager.isValidated = false;
	
	var clickedTileId: int = tileSet.get_cell_source_id(clickPosition);
	if (clickedTileId < editorManager.tileCount): return;
	
	tileSet.erase_cell(clickPosition);
	
	if (clickedTileId == Global.EntityType.PLAYER): editorManager.playerExists = false;
	elif (clickedTileId == Global.EntityType.GOAL): goalCount -= 1;
	
## Open the property menu and set the selected entity
## clickPosition: position that the mouse has clicked at
func edit_properties(clickPosition: Vector2) -> void:
	propertyMenu.selectedEntity = get_scene_at_cell(clickPosition);
	propertyMenu.show();
	
## Retrieves a reference to the scene at a specific cell in the tile set
## gridPosition: position of the cell being checked
## returns: the node at the cell if there is one, null otherwise
func get_scene_at_cell(gridPosition: Vector2i) -> Node2D:
	# The global position of the target cell that is clicked
	var targetGlobalPos = tileSet.map_to_local(gridPosition) + tileSet.global_position;
	# Iterate through each node in the tileset, if any have the same global position return it
	for node in tileSet.get_children():
		if node.global_position == targetGlobalPos:
			return node;
	return null;

## Moves the entity at the clicked position
func move_entity() -> void:
	# NOTE: THIS COMMENT BREAKS IT, BUT WE STILL SHOULD SAVE ROTATIONS SOMEWHERE
	#toolManager.currentObjectRotation = entityManager.tileSet.get_cell_alternative_tile(editorManager.currentMousePosition);
	# Await is needed to it has time to update selectedTile
	toolManager.prevEntity = toolManager.brushObject;
	await get_tree().process_frame;
	toolManager.brushObject = tileSet.get_cell_source_id(editorManager.currentMousePosition);
	if (toolManager.brushObject == Global.EntityType.PLAYER):
		editorManager.playerExists = false;
	tileSet.erase_cell(editorManager.currentMousePosition);
	toolManager.isMoving = true;
	
## Drop the tile currently selected, to be used with dragging tiles and entities with the cursor
func drop_entity() -> void:
	place_entity(editorManager.currentMousePosition);
	if (toolManager.prevEntity != -2):
		toolManager.brushObject = toolManager.prevEntity;
	toolManager.prevEntity = -1;
	toolManager.isMoving = false;
