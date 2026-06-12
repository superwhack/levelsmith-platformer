extends TileMapLayer

# Master and Editor Manager exports for easy access
@export var masterManager : Node2D;

## Called when the grid lines tile map layer is created.
func _ready() -> void:
	fill_grid_lines();

## Fills the grid with grid lines tiles.
func fill_grid_lines() -> void:
	clear();
	for height in range(0, masterManager.worldSize.y):
		for width in range(0, masterManager.worldSize.x):
			set_cell(Vector2i(width, height), 1, Vector2i.ZERO);
