extends Node

# Paths to the level and assets for the level
var levelPath : String;
var levelAssetPath : String;

# Path for default assets
const defaultPath : String = "res://Assets/Defaults/";

# A signal for when a level has been imported
signal levelImported;

## NOTE: TEMPORARY VARIABLE FOR STORING LEVEL'S NAME
var levelPathName : String;

## Create a new level, cloning from the default folder
## levelName: Name of the new level, indicates where it'll go in the folder
func make_new_level(levelName: String) -> void:
	# When making an enemy we need to set the path name and clear all enemies
	levelPathName = levelName;
	clear_enemies_folder();
	
	# Create a directory under User and set the level and asset path.
	DirAccess.make_dir_absolute("user://Levels/");
	levelPath = "user://Levels/" + levelName + "/";
	levelAssetPath = levelPath + "Assets/";
	
	# NOTE: In the future we might want to assign this elsewhere 
	AudioManager.audioLibraryPath = levelPath + "Assets/Audio/";
	
	# Create the directories for the level and asset path.
	DirAccess.make_dir_absolute(levelPath);
	DirAccess.make_dir_absolute(levelAssetPath);
	clone_data("user://Assets/", levelAssetPath);

## Export the current level
## tileMap: The tileMap
## playerData: All of the player's special information
## worldSize: Size of the world (x, y) for creating the csv file.
func export_level(tileMap: TileMapLayer, playerData: Panel, worldSize: Vector2) -> void:
	# Create JSON for enemies and player
	if (!DirAccess.dir_exists_absolute(levelPath)):
		DirAccess.make_dir_absolute(levelPath);
		
	# Creating Enemy Data in JSON.
	var data_to_send : String = '{"enemies": [';
	var enemyProperties : PackedStringArray = DirAccess.get_files_at("res://Resources/Enemies/");
	for enemyPropertyIndex in range(0, enemyProperties.size()):
		var enemyProperty : String = enemyProperties[enemyPropertyIndex];
		var propertyFile : Resource = load("res://Resources/Enemies/" + enemyProperty);
		data_to_send += '{"pos":{"x":' + str(propertyFile.position.x) + ',"y":' + str(propertyFile.position.y) + '},';
		if enemyProperty.contains("Patrol"):
			data_to_send += '"type":"patrolling", "stats":{';
			data_to_send += '"speed": ' + str(propertyFile.groundSpeed) + ", ";
			data_to_send += '"direction": ' + str(propertyFile.direction) + ", ";
			data_to_send += '"restricted": ' + str(propertyFile.restricted) + '}}';
		elif enemyProperty.contains("Shooting"):
			data_to_send += '"type":"shooting", "stats":{';
			data_to_send += '"direction": ' + str(propertyFile.direction) + ", ";
			data_to_send += '"shotSpeed": ' + str(propertyFile.shotSpeed) + ", ";
			data_to_send += '"fireRate": ' + str(propertyFile.fireRate) + ', ';
			data_to_send += '"projBounce": ' + str(propertyFile.projBounce) + ', ';
			data_to_send += '"gravity": ' + str(propertyFile.gravity) + '}}';
		elif enemyProperty.contains("Flying"):
			data_to_send += '"type":"flying", "stats":{';
			data_to_send += '"speed": ' + str(propertyFile.speed) + ", ";
			data_to_send += '"endpoint":{"x":' + str(propertyFile.pointBOffset.x) + ',"y":' + str(propertyFile.pointBOffset.y) + '}}}';
		if (enemyPropertyIndex < enemyProperties.size() - 1):
			data_to_send += ',';
	
	# Creating Player Data in JSON.
	data_to_send += '], "player": {';
	data_to_send += '"speed": ' + str(playerData.playerSpeed) + ", ";
	data_to_send += '"jump": ' + str(playerData.playerJumpHeight) + ", ";
	data_to_send += '"airControl": ' + str(playerData.playerAirControl) + ", ";
	data_to_send += '"fallSpeed": ' + str(playerData.playerFallSpeed) + ", ";
	data_to_send += '"coyoteTime": ' + str(playerData.playerCoyoteTime);
	data_to_send += '}}';
	
	# Convert our data to a json_string
	var json : Variant = JSON.parse_string(data_to_send)
	var json_string : String = JSON.stringify(json);
	
	# Write JSON to file and close it
	var JSONFile : FileAccess = FileAccess.open(levelPath + "Settings.JSON", FileAccess.WRITE);
	JSONFile.store_string(json_string);
	JSONFile.close();
	
	# Write tileData in the form of a CSV file, then close it
	var CSVFile : FileAccess = FileAccess.open(levelPath + "Tiles.CSV", FileAccess.WRITE);
	for currentRow in worldSize.y:
		var tileRow : Array;
		for currentCol in worldSize.x:
			# If there's a rotation, include it
			if (tileMap.get_cell_alternative_tile(Vector2(currentCol, currentRow)) > 0):
				tileRow.append(str(tileMap.get_cell_source_id(Vector2(currentCol, currentRow)),"|",tileMap.get_cell_alternative_tile(Vector2(currentCol, currentRow))));
			else:
				tileRow.append(tileMap.get_cell_source_id(Vector2(currentCol, currentRow)));
		CSVFile.store_csv_line(tileRow);
	CSVFile.close();
	
	clone_data("user://Assets/", levelAssetPath);

