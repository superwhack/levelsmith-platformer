extends Node2D

var filePath: String;

# References to images
var newImage: Image;
var imageToReplace: Image;

# References to audio
var newAudio: AudioStream;
var audioToReplace: AudioStream;

# References to both tile maps
@export var mainTileSet: TileMapLayer;
@export var previewTileSet: TileMapLayer;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func find_image(imageName: String) -> Image:
	return null;

func find_image_in_folder(folderName: String) -> Image:
	return null;

func validate_image(image: Image) -> Image:
	return null;

#func get_animation_from_folder(folderName: String) -> Array[Image]:
	#return;

func file_count_in_folder(folderName: String) -> int:
	return -1;

func refresh_assets() -> void:
	pass;

func replace_image(imageToReplace: Image, newImage: Image) -> void:
	pass;

func replace_audio(audioToReplace: AudioStream, newAudio: AudioStream) -> void:
	pass;

func return_to_default_image(imageName: String) -> void:
	pass;

func return_to_default_audio(audioName: String) -> void:
	pass;

func return_all_to_default(categoryName: String) -> void:
	pass;
