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
	queue_free()

func assign_script(id: String, position: Vector2i) -> void:
	pass;
func apply_script(file: Resource) -> void:
	pass;
