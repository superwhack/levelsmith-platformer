extends Node2D

## Managers and tile map for easy access.
@export var editorManager : Node2D;
@export var toolManager : Node2D;
@export var tileMap : TileMapLayer;

# Reference to PropertyMenu for editing properties
@export var propertyMenu : Panel;

# Amount of goals placed. 
var goalCount : int = 0;

@onready var brushObject : int = toolManager.brushObject;

var movingResource : Resource;

## Runs every frame during the editor state
func _ready() -> void:
	var clearGoalCount = func () -> void:
		goalCount = 0;
	Global.levelCreated.connect(clearGoalCount);

func _process(_delta: float) -> void:
	editorManager.goalExists = goalCount > 0;
	brushObject = toolManager.brushObject;

## Places down the current brush entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func place_entity(clickPosition: Vector2) -> void:
	editorManager.isValidated = false;
	if (!editorManager.isPlaceable): return;
	
	var clickedTileId : int = tileMap.get_cell_source_id(clickPosition);
	
	## Prevent placing on other objects of any kind.
	if (clickedTileId > 0): return;
	
	match (brushObject):
		Global.EntityType.PLAYER:
			if (editorManager.playerExists): return;
			
			editorManager.playerExists = true;
			tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, 1);
		Global.EntityType.PATROLLING, Global.EntityType.SHOOTING, Global.EntityType.FLYING, Global.EntityType.STATIONARY:
			# Place the enemy and wait until it's registered before continuing
			tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, 1);
			while get_scene_at_cell(clickPosition) == null:
				await get_tree().process_frame;
			
			# Create a property file for the enemy
			var placedEnemy : Node2D = get_scene_at_cell(clickPosition);
			var newEntity : Resource;
			var file : String;
			var time : int = Time.get_ticks_msec();
			if (brushObject == Global.EntityType.PATROLLING):
				var defaultPatrolling : Resource = load("res://Resources/PlayerPresets/PatrollingDefault.tres");
				newEntity = defaultPatrolling.duplicate(true);
				placedEnemy.adjust_arrow(90);
				placedEnemy.directionArrow.scale = Vector2(1, 1);
				file = "res://Resources/Enemies/Patrolling" + str(time) + ".tres";
			elif (brushObject == Global.EntityType.SHOOTING):
				var defaultShooting : Resource = load("res://Resources/PlayerPresets/ShootingDefault.tres");
				newEntity = defaultShooting.duplicate(true);
				placedEnemy.adjust_arrow(90);
				placedEnemy.directionArrow.scale = Vector2(1, 1);
				file = "res://Resources/Enemies/Shooting" + str(time) + ".tres";
			elif (brushObject == Global.EntityType.FLYING):
				var defaultFlying : Resource = load("res://Resources/PlayerPresets/FlyingDefault.tres");
				newEntity = defaultFlying.duplicate(true);
				file = "res://Resources/Enemies/Flying" + str(time) + ".tres";
			ResourceSaver.save(newEntity, file);
			placedEnemy.assign_script(str(time), clickPosition);
			editorManager.reset_enemy_positions();
		Global.EntityType.GOAL:
			goalCount += 1;
			tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, 1);
		Global.EntityType.PROP1, Global.EntityType.PROP2, Global.EntityType.PROP3, Global.EntityType.PROP4, Global.EntityType.PROP5, Global.EntityType.PROP6:
			# Include rotation for props
			tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, toolManager.currentObjectRotation);
		_: 
			tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, 1);

## Deletes an entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_entity (clickPosition: Vector2) -> void:
	editorManager.isValidated = false;
	
	var clickedObjectId : int = tileMap.get_cell_source_id(clickPosition);
	var clickedEntity : Node2D = get_scene_at_cell(clickPosition);
	
	if (clickedObjectId < editorManager.tileCount): return;
	elif (clickedObjectId == Global.EntityType.PLAYER): editorManager.playerExists = false;
	elif (clickedObjectId == Global.EntityType.GOAL): goalCount -= 1;
	elif (clickedEntity is Enemy):
		DirAccess.remove_absolute("res://Resources/Enemies/" + clickedEntity.name + ".tres");
		clickedEntity.queue_free();
	
	tileMap.erase_cell(clickPosition);

