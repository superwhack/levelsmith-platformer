extends Node

# References to all sprites in the level, references to template sprites
var playerSprites : Array[AnimatedSprite2D];
var playerTemplateSprite : AnimatedSprite2D;

var patrollingEnemySprites : Array[AnimatedSprite2D];
var patrollingEnemyTemplateSprite : AnimatedSprite2D;

var flyingEnemySprites : Array[AnimatedSprite2D];
var flyingEnemyTemplateSprite : AnimatedSprite2D;

var shootingEnemySprites : Array[AnimatedSprite2D];
var shootingEnemyTemplateSprite : AnimatedSprite2D;

var stationaryEnemySprites : Array[AnimatedSprite2D];
var stationaryEnemyTemplateSprite : AnimatedSprite2D;

var goalSprites : Array[AnimatedSprite2D];
var goalTemplateSprite : AnimatedSprite2D;

var coinSprites : Array[AnimatedSprite2D];
var coinTemplateSprite : AnimatedSprite2D;

var movingPlatformSprites : Array[AnimatedSprite2D];
var movingPlatformPreviewSprites : Array[Sprite2D];
var movingPlatformTemplateSprite : AnimatedSprite2D;

var checkpointSprites : Array[AnimatedSprite2D];
var checkpointTemplateSprite : AnimatedSprite2D;


# Path for default animations
var defaultAnimationsRootPath : String = "res://Assets/Sprites/Entities/";

# Array of all animated sprites within the project
@onready var allAnimatedSprites: Array[Array] = [
playerSprites, 
patrollingEnemySprites, 
flyingEnemySprites, 
shootingEnemySprites, 
stationaryEnemySprites,
goalSprites,
coinSprites,
movingPlatformSprites,
checkpointSprites];

# Reference to the asset manager
var assetManager : AssetManager;

## Create all the template sprites when the project starts
func _ready() -> void:
	create_template_sprites();

## Replace an animation with new frames
## animatedSprite : The animated sprite having its animation replaced
## animationName : The name of the specific animation within the sprite being replaced
## frames : An array of images that is replacing the current animation
func replace_animation(animatedSprite : AnimatedSprite2D, animationName : String, frames : Array[Image]) -> void:
	var spriteFrames : SpriteFrames = animatedSprite.sprite_frames;
	# Clear the frames within the animation
	spriteFrames.clear(animationName);
	# Add each frame to the animation
	for frame in frames:
		spriteFrames.add_frame(animationName, ImageTexture.create_from_image(frame));

## Replaces the animation to whatever animation has already been loaded. Replaces with default if none are loaded
## animatedSprite : The sprite having its animation replaced
## animationName : The name of the animation being replaced
func replace_animation_by_name(animatedSprite : AnimatedSprite2D, animationName : String):
	var spriteFrames : SpriteFrames = animatedSprite.sprite_frames;
	# Clear all frames of the animation
	spriteFrames.clear(animationName);
	# If there are no frames within the assets folder, get the defaults
	if (get_animation_frames(animationName).size() <= 0):
		for frame in get_default_animation_by_name(animationName):
			spriteFrames.add_frame(animationName, ImageTexture.create_from_image(frame));
	else:
		for frame in get_animation_frames(animationName):
			spriteFrames.add_frame(animationName, ImageTexture.create_from_image(frame));

## Gets the default animation of a specified animation
## animationName : The name of the animation
## returns : Array of all of the frames within the animation
func get_default_animation_by_name(animationName : String) -> Array[Image]:
	# Finds the name of the entity based on the name of the animation
	var entityName : String;
	if "Player" in animationName:
		entityName = "Player";
	elif "Patrol" in animationName:
		entityName = "PatrollingEnemy";
	elif "Fly" in animationName:
		entityName = "FlyingEnemy";
	elif "Shoot" in animationName:
		entityName = "ShootingEnemy";
	elif "Stationary" in animationName:
		entityName = "StationaryEnemy";
	elif "Coin" in animationName:
		entityName = "Coin";
	elif "Goal" in animationName:
		entityName = "Goal";
	elif "Platform" in animationName:
		entityName = "MovingPlatform";
	elif "Checkpoint" in animationName:
		entityName = "Checkpoint";
	# Get the path of the animation based on the entity and animation name
	var animationPath = defaultAnimationsRootPath + entityName + "/" + animationName + "/";
	# Create and return an array of all images within the default folder
	var defaultAnimation : Array[Image];
	for i : int in FileSearch.get_clean_file_count(animationPath):
		var animImage = load(str(animationPath, i + 1, ".png")).get_image()
		defaultAnimation.append(animImage);
	return defaultAnimation;

