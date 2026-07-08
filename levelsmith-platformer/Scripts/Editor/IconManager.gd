extends Node2D

# Icon textures
var propBackgroundIcon : Texture2D = preload("res://Assets/Sprites/UI/Icons/PropBackground.png");
var propForegroundIcon : Texture2D = preload("res://Assets/Sprites/UI/Icons/PropForeground.png");
var defaultIcon : Texture2D = preload("res://Assets/Sprites/UI/triangle.png");

# Base Sprite2D for each icon
var backgroundSprite : Sprite2D;
var foregroundSprite : Sprite2D;

#Offset for the icon appearing in the top left of each cell
const ICON_OFFSET : Vector2 = Vector2(30, 30);

# Heap dictionary (stores position and the sprite object)
var iconHeap : Dictionary[Vector2, Sprite2D] = {};

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	backgroundSprite = Sprite2D.new();
	backgroundSprite.texture = propBackgroundIcon;
	
	foregroundSprite = Sprite2D.new();
	foregroundSprite.texture = propForegroundIcon;

## Creates a new icon based on the type and places it at the given position.
## objectPosition: Where the icon is placed
## iconType: The type of icon to create
func create_icon(objectPosition: Vector2, iconType: String) -> void:
	var baseSprite : Sprite2D;
	
	match iconType:
		"foreground":
			baseSprite = foregroundSprite;
		"background": 
			baseSprite = backgroundSprite;
		_:
			baseSprite = Sprite2D.new();
			baseSprite.texture = defaultIcon;
	
	iconHeap.set(objectPosition, baseSprite.instantiate());
	iconHeap[objectPosition].global_position = objectPosition * Global.TILE_SIZE + ICON_OFFSET;
	add_child(iconHeap[objectPosition]);

func delete_icon(objectPosition: Vector2) -> void:
	iconHeap[objectPosition].queue_free();
	iconHeap.erase(objectPosition);
