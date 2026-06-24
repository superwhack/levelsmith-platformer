extends Node

var playerSprite : AnimatedSprite2D

var patrolEnemySprites : Array[AnimatedSprite2D];

var flyingEnemySprites : Array[AnimatedSprite2D];

var shootingEnemySprites : Array[AnimatedSprite2D];

var stationaryEnemySprites : Array[AnimatedSprite2D];

@export var mainTileMap : TileMapLayer;

func replace_animation(animatedSprite : AnimatedSprite2D, animationName : String, frames : Array[Image]) -> void:
	pass;

func refresh_animations() -> void:
	pass;

func pause_all_animations() -> void:
	pass;

func play_all_animations() -> void:
	pass;

func get_all_sprites() -> void:
	pass;