## Refreshes all animations in the project to match their template animation
func refresh_animations() -> void:
	get_all_sprites();
	for sprite in playerSprites:
		sprite.sprite_frames = playerTemplateSprite.sprite_frames;
	for sprite in patrollingEnemySprites:
		sprite.sprite_frames = patrollingEnemyTemplateSprite.sprite_frames;
	for sprite in stationaryEnemySprites:
		sprite.sprite_frames = stationaryEnemyTemplateSprite.sprite_frames;
	for sprite in shootingEnemySprites:
		sprite.sprite_frames = shootingEnemyTemplateSprite.sprite_frames;
	for sprite in flyingEnemySprites:
		sprite.sprite_frames = flyingEnemyTemplateSprite.sprite_frames;
	for sprite in goalSprites:
		sprite.sprite_frames = goalTemplateSprite.sprite_frames;
	for sprite in coinSprites:
		sprite.sprite_frames = coinTemplateSprite.sprite_frames;
	for sprite in movingPlatformSprites:
		sprite.sprite_frames = movingPlatformTemplateSprite.sprite_frames;
	for sprite in movingPlatformPreviewSprites:
		sprite.texture = movingPlatformTemplateSprite.sprite_frames.get_frame_texture("PlatformAnimation" , 0);
	for sprite in checkpointSprites:
		sprite.sprite_frames = checkpointTemplateSprite.sprite_frames;

## Gets the animation frames of a specified animation from the assets folder
## animationName: Name of the animation being retrieved
## returns : Array of the frames of the animation
func get_animation_frames(animationName : String) -> Array[Image]:
	return assetManager.animationSwapping.get_animation_from_folder(animationName);

## Pause all the animations within the project
func pause_all_animations() -> void:
	get_all_sprites()
	for spriteGroup in allAnimatedSprites:
		for sprite in spriteGroup:
			sprite.pause(); 

## Play all the animations within the project
func play_all_animations() -> void:
	get_all_sprites()
	for spriteGroup in allAnimatedSprites:
		for sprite in spriteGroup:
			sprite.play(); 

## Updates all template sprites to give them the animations within the assets folder
func update_template_sprites() -> void:
	for anim in playerTemplateSprite.sprite_frames.get_animation_names():
		replace_animation_by_name(playerTemplateSprite, anim);
	for anim in patrollingEnemyTemplateSprite.sprite_frames.get_animation_names():
		replace_animation_by_name(patrollingEnemyTemplateSprite, anim);
	for anim in stationaryEnemyTemplateSprite.sprite_frames.get_animation_names():
		replace_animation_by_name(stationaryEnemyTemplateSprite, anim);
	for anim in flyingEnemyTemplateSprite.sprite_frames.get_animation_names():
		replace_animation_by_name(flyingEnemyTemplateSprite, anim);
	for anim in shootingEnemyTemplateSprite.sprite_frames.get_animation_names():
		replace_animation_by_name(shootingEnemyTemplateSprite, anim);
	for anim in coinTemplateSprite.sprite_frames.get_animation_names():
		replace_animation_by_name(coinTemplateSprite, anim);
	for anim in goalTemplateSprite.sprite_frames.get_animation_names():
		replace_animation_by_name(goalTemplateSprite, anim);
	for anim in movingPlatformTemplateSprite.sprite_frames.get_animation_names():
		replace_animation_by_name(movingPlatformTemplateSprite, anim);
	for anim in checkpointTemplateSprite.sprite_frames.get_animation_names():
		replace_animation_by_name(checkpointTemplateSprite, anim);

