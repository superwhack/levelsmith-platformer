extends Node

var levelPath : String;
var levelAssetPath : String;

const defaultPath := "res://Assets/Defaults/";

signal levelImported;

## Create a new level, cloning from the default folder
## levelName: Name of the new level, indicates where it'll go in the folder
func make_new_level(levelName: String) -> void:
	clear_enemies_folder();
	DirAccess.make_dir_absolute("user://Levels/");
	levelPath = "user://Levels/" + levelName + "/";
	levelAssetPath = levelPath + "Assets/";
	# NOTE: In the future we might want to assign this elsewhere 
	AudioManager.audioLibraryPath = levelPath + "Assets/Audio/";
	DirAccess.make_dir_absolute(levelPath);
	DirAccess.make_dir_absolute(levelAssetPath);
	clone_data("user://Assets/", levelAssetPath);

## Export the current level
## tileSet: The tileSet
## playerData: All of the player's special information
## worldSize: Size of the world (x, y) for creating the csv file.
func export_level(tileSet: TileMapLayer, playerData: Panel, worldSize: Vector2) -> void:
	# Create JSON for enemies and player
	if !DirAccess.dir_exists_absolute(levelPath):
		DirAccess.make_dir_absolute(levelPath);
		
	# Enemy Data
	var data_to_send = '{"enemies": [';
	var enemyProperties = DirAccess.get_files_at("res://Resources/Enemies/");
	for enemyPropertyIndex in range(0, enemyProperties.size()):
		var enemyProperty = enemyProperties[enemyPropertyIndex];
		var propertyFile = load("res://Resources/Enemies/" + enemyProperty);
		data_to_send += '{"pos":{"x":' + str(propertyFile.position.x) + ',"y":' + str(propertyFile.position.y) + '},';
		if enemyProperty.contains("Patrol"):
			data_to_send += '"type":"patrolling", "stats":{';
			data_to_send += '"speed": ' + str(propertyFile.groundSpeed) + ", ";
			data_to_send += '"restricted": ' + str(propertyFile.restricted) + '}}';
		elif enemyProperty.contains("Shooting"):
			data_to_send += '"type":"shooting", "stats":{';
			data_to_send += '"direction": ' + str(propertyFile.direction) + ", ";
			data_to_send += '"shotSpeed": ' + str(propertyFile.shotSpeed) + ", ";
			data_to_send += '"fireRate": ' + str(propertyFile.fireRate) + '}}';
		if (enemyPropertyIndex < enemyProperties.size() - 1):
			data_to_send += ',';
	
	# Player Data
	data_to_send += '], "player": {';
	data_to_send += '"speed": ' + str(playerData.playerSpeed) + ", ";
	data_to_send += '"jump": ' + str(playerData.playerJumpHeight) + ", ";
	data_to_send += '"airControl": ' + str(playerData.playerAirControl) + ", ";
	data_to_send += '"fallSpeed": ' + str(playerData.playerFallSpeed) + ", ";
	data_to_send += '"coyoteTime": ' + str(playerData.playerCoyoteTime);
	data_to_send += '}}';
	
	var notJSON = FileAccess.open(levelPath + "Temp.txt", FileAccess.WRITE);
	notJSON.store_string(data_to_send);
	notJSON.close();
	
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
	
	clone_data("user://Assets/", levelAssetPath);

## Imports a level at the specified directory.
## tileMap: The Tile map layer to map the level terrain to
## playerData: The player's stats being imported
## directory: Source level directory
## returns: An int that depends on the state of the import
func import_level(tileMap: TileMapLayer, playerData: Panel, directory: String) -> int:
	levelPath = "user://Levels/" + directory + "/";
	levelAssetPath = levelPath + "Assets/"
	if !DirAccess.dir_exists_absolute(levelPath):
		PopUpManager.create_error_popup("Level Directory Doesn't Exist!", "The directory " + levelPath + " could not be found.");
		return 0;
	if !FileAccess.file_exists(levelPath + "Settings.JSON"):
		PopUpManager.create_error_popup("Level Properties Don't Exist!", "The directory " + levelPath + " does not have a file Settings.JSON.");
		return 0;
	if !FileAccess.file_exists(levelPath + "Tiles.CSV"):
		PopUpManager.create_error_popup("Level Tile Map Doesn't Exist!", "The directory " + levelPath + " does not have a file Tiles.CSV.");
		return 0;
	
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
				var entityTileData = tileData.split("|");
				if (int(entityTileData[0]) == Global.EntityType.PLAYER):
					playerExists = true;
				tileMap.set_cell(Vector2(col, row), int(entityTileData[0]), Vector2i.ZERO, int(entityTileData[1]));
				tileMap.update_internals()
			else:
				tileMap.set_cell(Vector2(col, row), int(tileData), Vector2i.ZERO);
			col += 1;
		row += 1;
	CSVFile.close();
	
	clone_data(levelAssetPath, "user://Assets/");
	levelImported.emit();
	
	# Int is based on state of the player in the imported level
	# 0: Import failed
	# 1: Import succeeded, but no player
	# 2: Import succeeded with player
	return int(playerExists) + 1;

