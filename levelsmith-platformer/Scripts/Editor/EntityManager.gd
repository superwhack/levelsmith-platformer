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
var duplicatingResource : Resource;

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
	if (!editorManager.isPlaceable):
		AudioManager.play_UI_effect("TilePlaceError");
		return;
	
	var clickedTileId : int = tileMap.get_cell_source_id(clickPosition);
	
	## Prevent placing on other objects of any kind.
	if (clickedTileId > 0): 
		AudioManager.play_UI_effect("TilePlaceError");
		return;
	if brushObject != Global.EntityType.PLAYER:
		AudioManager.play_UI_effect("TilePlace");
	match (brushObject):
		Global.EntityType.PLAYER:
			if (editorManager.playerExists): 
				AudioManager.play_UI_effect("TilePlaceError");
				return;
			editorManager.playerExists = true;
			tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, 1);
			AudioManager.play_UI_effect("TilePlace");
		Global.EntityType.PATROLLING, Global.EntityType.SHOOTING, Global.EntityType.FLYING, Global.EntityType.STATIONARY, Global.EntityType.MOVING_PLATFORM:
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
				if duplicatingResource:
					newEntity = duplicatingResource.duplicate(true);
				else:
					newEntity = defaultPatrolling.duplicate(true);
				placedEnemy.adjust_arrow(90);
				placedEnemy.directionArrow.scale = Vector2(1, 1);
				file = "res://Resources/Enemies/Patrolling" + str(time) + ".tres";
			elif (brushObject == Global.EntityType.SHOOTING):
				var defaultShooting : Resource = load("res://Resources/PlayerPresets/ShootingDefault.tres");
				if duplicatingResource:
					newEntity = duplicatingResource.duplicate(true);
				else:
					newEntity = defaultShooting.duplicate(true);
				placedEnemy.adjust_arrow(90);
				placedEnemy.directionArrow.scale = Vector2(1, 1);
				file = "res://Resources/Enemies/Shooting" + str(time) + ".tres";
			elif (brushObject == Global.EntityType.FLYING):
				var defaultFlying : Resource = load("res://Resources/PlayerPresets/FlyingDefault.tres");
				if duplicatingResource:
					newEntity = duplicatingResource.duplicate(true);
				else:
					newEntity = defaultFlying.duplicate(true);
				file = "res://Resources/Enemies/Flying" + str(time) + ".tres";
			elif (brushObject == Global.EntityType.STATIONARY):
				var defaultStationary : Resource = load("res://Resources/PlayerPresets/StationaryDefault.tres");
				newEntity = defaultStationary.duplicate(true);
				file = "res://Resources/Enemies/Stationary" + str(time) + ".tres";
			elif (brushObject == Global.EntityType.MOVING_PLATFORM):
				var defaultMoving : Resource = load("res://Resources/PlayerPresets/MovingPlatformDefault.tres");
				if duplicatingResource:
					newEntity = duplicatingResource.duplicate(true);
				else:
					newEntity = defaultMoving.duplicate(true);
				file = "res://Resources/Enemies/MovingPlatform" + str(time) + ".tres";
			ResourceSaver.save(newEntity, file);
			placedEnemy.assign_script(str(time), clickPosition);
			await get_tree().process_frame;
			editorManager.reset_enemy_positions();
		Global.EntityType.GOAL:
			goalCount += 1;
			tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, 1);
		Global.EntityType.COIN:
			tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, 1)
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
	
	if (clickedObjectId < editorManager.tileCount || clickedObjectId >= Global.BEDROCK_TILE): return;
	elif (clickedObjectId == Global.EntityType.PLAYER): editorManager.playerExists = false;
	elif (clickedObjectId == Global.EntityType.GOAL): goalCount -= 1;
	elif (clickedEntity is Enemy || clickedEntity is MovingPlatform):
		DirAccess.remove_absolute("res://Resources/Enemies/" + clickedEntity.name + ".tres");
		clickedEntity.queue_free();
	
	tileMap.erase_cell(clickPosition);

## Open the property menu and set the selected entity
## clickPosition: position that the mouse has clicked at
func edit_properties(clickPosition: Vector2) -> void:
	var clickedEntity : Node2D = get_scene_at_cell(clickPosition);
	propertyMenu.selectedEntity = clickedEntity;
	if clickedEntity is Enemy || clickedEntity is MovingPlatform:
		propertyMenu.show_menu(clickedEntity.propertyFile);
	elif clickedEntity is MovingPlatform:
		propertyMenu.show_menu(clickedEntity.propertyFile);
	elif clickedEntity is Player:
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