## Updates an individual template sprite to match its animations within the assets folder
## spriteName : The name of the sprite being updated
func update_template_sprite_by_name(spriteName : String) -> void:
	var fixedSpriteName = spriteName[0].to_lower() + spriteName.substr(1);
	var templateSpriteVarName = fixedSpriteName + "TemplateSprite";
	for anim in get(templateSpriteVarName).sprite_frames.get_animation_names():
		replace_animation_by_name(get(templateSpriteVarName), anim);

## Creates all template sprites
## For each entity, Animated Sprites are created with animations added matching all of their animations
func create_template_sprites() -> void:
	playerTemplateSprite = AnimatedSprite2D.new();
	playerTemplateSprite.sprite_frames = SpriteFrames.new();
	
	playerTemplateSprite.sprite_frames.add_animation("PlayerDeath");
	playerTemplateSprite.sprite_frames.set_animation_loop_mode("PlayerDeath", SpriteFrames.LoopMode.LOOP_NONE);
	playerTemplateSprite.sprite_frames.add_animation("PlayerRun");
	playerTemplateSprite.sprite_frames.add_animation("PlayerHurt");
	playerTemplateSprite.sprite_frames.add_animation("PlayerFall");
	playerTemplateSprite.sprite_frames.set_animation_loop_mode("PlayerFall", SpriteFrames.LoopMode.LOOP_NONE);
	playerTemplateSprite.sprite_frames.add_animation("PlayerWallSlide");
	playerTemplateSprite.sprite_frames.add_animation("PlayerJump");
	playerTemplateSprite.sprite_frames.set_animation_loop_mode("PlayerJump", SpriteFrames.LoopMode.LOOP_NONE);
	playerTemplateSprite.sprite_frames.add_animation("PlayerIdle");
	playerTemplateSprite.sprite_frames.add_animation("PlayerVictory");
	playerTemplateSprite.sprite_frames.set_animation_loop_mode("PlayerVictory", SpriteFrames.LoopMode.LOOP_NONE);
	playerTemplateSprite.animation = "PlayerIdle";
	playerTemplateSprite.sprite_frames.remove_animation("default");
	
	# TODO: Add player wallsliding frames
	
	patrollingEnemyTemplateSprite = AnimatedSprite2D.new();
	patrollingEnemyTemplateSprite.sprite_frames = SpriteFrames.new();
	
	patrollingEnemyTemplateSprite.sprite_frames.add_animation("PatrolDeath");
	patrollingEnemyTemplateSprite.sprite_frames.set_animation_loop_mode("PatrolDeath", SpriteFrames.LoopMode.LOOP_NONE);
	patrollingEnemyTemplateSprite.sprite_frames.add_animation("PatrolWalk");
	patrollingEnemyTemplateSprite.animation = "PatrolWalk"
	patrollingEnemyTemplateSprite.sprite_frames.remove_animation("default");
	
	flyingEnemyTemplateSprite = AnimatedSprite2D.new();
	flyingEnemyTemplateSprite.sprite_frames = SpriteFrames.new();
	
	flyingEnemyTemplateSprite.sprite_frames.add_animation("FlyDeath");
	flyingEnemyTemplateSprite.sprite_frames.set_animation_loop_mode("FlyDeath", SpriteFrames.LoopMode.LOOP_NONE);
	flyingEnemyTemplateSprite.sprite_frames.add_animation("FlyMove");
	flyingEnemyTemplateSprite.animation = "FlyMove";
	flyingEnemyTemplateSprite.sprite_frames.remove_animation("default");
	
	shootingEnemyTemplateSprite = AnimatedSprite2D.new();
	shootingEnemyTemplateSprite.sprite_frames = SpriteFrames.new();
	
	shootingEnemyTemplateSprite.sprite_frames.add_animation("ShootDeath");
	shootingEnemyTemplateSprite.sprite_frames.set_animation_loop_mode("ShootDeath", SpriteFrames.LoopMode.LOOP_NONE);
	shootingEnemyTemplateSprite.sprite_frames.add_animation("ShootIdle");
	shootingEnemyTemplateSprite.sprite_frames.add_animation("EnemyShoot");
	shootingEnemyTemplateSprite.sprite_frames.set_animation_loop_mode("EnemyShoot", SpriteFrames.LoopMode.LOOP_NONE);
	shootingEnemyTemplateSprite.animation = "EnemyShoot";
	shootingEnemyTemplateSprite.sprite_frames.remove_animation("default");
	
	stationaryEnemyTemplateSprite = AnimatedSprite2D.new();
	stationaryEnemyTemplateSprite.sprite_frames = SpriteFrames.new();
	
	stationaryEnemyTemplateSprite.sprite_frames.add_animation("StationaryDeath");
	stationaryEnemyTemplateSprite.sprite_frames.set_animation_loop_mode("StationaryDeath", SpriteFrames.LoopMode.LOOP_NONE);
	stationaryEnemyTemplateSprite.sprite_frames.add_animation("StationaryIdle");
	stationaryEnemyTemplateSprite.animation = "StationaryIdle";
	stationaryEnemyTemplateSprite.sprite_frames.remove_animation("default");
	
	goalTemplateSprite = AnimatedSprite2D.new();
	goalTemplateSprite.sprite_frames = SpriteFrames.new();
	
	goalTemplateSprite.sprite_frames.add_animation("GoalAnimation");
	goalTemplateSprite.animation = "GoalAnimation";
	goalTemplateSprite.sprite_frames.remove_animation("default");
	
	coinTemplateSprite = AnimatedSprite2D.new();
	coinTemplateSprite.sprite_frames = SpriteFrames.new();
	
	coinTemplateSprite.sprite_frames.add_animation("CoinAnimation");
	coinTemplateSprite.animation = "CoinAnimation";
	coinTemplateSprite.sprite_frames.remove_animation("default");
	
	movingPlatformTemplateSprite = AnimatedSprite2D.new();
	movingPlatformTemplateSprite.sprite_frames = SpriteFrames.new();
	
	movingPlatformTemplateSprite.sprite_frames.add_animation("PlatformAnimation");
	movingPlatformTemplateSprite.animation = "PlatformAnimation";
	movingPlatformTemplateSprite.sprite_frames.remove_animation("default");
	
	checkpointTemplateSprite = AnimatedSprite2D.new();
	checkpointTemplateSprite.sprite_frames = SpriteFrames.new();
	
	checkpointTemplateSprite.sprite_frames.add_animation("CheckpointInactive");
	checkpointTemplateSprite.sprite_frames.add_animation("CheckpointActive");
	checkpointTemplateSprite.sprite_frames.add_animation("CheckpointCollected");
	checkpointTemplateSprite.sprite_frames.set_animation_loop_mode("CheckpointCollected", SpriteFrames.LoopMode.LOOP_NONE);
	checkpointTemplateSprite.animation = "CheckpointInactive";
	checkpointTemplateSprite.sprite_frames.remove_animation("default");
	

