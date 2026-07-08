extends Node2D

# References to other nodes.
@export var tileMap : TileMapLayer;
@export var masterManager : Node2D;

# Icon textures
var propBackgroundIcon : Texture2D = preload("res://Assets/Sprites/UI/Icons/PropBackground.png");
var propForegroundIcon : Texture2D = preload("res://Assets/Sprites/UI/Icons/PropForeground.png");
var defaultIcon : Texture2D = preload("res://Assets/Sprites/UI/triangle.png");

#Offset for the icon appearing in the top left of each cell
const ICON_OFFSET : Vector2 = Vector2(20, 20);

# Heap dictionary (stores position and the sprite object)
var iconHeap : Dictionary[Vector2, Sprite2D] = {};

## Called when the node enters the scene tree for the first time. Sets up all signals.
func _ready() -> void:
	var clear_icons = func () -> void:
		iconHeap.clear();
	
	Global.levelCreated.connect(clear_icons);
	ImportExportManager.levelImported.connect(setup_icons);

## Creates a new icon based on the type and places it at the given position.
## objectPosition: Where the icon is placed in cell coordinates
## iconType: The type of icon to create
func create_icon(objectPosition: Vector2, iconType: String) -> void:
	var baseSprite : Sprite2D = Sprite2D.new();
	
	match iconType:
		"foreground":
			baseSprite.texture = propForegroundIcon;
		"background": 
			baseSprite.texture = propBackgroundIcon;
		_:
			baseSprite.texture = defaultIcon;
	
	baseSprite.z_index = 2;
	iconHeap.set(objectPosition, baseSprite);
	iconHeap[objectPosition].global_position = objectPosition * Global.TILE_SIZE + ICON_OFFSET;
	add_child(iconHeap[objectPosition]);

## Deletes an icon at the given position.
## objectPosition: Where the existing icon is in cell coordinates.
func delete_icon(objectPosition: Vector2) -> void:
	iconHeap[objectPosition].queue_free();
	iconHeap.erase(objectPosition);

## Scans the tile map and adds icons to all props that exist
func setup_icons() -> void:
	var currentCell : int;
	var currentPosition : Vector2;
	
	for row in masterManager.worldSize.y:
		for col in masterManager.worldSize.x:
			currentPosition = Vector2(col, row);
			currentCell = tileMap.get_cell_source_id(currentPosition);
			# Skip objects that aren't props for now (can be adjusted for later)
			if (currentCell < Global.EntityType.PROP1 || currentCell > Global.EntityType.PROP6): continue;
			
			# Background props are alternative indices 4 to 7.
			var isBackground : bool = tileMap.get_cell_alternative_tile(currentPosition) > 3;
			create_icon(currentPosition, "background" if isBackground else "foreground");
