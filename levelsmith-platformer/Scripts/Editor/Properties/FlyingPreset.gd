class_name FlyingPreset;
extends Resource;

# Tilemap position of the enemy.
@export var position: Vector2i;

# Flying speed of the enemy.
@export var speed: float = 300.0;

# Relative offset from Point A to Point B.
@export var pointBOffset: Vector2 = Vector2(128, 0);
