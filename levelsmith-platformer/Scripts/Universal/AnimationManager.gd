extends Node

var playerSprites : Array[AnimatedSprite2D];

var patrolEnemySprites : Array[AnimatedSprite2D];

var flyingEnemySprites : Array[AnimatedSprite2D];

var shootingEnemySprites : Array[AnimatedSprite2D];

var stationaryEnemySprites : Array[AnimatedSprite2D];

var defaultAnimationsRootPath : String = "res://Assets/Sprites/Entities/";

@onready var allAnimatedSprites: Array[Array] = [
playerSprites, 
patrolEnemySprites, 
flyingEnemySprites, 
shootingEnemySprites, 
stationaryEnemySprites];

var assetManager : AssetManager;

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
	for spriteGroup in allAnimatedSprites:
		for sprite in spriteGroup:
			for anim in sprite.sprite_frames.get_animation_names():
				replace_animation_by_name(sprite, anim);

func get_animation_frames(animationName : String) -> Array[Image]:
	return assetManager.animationSwapping.get_animation_from_folder(animationName);

func pause_all_animations() -> void:
	pass;

func play_all_animations() -> void:
	pass;

func get_all_sprites() -> void:
	for spriteGroup in allAnimatedSprites:
		spriteGroup.clear();
	for player in get_tree().get_nodes_in_group("Player"):
		playerSprites.append(player.find_child("AnimatedSprite2D"));
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if (enemy is EnemyFlyer):
			flyingEnemySprites.append(enemy.find_child("AnimatedSprite2D"));
		if (enemy is EnemyPatrol):
			patrolEnemySprites.append(enemy.find_child("AnimatedSprite2D"));
		#if (enemy is EnemyStationary):
			#stationaryEnemySprites.append(enemy.find_child("AnimatedSprite2D"));
		if (enemy is EnemyShooting):
			shootingEnemySprites.append(enemy.find_child("AnimatedSprite2D"));
