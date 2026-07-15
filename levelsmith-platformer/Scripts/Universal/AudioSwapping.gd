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
		save_mp3_stream(audio, targetFilePath + "/" + audioNameToReplace + ".mp3");
	elif (newAudioPath.get_extension().to_lower() == "wav"):
		var audio = AudioStreamWAV.new();
		audio = AudioStreamWAV.load_from_file(newAudioPath);
		audio.save_to_wav(targetFilePath + "/" + audioNameToReplace + ".wav")
	else:
		PopUpManager.create_error_popup("File type incorrect", "File must be .mp3 or .wav format.");

	
## Clears the audio in a given folder and replaces it with a default
func reset_audio() -> void:
	AudioManager.play_UI_effect("UISelection");
	assetManager.clear_files(audioNameToReplace);

func save_mp3_stream(stream : AudioStreamMP3, filePath : String) -> void:
	var bytes : PackedByteArray = stream.data;
	
	if (bytes.is_empty()):
		print("AudioStreamMP3 has no data");
		return;
	
	var file = FileAccess.open(filePath, FileAccess.WRITE);
	
	if (file):
		file.store_buffer(bytes);
		file.close();

func preview_audio_finished() -> void:
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
		loadedPreviewAudio = AudioStreamWAV.load_from_file(audioPath + ".mp3");
	else:
		loadedPreviewAudio = AudioStreamWAV.new()
		loadedPreviewAudio = AudioStreamWAV.load_from_file(AudioManager.BACKUP_AUDIO_LIBRARY_PATH + audioNameToReplace + "/" + audioNameToReplace + ".wav");
	previewAudioPlayer.stream = loadedPreviewAudio;
	preview_audio_finished();
	audioLength = loadedPreviewAudio.get_length()
	audioTimeline.max_value = audioLength;
