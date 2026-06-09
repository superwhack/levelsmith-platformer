extends TileMapLayer

# Master and Editor Manager exports for easy access
@export var masterManager : Node2D;

# The grid size, taken from the MasterManager.
@onready var gridSize : Vector2i = masterManager.worldSize;

## Called when the grid lines tile map layer is created.
func _ready() -> void:
	fill_grid_lines();
	
	print("Level Height:", gridSize.y);
	print("Level Width:", gridSize.x);

## Fills the grid with grid lines tiles.
func fill_grid_lines() -> void:
	for height in range(0, gridSize.y + 1):
		for width in range(0, gridSize.x + 1):
			self.set_cell(Vector2i(width, height), 1, Vector2i.ZERO);
