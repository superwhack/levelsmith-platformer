class_name Enemy
extends CharacterBody2D

# variable to adjust
@export var health: int = 1
@export var gravity: float = 980.0
var propertyFile : Resource;

# Sprite reference
#@onready var sprites: AnimatedSprite2D = $AnimatedSprite2D

## Initializing, add to the group named enemy
func _ready() -> void:
	add_to_group("enemy")

## process gravity every frame
func _physics_process(delta: float) -> void:
	check_out_of_bounds();
	apply_gravity(delta)

## Adds gravity
func apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta

## Applies damage to enemy, triggered by player stomping
func take_damage(amount: int = 1) -> void:
	health -= amount
	if health <= 0:
		die()

## Handles enemy death
func die() -> void:
	AudioManager.play_effect("EnemyDeath");
	queue_free()

## When the enemy walks/falls out of bounds, force kill them
func check_out_of_bounds() -> void:
	var masterManager : Node2D = get_tree().current_scene;
	
	# There is a 1 tile leeway given to enemies who leave bounds, before death
	if (global_position.x < (-1) * Global.tileSize
	|| global_position.x > (masterManager.worldSize.y + 1) * Global.tileSize
	|| global_position.y < (-1) * Global.tileSize
	|| global_position.y > (masterManager.worldSize.x + 1) * Global.tileSize):
		#print("Player OOB: ", global_position)
		die();

## OVERRIDE
## Assigns the script of the given ID (located in the Resources/Enemies folder) to an enemy at the given position.
## id: The ID of the script to assign
## position: The position of the enemy to assign to the script's appropriate value.
func assign_script(id: String, position: Vector2i) -> void:
	pass;

## OVERRIDE
## Applies the effects of the given properties in the file to the enemy, this function is used by finding the enemy at the location specified in the script.
## file: The property file to apply to the enemy 
func apply_script(file: Resource) -> void:
	pass;
