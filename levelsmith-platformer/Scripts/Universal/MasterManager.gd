extends Node2D

# State variable to represent the state the game is currently in
var state : Global.State = Global.State.MAIN_MENU;

# References to state managers and canvas components
@export var editorManager : Node2D;
@export var toolManager : Node2D;
@export var gameManager : Node2D;
@export var entityManager : Node2D;
@export var cameraManager : Camera2D;
@export var editorManagerCanvas : CanvasLayer;
@export var gameManagerCanvas : CanvasLayer;
@export var loadingScreen : CanvasLayer;
@export var loadingImage : TextureRect;
@export var mainMenuControl : Control;

# Reference to the global settings menu
@export var globalSettingsMenu : GlobalSettingsMenu;

# References to relevant buttons
@export var editorHomeButton : Button;
@export var editorPlayButton : Button;
@export var returnToEditorButton : Button;
@export var winReturnToEditorButton : Button;
@export var playPopUp : HBoxContainer;

# Reference to tile maps
@export var tileMap : TileMapLayer;
@export var previewTileMap : TileMapLayer;
@export var gridLines : TileMapLayer;

# Map that is currently loaded in the Play scene
var loadedMap : TileMapLayer;

## Vars for the world size.
@export var worldSize : Vector2i;

# Reference to the property menu
@export var propertyMenu : Panel;

# The file path to the loaded level
var loadedLevelPath : String = "";

# Tween information
var loadingTween : Tween
# The time that the screen wipe takes
var loadingTweenTime : float = 0.2
#The time that the full screen holds
var loadingHold : float = 0.10

# An enum for determining if we are going to the main menu or desktop.
enum ExitAction {
	MAIN_MENU,
	QUIT
}

## Runs when the scene enters the node tree
func _ready() -> void:
	# Connect global signals
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED);
	Global.reload.connect(load_tilemap);
	Global.levelCreated.connect(tileMap.clear);
	Global.levelCreated.connect(create_bedrock_border);
	Global.levelCreated.connect(edit);
	ImportExportManager.levelImported.connect(create_bedrock_border);
	
	# Connect all button signals
	editorHomeButton.pressed.connect(main_menu.bind(false));
	editorHomeButton.pressed.connect(AudioManager.play_UI_effect.bind("UISelection"));
	editorPlayButton.pressed.connect(play);
	editorPlayButton.mouse_entered.connect(mouse_entered_play_button);
	editorPlayButton.mouse_exited.connect(mouse_exited_play_button);
	returnToEditorButton.pressed.connect(edit);
	returnToEditorButton.pressed.connect(AudioManager.play_UI_effect.bind("UISelection"));
	get_window().close_requested.connect(check_unsaved_changes.bind(Callable(get_tree(), "quit"), ExitAction.QUIT));
	
	# Create the enemy resource folder and custom player preset.
	if (!DirAccess.dir_exists_absolute("user://Resources/")):
		DirAccess.make_dir_absolute("user://Resources/");
		DirAccess.make_dir_absolute("user://Resources/Enemies/");
		DirAccess.copy_absolute("res://Resources/PlayerPresets/Default.tres", "user://Resources/Custom.tres");
	
	# Open the main menu
	main_menu(false);
	
	# Show loading screen, open the main menu in start mode
	await screen_static();
	await main_menu(false, true);

## Handles the user pressing the fullscreen button
## event: The user input
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle-fullscreen"):
		# Toggle the window mode between Fullscreen and Windowed
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED);
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN);
	
## When the level is completed, validate it and automatically return to editor
## NOTE: In the future we may want to instead pop up a menu notifying the player of completion.
#func level_complete() -> void:
	#edit();
	#editorManager.isValidated = true;
	##print("LEVEL COMPLETE");

## Plays the screen wipe animation that covers the screen before a state transition.
func screen_wipe_in() -> void:
	# If the screen is already shown, return
	if (loadingScreen.visible): return;
	loadingScreen.show();
	# Create the loading animation tween
	loadingTween = create_tween();
	loadingTween.tween_property(loadingImage.material, "shader_parameter/progress", 1.0, loadingTweenTime);
	await loadingTween.finished;
	await get_tree().create_timer(loadingHold).timeout;

