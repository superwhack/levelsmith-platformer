extends Node
var levelPath : String;
const defaultPath := "res://Assets/Defaults/";

## Create a new level, cloning from the default folder
## name: Name of the new level, indicates where it'll go in the folder
func make_new_level(name: String) -> void:
	clear_enemies_folder();
	DirAccess.make_dir_absolute("user://Levels/");
	levelPath = "user://Levels/" + name + "/";
	#if DirAccess.dir_exists_absolute(levelPath):
	#	print("This level already exists!");
	#	return;
	# NOTE: In the future we might want to assign this elsewhere 
	AudioManager.audioLibraryPath = levelPath + "Assets/Audio/";
	DirAccess.make_dir_absolute(levelPath);
	clone_data();

## Export the current level
## tileSet: The tileSet
## playerData: All of the player's special information
## worldSize: Size of the world (x, y) for creating the csv file.
func export_level(tileSet: TileMapLayer, playerData: Panel, worldSize: Vector2) -> void:
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
	
	# Write JSON to file and close it
	var JSONFile = FileAccess.open(levelPath + "Settings.JSON", FileAccess.WRITE);
	JSONFile.store_string(json_string);
	JSONFile.close();
	
	# Write tileData in the form of a CSV file
	var CSVFile = FileAccess.open(levelPath + "Tiles.CSV", FileAccess.WRITE);
	for currentRow in worldSize.y + 1:
		var tileRow : Array;
		for currentCol in worldSize.x + 1:
			# If there's a rotation, include it
			if tileSet.get_cell_alternative_tile(Vector2(currentCol, currentRow)) > 0:
				tileRow.append(str(tileSet.get_cell_source_id(Vector2(currentCol, currentRow)),"|",tileSet.get_cell_alternative_tile(Vector2(currentCol, currentRow))));
			else:
				tileRow.append(tileSet.get_cell_source_id(Vector2(currentCol, currentRow)));
		CSVFile.store_csv_line(tileRow);
	CSVFile.close();

func import_level(tileSet: TileMapLayer, playerData: Panel, directory: String) -> bool:
	clear_enemies_folder();
	levelPath = "user://Levels/" + directory + "/";
	if !DirAccess.dir_exists_absolute(levelPath):
		print("Level directory does not exist!")
		return false;
	print("Attempting import...");
	# Read JSON to file and close it
	var JSONFile = FileAccess.open(levelPath + "Settings.JSON", FileAccess.READ);
	var json_as_dict = JSON.parse_string(JSONFile.get_as_text());
	var player = json_as_dict.player;
	playerData.playerSpeed = player.speed;
	playerData.playerJumpHeight = player.jump;
	playerData.playerAirControl = player.airControl;
	playerData.playerFallSpeed  = player.fallSpeed;
	playerData.playerCoyoteTime = player.coyoteTime;
	playerData.update_custom();
	playerData.update_sliders();
	JSONFile.close();
	
	# Read tileData in the form of a CSV file
	var CSVFile = FileAccess.open(levelPath + "Tiles.CSV", FileAccess.READ);
	var row = 0;
	var playerExists = false;
	while !CSVFile.eof_reached():
		var currentLine = CSVFile.get_csv_line();
		var col = 0;
		for tileData in currentLine:
			# Rotated tiles
			if tileData.contains("|"):
				if (int(tileData[0]) == Global.EntityType.PLAYER):
					playerExists = true;
				var rotatedTileData = tileData.split("|");
				tileSet.set_cell(Vector2(col, row), int(rotatedTileData[0]), Vector2i.ZERO, int(rotatedTileData[1]));
			else:
				tileSet.set_cell(Vector2(col, row), int(tileData), Vector2i.ZERO);
			col += 1;
		row += 1;
	CSVFile.close();
	return playerExists;

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

func clear_enemies_folder() -> void:
	var files = DirAccess.get_files_at("res://Resources/Enemies/");
	for file in files:
		DirAccess.remove_absolute("res://Resources/Enemies/" + file);
