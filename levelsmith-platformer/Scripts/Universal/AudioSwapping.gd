extends Node

# Reference to the asset manager
@export var assetManager : AssetManager;

var audioNameToReplace : String;

# All types of audio
var audioTypes : Array[String] = ["BounceTile", "CoinPickup", "EnemyDie", "Shoot", "Hurt", "PlayerDie", "Jump", "Victory", "WalkingGeneral", "WalkingIce", "WalkingSlime", "LevelMusic"];

var loadedPreviewAudio : AudioStream;
var previewAudioPlayer : AudioStreamPlayer;

@export var playButton : Button;
@export var stopButton : Button;
var isPlayingPreview : bool = false;

@export var audioTimeline : HSlider;

var audioLength : float;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	previewAudioPlayer = AudioStreamPlayer.new();
	add_child(previewAudioPlayer);
	playButton.pressed.connect(play_preview_audio);
	stopButton.pressed.connect(preview_audio_finished);
	previewAudioPlayer.finished.connect(preview_audio_finished);
	audioTimeline.drag_started.connect(drag_started);
	audioTimeline.drag_ended.connect(drag_ended);

func _process(delta: float) -> void:
	if (previewAudioPlayer.playing):
		audioTimeline.value = previewAudioPlayer.get_playback_position();

## Replaces the currently previewed audio  with one chosen via file dialog.
## newAudioPath: The file path of the new audio replacing the old one.x 
func replace_audio(newAudioPath: String) -> void:
	var targetFilePath : String = FileSearch.find_directory_by_name(audioNameToReplace);
	var targetDirectory : DirAccess = assetManager.clear_files(audioNameToReplace);
	# If the audio is mp3 or wav, create a copy
	if (newAudioPath.get_extension().to_lower() == "mp3"):
		var audio = AudioStreamMP3.new();
		audio = AudioStreamMP3.load_from_file(newAudioPath);
		if (!audio):
			audio = load_mp3_manually(newAudioPath);
			PopUpManager.create_error_popup("Manually Loading", "Attempting to manually load a file");
			if (!audio):
				PopUpManager.create_error_popup("Manual Loading Failed", "Failed to manually load file, reverting to default");
		save_mp3_stream(audio, targetFilePath + "/" + audioNameToReplace + ".mp3");
	elif (newAudioPath.get_extension().to_lower() == "wav"):
		var audio = AudioStreamWAV.new();
		audio = AudioStreamWAV.load_from_file(newAudioPath);
		audio.save_to_wav(targetFilePath + "/" + audioNameToReplace + ".wav")
	else:
		PopUpManager.create_error_popup("File type incorrect", "File must be .mp3 or .wav format.");
	load_preview_audio();

	
## Clears the audio in a given folder and replaces it with a default
func reset_audio() -> void:
	AudioManager.play_UI_effect("UISelection");
	assetManager.clear_files(audioNameToReplace);
	load_preview_audio();

func save_mp3_stream(stream : AudioStreamMP3, filePath : String) -> void:
	var bytes : PackedByteArray = stream.data;
	
	if (bytes.is_empty()):
		print("AudioStreamMP3 has no data");
		return;
	
	var file = FileAccess.open(filePath, FileAccess.WRITE);
	
	if (file):
		file.store_buffer(bytes);
		file.close();

func load_mp3_manually(filePath : String) -> AudioStreamMP3:
	var file = FileAccess.open(filePath, FileAccess.READ)
	if (!file):
		print("Failed to open file: ", filePath);
		return null
		
	var buffer := file.get_buffer(file.get_length())
	file.close()
	
	# Check if the file starts with the ID3v2 tag identifier "ID3"
	if (buffer.size() > 10 && buffer[0] == 0x49 && buffer[1] == 0x44 && buffer[2] == 0x33):
		
		# ID3v2 headers store the tag size in bytes 6, 7, 8, and 9 
		# using a 7-bit syncsafe integer format.
		var b1 = buffer[6] & 0x7F
		var b2 = buffer[7] & 0x7F
		var b3 = buffer[8] & 0x7F
		var b4 = buffer[9] & 0x7F
		
		# Calculate total metadata size (plus 10 bytes for the header itself)
		var tag_size = (b1 << 21) | (b2 << 14) | (b3 << 7) | b4
		var audio_start_index = tag_size + 10
		
		if audio_start_index < buffer.size():
			# Slice away the metadata, leaving only clean audio data
			buffer = buffer.slice(audio_start_index)
		else:
			print("Error: Metadata tag size exceeds file size.")
			return null

	# Feed the cleaned buffer straight into Godot's MP3 stream
	var new_stream := AudioStreamMP3.new()
	new_stream.data = buffer
	return new_stream

func preview_audio_finished() -> void:
	if (loadedPreviewAudio):
		previewAudioPlayer.play()
		previewAudioPlayer.stream_paused = true;
		audioTimeline.value = 0;

func play_preview_audio() -> void:
	previewAudioPlayer.stream_paused = !previewAudioPlayer.stream_paused;

func load_preview_audio() -> void:
	var audioPath = AudioManager.audioLibraryPath + audioNameToReplace + "/" + audioNameToReplace;
	if (FileAccess.file_exists(audioPath + ".mp3")):
		loadedPreviewAudio = AudioStreamMP3.new();
		loadedPreviewAudio = AudioStreamMP3.load_from_file(audioPath + ".mp3");
	elif (FileAccess.file_exists(audioPath + ".wav")):
		loadedPreviewAudio = AudioStreamWAV.new();
		loadedPreviewAudio = AudioStreamWAV.load_from_file(audioPath + ".wav");
	else:
		loadedPreviewAudio = AudioStreamWAV.new()
		loadedPreviewAudio = AudioStreamWAV.load_from_file(AudioManager.BACKUP_AUDIO_LIBRARY_PATH + audioNameToReplace + "/" + audioNameToReplace + ".wav");
	previewAudioPlayer.stream = loadedPreviewAudio;
	preview_audio_finished();
	audioLength = loadedPreviewAudio.get_length()
	audioTimeline.max_value = audioLength;

func drag_started():
	previewAudioPlayer.stream_paused = true;

func drag_ended(value_changed : bool):
	if (value_changed):
		previewAudioPlayer.play(audioTimeline.value);
		previewAudioPlayer.stream_paused = true;