## Plays the screen wipe animation that reveals the destination state after loading.
func screen_wipe_out() -> void:
	# If the loading screen is already showing, return
	if (!loadingScreen.visible): return;
	# Create the loading animation tween
	loadingTween = create_tween();
	loadingTween.tween_property(loadingImage.material, "shader_parameter/progress", 0.0, loadingTweenTime);
	await loadingTween.finished;
	loadingScreen.hide();

## special loading screen specific for main menu
func screen_static() -> void:
	await get_tree().create_timer(loadingHold).timeout;
	screen_wipe_out();

## Set up a new level
## levelName: Name of the level
## levelAuthor: Author of the level
## newSize: The width and height of the level
func level_setup( levelName: String, levelAuthor: String, newSize: Vector2i ) -> void:
	# Overrides alt+f4 for saving
	# Set the world size
	worldSize = newSize;
	# Initialize the camera
	cameraManager.initialize_camera();
	# Create the new level
	ImportExportManager.make_new_level(levelName, levelAuthor, worldSize);
	# Reset the custom player property
	propertyMenu.reset_custom();
	loadedLevelPath = "user://Levels/" + levelName + "/";
	# Set all fps based on the json file
	AnimationManager.set_all_fps_to_json(loadedLevelPath + "Settings.JSON");
	Global.levelCreated.emit();
	editorManager.returnClick = false;

## Draws the border around the level grid.
func create_bedrock_border() -> void:
	# Draw 4 corners first
	tileMap.set_cell(Vector2i(-1, -1), Global.BEDROCK_CORNER, Vector2i.ZERO);
	tileMap.set_cell(Vector2i(worldSize.x, -1), Global.BEDROCK_CORNER, Vector2i.ZERO, 1);
	tileMap.set_cell(Vector2i(-1, worldSize.y), Global.BEDROCK_CORNER, Vector2i.ZERO, 2);
	tileMap.set_cell(Vector2i(worldSize.x, worldSize.y), Global.BEDROCK_CORNER, Vector2i.ZERO, 3);
	
	# Top/Bottom Walls
	for x in range(0, worldSize.x):
		tileMap.set_cell(Vector2i(x, -1), Global.BEDROCK_WALL, Vector2i.ZERO);
		tileMap.set_cell( Vector2i(x, worldSize.y), Global.BEDROCK_WALL, Vector2i.ZERO, 1);
	
	# Left/Right Walls
	for y in range(0, worldSize.y):
		tileMap.set_cell(Vector2i(-1, y), Global.BEDROCK_WALL, Vector2i.ZERO, 2);
		tileMap.set_cell(Vector2i(worldSize.x, y), Global.BEDROCK_WALL, Vector2i.ZERO, 3);

## Imports a level 
## startPlay: Starts the level in play mode
func import_level_and_edit(startPlay: bool = false, skipWipeIn: bool = false) -> void:
	ImportExportManager.validate_import(loadedLevelPath);
	
	# Clear the enemies from the folder
	ImportExportManager.clear_enemies_folder();
	# Delete all child nodes
	for childNode in editorManager.tileMap.get_children():
		childNode.free();
	# Wait for the ImportExportManager to import the level CSV before setting the playerExists to true
	editorManager.playerExists = await ImportExportManager.import_level_CSV(editorManager.tileMap);
	# Set the world size
	worldSize = ImportExportManager.importedLevelSize;
	# Call setup functions
	editorManager.returnClick = false;
	entityManager.scan_goals(worldSize.x, worldSize.y);
	editorManager.reset_enemy_positions();
	# Wait a frame
	await get_tree().process_frame;
	# Initialize the camera, import data
	cameraManager.initialize_camera();
	ImportExportManager.import_JSON(editorManager.tileMap, propertyMenu, editorManager.levelSettingsMenu);
	ImportExportManager.levelImported.emit();
	# Start in play or edit
	if (startPlay && get_play_errors().is_empty()):
		await play(skipWipeIn);
	else:
		await edit(skipWipeIn);
	#propertyMenu._on_preset_options_item_selected(4);
	await get_tree().process_frame;

## Loads the given level to the player.
## levelPath: The folder path of the level.
## startPlay: Starts the level in play mode
func load_level(levelPath: String, startPlay: bool = false) -> void:
	# If it is a valid import, set the paths accordingly
	if (ImportExportManager.validate_import(levelPath)):
		print("Settings level path...", levelPath)
		ImportExportManager.levelPath = levelPath;
		loadedLevelPath = levelPath;
		await screen_wipe_in();
		await get_tree().process_frame;
		
		# Await so that the camera gets properly placed
		await import_level_and_edit(startPlay, true);

