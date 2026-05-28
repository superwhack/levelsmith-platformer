extends Node2D

# State variable to represent the state the game is currently in
var state : Global.State = Global.State.PLAY;

# References to both state managers
@export var editorManager : Node2D;
@export var gameManager : Node2D;

# Map that is currently loaded in the Play scene
var loadedMap : TileMapLayer;

func _ready() -> void:
	edit();

## Swap to edit state
func edit() -> void:
	print("Edit")
	editorManager.process_mode = Node.PROCESS_MODE_ALWAYS;
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED)
	# Update state variable
	state = Global.State.EDIT;
	# Change scene to edit scene
	gameManager.hide();
	gameManager.reset();
	editorManager.show();
	# Play the editor manager
	editorManager.process_mode = Node.PROCESS_MODE_INHERIT;

## Swap to play
func play() -> void:
	print(get_tree().get_node_count_in_group("Player"))
	editorManager.process_mode = Node.PROCESS_MODE_DISABLED;
	print("Play")
	# Update state variable
	state = Global.State.PLAY;
	# Save map
	save_tilemap();
	# Change scene to play 
	gameManager.show();
	gameManager.start();
	editorManager.hide();
	# Pause the editor manager
	editorManager.process_mode = Node.PROCESS_MODE_DISABLED;
	# Load map
	load_tilemap();
	# Reset the play scene
	gameManager.reset();

## Saves the tilemap to the resource folder
func save_tilemap() -> void:
	# Reference the tile map as the node to be saved
	var nodeToSave = editorManager.get_node("Tiles");
	# Create a PackedScene
	var scene = PackedScene.new();
	# Pack the node to save as a scene
	scene.pack(nodeToSave)
	# Save that scene to the resource folder
	ResourceSaver.save(scene, "res://Scenes/SavedTileMap.tscn");

## Loads the tilemap from the resource folder
func load_tilemap() -> void:
	# If any map is currently loaded, delete that
	if (loadedMap):
		gameManager.remove_child(loadedMap);
		loadedMap.queue_free();
	# Load the saved map from the resource folder
	var savedMap = load("res://Scenes/SavedTileMap.tscn");
	# Instantiate the map as a scene instance
	var sceneInstance = savedMap.instantiate();
	# Add that instance to the top of the GameManager's hierarchy
	gameManager.add_child(sceneInstance);
	gameManager.move_child(sceneInstance, 0);
	loadedMap = gameManager.get_child(0);
