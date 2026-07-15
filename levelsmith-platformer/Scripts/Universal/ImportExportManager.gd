extends Node

# Path for default assets. Unused.
const DEFAULT_PATH : String = "res://Assets/Defaults/";

# Paths to the level and assets for the level
var levelPath : String;
var levelAssetPath : String;

# A signal for when a level has been imported
signal levelImported;

## NOTE: TEMPORARY VARIABLE FOR STORING LEVEL'S NAME
var levelName : String;

# Stores size of an imported level
var importedLevelSize : Vector2i;

# Default player stats for a new level
var playerDefault : Resource = preload("res://Resources/PlayerPresets/Default.tres");

## Create a new level, cloning from the default folder
## levelName: Name of the new level, indicates where it'll go in the folder
## levelSize: The size of the level
## settings: The settings menu for the level
func make_new_level(levelName: String,  levelAuthor: String, levelSize: Vector2i, settings: Panel) -> void:
	# When making an enemy we need to set the path name and clear all enemies
	levelName = levelName;
	clear_enemies_folder();
	
	# Create a directory under User and set the level and asset path.
	DirAccess.make_dir_absolute("user://Levels/");
	levelPath = "user://Levels/" + levelName + "/";
	levelAssetPath = levelPath + "Assets/";
	# NOTE: In the future we might want to assign this elsewhere 
	#AudioManager.audioLibraryPath = levelPath + "Assets/Audio/";
	
	# Create the directories for the level and asset path.
	DirAccess.make_dir_absolute(levelPath);
	DirAccess.make_dir_absolute(levelAssetPath);
	
	# The current date and time from system. 
	var now : Dictionary = Time.get_datetime_dict_from_system()
	var meridiem : String = "AM";
	if (now.hour >= 12):
		meridiem = "PM";
		
	# So that time cannot equal 0:15 AM
	now.hour %= 12;
	if (now.hour == 0):
		now.hour = 12;
	
	# Generate default JSON file as a dictionary.
	var defaultJSON : Dictionary = {
		"metadata": {
			"author": levelAuthor,
			"dateCreated": "%02d.%02d.%04d" % [now.month, now.day, now.year],
			"timeCreated": "%02d:%02d" % [now.hour, now.minute] + " " + meridiem,
			"dateModified": "%02d.%02d.%04d" % [now.month, now.day, now.year],
			"timeModified": "%02d:%02d" % [now.hour, now.minute] + " " + meridiem,
			"dimensions": levelSize,
			"objects": 0,
			"version": Global.VERSION,
			"favorited": false,
			"validated": false
		},
		"enemies": [],
		"player": {
			"health": playerDefault.health,
			"speed": playerDefault.groundSpeed,
			"jump": playerDefault.jumpHeight,
			"airControl": playerDefault.airControl,
			"fallSpeed": playerDefault.fallSpeed,
			"coyoteTime": playerDefault.coyoteTime,
			"slopeSlowdown": playerDefault.slopeSlowdown,
			"oneways": playerDefault.oneways,
			"doubleJump": playerDefault.doubleJump,
			"wallJump": playerDefault.wallJump,
			"wallJumpDecay": playerDefault.wallJumpDecay
		},
		"settings": {
			"playZoom": 100.0,
			"followSpeed": 100.0,
			"deadzone": 0.0,
			"cameraPlayClamp": false
		},
		"animations": {
			"PlayerDeath": 8.0,
			"PlayerFall": 8.0,
			"PlayerHurt": 8.0,
			"PlayerIdle": 8.0,
			"PlayerJump": 8.0,
			"PlayerRun": 8.0,
			"StationaryDeath": 8.0,
			"StationaryIdle": 8.0,
			"EnemyShoot": 8.0,
			"ShootDeath": 8.0,
			"ShootIdle": 8.0,
			"PatrolDeath": 8.0,
			"PatrolWalk": 8.0,
			"FlyDeath": 8.0,
			"FlyMove": 8.0,
			"PlatformAnimation": 8.0,
			"GoalAnimation": 8.0,
			"CoinAnimation": 8.0
		}
	};
	
	# Convert our data to a json_string
	var jsonString : String = JSON.stringify(defaultJSON, "\t")
	
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
	
	#clone_data("user://Assets/", levelAssetPath);