## Checks if the level has unsaved changes, and creates a popup with appropriate functions.
## on_continue: A callable function, for going to main menu or force quitting app.
func check_unsaved_changes(onContinue: Callable, exit: ExitAction) -> void:
	# No unsaved changes, do regular action.
	if (!editorManager.unsavedChanges):
		onContinue.call();
		return;
	
	# Saves and brings the user to the main menu. First callable.
	var save = func() -> void:
		editorManager.unsavedChanges = false;
		#AudioManager.play_UI_effect("UISelection");
		var levelScreenshot : Image = await editorManager.levelScreenshotCamera.get_level_screenshot();
		ImportExportManager.save_level_screenshot(levelScreenshot);
		ImportExportManager.export_level(editorManager.tileMap, propertyMenu, worldSize, editorManager.levelSettingsMenu, editorManager.isValidated, get_play_errors().is_empty());
		onContinue.call();
	
	# No save, brings user to main menu
	var no_save = func() -> void:
		editorManager.unsavedChanges = false;
		onContinue.call();
	
	# If there are unsaved changes, popup to allow the user to save
	if (editorManager.unsavedChanges):
		PopUpManager.create_unsaved_changes_popup(save, no_save);
	# If exiting project show popup for save and quit
	if (exit == ExitAction.QUIT):
		PopUpManager.currentPopUp.set_save_quit_text("Save & Quit to Desktop");
		PopUpManager.currentPopUp.set_no_save_quit_text("Quit to Desktop");


## Swap to main menu state
## menuClickSound : Whether the sound should play for the menu being clicked
## onStart : Whether this is being called when starting the project
func main_menu(menuClickSound : bool = true, onStart : bool = false) -> void:
	# If there are unsaved changes, run the function to take care of those
	if (editorManager.unsavedChanges):
		check_unsaved_changes(main_menu, ExitAction.MAIN_MENU);
		return;
	# Fill the list of levels
	mainMenuControl.fill_level_list();
	# If it is when the project starts, screen wipe
	if (!onStart):
		await screen_wipe_in();
	# If the click sound should play, play it
	if (menuClickSound):
		AudioManager.play_UI_effect("UISelection");
	# Hide all non-menu states, show Main Menu scene
	gameManager.hide();
	gameManagerCanvas.hide();
	tileMap.clear();
	editorManager.hide();
	editorManager.clear_enemies(true);
	editorManagerCanvas.hide();
	propertyMenu.close();
	mainMenuControl.show();
	ImportExportManager.clear_enemies_folder();
	AudioManager.reset_audio();
	if (mainMenuControl.selectedItem):
		mainMenuControl.update_metadata(mainMenuControl.selectedItem);
		mainMenuControl.buttonPlayLevel.disabled = !mainMenuControl.selectedItem.playable;
	# Set the state to the Main Menu
	state = Global.State.MAIN_MENU;
	await get_tree().process_frame;
	if !onStart:
		await screen_wipe_out();
	loadedLevelPath = "";
	# Removes alt+f4 override
	get_tree().set_auto_accept_quit(true);

## Swap to edit state
func edit(skipWipeIn: bool = false) -> void:
	#AudioManager.play_UI_effect("UISelection");
	# Setup edit state
	get_tree().set_auto_accept_quit(false);
	gameManager.pausable = false;
	await get_tree().process_frame;
	if (!skipWipeIn):
		await screen_wipe_in();
	# Reset audio and play ui effect
	AudioManager.reset_audio();
	AnimationManager.pause_all_animations();
	# Pause players
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED);
	# Delete tileMap from the game manager
	if gameManager.tileMap:
		gameManager.tileMap.queue_free();
	
	# Update state variable
	state = Global.State.EDIT;
	# Change scene to edit scene
	mainMenuControl.hide();
	gameManager.hide();
	gameManagerCanvas.hide();
	editorManager.show();
	if !gameManager.goalReached:
		editorManager.returnClick = true;
	# Just so there aren't any issues when holding down a button before swapping to play
	toolManager.isErasing = false;
	toolManager.isPainting = false;
	# You can right click after completing a level
	toolManager.clickOnUI = false;
	entityManager.duplicatingResource = null;
	editorManagerCanvas.show();
	AnimationManager.pause_all_animations();
	# Play the editor manager
	editorManager.process_mode = Node.PROCESS_MODE_INHERIT;
	for frame in range(1, 3):
		await get_tree().process_frame;
	editorManager.reset_enemy_positions();
	editorManager.clear_enemies();
	await get_tree().process_frame;
	await screen_wipe_out();

