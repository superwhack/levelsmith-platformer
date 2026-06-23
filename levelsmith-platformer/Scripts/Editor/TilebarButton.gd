extends Button

# SourceID of this item
@export var thisItemID : int;
# Reference to the container this item is in
@export var tilebar : HBoxContainer;
# Reference to the tile set
@onready var tileSet : TileSet = tilebar.tileMap.tile_set;

func _process(_delta: float) -> void:
	# Change the texture to the texture currently set in the tile set
	icon = tileSet.get_source(thisItemID).texture;
