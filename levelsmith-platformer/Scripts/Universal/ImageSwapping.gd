extends Node

@export var assetManager : AssetManager;

var filePath : String;

# References to images
var imageToReplace : Image;
var imageNameToReplace : String;

# References to both tile maps
@export var mainTileMap : TileMapLayer;
@export var imagePreview : Panel;
@export var imagePreviewTexture : TextureRect;

var firstImageSelected : AssetItem = null;

# All types of tiles
var tileTypes : Array[String] = ["Solid", "Death","OneWay","Ice", "Sticky", "Bounce", "Slope" ];

# All types of props
var propTypes : Array[String] = ["Prop1", "Prop2", "Prop3", "Prop4", "Prop5"];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.levelCreated.connect(refresh_images);
	# Refresh all assets
	refresh_images();
	ImportExportManager.levelImported.connect(refresh_images);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

## Refresh all images in game
func refresh_images() -> void:
	# Change all tiles to their textures
	for i in range(tileTypes.size()):
		var tileImage : Image = assetManager.find_image_in_folder(FileSearch.find_directory_by_name(tileTypes[i]));
		var defaultTileImage : Image = assetManager.find_image(tileTypes[i] + ".png", "res://Assets/Defaults");
		change_tile_texture(i, tileImage if tileImage else defaultTileImage, mainTileMap);
	# Change all props to their textures
	for i in range(propTypes.size()):
		var propImage : Image = assetManager.find_image_in_folder(FileSearch.find_directory_by_name(propTypes[i]));
		var defaultPropImage : Image = assetManager.find_image(propTypes[i] + ".png", "res://Assets/Defaults");
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
		targetDirectory.copy(newImagePath, targetFilePath + "/replacement.png");
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
	imagePreviewTexture.texture = ImageTexture.create_from_image(assetManager.find_image(imageNameToReplace + ".png", "res://Assets/Defaults"));
