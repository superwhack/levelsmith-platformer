class_name MovingPlatformPreset;
extends Resource;

# Tilemap position of the platform.
@export var position : Vector2i;

# Flying speed of the platform.
@export var speed : float;

# Relative offset from Point A to Point B.
@export var pointBOffset : Vector2;

# Initial progress along movement when beginning
@export var progress : int;

@export var easing : bool;
@export var momentum : bool;
@export var visible : bool;