## Finds all sprites within the project, adds them to their corresponding array
func get_all_sprites() -> void:
	for spriteGroup in allAnimatedSprites:
		spriteGroup.clear();
	movingPlatformPreviewSprites.clear();
	for player in get_tree().get_nodes_in_group("Player"):
		playerSprites.append(player.find_child("AnimatedSprite2D"));
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if (enemy is EnemyFlyer):
			flyingEnemySprites.append(enemy.find_child("AnimatedSprite2D"));
		if (enemy is EnemyPatrol):
			patrollingEnemySprites.append(enemy.find_child("AnimatedSprite2D"));
		if (enemy is EnemyStationary):
			stationaryEnemySprites.append(enemy.find_child("AnimatedSprite2D"));
		if (enemy is EnemyShooting):
			shootingEnemySprites.append(enemy.find_child("AnimatedSprite2D"));
	for coin in get_tree().get_nodes_in_group("Coin"):
		if (coin is Coin):
			coinSprites.append(coin.find_child("AnimatedSprite2D"));
	for goal in get_tree().get_nodes_in_group("Goal"):
		goalSprites.append(goal.find_child("AnimatedSprite2D"));
	for platform in get_tree().get_nodes_in_group("Platform"):
		movingPlatformSprites.append(platform.find_child("AnimatedSprite2D"));
		movingPlatformPreviewSprites.append(platform.find_child("PreviewPlatform"));
	for checkpoint in get_tree().get_nodes_in_group("Checkpoint"):
		checkpointSprites.append(checkpoint.find_child("AnimatedSprite2D"));

