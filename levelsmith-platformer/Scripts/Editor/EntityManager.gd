extends Node2D

## Managers and tileset for easy access.
@export var editorManager : Node2D;
@export var toolManager : Node2D;
@export var tileSet : TileMapLayer;

# Reference to PropertyMenu for editing properties
@export var propertyMenu: Panel;

var goalCount: int = 0;
@onready var brushObject: int = toolManager.brushObject;

var movingResource: Resource;

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
	
	if (tileSet.get_cell_source_id(clickPosition) >= Global.EntityType.PATROLLING && tileSet.get_cell_source_id(clickPosition) <= Global.EntityType.FLYING):
		delete_entity(clickPosition);
	
	if (tileSet.get_cell_source_id(clickPosition) == Global.EntityType.PLAYER 
	&& brushObject != Global.EntityType.PLAYER):
		editorManager.playerExists = false;
	
	if (toolManager.brushObject == Global.EntityType.PLAYER 
	&& !editorManager.playerExists):
		editorManager.playerExists = true;
		tileSet.set_cell(clickPosition, toolManager.brushObject, Vector2i.ZERO, 1);
	elif (toolManager.brushObject == Global.EntityType.PLAYER):
		return;
	elif (toolManager.brushObject >= editorManager.tileCount):
		# If the tile is a prop, use rotation
		if (toolManager.brushObject >= Global.EntityType.PROP1 && toolManager.brushObject <= Global.EntityType.PROP6):
			tileSet.set_cell(clickPosition, toolManager.brushObject, Vector2i.ZERO, toolManager.currentObjectRotation);

		# If it's an enemy, create a new property file
		elif (toolManager.brushObject >= Global.EntityType.PATROLLING && toolManager.brushObject <= Global.EntityType.STATIONARY):
			var time = Time.get_ticks_msec();
			var saveBrush = toolManager.brushObject;
			tileSet.set_cell(clickPosition, toolManager.brushObject, Vector2i.ZERO, 1);
			# Wait five frames, I really don't like doing it like this but I'm not sure of a better way.
			for frame in range(1, 5):
				await get_tree().process_frame;
			if (saveBrush == Global.EntityType.PATROLLING):
				var defaultPatrolling: Resource = load("res://Resources/PlayerPresets/PatrollingDefault.tres");
				var newPatrolling: Resource = defaultPatrolling.duplicate(true);
				ResourceSaver.save(newPatrolling, "res://Resources/Enemies/Patrol" + str(time) + ".tres");
			elif (saveBrush == Global.EntityType.SHOOTING):
				var defaultShooting: Resource = load("res://Resources/PlayerPresets/ShootingDefault.tres");
				var newShooting: Resource = defaultShooting.duplicate(true);
				ResourceSaver.save(newShooting, "res://Resources/Enemies/Shooting" + str(time) + ".tres");
			get_scene_at_cell(clickPosition).assign_script(str(time), clickPosition);
		else:
			tileSet.set_cell(clickPosition, toolManager.brushObject, Vector2i.ZERO, 1);
	else:
		tileSet.set_cell(clickPosition, toolManager.brushObject, Vector2i.ZERO, toolManager.currentObjectRotation);
		
		editorManager.playerExists = true;
		tileSet.set_cell(clickPosition, brushObject, Vector2i.ZERO, 1);
	
	if (brushObject == Global.EntityType.GOAL): goalCount += 1;

## Deletes an entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_entity (clickPosition: Vector2) -> void:
	editorManager.isValidated = false;
	
	var clickedTileId: int = tileSet.get_cell_source_id(clickPosition);
	if (clickedTileId < editorManager.tileCount): return;
	if get_scene_at_cell(clickPosition) is Enemy:
		DirAccess.remove_absolute("res://Resources/Enemies/" + get_scene_at_cell(clickPosition).name + ".tres");
		get_scene_at_cell(clickPosition).queue_free();
	tileSet.erase_cell(clickPosition);
	
	if (clickedTileId == Global.EntityType.PLAYER): editorManager.playerExists = false;
	elif (clickedTileId == Global.EntityType.GOAL): goalCount -= 1;
	
## Open the property menu and set the selected entity
## clickPosition: position that the mouse has clicked at
func edit_properties(clickPosition: Vector2) -> void:
	propertyMenu.selectedEntity = get_scene_at_cell(clickPosition);
	if get_scene_at_cell(clickPosition) is Enemy:
		propertyMenu.show_menu(get_scene_at_cell(clickPosition).propertyFile);
	else:
		propertyMenu.show_menu();
	propertyMenu.show();
	
## Retrieves a reference to the scene at a specific cell in the tile set
## gridPosition: position of the cell being checked
## returns: the node at the cell if there is one, null otherwise
func get_scene_at_cell(gridPosition: Vector2i) -> Node2D:
	# Iterate through each node in the tileset, if any have the same global position return it
	for node in tileSet.get_children():
		if tileSet.local_to_map(node.global_position) == gridPosition:
			return node;
	return null;

## Moves the entity at the clicked position
func move_entity() -> void:
	# Await is needed to it has time to update selectedTile
	toolManager.prevEntity = toolManager.brushObject;
	toolManager.prevRotation = toolManager.currentObjectRotation;
	await get_tree().process_frame;
	toolManager.brushObject = tileSet.get_cell_source_id(editorManager.currentMousePosition);
	toolManager.currentObjectRotation = tileSet.get_cell_alternative_tile(editorManager.currentMousePosition);
	if get_scene_at_cell(editorManager.currentMousePosition) is Enemy:
		movingResource = get_scene_at_cell(editorManager.currentMousePosition).propertyFile;
	delete_entity(editorManager.currentMousePosition);
	toolManager.isMoving = true;
	
## Drop the tile currently selected, to be used with dragging tiles and entities with the cursor
func drop_entity() -> void:
	place_entity(editorManager.currentMousePosition);
	if (toolManager.prevEntity != -2):
		toolManager.brushObject = toolManager.prevEntity;
	toolManager.prevEntity = -1;
	toolManager.currentObjectRotation = toolManager.prevRotation;
	toolManager.isMoving = false;
	for frame in range(1, 5):
		await get_tree().process_frame;
	if get_scene_at_cell(editorManager.currentMousePosition) is Enemy && movingResource:
		movingResource.position = editorManager.currentMousePosition;
		get_scene_at_cell(editorManager.currentMousePosition).apply_script(movingResource);
		ResourceSaver.save(movingResource, "res://Resources/Enemies/" + get_scene_at_cell(editorManager.currentMousePosition).name + ".tres");
		movingResource = null;
		editorManager.reset_enemy_positions();

func scan_goals(xSize: int, ySize: int) -> void:
	goalCount = 0;
	for x in xSize:
		for y in ySize:
			if tileSet.get_cell_source_id(Vector2(x, y)) == Global.EntityType.GOAL:
				goalCount += 1;
	editorManager.goalExists = goalCount > 0;
