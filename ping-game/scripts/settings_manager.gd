extends Node

# Signal definitions
signal settings_changed()
signal joystick_size_changed(scale_factor: float)
signal bgm_volume_changed(volume: float, muted: bool)
signal sfx_volume_changed(volume: float, muted: bool)

# File path
const SETTINGS_PATH: String = "user://settings.json"

# State variables
var bgm_volume: float = 0.8 # 0.0 to 1.0
var bgm_muted: bool = false

var sfx_volume: float = 0.9 # 0.0 to 1.0
var sfx_muted: bool = false

var joystick_size: String = "normal" # "small", "normal", "large"
var haptic_enabled: bool = true

var fps_limit: int = 60 # 30 or 60

# Audio Players
var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_buses()
	_create_audio_players()
	load_settings()
	apply_all_settings()
	_start_procedural_bgm()

func _setup_audio_buses() -> void:
	# Ensure "Music" bus exists
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var music_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_idx, "Music")
		AudioServer.set_bus_send(music_idx, "Master")
		
	# Ensure "SFX" bus exists
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var sfx_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")

func _create_audio_players() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "GlobalBGMPlayer"
	bgm_player.bus = "Music"
	add_child(bgm_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "GlobalSFXPlayer"
	sfx_player.bus = "SFX"
	add_child(sfx_player)

func apply_all_settings() -> void:
	# FPS Target
	Engine.max_fps = fps_limit
	
	# Apply Audio
	_apply_bus_volume("Music", bgm_volume, bgm_muted)
	_apply_bus_volume("SFX", sfx_volume, sfx_muted)
	
	settings_changed.emit()
	joystick_size_changed.emit(get_joystick_scale())

func _apply_bus_volume(bus_name: String, volume_linear: float, muted: bool) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var is_mute = muted or volume_linear <= 0.005
	AudioServer.set_bus_mute(idx, is_mute)
	if not is_mute:
		# Convert linear 0.0 - 1.0 to dB
		var db = linear_to_db(volume_linear)
		AudioServer.set_bus_volume_db(idx, db)

# --- SETTERS ---

func set_bgm_volume(val: float) -> void:
	bgm_volume = clamp(val, 0.0, 1.0)
	_apply_bus_volume("Music", bgm_volume, bgm_muted)
	bgm_volume_changed.emit(bgm_volume, bgm_muted)
	save_settings()

func set_bgm_muted(muted: bool) -> void:
	bgm_muted = muted
	_apply_bus_volume("Music", bgm_volume, bgm_muted)
	bgm_volume_changed.emit(bgm_volume, bgm_muted)
	save_settings()

func set_sfx_volume(val: float) -> void:
	sfx_volume = clamp(val, 0.0, 1.0)
	_apply_bus_volume("SFX", sfx_volume, sfx_muted)
	sfx_volume_changed.emit(sfx_volume, sfx_muted)
	save_settings()

func set_sfx_muted(muted: bool) -> void:
	sfx_muted = muted
	_apply_bus_volume("SFX", sfx_volume, sfx_muted)
	sfx_volume_changed.emit(sfx_volume, sfx_muted)
	save_settings()

func set_joystick_size(size_str: String) -> void:
	if size_str in ["small", "normal", "large"]:
		joystick_size = size_str
		joystick_size_changed.emit(get_joystick_scale())
		save_settings()

func set_haptic_enabled(enabled: bool) -> void:
	haptic_enabled = enabled
	save_settings()

func set_fps_limit(fps: int) -> void:
	if fps == 30 or fps == 60:
		fps_limit = fps
		Engine.max_fps = fps_limit
		save_settings()

# --- GETTERS & UTILITIES ---

func get_joystick_scale() -> float:
	match joystick_size:
		"small": return 0.8
		"large": return 1.25
		_: return 1.0

func vibrate(duration_ms: int = 40) -> void:
	if not haptic_enabled:
		return
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(duration_ms)

func play_sfx(freq: float = 659.25, duration: float = 0.08, volume_scale: float = 0.3) -> void:
	if sfx_muted or sfx_volume <= 0.005:
		return
	var sample_rate = 44100
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = 1.0 - (float(i) / float(num_samples))
		var val = sin(2.0 * PI * freq * t) * env * volume_scale
		var sample_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_val)
		
	stream.data = data
	sfx_player.stream = stream
	sfx_player.play()

# --- PROCEDURAL BGM LOOP ---
# Generates a soft, pleasant lofi-style ambient chord loop for PING!
func _start_procedural_bgm() -> void:
	var sample_rate = 22050
	var chord_duration = 2.0 # 2 seconds per chord
	# Chords: Cmaj7 (C4, E4, G4, B4), Am7 (A3, C4, E4, G4), Fmaj7 (F3, A3, C4, E4), G7 (G3, B3, D4, F4)
	var chord_freqs = [
		[261.63, 329.63, 392.00, 493.88], # Cmaj7
		[220.00, 261.63, 329.63, 392.00], # Am7
		[174.61, 220.00, 261.63, 329.63], # Fmaj7
		[196.00, 246.94, 293.66, 349.23]  # G7
	]
	
	var total_duration = chord_duration * chord_freqs.size()
	var total_samples = int(sample_rate * total_duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var global_t = float(i) / float(sample_rate)
		var chord_idx = int(global_t / chord_duration) % chord_freqs.size()
		var local_t = fmod(global_t, chord_duration)
		
		# Gentle envelope
		var attack = min(local_t / 0.15, 1.0)
		var decay = 1.0 - (local_t / chord_duration) * 0.4
		var env = attack * decay * 0.08
		
		var sample_sum = 0.0
		var freqs = chord_freqs[chord_idx]
		for f in freqs:
			sample_sum += sin(2.0 * PI * f * local_t)
		sample_sum /= freqs.size()
		
		var final_val = sample_sum * env
		var sample_val = int(clamp(final_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_val)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	stream.data = data
	
	bgm_player.stream = stream
	bgm_player.play()

# --- SAVE & LOAD PERSISTENCE ---

func save_settings() -> void:
	var dict = {
		"bgm_volume": bgm_volume,
		"bgm_muted": bgm_muted,
		"sfx_volume": sfx_volume,
		"sfx_muted": sfx_muted,
		"joystick_size": joystick_size,
		"haptic_enabled": haptic_enabled,
		"fps_limit": fps_limit
	}
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(dict, "\t"))
		f.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings()
		return
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not f:
		return
	var text = f.get_as_text()
	f.close()
	
	var json = JSON.new()
	if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
		var d = json.data
		if "bgm_volume" in d: bgm_volume = clamp(float(d["bgm_volume"]), 0.0, 1.0)
		if "bgm_muted" in d: bgm_muted = bool(d["bgm_muted"])
		if "sfx_volume" in d: sfx_volume = clamp(float(d["sfx_volume"]), 0.0, 1.0)
		if "sfx_muted" in d: sfx_muted = bool(d["sfx_muted"])
		if "joystick_size" in d: joystick_size = str(d["joystick_size"])
		if "haptic_enabled" in d: haptic_enabled = bool(d["haptic_enabled"])
		if "fps_limit" in d: fps_limit = int(d["fps_limit"])