## Export the current level
## tileMap: The tileMap
## playerData: All of the player's special information
## worldSize: Size of the world (x, y) for creating the csv file.
## settings: The settings menu to export the configurations from
func export_level(tileMap: TileMapLayer, playerData: Panel, worldSize: Vector2i, settings: Panel, isValidated : bool = false) -> void:
	PopUpManager.create_save_popup();
	# Create JSON for enemies and player
	if (!DirAccess.dir_exists_absolute(levelPath)):
		DirAccess.make_dir_absolute(levelPath);
		
	# First, get the meta data so we don't delete permanent data.
	var json : Dictionary = { };

	# If the Settings file exists, get entire file as text
	if (FileAccess.file_exists(levelPath + "Settings.JSON")):
		var jsonFile : FileAccess = FileAccess.open(levelPath + "Settings.JSON", FileAccess.READ);
		json = JSON.parse_string(jsonFile.get_as_text());
		jsonFile.close();
	
	##                        ##
	## Metadata JSON Creation ##
	##                        ##
	# If no meta data, add the meta data section. For backwards compat
	if !json.has("metadata"):
		json["metadata"] = {};

	var metadata : Dictionary = json["metadata"];

	var now : Dictionary = Time.get_datetime_dict_from_system();
	var meridiem : String = "AM";
	
	if (now.hour >= 12):
		meridiem = "PM";
		
	# So that time cannot equal 0:15 AM
	now.hour %= 12;
	if (now.hour == 0):
		now.hour = 12;
		
	var objects : int = get_object_count(tileMap, worldSize);

	# Update metadata without completely overwriting it.
	# If date created is missing, fill it in with the now
	if !metadata.has("dateCreated"):
		metadata["dateCreated"] = "%02d.%02d.%04d" % [now.month, now.day, now.year];

	if !metadata.has("timeCreated"):
		metadata["timeCreated"] = "%02d:%02d" % [now.hour, now.minute] + " " + meridiem;
		
	metadata["dateModified"] = "%02d.%02d.%04d" % [now.month, now.day, now.year];
	metadata["timeModified"] = "%02d:%02d" % [now.hour, now.minute] + " " + meridiem;
	metadata["dimensions"] = worldSize;
	metadata["version"] = Global.VERSION;
	metadata["objects"] = objects;
	metadata["validated"] = isValidated;

	json["metadata"] = metadata;
	
	##                      ##
	## Player JSON Creation ##
	##                      ##
	json["player"] = {
		"health": playerData.playerHealth,
		"speed": playerData.playerSpeed,
		"acceleration": playerData.playerAcceleration,
		"deceleration": playerData.playerDeceleration,
		"jump": playerData.playerJumpHeight,
		"airControl": playerData.playerAirControl,
		"fallSpeed": playerData.playerGravity,
		"coyoteTime": playerData.playerCoyoteTime,
		"slopeSlowdown": playerData.playerSlopeSlowdown,
		"oneways": playerData.playerOneways,
		"doubleJump": playerData.playerDoubleJump,
		"wallJump": playerData.playerWallJump,
		"wallJumpDecay": playerData.playerWallJumpDecay
	};

	##                        ##
	## Settings JSON Creation ##
	##                        ##
	json["settings"] = {
		"playZoom": settings.gameplayZoom.value,
		"followSpeed": settings.followSpeed.value,
		"deadzone": settings.cameraDeadzone.value,
		"cameraPlayClamp": settings.cameraClamp.value
	};
	
	##                     ##
	## Enemy JSON Creation ##
	##                     ##
	var enemies : Array = [];
	var enemyProperties : PackedStringArray = DirAccess.get_files_at("user://Resources/Enemies/");

	for enemyProperty in enemyProperties:
		var propertyFile : Resource = load("user://Resources/Enemies/" + enemyProperty);
		
		# Shared enemy properties, like the position.
		var enemy : Dictionary = {
			"pos": {
				"x": propertyFile.position.x,
				"y": propertyFile.position.y
			}
		};
		
		if (enemyProperty.contains("Patrol")):
			enemy["type"] = "patrolling"
			enemy["stats"] = {
				"speed": propertyFile.groundSpeed,
				"direction": propertyFile.direction,
				"restricted": propertyFile.restricted
			};
		elif (enemyProperty.contains("Shooting")):
			enemy["type"] = "shooting"
			enemy["stats"] = {
				"direction": propertyFile.direction,
				"randomDirection": propertyFile.randomDirection,
				"shotSpeed": propertyFile.shotSpeed,
				"fireRate": propertyFile.fireRate,
				"projBounce": propertyFile.projBounce,
				"gravity": propertyFile.gravity
			};
		elif (enemyProperty.contains("Flying")):
			enemy["type"] = "flying"
			enemy["stats"] = {
				"speed": propertyFile.speed,
				"endpoint": {
					"x": propertyFile.pointBOffset.x,
					"y": propertyFile.pointBOffset.y
				}
			};
		elif (enemyProperty.contains("Stationary")):
			enemy["type"] = "stationary"
			enemy["stats"] = {
				"isFacingRight": propertyFile.isFacingRight,
				"gravity": propertyFile.gravity
			};
		elif (enemyProperty.contains("MovingPlatform")):
			enemy["type"] = "movingPlatform"
			enemy["stats"] = {
				"speed": propertyFile.speed,
				"endpoint": {
					"x": propertyFile.pointBOffset.x,
					"y": propertyFile.pointBOffset.y
				},
				"progress": propertyFile.progress,
				"easing": propertyFile.easing
			};
		
		# If enemy has a type, append it. Otherwise, we have no compatibility for the enemy.
		if (enemy.has("type")):
			enemies.append(enemy);

	json["enemies"] = enemies;
	
	json["animations"] = {
		"PlayerDeath": AnimationManager.get_animation_fps("PlayerDeath"),
		"PlayerFall": AnimationManager.get_animation_fps("PlayerFall"),
		"PlayerHurt": AnimationManager.get_animation_fps("PlayerHurt"),
		"PlayerIdle": AnimationManager.get_animation_fps("PlayerIdle"),
		"PlayerJump": AnimationManager.get_animation_fps("PlayerJump"),
		"PlayerRun": AnimationManager.get_animation_fps("PlayerRun"),
		"StationaryDeath": AnimationManager.get_animation_fps("StationaryDeath"),
		"StationaryIdle": AnimationManager.get_animation_fps("StationaryIdle"),
		"EnemyShoot": AnimationManager.get_animation_fps("EnemyShoot"),
		"ShootDeath": AnimationManager.get_animation_fps("ShootDeath"),
		"ShootIdle": AnimationManager.get_animation_fps("ShootIdle"),
		"PatrolDeath": AnimationManager.get_animation_fps("PatrolDeath"),
		"PatrolWalk": AnimationManager.get_animation_fps("PatrolWalk"),
		"FlyDeath": AnimationManager.get_animation_fps("FlyDeath"),
		"FlyMove": AnimationManager.get_animation_fps("FlyMove"),
		"PlatformAnimation": AnimationManager.get_animation_fps("PlatformAnimation"),
		"GoalAnimation": AnimationManager.get_animation_fps("GoalAnimation"),
		"CoinAnimation": AnimationManager.get_animation_fps("CoinAnimation")
	}
	
	
	## NOTE: THIS IS TEMPORARY CODE TO TURN ON WHEN JSON FILE NEEDS TO BE VALIDATED
	#var tmpFile : FileAccess = FileAccess.open(levelPath + "Temp.txt", FileAccess.WRITE);
	#tmpFile.store_string(dataToSend);
	#tmpFile.close();
	
	# Write JSON to file and close it
	var jsonFile : FileAccess = FileAccess.open(levelPath + "Settings.JSON", FileAccess.WRITE)
	jsonFile.store_string(JSON.stringify(json, "\t"))
	jsonFile.close()
	
	# Write tileData in the form of a CSV file, then close it
	var CSVFile : FileAccess = FileAccess.open(levelPath + "Tiles.CSV", FileAccess.WRITE);
	for currentRow in worldSize.y:
		var tileRow : Array;
		for currentCol in worldSize.x:
			# If there's a rotation, include it
			if (tileMap.get_cell_alternative_tile(Vector2(currentCol, currentRow)) > 0):
				tileRow.append(str(tileMap.get_cell_source_id(Vector2(currentCol, currentRow)),"|",tileMap.get_cell_alternative_tile(Vector2(currentCol, currentRow))));
			else:
				if tileMap.get_cell_source_id(Vector2(currentCol, currentRow)) == -1:
					tileRow.append("");
				else:
					tileRow.append(tileMap.get_cell_source_id(Vector2(currentCol, currentRow)));
		CSVFile.store_csv_line(tileRow);
	CSVFile.close();
	
	#clone_data("user://Assets/", levelAssetPath);
	
	await get_tree().create_timer(0.2).timeout;
	PopUpManager.clear_all_popups();
	PopUpManager.create_save_complete_popup();
	await get_tree().create_timer(0.65).timeout;
	PopUpManager.clear_all_popups();

