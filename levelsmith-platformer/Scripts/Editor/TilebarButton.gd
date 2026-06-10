extends TextureButton

@export var thisItemID: int;
@export var tilebar: HBoxContainer;

@onready var tileSet: TileSet = tilebar.tileMap.tile_set;

func _process(delta: float) -> void:
	texture_normal = tileSet.get_source(thisItemID).texture;
