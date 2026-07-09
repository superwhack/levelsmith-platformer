extends Area2D

# Reference to the VisibleOnScreenEnabler
@export var onScreen : VisibleOnScreenEnabler2D;

# Reference to child Sprite2D
@export var sprite : Sprite2D;
# Reverences to Texture2D assets for bullet variants
@export var dangerTexture : Texture2D;
@export var bounceTexture : Texture2D;

#var direction : float;
var speed : float;
# Whether or not the projectile can be bounced on
var bounceable : bool;

## When the scene enters the tree, assign proper texture and connect important signals
func _ready() -> void:
	body_entered.connect(delete_projectile);
	onScreen.screen_exited.connect(delete_projectile);
	
	if bounceable:
		sprite.texture = bounceTexture;
	else:
		sprite.texture = dangerTexture;

## Move the projectile at a speed
func _process(delta: float) -> void:
	global_position += transform.x * delta * speed * 100;

## Delete this projectile once it's offscreen
func delete_projectile(body: Node2D = null) -> void:
	if body == null || body is MovingPlatform:
		queue_free();
	elif body is TileMapLayer:
		# STRETCH : If we can figure out how to get the proper position of the tile, this can be uncommented to let projectiles pass on the underside of one ways
		#var tilePos : Vector2i = body.local_to_map(<REPLACE>);
		#var tileData : TileData = body.get_cell_tile_data(tilePos);
		#if tileData.get_custom_data("name") == "oneway":
		#	if rotation > deg_to_rad(-180) && rotation < 0:
		#		return;
		queue_free();