## Saves the level screenshot to an image file
## screenshotImage: The image to save.
func save_level_screenshot(screenshotImage: Image) -> void:
	screenshotImage.save_png(levelPath + "Preview.PNG");

## Validates a level import at a given directory
## sourceName: Source level name
## returns: false if it fails, true otherwise
func validate_import(sourceName: String) -> bool:
	levelPath = sourceName;
	levelAssetPath = levelPath + "Assets/"
	var errors : Array[String];
	
	if (!DirAccess.dir_exists_absolute(levelPath)):
		errors.append("Directory " + levelPath + " does not exist!");
		
	if (!FileAccess.file_exists(levelPath + "Settings.JSON")):
		errors.append(levelPath + "Settings.JSON does not exist!");
		
	if (!FileAccess.file_exists(levelPath + "Tiles.CSV")):
		errors.append(levelPath + "Tiles.CSV does not exist!");
	if (errors.size() == 0):
		sourceName = sourceName.left(-1);
		levelName = sourceName.substr(sourceName.rfind("/") + 1);
		return true;
		
	# If import fails, send a pop-up to the user.
	#PopUpManager.create_multi_error_popup("Level Import Failed from directory " + levelPath + "!", errors);
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
				if tileData == "":
					tileData = "-1";
				tileMap.set_cell(Vector2(col, row), int(tileData), Vector2i.ZERO);
			col += 1;
		row += 1;
		currentLine = CSVFile.get_csv_line();
	CSVFile.close();
	
	importedLevelSize = Vector2(col, row);
	await get_tree().process_frame;
	#clone_data(levelAssetPath, "user://Assets/");
	
	return playerExists;