## Updates a given animation's fps to a given fps
## animationName : The name of the animation being updated
## newFPS : The fps the animation will be changed to
func update_animation_fps(animationName : String, newFPS : float):
	# Checks which entity is having its animation changed based on the name of the animation
	# Changes that entity's template animation to have a new fps
	if "Player" in animationName:
		playerTemplateSprite.sprite_frames.set_animation_speed(animationName, newFPS);
	elif "Patrol" in animationName:
		patrollingEnemyTemplateSprite.sprite_frames.set_animation_speed(animationName, newFPS);
	elif "Stationary" in animationName:
		stationaryEnemyTemplateSprite.sprite_frames.set_animation_speed(animationName, newFPS);
	elif "Fly" in animationName:
		flyingEnemyTemplateSprite.sprite_frames.set_animation_speed(animationName, newFPS);
	elif "Shoot" in animationName:
		shootingEnemyTemplateSprite.sprite_frames.set_animation_speed(animationName, newFPS);
	elif "Coin" in animationName:
		coinTemplateSprite.sprite_frames.set_animation_speed(animationName, newFPS);
	elif "Goal" in animationName:
		goalTemplateSprite.sprite_frames.set_animation_speed(animationName, newFPS);
	elif "Platform" in animationName:
		movingPlatformTemplateSprite.sprite_frames.set_animation_speed(animationName, newFPS);
	elif "Checkpoint" in animationName:
		checkpointTemplateSprite.sprite_frames.set_animation_speed(animationName, newFPS);

## Gets a reference to a template sprite
## spriteName : The name of the sprite being referenced
## returns : Template sprite with the name
func get_template_sprite(spriteName : String) -> AnimatedSprite2D:
	return get(spriteName[0].to_lower() + spriteName.substr(1) + "TemplateSprite");

## Gets the fps of a specified animation
## animationName : The name of the animation being checked
## returns : The fps of the animation
func get_animation_fps(animationName : String) -> float:
	var fps : float = 12;
	# Finds which template is being checked based on the name of the animation
	# Sets the fps to that of the animation within the template sprite
	if "Player" in animationName:
		fps = playerTemplateSprite.sprite_frames.get_animation_speed(animationName);
	elif "Patrol" in animationName:
		fps = patrollingEnemyTemplateSprite.sprite_frames.get_animation_speed(animationName);
	elif "Stationary" in animationName:
		fps = stationaryEnemyTemplateSprite.sprite_frames.get_animation_speed(animationName);
	elif "Fly" in animationName:
		fps = flyingEnemyTemplateSprite.sprite_frames.get_animation_speed(animationName);
	elif "Shoot" in animationName:
		fps = shootingEnemyTemplateSprite.sprite_frames.get_animation_speed(animationName);
	elif "Coin" in animationName:
		fps = coinTemplateSprite.sprite_frames.get_animation_speed(animationName);
	elif "Goal" in animationName:
		fps = goalTemplateSprite.sprite_frames.get_animation_speed(animationName);
	elif "Platform" in animationName:
		fps = movingPlatformTemplateSprite.sprite_frames.get_animation_speed(animationName);
	elif "Checkpoint" in animationName:
		fps = checkpointTemplateSprite.sprite_frames.get_animation_speed(animationName);
	return fps

## Sets all the fps values to their corresponding values within the JSON
func set_all_fps_to_json(jsonPath : String) -> void:
	var JSONFile : FileAccess= FileAccess.open(jsonPath, FileAccess.READ);
	var json_as_dict : Variant = JSON.parse_string(JSONFile.get_as_text());
	for anim in json_as_dict.get("animations", {}):
		AnimationManager.update_animation_fps(anim, json_as_dict["animations"][anim]);
