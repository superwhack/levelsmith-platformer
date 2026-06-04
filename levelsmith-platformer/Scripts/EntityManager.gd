extends Node2D

## Managers and tileset for easy access.
@export var editorManager : Node2D;
@export var toolManager : Node2D;
@export var tileSet : TileMapLayer;

# Reference to PropertyMenu for editing properties
@export var propertyMenu: Panel;

var isEditing : bool;

## Places down the current brush entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func place_entity(clickPosition: Vector2) -> void:
	editorManager.validationCheck = false;
	if (!editorManager.isPlaceable): return;
	
	if (tileSet.get_cell_source_id(clickPosition) == toolManager.brushObject 
	|| (tileSet.get_cell_source_id(clickPosition) < editorManager.tileCount 
	&& tileSet.get_cell_source_id(clickPosition) >= 0)): 
		return;
	
	if (tileSet.get_cell_source_id(clickPosition) == Global.EntityType.PLAYER 
	&& toolManager.brushObject != Global.EntityType.PLAYER):
		editorManager.playerSpawnPosition = Vector2(-1, -1);
	
	if (toolManager.brushObject == Global.EntityType.PLAYER 
	&& editorManager.playerSpawnPosition == Vector2(-1,-1)):
		editorManager.playerSpawnPosition = clickPosition;
		tileSet.set_cell(clickPosition, toolManager.brushObject, Vector2i.ZERO, 1);
	elif (toolManager.brushObject == Global.EntityType.PLAYER):
		return;
	elif (toolManager.brushObject >= editorManager.tileCount):
		# If the tile is a prop, use rotation
		if (toolManager.brushObject >= 12 && toolManager.brushObject <= 17):
			tileSet.set_cell(clickPosition, toolManager.brushObject, Vector2i.ZERO, toolManager.currentTileRotation);
		else:
			tileSet.set_cell(clickPosition, toolManager.brushObject, Vector2i.ZERO, 1);
	else:
		tileSet.set_cell(clickPosition, toolManager.brushObject, Vector2i.ZERO, toolManager.currentObjectRotation);
		
## Deletes an entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_entity (clickPosition: Vector2) -> void:
	editorManager.validationCheck = false;
	if (tileSet.get_cell_source_id(clickPosition) == Global.EntityType.PLAYER):
		editorManager.playerSpawnPosition = Vector2(-1, -1);
	tileSet.erase_cell(clickPosition);
	
	
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
	
	
func move_entity() -> void:
	# NOTE: THIS COMMENT BREAKS IT, BUT WE STILL SHOULD SAVE ROTATIONS SOMEWHERE
	#toolManager.currentObjectRotation = entityManager.tileSet.get_cell_alternative_tile(editorManager.currentMousePosition);
	# Await is needed to it has time to update selectedTile
	toolManager.prevEntity = toolManager.brushObject;
	await get_tree().process_frame;
	toolManager.brushObject = tileSet.get_cell_source_id(editorManager.currentMousePosition);
	if (toolManager.brushObject == Global.EntityType.PLAYER):
		editorManager.playerSpawnPosition = Vector2(-1, -1);
	tileSet.erase_cell(editorManager.currentMousePosition);
	
## Drop the tile currently selected, to be used with dragging tiles and entities with the cursor
func drop_tile() -> void:
	place_entity(editorManager.currentMousePosition);
	if (editorManager.prevEntity != -2):
		toolManager.brushObject = editorManager.prevEntity;
	editorManager.prevEntity = -1;