## Import the JSON file
## tileMap: Tile map for searching for enemies
## playerData: The panel that contains player data to adjust it
## settings: Settings to import saved configurations to
func import_JSON(tileMap: TileMapLayer, playerData: Panel, settings: Panel) -> void:
	# Read JSON to file and close it
	var JSONFile : FileAccess= FileAccess.open(levelPath + "Settings.JSON", FileAccess.READ);
	var json_as_dict : Variant = JSON.parse_string(JSONFile.get_as_text());
	
	# Player information read
	var player = json_as_dict.get("player", {});
	playerData.playerHealth = player.get("health", playerData.playerHealth);
	playerData.playerSpeed = player.get("speed", playerData.playerSpeed);
	playerData.playerAcceleration = player.get("acceleration", playerData.playerAcceleration);
	playerData.playerDeceleration = player.get("deceleration", playerData.playerDeceleration);
	playerData.playerJumpHeight = player.get("jump", playerData.playerJumpHeight);
	playerData.playerAirControl = player.get("airControl", playerData.playerAirControl);
	playerData.playerGravity = player.get("fallSpeed", playerData.playerGravity);
	playerData.playerCoyoteTime = player.get("coyoteTime", playerData.playerCoyoteTime);
	playerData.playerSlopeSlowdown = player.get("slopeSlowdown", playerData.playerSlopeSlowdown);
	playerData.playerOneways = player.get("oneways", playerData.playerOneways);
	playerData.playerDoubleJump = player.get("doubleJump", playerData.playerDoubleJump);
	playerData.playerWallJump = player.get("wallJump", playerData.playerWallJump);
	playerData.playerWallJumpDecay = player.get("wallJumpDecay", playerData.playerWallJumpDecay);
	playerData.update_custom();
	playerData.update_sliders();

	# Settings information read
	var settingsConfig = json_as_dict.get("settings", {});
	settings.gameplayZoom.value = settingsConfig.get("playZoom", settings.gameplayZoom.value);
	settings.followSpeed.value = settingsConfig.get("followSpeed", settings.followSpeed.value);
	settings.cameraDeadzone.value = settingsConfig.get("deadzone", settings.cameraDeadzone.value);
	settings.cameraClamp.value = settingsConfig.get("cameraPlayClamp", settings.cameraClamp.value);
	settings.update_sliders();
	
	AnimationManager.set_all_fps_to_json(levelPath + "Settings.JSON");

	# Enemy information read, no enemies if from older version
	var enemies : Array = json_as_dict.get("enemies", []);
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
	
