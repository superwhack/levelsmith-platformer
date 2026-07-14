extends Node2D

# References to other managers
@export var toolManager : Node2D;
@export var masterManager : Node2D;
@export var iconManager : Node2D;

# Camera reference
@export var mainCamera : Camera2D;
@export var levelScreenshotCamera : Camera2D;
@export var screenUI : CanvasLayer;

# References to grid TileMapLayer child nodes
@export var tileMap : TileMapLayer;
@export var previewTileMap : TileMapLayer;

# Relevant button elements
@export var playButton : Button;
@export var exportButton : Button;

# Asset Manager and Button
@export var assetManager : AssetManager;
@export var assetManagerButton : Button;
@export var closeAssetManagerButton : Button;

# Settings Menu and button
@export var levelSettingsMenu : LevelSettingsMenu;
@export var levelSettingsButton : Button;
@export var globalSettingsButton : Button;

# Cursor Manager
@export var customCursorManager : Node2D;

# Mouse position variables
var currentMousePosition : Vector2;
var prevMousePosition : Vector2;

# State of the hotbar
var currentHotbarState : Global.HotbarState;

# Flags
var isValidated : bool = false;
var isPlaceable : bool = true;
var playerExists : bool = false;
var goalExists : bool = false;

var returnClick : bool = false;

# Stores the number of tiles made
var tileCount : int = Global.TileType.size();

## Runs when the node first enters the tree
func _ready() -> void:
	var reset_player_and_goal = func() -> void:
		playerExists = false;
		goalExists = false;
	
	var export_level = func() -> void:
		AudioManager.play_UI_effect("UISelection")
		masterManager.propertyMenu.close();
		var levelScreenshot : Image = await screenshot_level();
		
		ImportExportManager.save_level_screenshot(levelScreenshot);
		ImportExportManager.export_level(tileMap, masterManager.propertyMenu, masterManager.worldSize, levelSettingsMenu, isValidated);
	
	assetManagerButton.pressed.connect(open_asset_manager);
	levelSettingsButton.pressed.connect(open_level_settings_menu);
	globalSettingsButton.pressed.connect(masterManager.open_global_settings_menu);
	Global.levelCreated.connect(reset_player_and_goal);
	exportButton.pressed.connect(export_level);
	closeAssetManagerButton.pressed.connect(close_asset_manager);

## Runs every frame during the editing state
## _delta: how much time has passed since the last frame
func _process(_delta: float) -> void:
	# Record the position of the mouse on this frame
	currentMousePosition = get_grid_mouse_position(get_global_mouse_position());
	# Check if the tile is placeable in this spot
	isPlaceable = !check_out_of_bounds(currentMousePosition);
	
	if (toolManager.currentTool != Global.Tool.CURSOR && tileMap.get_cell_source_id(currentMousePosition) >= tileCount): isPlaceable = false; 
	
	if (toolManager.currentTool == Global.Tool.CURSOR && tileMap.get_cell_source_id(currentMousePosition) < tileCount && tileMap.get_cell_source_id(currentMousePosition) >= 0): isPlaceable = false;
	 
	# Pause the player and enemies
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED);
	get_tree().set_group("Moving", "process_mode", Node.PROCESS_MODE_DISABLED);

	playButton.modulate = Color(1, 1, 1) if playerExists && goalExists else Color(1, 1, 1, 0.5);
	
	# Save the mouse position to the previous frame
	prevMousePosition = currentMousePosition;
	
## When the user does a save level input, save the level.
## event: The user input
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("level_save")):
		masterManager.propertyMenu.close();
		var levelScreenshot : Image = await screenshot_level();
		ImportExportManager.save_level_screenshot(levelScreenshot);
		ImportExportManager.export_level(tileMap, masterManager.propertyMenu, masterManager.worldSize, levelSettingsMenu, isValidated);


## Takes a screenshot of the level by hiding the UI and disabling the main camera
## returns; The image of the level
func screenshot_level() -> Image:
	mainCamera.enabled = false;
	levelScreenshotCamera.enabled = true;
	screenUI.hide();
	previewTileMap.hide();
	await RenderingServer.frame_post_draw;
	
	var screenshotImage = levelScreenshotCamera.get_level_screenshot();
	
	screenUI.show();
	previewTileMap.show();
	mainCamera.enabled = true;
	levelScreenshotCamera.enabled = false;
	await RenderingServer.frame_post_draw; 
	
	return screenshotImage;

## NOTE: TEMPORARY FIX FUNCTION PT 1
## Clear all enemies without a property file
func clear_enemies(alwaysClear: bool = false) -> void:
	for child in tileMap.get_children():
		if child is Enemy || child is MovingPlatform:
			if alwaysClear || child.propertyFile == null:
				child.queue_free();

## Changes current hotbar state (used for hotkeys)
## newState: Global.HotbarState
func change_current_hotbar(newState: Global.HotbarState):
	currentHotbarState = newState;

## Converts the mouse's position into grid coordinates.
## mousePosition: Where the cursor currently is in world space.
## returns: The grid-coordinate equivalent of the position.
func get_grid_mouse_position(mousePosition: Vector2) -> Vector2:
	return tileMap.local_to_map(tileMap.to_local(mousePosition));
	
## Checks if the mouse is currently outside of the world grid size
## mousePosition: Where the mouse is during this check 
## returns: True if the mouse is out of bounds
func check_out_of_bounds(mousePosition: Vector2i) -> bool:
	return mousePosition.x < 0 || mousePosition.x >= masterManager.worldSize.x || mousePosition.y < 0 || mousePosition.y >= masterManager.worldSize.y;
	
## Reset all the enemy positions to the center of their tiles.
func reset_enemy_positions() -> void:
	for moving in get_tree().get_nodes_in_group("Moving"):
		if (moving is Enemy || moving is MovingPlatform) && moving.propertyFile:
			moving.global_position = tileMap.map_to_local(moving.propertyFile.position);
			if !moving is EnemyFlyer:
				moving.global_position += Vector2(0, 20);
			if moving is EnemyPatrol:
				moving.directionArrow.show();
			elif moving is EnemyShooting:
				moving.directionArrow.show();
			elif moving is EnemyFlyer:
				moving.previewLine.show();
		if moving is MovingPlatform && moving.propertyFile:
			moving.global_position = tileMap.map_to_local(moving.propertyFile.position);
			moving.previewPlatform.show();
			moving.previewLine.show();

## Opens the asset manager
func open_asset_manager() -> void:
	# WARNING: get_tree().paused has the potential to cause issues
	get_tree().paused = true;
	AudioManager.play_UI_effect("UISelection")
	previewTileMap.hide();
	iconManager.previewIcon.hide();
	assetManager.show();

## Opens the settings menu
func open_level_settings_menu() -> void:
	# WARNING: get_tree().paused has the potential to cause issues
	get_tree().paused = true;
	AudioManager.play_UI_effect("UISelection")
	previewTileMap.hide();
	iconManager.previewIcon.hide();
	levelSettingsMenu.show();

## Closes the asset manager
func close_asset_manager() -> void:
	# WARNING: get_tree().paused has the potential to cause issues
	get_tree().paused = false;
	AudioManager.play_UI_effect("UISelection");
	previewTileMap.show();
	assetManager.hide();
	assetManager.animationSwapping.playingAnimation = false;
	AnimationManager.refresh_animations();

## Closes the settings menu
func close_level_settings_menu() -> void:
	# WARNING: get_tree().paused has the potential to cause issues
	get_tree().paused = false;
	AudioManager.play_UI_effect("UISelection");
	previewTileMap.show();
	levelSettingsMenu.hide();
