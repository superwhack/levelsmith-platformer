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

## Zooms out this camera to cover the entire level and centers it.
func zoom_out() -> void:
	var minZoom : float = baseCamera.get_min_zoom_to_fit_roam(self);
	zoom = Vector2.ONE * minZoom;
	
	global_position = baseCamera.roamBounds.get_center();

## Takes a screenshot of the entire level. 
## returns: An image file containing the level screenshot.
func get_level_screenshot() -> Image:
	# Set this to update once, which updates the render target once before being disabled.
	# Means we don't have the viewport active all the time.
	screenshotViewport.render_target_update_mode = SubViewport.UPDATE_ONCE;
	enabled = true;
	make_current();
	# Hide the preview and selector frame, then show post-screenshot.
	masterManager.editorManager.previewTileMap.hide();
	masterManager.editorManager.customCursorManager.hide_selector_frame();
	masterManager.editorManager.customCursorManager.hide_entity_highlight();
	masterManager.editorManager.iconManager.hide_preview_icon();
	masterManager.editorManager.isScreenshotting = true;
	
	await RenderingServer.frame_post_draw;
	
	enabled = false;
	masterManager.editorManager.previewTileMap.show();
	masterManager.editorManager.customCursorManager.show_selector_frame();
	masterManager.editorManager.iconManager.show_preview_icon();
	masterManager.editorManager.isScreenshotting = false;
	return screenshotViewport.get_texture().get_image();