## Reads the metadata section from the Settings JSON
## levelPath: The given path to the level directory.
## Returns either a full or empty dictionary.
func get_metadata(levelPath : String) -> Dictionary:
	# If no settings JSON, return empty
	if (!FileAccess.file_exists(levelPath + "/Settings.JSON")):
		return { };
	
	var jsonFile : FileAccess = FileAccess.open(levelPath + "/Settings.JSON", FileAccess.READ);
	var jsonDict : Dictionary = JSON.parse_string(jsonFile.get_as_text());
	jsonFile.close();
	# Return metadata
	return jsonDict.get("metadata", {});


## Sets a specific metadata value.
## levelPath: The given path to the level directory.
## key: The name of the metadata value to be changed.
## value: The new value of the metadata being changed.
func set_metadata(levelPath: String, key: String, value: Variant) -> void:
	if (!FileAccess.file_exists(levelPath + "/Settings.JSON")):
		return;
		
	# Read file
	var file : FileAccess = FileAccess.open(levelPath + "/Settings.JSON", FileAccess.READ);
	var json : Dictionary = JSON.parse_string(file.get_as_text());
	file.close();

	# Not all files have metadata, so lets check first
	if !json.has("metadata"):
		json["metadata"] = {};

	# Change the given key to the value in the metadata.
	json["metadata"][key] = value;

	# Write it to the file and close again.
	file = FileAccess.open(levelPath + "/Settings.JSON", FileAccess.WRITE);
	file.store_string(JSON.stringify(json, "\t"));
	file.close();

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
	var files : PackedStringArray = DirAccess.get_files_at("user://Resources/Enemies/");
	
	for file in files:
		DirAccess.remove_absolute("user://Resources/Enemies/" + file);

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
			newResource.randomDirection = enemy.stats.randomDirection;
			newResource.shotSpeed = enemy.stats.shotSpeed;
			newResource.fireRate = enemy.stats.fireRate;
			newResource.projBounce = enemy.stats.projBounce;
			newResource.gravity = enemy.stats.gravity;
		"flying":
			newResource.speed = enemy.stats.speed;
			newResource.pointBOffset.x = enemy.stats.endpoint.x;
			newResource.pointBOffset.y = enemy.stats.endpoint.y;
		"stationary":
			newResource.isFacingRight = enemy.stats.isFacingRight;
			newResource.gravity = enemy.stats.gravity;
		"movingPlatform":
			newResource.speed = enemy.stats.speed;
			newResource.pointBOffset.x = enemy.stats.endpoint.x;
			newResource.pointBOffset.y = enemy.stats.endpoint.y;
			newResource.progress = enemy.stats.progress;
			newResource.easing = enemy.stats.easing;
	ResourceSaver.save(newResource, "user://Resources/Enemies/" + capitalType + "-" + str(int(enemy.pos.x)) + str(int(enemy.pos.y)) + ".tres");
	locatedEnemy.assign_script("-" + str(int(enemy.pos.x)) + str(int(enemy.pos.y)), Vector2i(enemy.pos.x, enemy.pos.y));
	if locatedEnemy is EnemyStationary: locatedEnemy.update_flipped();


