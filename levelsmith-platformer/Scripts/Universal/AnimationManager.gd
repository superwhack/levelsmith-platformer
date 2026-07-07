extends Node

var playerSprites : Array[AnimatedSprite2D];
var playerTemplateSprite : AnimatedSprite2D = AnimatedSprite2D.new();

var patrollingEnemySprites : Array[AnimatedSprite2D];
var patrollingEnemyTemplateSprite : AnimatedSprite2D;

var flyingEnemySprites : Array[AnimatedSprite2D];
var flyingEnemyTemplateSprite : AnimatedSprite2D;

var shootingEnemySprites : Array[AnimatedSprite2D];
var shootingEnemyTemplateSprite : AnimatedSprite2D;

var stationaryEnemySprites : Array[AnimatedSprite2D];
var stationaryEnemyTemplateSprite : AnimatedSprite2D;

var defaultAnimationsRootPath : String = "res://Assets/Sprites/Entities/";


@onready var allAnimatedSprites: Array[Array] = [
playerSprites, 
patrollingEnemySprites, 
flyingEnemySprites, 
shootingEnemySprites, 
stationaryEnemySprites];

var assetManager : AssetManager;

func _ready() -> void:
	create_template_sprites();
	
	Global.levelCreated.connect(update_template_sprites);

func replace_animation(animatedSprite : AnimatedSprite2D, animationName : String, frames : Array[Image]) -> void:
	var spriteFrames : SpriteFrames = animatedSprite.sprite_frames;
	spriteFrames.clear(animationName);
	for frame in frames:
		spriteFrames.add_frame(animationName, ImageTexture.create_from_image(frame));

func replace_animation_by_name(animatedSprite : AnimatedSprite2D, animationName : String):
	var spriteFrames : SpriteFrames = animatedSprite.sprite_frames;
	spriteFrames.clear(animationName);
	if (get_animation_frames(animationName).size() <= 0):
		for frame in get_default_animation_by_name(animationName):
			spriteFrames.add_frame(animationName, ImageTexture.create_from_image(frame));
	else:
		for frame in get_animation_frames(animationName):
			spriteFrames.add_frame(animationName, ImageTexture.create_from_image(frame));

func get_default_animation_by_name(animationName : String) -> Array[Image]:
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
	var animationPath = defaultAnimationsRootPath + entityName + "/" + animationName + "/";
	var defaultAnimation : Array[Image];
	for i : int in FileSearch.get_clean_file_count(animationPath):
		var animImage = load(str(animationPath, i + 1, ".png")).get_image()
		defaultAnimation.append(animImage);
	return defaultAnimation;

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

func get_animation_frames(animationName : String) -> Array[Image]:
	return assetManager.animationSwapping.get_animation_from_folder(animationName);

func pause_all_animations() -> void:
	pass;

func play_all_animations() -> void:
	pass;

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

func update_template_sprite_by_name(spriteName : String) -> void:
	var fixedSpriteName = spriteName[0].to_lower() + spriteName.substr(1);
	var templateSpriteVarName = fixedSpriteName + "TemplateSprite";
	for anim in get(templateSpriteVarName).sprite_frames.get_animation_names():
		replace_animation_by_name(get(templateSpriteVarName), anim);

func create_template_sprites() -> void:
	playerTemplateSprite = AnimatedSprite2D.new();
	playerTemplateSprite.sprite_frames = SpriteFrames.new();
	
	playerTemplateSprite.sprite_frames.add_animation("PlayerDeath");
	playerTemplateSprite.sprite_frames.add_animation("PlayerRun");
	playerTemplateSprite.sprite_frames.add_animation("PlayerHurt");
	playerTemplateSprite.sprite_frames.add_animation("PlayerFall");
	playerTemplateSprite.sprite_frames.add_animation("PlayerJump");
	playerTemplateSprite.sprite_frames.add_animation("PlayerIdle");
	playerTemplateSprite.sprite_frames.remove_animation("default");
	
	patrollingEnemyTemplateSprite = AnimatedSprite2D.new();
	patrollingEnemyTemplateSprite.sprite_frames = SpriteFrames.new();
	
	patrollingEnemyTemplateSprite.sprite_frames.add_animation("PatrolDeath");
	patrollingEnemyTemplateSprite.sprite_frames.add_animation("PatrolWalk");
	patrollingEnemyTemplateSprite.sprite_frames.remove_animation("default");
	
	flyingEnemyTemplateSprite = AnimatedSprite2D.new();
	flyingEnemyTemplateSprite.sprite_frames = SpriteFrames.new();
	
	flyingEnemyTemplateSprite.sprite_frames.add_animation("FlyDeath");
	flyingEnemyTemplateSprite.sprite_frames.add_animation("FlyMove");
	flyingEnemyTemplateSprite.sprite_frames.remove_animation("default");
	
	shootingEnemyTemplateSprite = AnimatedSprite2D.new();
	shootingEnemyTemplateSprite.sprite_frames = SpriteFrames.new();
	
	shootingEnemyTemplateSprite.sprite_frames.add_animation("ShootDeath");
	shootingEnemyTemplateSprite.sprite_frames.add_animation("ShootIdle");
	shootingEnemyTemplateSprite.sprite_frames.add_animation("EnemyShoot");
	shootingEnemyTemplateSprite.sprite_frames.remove_animation("default");
	
	stationaryEnemyTemplateSprite = AnimatedSprite2D.new();
	stationaryEnemyTemplateSprite.sprite_frames = SpriteFrames.new();
	
	stationaryEnemyTemplateSprite.sprite_frames.add_animation("StationaryDeath");
	stationaryEnemyTemplateSprite.sprite_frames.add_animation("StationaryIdle");
	stationaryEnemyTemplateSprite.sprite_frames.remove_animation("default");
	

func get_all_sprites() -> void:
	for spriteGroup in allAnimatedSprites:
		spriteGroup.clear();
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
