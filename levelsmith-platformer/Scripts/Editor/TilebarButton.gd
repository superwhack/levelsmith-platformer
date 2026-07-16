extends Button

# SourceID of this item
@export var thisItemID : int;
# Reference to the container this item is in
@export var tilebar : HBoxContainer;
# Option to enable/disable updating the texture
@export var isTextureUpdating : bool = false;
# Reference to the tile set
@onready var tileSet : TileSet = tilebar.tileMap.tile_set;

@export var isEntity : bool = false;

@export var entityName : String = "";

@export var image : TextureRect;

func _ready() -> void:
	pressed.connect(change_brush_object)

func _process(_delta: float) -> void:
	# Change the texture to the texture currently set in the tile set
	if (isTextureUpdating): 
		if(isEntity && entityName != ""):
			var templateAnimation : AnimatedSprite2D = AnimationManager.get(entityName + "TemplateSprite");
			#if entityName == "checkpoint":
			#	print(templateAnimation.animation);
			image.texture = templateAnimation.sprite_frames.get_frame_texture(templateAnimation.animation, 0);
		else:
			image.texture = tileSet.get_source(thisItemID).texture;
	

func change_brush_object() -> void:
	AudioManager.play_UI_effect("UISelection");
	tilebar.toolManager.update_brush_object(thisItemID);
