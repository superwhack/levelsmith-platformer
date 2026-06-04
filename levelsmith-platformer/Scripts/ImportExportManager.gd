extends Node
var levelPath : String;
@export var tileMap : TileMapLayer;
const defaultPath := "res://Assets/Defaults/";

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

## Create a new level, cloning from the default folder
## name: Name of the new level, indicates where it'll go in the folder
func make_new_level(name: String) -> void:
	DirAccess.make_dir_absolute("user://Levels/");
	levelPath = "user://Levels/" + name + "/";
	#if DirAccess.dir_exists_absolute(levelPath):
	#	print("This level already exists!");
	#	return;
	# NOTE: In the future we might want to assign this elsewhere 
	AudioManager.audioLibraryPath = levelPath + "Assets/Audio/";
	DirAccess.make_dir_absolute(levelPath);
	clone_data();

func export_level() -> void:
	return;
	var data_to_send = '{"enemies": [], "player": [';
	
	var json = JSON.parse_string(data_to_send)
	var json_string = JSON.stringify(json);
	print(json_string)
	var file = FileAccess.open(levelPath + "ex.txt", FileAccess.WRITE);
	file.store_string(json_string);
	file.close();

## Clone all of the data from the default folder 
func clone_data(directory: String = ""):
	# Recursively loop through all folders
	var childDirectories = DirAccess.get_directories_at(defaultPath + directory);
	for currentDirectory in childDirectories:
		var newPath = directory + currentDirectory + "/";
		DirAccess.make_dir_absolute(levelPath + newPath);
		clone_data(directory + currentDirectory + "/");
	
	# Copy all file data
	var files = DirAccess.get_files_at(defaultPath + directory)
	for file in files:
		DirAccess.copy_absolute(defaultPath + directory + file, levelPath + directory + file);

	#var file = FileAccess.open(levelPath + "/a.txt", FileAccess.WRITE);
	#file.store_string("TESTING");
	#file.close();