func duplicate_entity(clickPos: Vector2) -> void:
	var entity = get_scene_at_cell(clickPos);
	toolManager.update_brush_object(tileMap.get_cell_source_id(clickPos));
	propertyMenu.close();
	duplicatingResource = entity.propertyFile.duplicate(true);

## Moves the entity at the clicked position
func move_entity(previousClickPos: Vector2) -> void:
	duplicatingResource = null;
	propertyMenu.close();
	
	toolManager.prevPosition = previousClickPos;
	toolManager.prevBrushObject = toolManager.brushObject;
	toolManager.prevRotation = toolManager.currentObjectRotation;
	
	# Await is needed to it has time to update selectedTile
	await get_tree().process_frame;
	toolManager.brushObject = tileMap.get_cell_source_id(previousClickPos);
	toolManager.currentObjectRotation = tileMap.get_cell_alternative_tile(previousClickPos);
	if get_scene_at_cell(previousClickPos) is Enemy || get_scene_at_cell(previousClickPos) is MovingPlatform:
		movingResource = get_scene_at_cell(previousClickPos).propertyFile;
	if (!toolManager.isCopying):
		delete_entity(previousClickPos);

## Drop the tile currently selected, to be used with dragging tiles and entities with the cursor
## reset: false by default, if it's true the placed object will always return to it's spawn
func drop_entity(reset: bool = false) -> void:
	var dropPosition : Vector2;
	var clickedObjectId : int = tileMap.get_cell_source_id(editorManager.currentMousePosition);
	
	# Drop the entity on its original spot if mouse is over any object.
	if (clickedObjectId >= 0 || !editorManager.isPlaceable || reset):
		if toolManager.prevPosition == Vector2(-1 ,-1):
			toolManager.prevBrushObject = -1;
			toolManager.prevPosition = Vector2(0,0);
			toolManager.currentObjectRotation = toolManager.prevRotation;
			AudioManager.play_UI_effect("TilePlaceError");
			return;
		# Only allow it to be placed if you aren't copying
		editorManager.isPlaceable = !toolManager.isCopying;
		dropPosition = toolManager.prevPosition;
	else:
		dropPosition = editorManager.currentMousePosition;
	place_entity(dropPosition);
	
	# If it's not an enemy, this code needs to be run before await to prevent duplication
	if ((toolManager.brushObject < Global.EntityType.PATROLLING || toolManager.brushObject > Global.EntityType.STATIONARY) && toolManager.brushObject != Global.EntityType.MOVING_PLATFORM):
		if (toolManager.prevBrushObject != -2):
			toolManager.brushObject = toolManager.prevBrushObject;
		toolManager.prevBrushObject = -1;
		toolManager.prevPosition = Vector2(0,0);
		toolManager.currentObjectRotation = toolManager.prevRotation;
		# Wait until a node is found at the dropped cell
		while (!get_scene_at_cell(dropPosition)):
			await get_tree().process_frame;
	# if it is an enemy, it needs to be run after the await
	else:
		# Wait until a node is found at the dropped cell
		while (!get_scene_at_cell(dropPosition)):
			await get_tree().process_frame;
		if (toolManager.prevBrushObject != -2):
			toolManager.brushObject = toolManager.prevBrushObject;
		toolManager.prevBrushObject = -1;
		toolManager.prevPosition = Vector2(0,0);
		toolManager.currentObjectRotation = toolManager.prevRotation;
	
	var droppedEntity : Node2D = get_scene_at_cell(dropPosition);
	if !(droppedEntity is Enemy || droppedEntity is MovingPlatform) || !movingResource: return;
	
	var newResource = movingResource.duplicate(true);
	newResource.position = dropPosition;
	droppedEntity.apply_script(newResource);
	
	# Reset direciton arrows
	if droppedEntity is EnemyShooting:
		droppedEntity.adjust_arrow(droppedEntity.fireDirection + 90, droppedEntity.randomDirection);
		droppedEntity.directionArrow.scale = Vector2(1, 1);
	elif droppedEntity is EnemyPatrol:
		droppedEntity.adjust_arrow(int(newResource.direction) * 180 + 90);
		droppedEntity.directionArrow.scale = Vector2(1, 1);
	elif droppedEntity is EnemyStationary:
		droppedEntity.update_flipped();
	ResourceSaver.save(newResource, "res://Resources/Enemies/" + droppedEntity.name + ".tres");
	newResource = null;
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
