extends Resource
## A class that contains variables for different player movement stats, 
## such as ground speed or jumping height.
class_name PlayerMovementPreset

# Variables for player movement stats
@export var health : int;
@export var groundSpeed : float;
@export var jumpHeight : float;
@export var airControl : float;
@export var fallSpeed : float;
@export var coyoteTime : float;

@export var doubleJump : bool;
@export var wallJump : bool;
@export var wallJumpDecay : bool;
