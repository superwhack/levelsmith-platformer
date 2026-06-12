extends Button

@export var thisItemID: int;
@export var tilebar: HBoxContainer;

@onready var tileSet: TileSet = tilebar.tileMap.tile_set;

func _process(delta: float) -> void:
	icon = tileSet.get_source(thisItemID).texture;
