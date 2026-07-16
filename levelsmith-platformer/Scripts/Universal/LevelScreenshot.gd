extends Camera2D

# References to necessary nodes
@export var masterManager : Node2D;
@export var baseCamera : Camera2D;
@export var screenshotViewport : SubViewport;


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.levelCreated.connect(zoom_out);
	ImportExportManager.levelImported.connect(zoom_out);
	screenshotViewport.world_2d = get_tree().root.get_viewport().world_2d;
	enabled = true;
	make_current();
	
## Zooms out this camera to cover the entire level.
func zoom_out() -> void:
	# NOTE: Pretty much all of this came from CameraManager.
	# Ideally, we would be able to use the functions from CM,
	# but I would have to restructure the function params for a given camera.
	var level_bounds := Rect2(Vector2.ZERO, masterManager.worldSize * Global.TILE_SIZE);

	level_bounds.position -= Vector2.ONE * Global.TILE_SIZE;
	level_bounds.size += Vector2.ONE * Global.TILE_SIZE * 2;

	var roam_margin = 4.0 * Global.TILE_SIZE;
	var roam_bounds := Rect2(
		level_bounds.position - Vector2.ONE * roam_margin,
		level_bounds.size + Vector2.ONE * roam_margin * 2
	);

	var viewport_size = screenshotViewport.size;

	var zoom_x = viewport_size.x / roam_bounds.size.x;
	var zoom_y = viewport_size.y / roam_bounds.size.y;

	zoom = Vector2.ONE * min(zoom_x, zoom_y)
	global_position = roam_bounds.get_center()

## Takes a screenshot of the entire level. 
## returns: An image file containing the level screenshot.
func get_level_screenshot() -> Image:
	# Set this to update once, which updates the render target once before being disabled.
	# Means we don't have the viewport active all the time.
	screenshotViewport.render_target_update_mode = SubViewport.UPDATE_ONCE;
	enabled = true;
	make_current();
	# Hide the preview and selector frame, then show post-screenshot.
	masterManager.previewTileMap.hide();
	#masterManager.editorManager.customCursorManager.hide_selector_frame();
	await RenderingServer.frame_post_draw;
	return screenshotViewport.get_texture().get_image();
	enabled = false;
	masterManager.previewTileMape.show();
	#masterManager.editorManager.customCursorManager.show_selector_frame();