## Validates a level import at a given directory
## sourceName: Source level name
## returns: false if it fails, true otherwise
func validate_import(sourceName: String) -> bool:
	levelPath = "user://Levels/" + sourceName + "/";
	levelAssetPath = levelPath + "Assets/"
	var errors : Array[String];
	
	if (!DirAccess.dir_exists_absolute(levelPath)):
		errors.append("Directory " + levelPath + " does not exist!");
		
	if (!FileAccess.file_exists(levelPath + "Settings.JSON")):
		errors.append(levelPath + "Settings.JSON does not exist!");
		
	if (!FileAccess.file_exists(levelPath + "Tiles.CSV")):
		errors.append(levelPath + "Tiles.CSV does not exist!");
		
	if (errors.size() == 0):
		return true;
		
	# If import fails, send a pop-up to the user.
	PopUpManager.create_multi_error_popup("Level Import Failed from directory " + levelPath + "!", errors);
	return false;

## Imports a level at the specified directory.
## tileMap: The Tile map layer to map the level terrain to
## returns: if the player exists, true if they do
func import_level_CSV(tileMap: TileMapLayer) -> bool:
	# Read tileData in the form of a CSV file
	var CSVFile : FileAccess = FileAccess.open(levelPath + "Tiles.CSV", FileAccess.READ);
	var row : int = 0;
	var playerExists : bool = false;
	var currentLine : PackedStringArray = CSVFile.get_csv_line();
	
	# While the end of the CSV has not been reached...
	while (!CSVFile.eof_reached()):

		var col : int = 0;

		# For every tile in the current line, determine if it is a player,
		# or place it in the tileMap.
		for tileData in currentLine:
			# Rotated tiles
			if (tileData.contains("|")):
				var entityTileData : PackedStringArray = tileData.split("|");
				if ((int(entityTileData[0]) == Global.EntityType.PLAYER)):
					playerExists = true;
				tileMap.set_cell(Vector2(col, row), int(entityTileData[0]), Vector2i.ZERO, int(entityTileData[1]));
			else:
				tileMap.set_cell(Vector2(col, row), int(tileData), Vector2i.ZERO);
			col += 1;
		row += 1;
		currentLine = CSVFile.get_csv_line();
	CSVFile.close();
	
	await get_tree().process_frame;
	clone_data(levelAssetPath, "user://Assets/");
	levelImported.emit();

	return playerExists;

## Import the JSON file
## tileMap: Tile map for searching for enemies
## playerData: The panel that contains player data to adjust it
func import_JSON(tileMap: TileMapLayer, playerData: Panel) -> void:
	# Read JSON to file and close it
	var JSONFile  : FileAccess= FileAccess.open(levelPath + "Settings.JSON", FileAccess.READ);
	var json_as_dict : Variant = JSON.parse_string(JSONFile.get_as_text());
	
	# Player information read
	var player : Variant = json_as_dict.player;
	playerData.playerSpeed = player.speed;
	playerData.playerJumpHeight = player.jump;
	playerData.playerAirControl = player.airControl;
	playerData.playerFallSpeed = player.fallSpeed;
	playerData.playerCoyoteTime = player.coyoteTime;
	playerData.update_custom();
	
	
	# Enemy information read
	var enemies : Array = json_as_dict.enemies;
	for enemy in enemies:
		# Locate the enemy at the indicated position
		var locatedEnemy : Node2D;
		for node in tileMap.get_children():
			if (tileMap.local_to_map(node.global_position) == Vector2i(enemy.pos.x, enemy.pos.y)):
				locatedEnemy = node;
		if (locatedEnemy != null):
			match_enemy_type(enemy, locatedEnemy);
	
	# If any enemy did not get data due to some form of corruption, it needs it.
	repair_corrupted_enemies(tileMap);
	
	JSONFile.close();