## If any enemy data is corrupted, we can repair it by giving it default values.
## tileMap: the main tile map layer.
func repair_corrupted_enemies(tileMap: TileMapLayer) -> void:
	for node in tileMap.get_children():
		if node is EnemyPatrol && node.propertyFile == null:
			var nodePos : String = str(tileMap.local_to_map(node.global_position).x) + str(tileMap.local_to_map(node.global_position).y);
			var defaultPatrolling : Resource = load("res://Resources/PlayerPresets/PatrollingDefault.tres");
			var newPatrolling : Resource = defaultPatrolling.duplicate(true);
			ResourceSaver.save(newPatrolling, "user://Resources/Enemies/Patrolling-" + nodePos + ".tres");
			node.assign_script("-" + nodePos, tileMap.local_to_map(node.global_position));
		elif node is EnemyShooting && node.propertyFile == null:
			var nodePos : String = str(tileMap.local_to_map(node.global_position).x) + str(tileMap.local_to_map(node.global_position).y);
			var defaultShooting : Resource = load("res://Resources/PlayerPresets/ShootingDefault.tres");
			var newShooting : Resource = defaultShooting.duplicate(true);
			ResourceSaver.save(newShooting, "user://Resources/Enemies/Shooting-" + nodePos + ".tres");
			node.assign_script("-" + nodePos, tileMap.local_to_map(node.global_position));
		elif node is EnemyFlyer && node.propertyFile == null:
			var nodePos : String = str(tileMap.local_to_map(node.global_position).x) + str(tileMap.local_to_map(node.global_position).y);
			var defaultFlying : Resource = load("res://Resources/PlayerPresets/FlyingDefault.tres");
			var newFlying : Resource = defaultFlying.duplicate(true);
			ResourceSaver.save(newFlying, "user://Resources/Enemies/Flying-" + nodePos + ".tres");
			node.assign_script("-" + nodePos, tileMap.local_to_map(node.global_position));
		elif node is EnemyStationary && node.propertyFile == null:
			var nodePos : String = str(tileMap.local_to_map(node.global_position).x) + str(tileMap.local_to_map(node.global_position).y);
			var defaultStationary : Resource = load("res://Resources/PlayerPresets/StationaryDefault.tres");
			var newStationary : Resource = defaultStationary.duplicate(true);
			ResourceSaver.save(newStationary, "user://Resources/Enemies/Stationary-" + nodePos + ".tres");
			node.assign_script("-" + nodePos, tileMap.local_to_map(node.global_position));
			
## Gets the object count of the given tile map and worldsize.
## tileMap: the main tile map layer.
## worldSize: the world size.
## Returns the amount of tiles that are not empty and not ignored IDs.
func get_object_count(tileMap: TileMapLayer, worldSize : Vector2i) -> int:
	var count : int = 0;

	for y in worldSize.y:
		for x in worldSize.x:
			var tileId : int = tileMap.get_cell_source_id(Vector2i(x, y));

			if (tileId != Global.EMPTY_TILE && tileId < Global.BEDROCK_CORNER):
				count += 1;

	return count;
