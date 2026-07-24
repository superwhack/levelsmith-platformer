class_name ShootingPreset;
extends Resource

# Tilemap position of the enemy.
@export var position : Vector2i;

# Direction of firing
@export var direction : float;
# True if direction is disregarded and enemy fires randomly
@export var randomDirection : bool;

# Speed of projectiles fired
@export var shotSpeed : float;

# Time between shots
@export var fireRate : float;

# True if projectiles are bouncable
@export var projBounce : bool;

# True if the shooting enemy has gravity and can have tile affects and gravity applied
@export var gravity : bool;

# True if the projectiles stay active even when off screen
@export var persistence : bool;

# True if the enemy should always be active
@export var active : bool;
