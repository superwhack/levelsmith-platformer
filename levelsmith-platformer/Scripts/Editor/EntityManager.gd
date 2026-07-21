extends Node2D

# Managers and tile map for easy access.
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

## Called immediately. Ensures a new level will have a goal count of 0.
func _ready() -> void:
	var clearGoalCount = func() -> void:
		goalCount = 0;
	Global.levelCreated.connect(clearGoalCount);

## Runs every frame during the editor state
func _process(_delta : float) -> void:
	editorManager.goalExists = goalCount > 0;
	brushObject = toolManager.brushObject;

## Places down the current brush entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func place_entity(clickPosition : Vector2) -> void:
	editorManager.unsavedChanges = true;
	editorManager.isValidated = false;
	
	if (!editorManager.isPlaceable):
		AudioManager.play_UI_effect("TilePlaceError");
		return;
	
	var clickedTileId : int = tileMap.get_cell_source_id(clickPosition);
	
	## Prevent placing on other objects of any kind.
	if (clickedTileId > 0): 
		AudioManager.play_UI_effect("TilePlaceError");
		return;
	if (brushObject != Global.EntityType.PLAYER):
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
			var entityName : String;
			var file : String;
			var time : int = Time.get_ticks_msec();
			
			# Set name based on the brush object.
			match (brushObject):
				Global.EntityType.PATROLLING:
					entityName = "Patrolling";
					placedEnemy.adjust_arrow(90);
					placedEnemy.directionArrow.scale = Vector2(1, 1);
				Global.EntityType.SHOOTING:
					entityName = "Shooting";
					placedEnemy.adjust_arrow(90);
					placedEnemy.directionArrow.scale = Vector2(1, 1);
				Global.EntityType.FLYING:
					entityName = "Flying";
				Global.EntityType.STATIONARY:
					entityName = "Stationary";
				Global.EntityType.MOVING_PLATFORM:
					entityName = "MovingPlatform";
			
			var defaultEnemyPreset : Resource = load("res://Resources/PlayerPresets/" + entityName + "Default.tres");
			if duplicatingResource:
				newEntity = duplicatingResource.duplicate(true);
			else:
				newEntity = defaultEnemyPreset.duplicate(true);
			file = "user://Resources/Enemies/" + entityName + str(time) + ".tres";
			
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
			# Include rotation and foreground/background for props
			tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, toolManager.currentObjectRotation + (4 if toolManager.isBackground else 0));
			editorManager.iconManager.create_icon(clickPosition, "background" if toolManager.isBackground else "foreground");
		_: 
			tileMap.set_cell(clickPosition, brushObject, Vector2i.ZERO, 1);

## Deletes an entity at the clicked position.
## clickPosition: Where the mouse is during the click.
func delete_entity(clickPosition : Vector2) -> void:
	editorManager.unsavedChanges = true;
	editorManager.isValidated = false;
	
	var clickedObjectId : int = tileMap.get_cell_source_id(clickPosition);
	var clickedEntity : Node2D = get_scene_at_cell(clickPosition);
	
	if (clickedObjectId < editorManager.tileCount || clickedObjectId >= Global.BEDROCK_CORNER): return;
	elif (clickedObjectId == Global.EntityType.PLAYER): editorManager.playerExists = false;
	elif (clickedObjectId == Global.EntityType.GOAL): goalCount -= 1;
	elif (clickedEntity is Enemy || clickedEntity is MovingPlatform):
		DirAccess.remove_absolute("user://Resources/Enemies/" + clickedEntity.name + ".tres");
		clickedEntity.queue_free();
	
	if movingResource == null:
		AudioManager.play_UI_effect("TileDelete");
	tileMap.erase_cell(clickPosition);
	editorManager.iconManager.delete_icon(clickPosition);

## Open the property menu and set the selected entity
## clickPosition: position that the mouse has clicked at
func edit_properties(clickPosition : Vector2) -> void:
	var clickedEntity : Node2D = get_scene_at_cell(clickPosition);
	propertyMenu.selectedEntity = clickedEntity;
	if clickedEntity is Enemy || clickedEntity is MovingPlatform:
		propertyMenu.show_menu(clickedEntity.propertyFile);
	elif clickedEntity is Player:
		propertyMenu.show_menu();
	