## Open the property menu and set the selected entity
## clickPosition: position that the mouse has clicked at
func edit_properties(clickPosition: Vector2) -> void:
	var clickedEntity : Node2D = get_scene_at_cell(clickPosition);
	propertyMenu.selectedEntity = clickedEntity;
	if clickedEntity is Enemy:
		propertyMenu.show_menu(clickedEntity.propertyFile);
	else:
		propertyMenu.show_menu();
	
## Retrieves a reference to the scene at a specific cell in the tile set
## gridPosition: position of the cell being checked
## returns: the node at the cell if there is one, null otherwise
func get_scene_at_cell(gridPosition: Vector2i) -> Node2D:
	# Iterate through each node in the tile map, if any have the same global position return it
	for node in tileMap.get_children():
		if tileMap.local_to_map(node.global_position) == gridPosition:
			return node;
	return null;

## Moves the entity at the clicked position
func move_entity(previousClickPos: Vector2) -> void:
	propertyMenu.close();
	# Await is needed to it has time to update selectedTile
	toolManager.prevPosition = previousClickPos;
	toolManager.prevEntity = toolManager.brushObject;
	toolManager.prevRotation = toolManager.currentObjectRotation;
	
	await get_tree().process_frame;
	toolManager.brushObject = tileMap.get_cell_source_id(previousClickPos);
	toolManager.currentObjectRotation = tileMap.get_cell_alternative_tile(previousClickPos);
	if get_scene_at_cell(previousClickPos) is Enemy:
		movingResource = get_scene_at_cell(previousClickPos).propertyFile;
	delete_entity(previousClickPos);

## Drop the tile currently selected, to be used with dragging tiles and entities with the cursor
func drop_entity() -> void:
	var dropPosition : Vector2;
	var clickedObjectId : int = tileMap.get_cell_source_id(editorManager.currentMousePosition);
	
	if ((clickedObjectId < editorManager.tileCount && clickedObjectId >= 0) || clickedObjectId == Global.EntityType.PLAYER):
		# Drop the entity on its original spot if landing on a tile or player.
		editorManager.isPlaceable = true;
		dropPosition = toolManager.prevPosition;
	else:
		dropPosition = editorManager.currentMousePosition;
	place_entity(dropPosition);
	
	if (toolManager.prevEntity != -2):
		toolManager.brushObject = toolManager.prevEntity;
	toolManager.prevEntity = -1;
	toolManager.prevPosition = Vector2(0,0);
	toolManager.currentObjectRotation = toolManager.prevRotation;
	
	# Wait until a node is found at the dropped cell
	while (!get_scene_at_cell(dropPosition)):
		await get_tree().process_frame;
		
	var droppedEntity : Node2D = get_scene_at_cell(dropPosition);
	if droppedEntity is not Enemy || !movingResource: return;
	
	movingResource.position = dropPosition;
	droppedEntity.apply_script(movingResource);
	
	# Reset direciton arrows
	if droppedEntity is EnemyShooting:
		droppedEntity.adjust_arrow(droppedEntity.direction + 90);
		droppedEntity.directionArrow.scale = Vector2(1, 1);
	elif droppedEntity is EnemyPatrol:
		droppedEntity.adjust_arrow(int(movingResource.direction) * 180 + 90);
		droppedEntity.directionArrow.scale = Vector2(1, 1);
	ResourceSaver.save(movingResource, "res://Resources/Enemies/" + droppedEntity.name + ".tres");
	movingResource = null;
	editorManager.reset_enemy_positions();

## Scan through the grid to see how many goals have been placed.
## xSize: the x dimension on the level
## ySize: the y dimension on the level
func scan_goals(xSize: int, ySize: int) -> void:
	goalCount = 0;
	for x in xSize:
		for y in ySize:
			if tileMap.get_cell_source_id(Vector2(x, y)) == Global.EntityType.GOAL:
				goalCount += 1;
	editorManager.goalExists = goalCount > 0;
