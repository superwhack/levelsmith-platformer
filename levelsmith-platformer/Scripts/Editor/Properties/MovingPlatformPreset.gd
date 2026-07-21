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

# Delay, in seconds, when the platform reaches the end of the path before turning back
@export var delay : float;

# Easing between the two points
@export var easing : bool;

# True if the platform exerts it's momentum on the player when the player leaves
@export var momentum : bool;

# True if the platform's line is visible in play
@export var visible : bool;

# True if the platform is always active
@export var active : bool;
