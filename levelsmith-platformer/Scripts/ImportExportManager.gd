extends Node
var levelPath : String;
const defaultPath := "res://Assets/Defaults/";

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

func export_level(playerData: Panel, tileSet: TileMapLayer, worldSize: Vector2) -> void:
	# If anything doesn't exist, abort
	if (!playerData || !tileSet):
		return;
	
	# Create JSON for enemies and player
	var data_to_send = '{"enemies": [], "player": {';
	data_to_send += '"speed": ' + str(playerData.playerSpeed) + ", ";
	data_to_send += '"jump": ' + str(playerData.playerJumpHeight) + ", ";
	data_to_send += '"airControl": ' + str(playerData.playerAirControl) + ", ";
	data_to_send += '"fallSpeed": ' + str(playerData.playerFallSpeed) + ", ";
	data_to_send += '"coyoteTime": ' + str(playerData.playerCoyoteTime);
	data_to_send += '}}';
	var json = JSON.parse_string(data_to_send)
	var json_string = JSON.stringify(json);
	print(data_to_send)
	
	# Write JSON to file and close it
	var JSONFile = FileAccess.open(levelPath + "Settings.JSON", FileAccess.WRITE);
	JSONFile.store_string(json_string);
	JSONFile.close();
	
	# Write tileData in the form of a CSV file
	var CSVFile = FileAccess.open(levelPath + "Tiles.CSV", FileAccess.WRITE);
	for currentRow in worldSize.y:
		var tileRow : String;
		for currentCol in worldSize.x:
			# CONTINUE
			print("t")
	CSVFile.close();

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
