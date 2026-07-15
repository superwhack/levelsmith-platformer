extends Camera2D

# References to necessary nodes
@export var masterManager : Node2D;
@export var baseCamera : Camera2D;
@export var screenshotViewport : SubViewport;


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.levelCreated.connect(zoom_out);
	ImportExportManager.levelImported.connect(zoom_out);

## Zooms out this camera to cover the entire level.
func zoom_out() -> void:
	zoom = Vector2.ONE * baseCamera.get_min_zoom_to_fit_roam();
	position = lerp(Vector2.ZERO, Vector2(masterManager.worldSize * Global.TILE_SIZE), 0.48);

## Takes a screenshot of the entire level
## returns: An image file containing the level screenshot.
func get_level_screenshot() -> Image:
	return screenshotViewport.get_texture().get_image();
