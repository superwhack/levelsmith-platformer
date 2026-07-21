extends Resource
class_name PlayerMovementPreset

# Player's maximum health
@export var health : int;

# Player's groundspeed when walking
@export var groundSpeed : float;

# Player's ac/deceleration, affects how slowly they begin/stop moving
@export var acceleration : float;
@export var deceleration : float;

# Jump height affects jump height
@export var jumpHeight : float;

# `Friction` in air, makes it harder to turn in midair when lower
@export var airControl : float;

# Fall speed determines maximum fall speed
@export var fallSpeed : float;

# How long the player can be off the ground and still jump
@export var coyoteTime : float;

# True if slopes affect speed like usual with a CharacterBody2D
@export var slopeSlowdown : bool;

# True if the player can drop through oneways
@export var oneways : bool;

# True if the player can double jump
@export var doubleJump : bool;

# True if player can wall jump
@export var wallJump : bool;
# True if player's wall jump decays when jumping off the same side repeatedly
@export var wallJumpDecay : bool;
