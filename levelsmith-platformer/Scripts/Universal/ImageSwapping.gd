extends Node

# Reference to the asset manager
@export var assetManager : AssetManager;
# References to images
var imageToReplace : Image;
var imageNameToReplace : String;
# References to nodes for previewing the image within the asset manager
@export var imagePreview : Panel;
@export var imagePreviewTexture : TextureRect;
# Reference to the main tile map
var mainTileMap : TileMapLayer;
# All types of tiles
var tileTypes : Array[String] = ["Solid", "Hazard", "OneWay", "Ice", "Sticky", "Bounce", "Death", "Slope" ];
# All types of props
var propTypes : Array[String] = ["Prop1", "Prop2", "Prop3", "Prop4", "Prop5", "Prop6"];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mainTileMap = assetManager.mainTileMap;

## Refresh all images in game
func refresh_images() -> void:
	# Change all tiles to their textures
	for i in range(tileTypes.size()):
		var tileImage : Image = assetManager.find_image_in_folder(FileSearch.find_directory_by_name(tileTypes[i]));
		var defaultTileImage : Image = load(assetManager.defaultsFilePath + "Tiles/" + tileTypes[i] + ".png").get_image();
		change_tile_texture(i, tileImage if tileImage else defaultTileImage, mainTileMap);
	# Change all props to their textures
	for i in range(propTypes.size()):
		var propImage : Image = assetManager.find_image_in_folder(FileSearch.find_directory_by_name(propTypes[i]));
		var defaultPropImage : Image = load(assetManager.defaultsFilePath + "Props/" + propTypes[i] + ".png").get_image();
		change_tile_texture(Global.EntityType.PROP1 + i, propImage if propImage else defaultPropImage, mainTileMap);

## Change the texture of an atlas tile to a new image texture
## sourceID: Source ID of the tile being changed
## newImage: Image being switched to
## tileMap: The tileMap being changed
## NOTE: Only works with images >= 128px x 128px
func change_tile_texture(sourceID: int, newImage: Image, tileMap: TileMapLayer) -> void:
	if (newImage == null):
		return;
	# Create a Texture2D from the image
	var newTexture : Texture2D = ImageTexture.create_from_image(newImage);
	# Set a reference to the tile map's tile set
	var tileSet : TileSet = tileMap.tile_set;
	# Set a reference to the source in the tile set
	var source : TileSetAtlasSource = tileSet.get_source(sourceID) as TileSetAtlasSource;
	# If the source is found, set the texture to the image
	if (source):
		source.texture = newTexture;
		# NOTE: TEMPORARY FIX PT 2
		for frame in range(0, 5):
			await get_tree().process_frame;
		assetManager.editorManager.clear_enemies();

## Replaces the currently previewed image with one chosen via file dialog.
## newImagePath: The file path of the new image replacing the old one.x 
func replace_image(newImagePath: String) -> void:
	var targetFilePath : String = FileSearch.find_directory_by_name(imageNameToReplace);
	var targetDirectory : DirAccess = assetManager.clear_image(imageNameToReplace);
	# If the image is a png, create a copy
	if (newImagePath.get_extension().to_lower() == "png"):
		assetManager.clear_image(imageNameToReplace);
		var image = Image.new();
		image.load(newImagePath);
		assetManager.validate_image(image);
		image.save_png(targetFilePath + "/replacement.png");
		#targetDirectory.copy(newImagePath, targetFilePath + "/replacement.png");
	else:
		PopUpManager.create_error_popup("File type incorrect", "File must be .png format.");
	
	refresh_images();
	var replacementImage : Image = assetManager.find_image_in_folder(targetFilePath);
	if (replacementImage):
		imagePreviewTexture.texture = ImageTexture.create_from_image(replacementImage);
	else:
		imagePreviewTexture.texture = ImageTexture.create_from_image(assetManager.find_image(imageNameToReplace + ".png", "res://Assets/Defaults"));

## Clears the image in a given folder and replaces it with a default
func reset_image() -> void:
	assetManager.clear_image(imageNameToReplace);
	refresh_images();
	imagePreviewTexture.texture = ImageTexture.create_from_image(get_default_image(imageNameToReplace));

func get_default_image(imageName : String) -> Image:
	var defaultImage : Image = Image.new();
	if ("Prop" in imageName):
		defaultImage = load("res://Assets/Defaults/Assets/Sprites/Props/" + imageName + ".png").get_image();
	elif ("Goal" in imageName):
		defaultImage = load("res://Assets/Defaults/Assets/Sprites/Entities/" + imageName + ".png").get_image();
	else:
		defaultImage = load("res://Assets/Defaults/Assets/Sprites/Tiles/" + imageName + ".png").get_image();
	return defaultImage;
