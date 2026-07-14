extends Node

# Reference to the asset manager
@export var assetManager : AssetManager;

var audioNameToReplace : String;

# All types of aduio
var audioTypes : Array[String] = ["BounceTile", "CoinPickup", "EnemyDeath", "EnemyShoot", "HazardTile", "PlayerDeath", "PlayerJump", "Victory", "WalkingGeneral", "WalkingIce", "WalkingSlime", "LevelMusic"];


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass;

## Replaces the currently previewed audio  with one chosen via file dialog.
## newAudioPath: The file path of the new audio replacing the old one.x 
func replace_audio(newAudioPath: String) -> void:
	var targetFilePath : String = FileSearch.find_directory_by_name(audioNameToReplace);
	var targetDirectory : DirAccess = assetManager.clear_files(audioNameToReplace);
	# If the audio is mp3 or wav, create a copy
	if (newAudioPath.get_extension().to_lower() == "mp3"):
		var audio = AudioStreamMP3.new();
		audio = AudioStreamMP3.load_from_file(newAudioPath);
		save_mp3_stream(audio, targetFilePath + "/" + audioNameToReplace + ".mp3");
	elif (newAudioPath.get_extension().to_lower() == "wav"):
		var audio = AudioStreamWAV.new();
		audio = AudioStreamWAV.load_from_file(newAudioPath);
		audio.save_to_wav(targetFilePath + "/" + audioNameToReplace + ".wav")
	else:
		PopUpManager.create_error_popup("File type incorrect", "File must be .mp3 or .wav format.");

	
## Clears the audio in a given folder and replaces it with a default
func reset_audio() -> void:
	pass;
	

func save_mp3_stream(stream : AudioStreamMP3, filePath : String) -> void:
	var bytes : PackedByteArray = stream.data;
	
	if (bytes.is_empty()):
		print("AudioStreamMP3 has no data");
		return;
	
	var file = FileAccess.open(filePath, FileAccess.WRITE);
	
	if (file):
		file.store_buffer(bytes);
		file.close();