## Swap to play state
func play(skipWipeIn: bool = false) -> void:
	AudioManager.play_UI_effect("UISelection");
	# Check that the game can be run
	if (!get_play_errors().is_empty()):
		return;
	if !skipWipeIn:
		await screen_wipe_in();
	propertyMenu.close();
	AudioManager.play_music("LevelMusic");
	AnimationManager.play_all_animations();
	# Update state variable
	state = Global.State.PLAY;
	# Save map
	save_tilemap();
	# Change scene to play 
	gameManager.show();
	gameManager.playerPreset = propertyMenu.selectedPlayerPreset;
	gameManagerCanvas.show();
	editorManager.hide();
	editorManagerCanvas.hide();
	mainMenuControl.hide();
	previewTileMap.clear();
	toolManager.disable_box_brush();
	# Pause the editor manager
	editorManager.process_mode = Node.PROCESS_MODE_DISABLED;
	# Reset the play scene and load the map
	gameManager.freeze(true);
	await gameManager.full_restart();
	await get_tree().process_frame;
	await screen_wipe_out();
	gameManager.freeze(false);

## Saves the tilemap to the resource folder
func save_tilemap() -> void:
	# Reference the tile map as the node to be saved
	var nodeToSave : Node = tileMap;
	# Create a PackedScene
	var scene : PackedScene = PackedScene.new();
	# Pack the node to save as a scene
	scene.pack(nodeToSave);
	# Save that scene to the resource folder
	ResourceSaver.save(scene, "user://SavedTileMap.tscn");

## Loads the tilemap from the resource folder
func load_tilemap() -> void:
	# If any map is currently loaded, delete that
	if (loadedMap):
		gameManager.remove_child(loadedMap);
		loadedMap.queue_free();
	# Load the saved map from the resource folder
	var savedMap : Resource = ResourceLoader.load("user://SavedTileMap.tscn");
	# Instantiate the map as a scene instance
	var sceneInstance : Node = savedMap.instantiate();
	# Add that instance to the top of the GameManager's hierarchy
	gameManager.add_child(sceneInstance);
	gameManager.move_child(sceneInstance, 0);
	
	# WARNING: Unsure if this could be a reference
	loadedMap = gameManager.get_child(0);
	gameManager.tileMap = loadedMap;

## Shows the play pop up to the user.
func mouse_entered_play_button() -> void:
	var errors : Array[String] = get_play_errors();
	# So long as there are errors, modify the pop-up to be accurate.
	if (errors.size() > 0):
		playPopUp.set_title("REQUIRED TO RUN");
		var bodyText : String = "";
		for messageNum in range(0, errors.size()):
			bodyText += " + " + errors[messageNum];
			if (messageNum != errors.size() - 1):
				bodyText += "\n";
		playPopUp.set_body_text(bodyText);
		playPopUp.show();

## Hides the play pop up from the user.
func mouse_exited_play_button() -> void:
	playPopUp.hide();

## Validates if a level is playable, and returns a string of any found errors
## Returns an array of error points, but not a full error description.
func get_play_errors() -> Array[String]:
	var errors : Array[String] = [];
	# Add player nonexistant error
	if (!editorManager.playerExists):
		errors.append("Player");
	# Add goal nonexistant error
	if (!editorManager.goalExists):
		errors.append("End Goal");
	return errors;

## Display the global settings menu
func open_global_settings_menu() -> void:
	# Pause the tree, show the settings menu
	get_tree().paused = true;
	AudioManager.play_UI_effect("UISelection")
	previewTileMap.hide();
	globalSettingsMenu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED;
	globalSettingsMenu.show();

## Closes the settings menu
func close_global_settings_menu() -> void:
	# Unpause the tree, hide the settings menu
	get_tree().paused = false;
	AudioManager.play_UI_effect("UISelection");
	previewTileMap.show();
	globalSettingsMenu.hide();
	globalSettingsMenu.process_mode = Node.PROCESS_MODE_DISABLED;