## Import the JSON file
## tileMap: Tile map for searching for enemies
## playerData: The panel that contains player data to adjust it
func import_JSON(tileMap: TileMapLayer, playerData: Panel) -> void:
	# Read JSON to file and close it
	var JSONFile = FileAccess.open(levelPath + "Settings.JSON", FileAccess.READ);
	var json_as_dict = JSON.parse_string(JSONFile.get_as_text());
	
	# Player information read
	var player = json_as_dict.player;
	playerData.playerSpeed = player.speed;
	playerData.playerJumpHeight = player.jump;
	playerData.playerAirControl = player.airControl;
	playerData.playerFallSpeed  = player.fallSpeed;
	playerData.playerCoyoteTime = player.coyoteTime;
	playerData.update_custom();
	
	
	# Enemy information read
	var enemies = json_as_dict.enemies;
	for enemy in enemies:
		# Locate the enemy at the indicated position
		var locatedEnemy;
		for node in tileMap.get_children():
			if tileMap.local_to_map(node.global_position) == Vector2i(enemy.pos.x, enemy.pos.y):
				locatedEnemy = node;
		if locatedEnemy != null:
			match enemy.type:
				"patrolling":
					var defaultPatrolling: Resource = load("res://Resources/PlayerPresets/PatrollingDefault.tres");
					var newPatrolling: Resource = defaultPatrolling.duplicate(true);
					newPatrolling.groundSpeed = enemy.stats.speed;
					newPatrolling.restricted = enemy.stats.restricted;
					ResourceSaver.save(newPatrolling, "res://Resources/Enemies/Patrol-" + str(int(enemy.pos.x)) + str(int(enemy.pos.y)) + ".tres");
					locatedEnemy.assign_script("-" + str(int(enemy.pos.x)) + str(int(enemy.pos.y)), Vector2i(enemy.pos.x, enemy.pos.y));
				"shooting":
					var defaultShooting: Resource = load("res://Resources/PlayerPresets/ShootingDefault.tres");
					var newShooting: Resource = defaultShooting.duplicate(true);
					newShooting.direction = enemy.stats.direction;
					newShooting.shotSpeed = enemy.stats.shotSpeed;
					newShooting.fireRate = enemy.stats.fireRate;
					ResourceSaver.save(newShooting, "res://Resources/Enemies/Shooting-" + str(int(enemy.pos.x)) + str(int(enemy.pos.y)) + ".tres");
					locatedEnemy.assign_script("-" + str(int(enemy.pos.x)) + str(int(enemy.pos.y)), Vector2i(enemy.pos.x, enemy.pos.y));
	# If any enemy did not get data due to some form of corruption, it needs it.
	for node in tileMap.get_children():
		if node is EnemyPatrol:
			var nodePos = str(tileMap.local_to_map(node.global_position).x) + str(tileMap.local_to_map(node.global_position).y);
			var defaultPatrolling: Resource = load("res://Resources/PlayerPresets/PatrollingDefault.tres");
			var newPatrolling: Resource = defaultPatrolling.duplicate(true);
			ResourceSaver.save(newPatrolling, "res://Resources/Enemies/Patrol-" + nodePos + ".tres");
			node.assign_script("-" + nodePos, tileMap.local_to_map(node.global_position));
		if node is EnemyShooting:
			var nodePos = str(tileMap.local_to_map(node.global_position).x) + str(tileMap.local_to_map(node.global_position).y);
			var defaultShooting: Resource = load("res://Resources/PlayerPresets/ShootingDefault.tres");
			var newShooting: Resource = defaultShooting.duplicate(true);
			ResourceSaver.save(newShooting, "res://Resources/Enemies/Shooting-" + nodePos + ".tres");
			node.assign_script("-" + nodePos, tileMap.local_to_map(node.global_position));
	
	JSONFile.close();



## Clone all of the data from the user asset folder 
## from: the source directory
## to: the destination directory
## directory: The current directory being cloned
func clone_data(from: String, to: String, directory: String = ""):
	# Recursively loop through all folders
	var childDirectories: PackedStringArray = DirAccess.get_directories_at(from + directory);
	for currentDirectory in childDirectories:
		var newPath = directory + currentDirectory + "/";
		DirAccess.make_dir_absolute(to + newPath);
		clone_data(from, to, directory + currentDirectory + "/");
	
	# Copy all file data.
	# Erase all files in the destination folder if the source has nothing.
	var files: PackedStringArray = DirAccess.get_files_at(from + directory);
	if (files.size() <= 0):
		var destinationFiles: PackedStringArray = DirAccess.get_files_at(to + directory);
		for file in destinationFiles:
			DirAccess.remove_absolute(to + directory + file);
	else:
		for file in files:
			DirAccess.copy_absolute(from + directory + file, to + directory + file);
	
	#var file = FileAccess.open(levelPath + "/a.txt", FileAccess.WRITE);
	#file.store_string("TESTING");
	#file.close();

func clear_enemies_folder() -> void:
	var files = DirAccess.get_files_at("res://Resources/Enemies/");
	for file in files:
		DirAccess.remove_absolute("res://Resources/Enemies/" + file);
