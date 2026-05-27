extends HBoxContainer

@onready var editorManager : Node2D = get_parent().get_parent().get_parent();

func _on_solid_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.SOLID);

func _on_bounce_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.BOUNCE);

func _on_ice_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.ICE);

func _on_sticky_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.STICKY);

func _on_slope_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.SLOPE);

func _on_oneway_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.ONEWAY);

func _on_death_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.DEATH);
