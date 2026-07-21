extends Node

# The root file path of the assets folder
var filePath : String = "";

## Gets the amount of files within a folder
## folderName: Name of the folder to check
## returns: The amount of files in the folder
func file_count_in_folder(folderName: String) -> int:
	# Get the path to the folder
	var pathToFolder : String = find_directory_by_name(folderName);
	# If there is a path to the folder
	if (pathToFolder):
		# Open the directory at the path
		var dir : DirAccess = DirAccess.open(pathToFolder);
		# Store all files in that path in an array
		var allFiles : PackedStringArray = dir.get_files();
		# Return the size of that array
		return allFiles.size();
	# If there is no path to the folder
	else:
		# Print error
		PopUpManager.create_error_popup("Folder not found", "Could not find folder with name " + folderName + ".");
	return -1;

## Gets the amount of files in a folder not including .import or .remap files
## folderPath : Path to the folder being counted
## returns : Number of files within the folder
func get_clean_file_count(folderPath: String) -> int:
	# If there is nothing at the folder path, return 0
	if (!DirAccess.dir_exists_absolute(folderPath)):
		return 0
	# Set the uniqueFiles array based on all of the files with completely unique names
	var files = DirAccess.get_files_at(folderPath)
	var uniqueFiles: Array[String] = []
	for file in files:
		# Strip export artifacts (.remap / .import) to get the true file name
		var cleanName = file
		cleanName = cleanName.replace(".import", "").replace(".remap", "");
		if not uniqueFiles.has(cleanName):
			uniqueFiles.append(cleanName)          
	# Return the size of the array of unique files
	return uniqueFiles.size()

## Recursively finds the path to a specific directory based on its name
## targetDirectoryName: Name of the target directory
## currentDirectory: Path to the directory currently being checked
## returns: Path to the directory
func find_directory_by_name(targetDirectoryName: String, currentDirectory: String = filePath) -> String:
	# Opens the directory at the currentDirectory path
	var dir : DirAccess = DirAccess.open(currentDirectory);
	# If there is a directory at that path
	if (dir):
		# Initialize the file stream
		dir.list_dir_begin();
		# Set the currentFileName to the next item being checked
		var currentFileName : String = dir.get_next();
		# Loop as long as the currentFileName is not empty
		while (currentFileName != ""):
			# Track the full path to the file being checked
			var fullPath : String = currentDirectory + "/" + currentFileName;
			# If the current item being checked is a folder
			if (dir.current_is_dir()):
				# If the folder name is equal to the target name, return the path
				if (currentFileName == targetDirectoryName):
					return fullPath;
				# If the folder name is not the target
				else:
					# Call this function with the new path
					var result : String = find_directory_by_name(targetDirectoryName, fullPath);
					if (result != ""):
						return result;
			# Update the currentFileName to be the next file
			currentFileName = dir.get_next();
	return "";

## Recursively searches directories for a file of a specific name
## targetFileName: The name of the target file
## currentDirectory: The file path currently being checked
## returns: File path to the file with that name
func find_file_by_name(targetFileName: String, currentDirectory: String = filePath) -> String:
	# Opens the folder at the given currentDirectory path
	var dir : DirAccess = DirAccess.open(currentDirectory);
	# If the directory opened successfully
	if (dir):
		# Initialize the file stream
		dir.list_dir_begin();
		# Set the current file name to the next file in the directory
		var currentFileName : String = dir.get_next();
		# Loop if the current name exists
		while (currentFileName != ""):
			# Instantiate a variable to represent the full path currently being accessed
			var fullPath : String = currentDirectory + "/" + currentFileName;
			# If the current item is a directory
			if (dir.current_is_dir()):
				# Call this function on the directory currently being accessed
				var result : String = find_file_by_name(targetFileName, fullPath);
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

## Recursively deletes all content within a given folder
## folderPath : The path that the folder exists at
func delete_folder(folderPath: String) -> void:
	# If there is no folder at the path, return;
	if (not DirAccess.dir_exists_absolute(folderPath)):
		return;
	# If there are any folders within this folder, call this function on that folder
	for dirName in DirAccess.get_directories_at(folderPath):
		delete_folder(str(folderPath + "/" + dirName));
	# If there are any files within this folder, remove those files
	for fileName in DirAccess.get_files_at(folderPath):
		DirAccess.remove_absolute(str(folderPath + "/" + fileName));
	# Remove this folder
	DirAccess.remove_absolute(folderPath);
