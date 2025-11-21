extends Node

const SETTINGS_PATH = "user://audio_settings.cfg"
const MUSIC_BUS_NAME = "Music"

var music_bus_index: int = -1

func _ready() -> void:
	# Get the music bus index
	music_bus_index = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	
	if music_bus_index == -1:
		push_warning("Music bus not found! Creating it...")
		# If the bus doesn't exist, we'll use the master bus
		music_bus_index = 0
	
	# Load saved settings
	load_settings()

func set_music_volume(volume_percent: float) -> void:
	"""Set music volume from 0 to 100"""
	if music_bus_index == -1:
		return
	
	# Convert percentage (0-100) to decibels
	# 0% = -80 dB (essentially muted)
	# 100% = 0 dB (full volume)
	var db: float
	if volume_percent <= 0:
		db = -80
	else:
		# Linear to logarithmic conversion
		db = linear_to_db(volume_percent / 100.0)
	
	AudioServer.set_bus_volume_db(music_bus_index, db)
	
	# Mute if volume is 0
	AudioServer.set_bus_mute(music_bus_index, volume_percent <= 0)

func get_music_volume() -> float:
	"""Get music volume as percentage (0-100)"""
	if music_bus_index == -1:
		return 100.0
	
	if AudioServer.is_bus_mute(music_bus_index):
		return 0.0
	
	var db = AudioServer.get_bus_volume_db(music_bus_index)
	# Convert decibels back to percentage
	return db_to_linear(db) * 100.0

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", get_music_volume())
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	if err == OK:
		var volume = config.get_value("audio", "music_volume", 100.0)
		set_music_volume(volume)
	else:
		# Default to 100% volume
		set_music_volume(100.0)
