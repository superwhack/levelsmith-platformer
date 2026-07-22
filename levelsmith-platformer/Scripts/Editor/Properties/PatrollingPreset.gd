class_name PatrollingPreset
extends Resource

# Tilemap position of the enemy.
@export var position : Vector2i;

# Speed of the enemy
@export var groundSpeed : float;

# Initial direction of the enemy
@export var direction : bool;

# True if the enemy is restricted and can't walk off of platforms/tiles
@export var restricted : bool;
