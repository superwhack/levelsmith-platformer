extends Area2D

# Reference to the VisibleOnScreenEnabler
@export var onScreen : VisibleOnScreenEnabler2D;

#var direction : float;
var speed : float;
# Whether or not the projectile can be bounced on
var bounceable : bool;

## When the scene enters the tree, connect important signals
func _ready() -> void:
	body_entered.connect(delete_projectile);
	onScreen.screen_exited.connect(delete_projectile);

## Move the projectile at a speed
func _process(delta: float) -> void:
	global_position += transform.x * delta * speed * 100;

## Delete this projectile once it's offscreen
func delete_projectile(body: Node2D = null) -> void:
	if body == null:
		queue_free();
	elif body is TileMapLayer:
		queue_free();
