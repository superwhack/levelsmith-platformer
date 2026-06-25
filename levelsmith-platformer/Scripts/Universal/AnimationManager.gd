extends Node

var playerSprite : AnimatedSprite2D

var patrolEnemySprites : Array[AnimatedSprite2D];

var flyingEnemySprites : Array[AnimatedSprite2D];

var shootingEnemySprites : Array[AnimatedSprite2D];

var stationaryEnemySprites : Array[AnimatedSprite2D];

@export var mainTileMap : TileMapLayer;

func replace_animation(animatedSprite : AnimatedSprite2D, animationName : String, frames : Array[Image]) -> void:
	var spriteFrames : SpriteFrames = animatedSprite.sprite_frames;
	spriteFrames.clear(animationName);
	for frame in frames:
		spriteFrames.add_frame(animationName, ImageTexture.create_from_image(frame));

func refresh_animations() -> void:
	pass;

func pause_all_animations() -> void:
	pass;

func play_all_animations() -> void:
	pass;

func get_all_sprites() -> void:
	var playerNode = get_tree().get_first_node_in_group("Player");
	playerSprite = playerNode.find_child("AnimatedSprite2D");
	for enemy in get_tree().get_nodes_in_group("Enemy");
