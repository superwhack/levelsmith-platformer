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
	#find_image_in_folder("Tile");
	find_image("Dodo.png");
	print(find_directory_by_name("Other4"))
	pass;

## Finds an image by its name
## imageName: Name of the image
## returns: Loaded image
func find_image(imageName: String) -> Image:
	# Get the path to the image
	var imagePath = find_file_by_name(imageName);
	# If the path exists
	if (imagePath):
		# Create and load an image from the path
		var image = Image.new();
		image.load(imagePath);
		# Return the loaded image
		return image;
	# If the path does not exist, print error
	else:
		print("No file found");
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
	#var dir = DirAccess.open()
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

## Recursively searches directories for a file of a specific name
## targetFileName: The name of the target file
## currentDirectory: The file path currently being checked
## returns: File path to the file with that name
func find_file_by_name(targetFileName: String, currentDirectory: String = filePath) -> String:
	# Opens the folder at the given currentDirectory path
	var dir = DirAccess.open(currentDirectory);
	# If the directory opened successfully
	if (dir):
		# Initialize the file stream
		dir.list_dir_begin();
		# Set the current file name to the next file in the directory
		var currentFileName = dir.get_next();
		# Loop if the current name exists
		while (currentFileName != ""):
			# Instantiate a variable to represent the full path currently being accessed
			var fullPath = currentDirectory + "/" + currentFileName;
			# If the current item is a directory
			if (dir.current_is_dir()):
				# Call this function on the directory currently being accessed
				var result = find_file_by_name(targetFileName, fullPath);
				# If the result is something, return it
				if (result != ""):
					return result;
			# If the current item is not a directory
			else:
				# If the current file being accessed is the correct name, return the full path to it
				if (currentFileName == targetFileName):
					return fullPath;
			# set the current file name to the next file
			currentFileName = dir.get_next();
	return "";

## Recursively finds the path to a specific directory based on its name
## targetDirectoryName: Name of the target directory
## currentDirectory: Path to the directory currently being checked
## returns: Path to the directory
func find_directory_by_name(targetDirectoryName: String, currentDirectory: String = filePath) -> String:
	# Opens the directory at the currentDirectory path
	var dir = DirAccess.open(currentDirectory);
	# If there is a directory at that path
	if (dir):
		# Initialize the file stream
		dir.list_dir_begin();
		# Set the currentFileName to the next item being checked
		var currentFileName = dir.get_next();
		# Loop as long as the currentFileName is not empty
		while (currentFileName != ""):
			# Track the full path to the file being checked
			var fullPath = currentDirectory + "/" + currentFileName;
			# If the current item being checked is a folder
			if (dir.current_is_dir()):
				# If the folder name is equal to the target name, return the path
				if (currentFileName == targetDirectoryName):
					return fullPath;
				# If the folder name is not the target
				else:
					# Call this function with the new path
					var result = find_directory_by_name(targetDirectoryName, fullPath);
					if (result != ""):
						return result;
			# Update the currentFileName to be the next file
			currentFileName = dir.get_next();
	return "";