## Retrieves a reference to the scene at a specific cell in the tile set
## gridPosition: position of the cell being checked
## returns: the node at the cell if there is one, null otherwise
func get_scene_at_cell(gridPosition : Vector2i) -> Node2D:
	# Iterate through each node in the tile map, if any have the same global position return it
	for node in tileMap.get_children():
		if tileMap.local_to_map(node.global_position) == gridPosition:
			return node;
	return null;

## Stores the selected entity for duplicating
## clickPos: Where the mouse clicked
func duplicate_entity(clickPosition : Vector2) -> void:
	var entity = get_scene_at_cell(clickPosition);
	editorManager.customCursorManager.highlight_selected_entity(clickPosition);
	toolManager.update_brush_object(tileMap.get_cell_source_id(clickPosition));
	propertyMenu.close();
	duplicatingResource = entity.propertyFile.duplicate(true);

## Moves the entity at the clicked position
func move_entity(previousClickPosition: Vector2) -> void:
	duplicatingResource = null;
	propertyMenu.close();
	
	toolManager.prevPosition = previousClickPosition;
	toolManager.prevBrushObject = toolManager.brushObject;
	toolManager.prevRotation = toolManager.currentObjectRotation;
	toolManager.prevIsBackground = toolManager.isBackground;
	
	# Await is needed to it has time to update selectedTile
	await get_tree().process_frame;
	var alternativeTile : int = tileMap.get_cell_alternative_tile(previousClickPosition);
	toolManager.brushObject = tileMap.get_cell_source_id(previousClickPosition);
	toolManager.isBackground = alternativeTile >= 4;
	toolManager.currentObjectRotation = alternativeTile - (4 if toolManager.isBackground else 0);
	
	
	if get_scene_at_cell(previousClickPosition) is Enemy || get_scene_at_cell(previousClickPosition) is MovingPlatform:
		movingResource = get_scene_at_cell(previousClickPosition).propertyFile;
	if (!toolManager.isDuplicating):
		delete_entity(previousClickPosition);

## Drop the tile currently selected, to be used with dragging tiles and entities with the cursor
## reset: false by default, if it's true the placed object will always return to it's spawn
func drop_entity(reset: bool = false) -> void:
	var dropPosition : Vector2;
	var clickedObjectId : int = tileMap.get_cell_source_id(editorManager.currentMousePosition);
	
	# Drop the entity on its original spot if mouse is over any object.
	if (clickedObjectId >= 0 || !editorManager.isPlaceable || reset):
		AudioManager.play_UI_effect("TilePlaceError");
		if toolManager.prevPosition == Vector2(-1 ,-1):
			toolManager.prevBrushObject = -1;
			toolManager.prevPosition = Vector2(0,0);
			toolManager.currentObjectRotation = toolManager.prevRotation;
			toolManager.isBackground = toolManager.prevIsBackground;
			return;
		# Only allow it to be placed if you aren't duplicating
		editorManager.isPlaceable = !toolManager.isDuplicating;
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
		toolManager.isBackground = toolManager.prevIsBackground;
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
			toolManager.brushObject = toolManager.prevBrushObject;
		toolManager.prevBrushObject = -1;
		toolManager.prevPosition = Vector2(0,0);
		toolManager.currentObjectRotation = toolManager.prevRotation;
		toolManager.isBackground = toolManager.prevIsBackground;
	
	var droppedEntity : Node2D = get_scene_at_cell(dropPosition);
	if !(droppedEntity is Enemy || droppedEntity is MovingPlatform) || !movingResource: return;
	
	var newResource : Resource = movingResource.duplicate(true);
	newResource.position = dropPosition;
	droppedEntity.apply_script(newResource);
	
	# Reset direction arrows
	if droppedEntity is EnemyShooting:
		droppedEntity.adjust_arrow(droppedEntity.fireDirection, droppedEntity.randomDirection);
		droppedEntity.directionArrow.scale = Vector2(1, 1);
	elif droppedEntity is EnemyPatrol:
		droppedEntity.adjust_arrow(int(newResource.direction) * 180 + 90);
		droppedEntity.directionArrow.scale = Vector2(1, 1);
	elif droppedEntity is EnemyStationary:
		droppedEntity.update_flipped();
	ResourceSaver.save(newResource, "user://Resources/Enemies/" + droppedEntity.name + ".tres");
	newResource = null;
	editorManager.reset_enemy_positions();
	
	editorManager.unsavedChanges = true;
	editorManager.isValidated = false;

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
