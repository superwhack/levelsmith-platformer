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

# Stores size of an imported level
var importedLevelSize : Vector2;

# Default player stats for a new level
var playerDefault : Resource = preload("res://Resources/PlayerPresets/Default.tres");

## Create a new level, cloning from the default folder
## levelName: Name of the new level, indicates where it'll go in the folder
func make_new_level(levelName: String, levelSize: Vector2) -> void:
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
	
	# Generate default JSON file
	var defaultPlayerJSON : String = '{"enemies": [], "player": {';
	defaultPlayerJSON += '"health": ' + str(playerDefault.health) + ", ";
	defaultPlayerJSON += '"speed": ' + str(playerDefault.groundSpeed) + ", ";
	defaultPlayerJSON += '"jump": ' + str(playerDefault.jumpHeight) + ", ";
	defaultPlayerJSON += '"airControl": ' + str(playerDefault.airControl) + ", ";
	defaultPlayerJSON += '"fallSpeed": ' + str(playerDefault.fallSpeed) + ", ";
	defaultPlayerJSON += '"coyoteTime": ' + str(playerDefault.coyoteTime);
	defaultPlayerJSON += '}}';
	
	# Convert our data to a json_string
	var json : Variant = JSON.parse_string(defaultPlayerJSON)
	var jsonString : String = JSON.stringify(json);
	
	# Write JSON to file and close it
	var JSONFile : FileAccess = FileAccess.open(levelPath + "Settings.JSON", FileAccess.WRITE);
	JSONFile.store_string(jsonString);
	JSONFile.close();
	
	# Generate default CSV file with empty tiles
	var CSVFile : FileAccess = FileAccess.open(levelPath + "Tiles.CSV", FileAccess.WRITE);
	for row in levelSize.y:
		var tileRow : Array;
		for col in levelSize.x:
			tileRow.append("-1");
		CSVFile.store_csv_line(tileRow);
	CSVFile.close();
	
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
	var dataToSend : String = '{"enemies": [';
	var enemyProperties : PackedStringArray = DirAccess.get_files_at("res://Resources/Enemies/");
	for enemyPropertyIndex in range(0, enemyProperties.size()):
		var enemyProperty : String = enemyProperties[enemyPropertyIndex];
		var propertyFile : Resource = load("res://Resources/Enemies/" + enemyProperty);
		dataToSend += '{"pos":{"x":' + str(propertyFile.position.x) + ',"y":' + str(propertyFile.position.y) + '},';
		if enemyProperty.contains("Patrol"):
			dataToSend += '"type":"patrolling", "stats":{';
			dataToSend += '"speed": ' + str(propertyFile.groundSpeed) + ", ";
			dataToSend += '"direction": ' + str(propertyFile.direction) + ", ";
			dataToSend += '"restricted": ' + str(propertyFile.restricted) + '}}';
		elif enemyProperty.contains("Shooting"):
			dataToSend += '"type":"shooting", "stats":{';
			dataToSend += '"direction": ' + str(propertyFile.direction) + ", ";
			dataToSend += '"shotSpeed": ' + str(propertyFile.shotSpeed) + ", ";
			dataToSend += '"fireRate": ' + str(propertyFile.fireRate) + ', ';
			dataToSend += '"projBounce": ' + str(propertyFile.projBounce) + ', ';
			dataToSend += '"gravity": ' + str(propertyFile.gravity) + '}}';
		elif enemyProperty.contains("Flying"):
			dataToSend += '"type":"flying", "stats":{';
			dataToSend += '"speed": ' + str(propertyFile.speed) + ", ";
			dataToSend += '"endpoint":{"x":' + str(propertyFile.pointBOffset.x) + ',"y":' + str(propertyFile.pointBOffset.y) + '}}}';
		elif enemyProperty.contains("MovingPlatform"):
			dataToSend += '"type":"movingPlatform", "stats":{';
			dataToSend += '"speed": ' + str(propertyFile.speed) + ", ";
			dataToSend += '"endpoint":{"x":' + str(propertyFile.pointBOffset.x) + ',"y":' + str(propertyFile.pointBOffset.y) + '}, ';
			dataToSend += '"progress": ' + str(propertyFile.progress) + "}}";
		if (enemyPropertyIndex < enemyProperties.size() - 1):
			dataToSend += ',';
	# Creating Player Data in JSON.
	dataToSend += '], "player": {';
	dataToSend += '"health": ' + str(playerData.playerHealth) + ", ";
	dataToSend += '"speed": ' + str(playerData.playerSpeed) + ", ";
	dataToSend += '"jump": ' + str(playerData.playerJumpHeight) + ", ";
	dataToSend += '"airControl": ' + str(playerData.playerAirControl) + ", ";
	dataToSend += '"fallSpeed": ' + str(playerData.playerFallSpeed) + ", ";
	dataToSend += '"coyoteTime": ' + str(playerData.playerCoyoteTime) + ", ";
	dataToSend += '"doubleJump": ' + str(playerData.playerDoubleJump) + ", ";
	dataToSend += '"wallJump": ' + str(playerData.playerWallJump) + ", ";
	dataToSend += '"wallJumpDecay": ' + str(playerData.playerWallJumpDecay);
	dataToSend += '}}';
	
	# Convert our data to a json_string
	var json : Variant = JSON.parse_string(dataToSend)
	var jsonString : String = JSON.stringify(json);
	
	## NOTE: THIS IS TEMPORARY CODE TO TURN ON WHEN JSON FILE NEEDS TO BE VALIDATED
	#var tmpFile : FileAccess = FileAccess.open(levelPath + "Temp.txt", FileAccess.WRITE);
	#tmpFile.store_string(dataToSend);
	#tmpFile.close();
	
	# Write JSON to file and close it
	var JSONFile : FileAccess = FileAccess.open(levelPath + "Settings.JSON", FileAccess.WRITE);
	JSONFile.store_string(jsonString);
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
	levelPath = sourceName + "/";
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
	var col : int = 0;
	var playerExists : bool = false;
	var currentLine : PackedStringArray = CSVFile.get_csv_line();
	
	# While the end of the CSV has not been reached...
	while (!CSVFile.eof_reached()):
		col = 0;
		
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
	
	importedLevelSize = Vector2(col, row);
	await get_tree().process_frame;
	clone_data(levelAssetPath, "user://Assets/");
	
	return playerExists;

