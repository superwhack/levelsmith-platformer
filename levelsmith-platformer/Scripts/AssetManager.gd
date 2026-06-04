extends Node2D

var filePath: String = "user://Assets";

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
	find_image_in_folder("Tile");


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func find_image(imageName: String) -> Image:
	return null;

## Finds and loads the first image found in given folder
## folderName: Name of the folder to search in
## returns: Image loaded if it is found
func find_image_in_folder(folderName: String) -> Image:
	# Opens the folder at the given folderName path
	var dir = DirAccess.open(filePath + "/" + folderName);
	# If a folder was sucessfully opened
	if (dir):
		# Initialize file stream
		dir.list_dir_begin();
		# Get the image name in the folder
		var imageName: String = dir.get_next();
		# If there is no image in the folder, print error
		if (imageName == ""):
			print("No file found");
			return null;
		else:
			# Initialize an image
			var image: Image = Image.new();
			# Load the image based on it's file path
			image.load(filePath + "/" + folderName + "/" + imageName);
			# Close file stream
			dir.list_dir_end();
			# Return loaded image
			return image;
	else:
		print("Could not open file path");
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
