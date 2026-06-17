extends Node2D

# State variable to represent the state the game is currently in
var state : Global.State = Global.State.EDIT;

# References to state managers and canvas components
@export var editorManager: Node2D;
@export var toolManager: Node2D;
@export var gameManager: Node2D;
@export var entityManager: Node2D;
@export var audioManager: Node;
@export var cameraManager: Camera2D;
@export var editorManagerCanvas: CanvasLayer;
@export var gameManagerCanvas: CanvasLayer;
@export var mainMenuControl: Control;

# Reference to tileset
@export var tileSet: TileMapLayer;
@export var previewTileMap: TileMapLayer;
@export var gridLines: TileMapLayer;

# Map that is currently loaded in the Play scene
var loadedMap: TileMapLayer;

## NOTE: Magic numbers!!! This should be dynamic when loading/creating a level!
## Vars for the world size.
@export var worldSize: Vector2i;

@export var propertyMenu : Panel;

@export var playButton : Button;

func _ready() -> void:
	#Global.reload.connect(load_tilemap);
	#Global.complete.connect(level_complete);
	#ImportExportManager.make_new_level("Level01");
	AudioManager.masterVolume = 0;
	AudioManager.update_volume();
	playButton.pressed.connect(play);
	
	# NOTE: This probably shouldn't be here for the final build
	# Create the Enemies folder, github can't push empty folders
	if !DirAccess.dir_exists_absolute("res://Resources/Enemies/"):
		DirAccess.make_dir_absolute("res://Resources/Enemies/");
		
	#edit();
	main_menu();

## When the level is completed, validate it and automatically return to editor
## NOTE: In the future we may want to instead pop up a menu notifying the player of completion.
func level_complete() -> void:
	edit();
	editorManager.isValidated = true;
	print("LEVEL COMPLETE");
	
func level_setup( levelName: String, newSize: Vector2i ) -> void:
	worldSize = newSize;
	ImportExportManager.make_new_level( levelName );
	Global.reload.connect(load_tilemap);
	Global.complete.connect(level_complete);
	#AudioManager.masterVolume = 0;
	#AudioManager.update_volume();
	print("NEW LEVEL SET UP");
	tileSet.clear();
	editorManager.playerExists = false;
	editorManager.goalExists = false;
	entityManager.goalCount = 0;
	gridLines.fill_grid_lines();
	cameraManager.refresh_bounds();
	edit();

## Swap to main menu state
func main_menu() -> void:
	
	gameManager.hide();
	gameManagerCanvas.hide();
	editorManager.hide();
	editorManagerCanvas.hide();
	mainMenuControl.show();
	
	state = Global.State.MAIN_MENU;

## Swap to edit state
func edit() -> void:
	toolManager.change_tool(Global.Tool.BRUSH);
	AudioManager.play_UI_music("EditorMusic");
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED);
	# Update state variable
	state = Global.State.EDIT;
	# Change scene to edit scene
	mainMenuControl.hide();
	gameManager.hide();
	gameManagerCanvas.hide();
	editorManager.show();
	editorManager.returnClick = true;
	editorManagerCanvas.show();
	# Play the editor manager
	editorManager.process_mode = Node.PROCESS_MODE_INHERIT;
	for frame in range(1, 3):
		await get_tree().process_frame;
	editorManager.reset_enemy_positions();

## Swap to play state
func play() -> void:
	var errors : Array[String];
	if (!editorManager.playerExists):
		errors.append("There is no player placed down.")
	if (!editorManager.goalExists):
		errors.append("There is no goal placed down.")
	if errors.size() != 0:
		PopUpManager.create_multi_error_popup("Cannot Start Level", errors);
		return;
	propertyMenu.close();
	AudioManager.play_music("LevelMusic");
	# Update state variable
	state = Global.State.PLAY;
	# Save map
	save_tilemap();
	# Change scene to play 
	gameManager.show();
	gameManager.start();
	gameManagerCanvas.show()
	editorManager.hide();
	editorManagerCanvas.hide();
	previewTileMap.clear();
	toolManager.disable_box_brush();
	# Pause the editor manager
	editorManager.process_mode = Node.PROCESS_MODE_DISABLED;
	# Reset the play scene and load the map
	gameManager.reset();
	gameManager.playerPreset = propertyMenu.selectedPlayerPreset;

## Saves the tilemap to the resource folder
func save_tilemap() -> void:
	# Reference the tile map as the node to be saved\
	var nodeToSave = tileSet;
	# Create a PackedScene
	var scene = PackedScene.new();
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
	var savedMap = ResourceLoader.load("user://SavedTileMap.tscn");
	# Instantiate the map as a scene instance
	var sceneInstance = savedMap.instantiate();
	# Add that instance to the top of the GameManager's hierarchy
	gameManager.add_child(sceneInstance);
	gameManager.move_child(sceneInstance, 0);
	
	# WARNING: Unsure if this could be a reference
	loadedMap = gameManager.get_child(0);
	gameManager.tileSet = loadedMap;
## THESE ARE TEMPORARY AND SHOULD BE CHANGED WHEN BUTTONS ARE PUT IN
func _process(_delta: float) -> void:
	if (Input.is_action_just_pressed("tempSave")):
		ImportExportManager.export_level(editorManager.tileSet, propertyMenu, worldSize);
	if (Input.is_action_just_pressed("tempLoad")):
		propertyMenu.close();
		var result = ImportExportManager.validate_import("Level01");
		if (result):
			ImportExportManager.clear_enemies_folder();
			for childNode in editorManager.tileSet.get_children():
				childNode.free();
			editorManager.playerExists = await ImportExportManager.import_level_CSV(editorManager.tileSet, propertyMenu);
			editorManager.reset_enemy_positions();
			await get_tree().process_frame;
			ImportExportManager.import_JSON(editorManager.tileSet, propertyMenu)
			propertyMenu._on_preset_options_item_selected(4);
		editorManager.check_goal_exists();
