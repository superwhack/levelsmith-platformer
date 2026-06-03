extends Node

var masterVolume := 1.0;
var musicVolume := 1.0;
var SFXVolume := 1.0;

const audioPlayerCount := 6;
# NOTE: This would be a folder alongside the other assets in the user's local directory, it needs to be changed
const audioLibraryPath := "res://Assets/Audio/";
const UIAudioLibraryPath := "res://Assets/Audio/";
var audioLibrary : Dictionary;

var musicPlayer : AudioStreamPlayer;
var availablePlayers : Array[AudioStreamPlayer];
var inusePlayers : Array[AudioStreamPlayer]
var queue : Array[String];

func _ready() -> void:
	musicPlayer = AudioStreamPlayer.new();
	add_child(musicPlayer);
	musicPlayer.finished.connect(music_loop.bind(musicPlayer));
	musicPlayer.bus = "master";
	
	# Loop through and create every potential audioPlayer for use with UI and in game
	for i in audioPlayerCount:
		var audioPlayer = AudioStreamPlayer.new();
		add_child(audioPlayer);
		availablePlayers.append(audioPlayer);
		audioPlayer.finished.connect(audio_finished.bind(audioPlayer));
		audioPlayer.bus = "master";

func music_loop(player: AudioStreamPlayer) -> void:
	player.play();
func audio_finished(player: AudioStreamPlayer) -> void:
	availablePlayers.append(player);
	inusePlayers.erase(player);
func play_music(musicName: String) -> void:
	musicPlayer.stop();
	musicPlayer.stream = load(musicName);


func play_effect(effectName: String, isUI: bool = false) -> void:
	queue.append(effectName);

## Reset and stop all audio
func reset_audio() -> void:
	for i in inusePlayers.size():
		inusePlayers[i].stop();
		availablePlayers.append(inusePlayers[i]);
	inusePlayers.clear();
	musicPlayer.stop();

## If there are any current sounds in the queue and any avaliable players, start playing the sound.
## delta: unused
func _process(delta: float) -> void:
	if !queue.is_empty() && !availablePlayers.is_empty():
		availablePlayers[0].stream = load(queue.pop_front());
		availablePlayers[0].play;
		availablePlayers.pop_front();