## Clone all of the data from the user asset folder 
## from: the source directory
## to: the destination directory
## directory: The current directory being cloned
func clone_data(from: String, to: String, directory: String = ""):
	# Recursively loop through all folders and clone data to destination directory
	var childDirectories : PackedStringArray = DirAccess.get_directories_at(from + directory);
	for currentDirectory in childDirectories:
		var newPath : String = directory + currentDirectory + "/";
		DirAccess.make_dir_absolute(to + newPath);
		clone_data(from, to, directory + currentDirectory + "/");
	
	# Copy all file data.
	# Erase all files in the destination folder if the source has nothing.
	var files : PackedStringArray = DirAccess.get_files_at(from + directory);
	if (files.size() <= 0):
		var destinationFiles : PackedStringArray = DirAccess.get_files_at(to + directory);
		for file in destinationFiles:
			DirAccess.remove_absolute(to + directory + file);
	else:
		for file in files:
			DirAccess.copy_absolute(from + directory + file, to + directory + file);
	
	#var file = FileAccess.open(levelPath + "/a.txt", FileAccess.WRITE);
	#file.store_string("TESTING");
	#file.close();

## Gets files in the enemies folder and delete every single file.
func clear_enemies_folder() -> void:
	var files : PackedStringArray = DirAccess.get_files_at("res://Resources/Enemies/");
	for file in files:
		DirAccess.remove_absolute("res://Resources/Enemies/" + file);
		
## Matches the enemy type with the correct data, used when importing data
## type: The type of enemy, stored as an Enum.
func match_enemy_type(enemy: Dictionary, locatedEnemy: Node2D) -> void:
	var capitalType : String = enemy.type[0].to_upper() + enemy.type.substr(1);
	var defaultResource : Resource = load("res://Resources/PlayerPresets/" + capitalType + "Default.tres");
	var newResource : Resource = defaultResource.duplicate(true);
	
	match enemy.type:
		"patrolling":
			newResource.groundSpeed = enemy.stats.speed;
			newResource.direction = enemy.stats.direction;
			newResource.restricted = enemy.stats.restricted;
		"shooting":
			newResource.direction = enemy.stats.direction;
			newResource.shotSpeed = enemy.stats.shotSpeed;
			newResource.fireRate = enemy.stats.fireRate;
			newResource.projBounce = enemy.stats.projBounce;
			newResource.gravity = enemy.stats.gravity;
		"flying":
			newResource.speed = enemy.stats.speed;
			newResource.pointBOffset.x = enemy.stats.endpoint.x;
			newResource.pointBOffset.y = enemy.stats.endpoint.y;
	ResourceSaver.save(newResource, "res://Resources/Enemies/" + capitalType + "-" + str(int(enemy.pos.x)) + str(int(enemy.pos.y)) + ".tres");
	locatedEnemy.assign_script("-" + str(int(enemy.pos.x)) + str(int(enemy.pos.y)), Vector2i(enemy.pos.x, enemy.pos.y));
			
## If any enemy data is corrupted, we can repair it by giving it default values.
func repair_corrupted_enemies(tileMap: TileMapLayer) -> void:
	for node in tileMap.get_children():
		if node is EnemyPatrol && node.propertyFile == null:
			var nodePos : String = str(tileMap.local_to_map(node.global_position).x) + str(tileMap.local_to_map(node.global_position).y);
			var defaultPatrolling : Resource = load("res://Resources/PlayerPresets/PatrollingDefault.tres");
			var newPatrolling : Resource = defaultPatrolling.duplicate(true);
			ResourceSaver.save(newPatrolling, "res://Resources/Enemies/Patrolling-" + nodePos + ".tres");
			node.assign_script("-" + nodePos, tileMap.local_to_map(node.global_position));
		elif node is EnemyShooting && node.propertyFile == null:
			var nodePos : String = str(tileMap.local_to_map(node.global_position).x) + str(tileMap.local_to_map(node.global_position).y);
			var defaultShooting : Resource = load("res://Resources/PlayerPresets/ShootingDefault.tres");
			var newShooting : Resource = defaultShooting.duplicate(true);
			ResourceSaver.save(newShooting, "res://Resources/Enemies/Shooting-" + nodePos + ".tres");
			node.assign_script("-" + nodePos, tileMap.local_to_map(node.global_position));
		elif node is EnemyFlyer && node.propertyFile == null:
			var nodePos : String = str(tileMap.local_to_map(node.global_position).x) + str(tileMap.local_to_map(node.global_position).y);
			var defaultFlying : Resource = load("res://Resources/PlayerPresets/FlyingDefault.tres");
			var newFlying : Resource = defaultFlying.duplicate(true);
			ResourceSaver.save(newFlying, "res://Resources/Enemies/Flying-" + nodePos + ".tres");
			node.assign_script("-" + nodePos, tileMap.local_to_map(node.global_position));
