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
@export var mainMenuControl : Control;

# References to relevant buttons
@export var editorHomeButton : Button;
@export var editorPlayButton : Button;
@export var returnToEditorButton : Button;
@export var playPopUp : HBoxContainer;

# Reference to tile maps
@export var tileMap : TileMapLayer;
@export var previewTileMap : TileMapLayer;
@export var gridLines : TileMapLayer;

# Map that is currently loaded in the Play scene
var loadedMap : TileMapLayer;

## NOTE: Magic numbers!!! This should be dynamic when loading/creating a level!
## Vars for the world size.
@export var worldSize : Vector2i;
@export var propertyMenu : Panel;

var loadedLevelPath: String = "";

func _ready() -> void:
	Global.reload.connect(load_tilemap);
	#Global.complete.connect(level_complete);
	Global.levelCreated.connect(tileMap.clear);
	Global.levelCreated.connect(create_bedrock_border);
	Global.levelCreated.connect(edit);
	ImportExportManager.levelImported.connect(create_bedrock_border);
	ImportExportManager.levelImported.connect(edit);
	
	# Connect all button signals
	editorHomeButton.pressed.connect(main_menu);
	editorPlayButton.pressed.connect(play);
	editorPlayButton.mouse_entered.connect(mouse_entered_play_button);
	editorPlayButton.mouse_exited.connect(mouse_exited_play_button);
	returnToEditorButton.pressed.connect(edit);
	
	# NOTE: This probably shouldn't be here for the final build
	# Create the Enemies folder, github can't push empty folders
	if (!DirAccess.dir_exists_absolute("res://Resources/Enemies/")):
		DirAccess.make_dir_absolute("res://Resources/Enemies/");
		
	main_menu(false);
	
## When the user does a save level input, save the level.
## event: The user input
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("level_save")):
		ImportExportManager.export_level(editorManager.tileMap, propertyMenu, worldSize, editorManager.settingsMenu);

## When the level is completed, validate it and automatically return to editor
## NOTE: In the future we may want to instead pop up a menu notifying the player of completion.
#func level_complete() -> void:
	#edit();
	#editorManager.isValidated = true;
	##print("LEVEL COMPLETE");

## Set up a new level
## levelName: Name of the level
## newSize: The width and height of the level
func level_setup( levelName: String, newSize: Vector2i ) -> void:
	worldSize = newSize;
	cameraManager.initialize_camera();
	ImportExportManager.make_new_level(levelName, worldSize, editorManager.settingsMenu);
	propertyMenu.reset_custom();
	loadedLevelPath = "user://Levels/" + levelName + "/";
	#AudioManager.masterVolume = 0;
	#AudioManager.update_volume();
	#print("NEW LEVEL SET UP");
	Global.levelCreated.emit();
	editorManager.returnClick = false;

func create_bedrock_border() -> void:
	for x in range(-1, worldSize.x + 1):
		tileMap.set_cell(Vector2i(x, -1), Global.BEDROCK_TILE, Vector2i.ZERO);
		#print(tileMap.get_cell_source_id(Vector2i(-1,0))," ",tileMap.get_cell_atlas_coords(Vector2i(-1,0)))
		tileMap.set_cell( Vector2i(x, worldSize.y), Global.BEDROCK_TILE, Vector2i.ZERO);
		#print(tileMap.get_cell_source_id(Vector2i(-1,0))," ",tileMap.get_cell_atlas_coords(Vector2i(-1,0)))

	for y in range(0, worldSize.y):
		tileMap.set_cell(Vector2i(-1, y), Global.BEDROCK_TILE, Vector2i.ZERO);
		#print(tileMap.get_cell_source_id(Vector2i(-1,0))," ",tileMap.get_cell_atlas_coords(Vector2i(-1,0)))
		tileMap.set_cell(Vector2i(worldSize.x, y), Global.BEDROCK_TILE, Vector2i.ZERO);
		#print(tileMap.get_cell_source_id(Vector2i(-1,0))," ",tileMap.get_cell_atlas_coords(Vector2i(-1,0)))

	#print("Bedrock border created: ", tileMap.get_used_rect());

## Imports a level 
func import_level_and_edit() -> void:
	ImportExportManager.clear_enemies_folder();
	for childNode in editorManager.tileMap.get_children():
		childNode.free();
	editorManager.playerExists = await ImportExportManager.import_level_CSV(editorManager.tileMap);
	worldSize = ImportExportManager.importedLevelSize;
	editorManager.returnClick = false;
	entityManager.scan_goals(worldSize.x, worldSize.y);
	editorManager.reset_enemy_positions();
	await get_tree().process_frame;
	ImportExportManager.import_JSON(editorManager.tileMap, propertyMenu, editorManager.settingsMenu);
	ImportExportManager.levelImported.emit();
	#propertyMenu._on_preset_options_item_selected(4);

## Loads the given level to the player.
## levelPath: The folder path of the level.
func load_level(levelPath: String) -> void:
	if (ImportExportManager.validate_import(levelPath)):
		ImportExportManager.levelPath = levelPath;
		loadedLevelPath = levelPath;
		# Await so that the camera gets properly placed
		await import_level_and_edit();
		cameraManager.initialize_camera();

## Swap to main menu state
func main_menu(menuClickSound : bool = true) -> void:
	if menuClickSound:
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
	mainMenuControl.fill_level_list();
	# Set the state to the Main Menu
	state = Global.State.MAIN_MENU;
	loadedLevelPath = "";

## Swap to edit state
func edit() -> void:
	AudioManager.reset_audio();
	AudioManager.play_UI_effect("UISelection");
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED);
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

## Swap to play state
func play() -> void:
	# Check that the game can be run
	if (!get_play_errors().is_empty()):
		return;
	propertyMenu.close();
	AudioManager.play_UI_effect("UISelection");
	AudioManager.play_music("LevelMusic");
	# Update state variable
	state = Global.State.PLAY;
	# Save map
	save_tilemap();
	# Change scene to play 
	gameManager.show();
	gameManager.playerPreset = propertyMenu.selectedPlayerPreset;
	gameManager.start();
	gameManagerCanvas.show();
	editorManager.hide();
	editorManagerCanvas.hide();
	previewTileMap.clear();
	toolManager.disable_box_brush();
	# Pause the editor manager
	editorManager.process_mode = Node.PROCESS_MODE_DISABLED;
	# Reset the play scene and load the map
	gameManager.reset();
	

## Saves the tilemap to the resource folder
func save_tilemap() -> void:
	# Reference the tile map as the node to be saved\
	var nodeToSave : Node = tileMap;
	# Create a PackedScene
	var scene : PackedScene = PackedScene.new();
	# Pack the node to save as a scene
	scene.pack(nodeToSave)
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
	
	if (!editorManager.playerExists):
		errors.append("Player");
	if (!editorManager.goalExists):
		errors.append("End Goal");
		
	return errors;