## Import the JSON file
## tileMap: Tile map for searching for enemies
## playerData: The panel that contains player data to adjust it
func import_JSON(tileMap: TileMapLayer, playerData: Panel) -> void:
	# Read JSON to file and close it
	var JSONFile : FileAccess= FileAccess.open(levelPath + "Settings.JSON", FileAccess.READ);
	var json_as_dict : Variant = JSON.parse_string(JSONFile.get_as_text());
	
	# Player information read
	var player = json_as_dict.player;
	playerData.playerHealth = player.health;
	playerData.playerSpeed = player.speed;
	playerData.playerJumpHeight = player.jump;
	playerData.playerAirControl = player.airControl;
	playerData.playerFallSpeed = player.fallSpeed;
	playerData.playerCoyoteTime = player.coyoteTime;
	playerData.playerDoubleJump = player.doubleJump;
	playerData.playerWallJump = player.wallJump;
	playerData.playerWallJumpDecay = player.wallJumpDecay;
	playerData.update_custom();
	playerData.update_sliders();
	
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
		"movingPlatform":
			newResource.speed = enemy.stats.speed;
			newResource.pointBOffset.x = enemy.stats.endpoint.x;
			newResource.pointBOffset.y = enemy.stats.endpoint.y;
			print(enemy.stats.progress);
			newResource.progress = enemy.stats.progress;
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
