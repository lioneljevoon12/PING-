extends Node

# Signal definitions
signal settings_changed()
signal joystick_size_changed(scale_factor: float)
signal text_size_changed(scale_factor: float)
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

var text_size: String = "normal" # "small", "normal", "large"

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
	_setup_global_hooks()

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
	text_size_changed.emit(get_text_scale())

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
		_joy_dirty = true
		joystick_size_changed.emit(get_joystick_scale())
		save_settings()
		_sweep()

func set_text_size(size_str: String) -> void:
	if size_str in ["small", "normal", "large"]:
		text_size = size_str
		_text_dirty = true
		text_size_changed.emit(get_text_scale())
		save_settings()
		_sweep()

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

func get_text_scale() -> float:
	match text_size:
		"small": return 0.9
		"large": return 1.15
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
		"fps_limit": fps_limit,
		"text_size": text_size
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
		if "text_size" in d and str(d["text_size"]) in ["small", "normal", "large"]: text_size = str(d["text_size"])

# --- HOOK GLOBAL: SFX bus, getar tombol, ukuran analog, ukuran teks ---
var _text_dirty: bool = false
var _joy_dirty: bool = false
var _joy_scene_id: int = 0
const JOY_RADIUS_PROPS := { "dpad_radius": 55.0, "joystick_max_radius": 58.0, "joystick_max_dist": 65.0 }
const TEXT_PROPS_BASIC := ["font_size"]
const TEXT_PROPS_RICH := ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]

func _setup_global_hooks() -> void:
	get_tree().node_added.connect(_on_node_added)
	var t = Timer.new()
	t.wait_time = 0.25
	t.autostart = true
	t.timeout.connect(_sweep)
	add_child(t)

func _on_node_added(n: Node) -> void:
	# Semua suara efek level dialihkan ke bus "SFX" agar slider Efek Suara berfungsi
	if n is AudioStreamPlayer and n != bgm_player and n != sfx_player:
		if (n as AudioStreamPlayer).bus == &"Master":
			(n as AudioStreamPlayer).bus = &"SFX"
	# Getar ringan pada setiap tombol (bila Getar Layar aktif)
	elif n is BaseButton:
		var b = n as BaseButton
		if not b.pressed.is_connected(_on_button_tap):
			b.pressed.connect(_on_button_tap)

func _on_button_tap() -> void:
	vibrate(18)

func _sweep() -> void:
	var tree = get_tree()
	if tree == null or tree.current_scene == null:
		return
	var scene = tree.current_scene
	var ts = get_text_scale()
	var js = get_joystick_scale()
	var scene_changed = (scene.get_instance_id() != _joy_scene_id)
	_joy_scene_id = scene.get_instance_id()
	var need_text = (ts != 1.0) or _text_dirty
	var need_joy = (js != 1.0) or _joy_dirty or (scene_changed and js != 1.0)
	if not need_text and not need_joy:
		return
	if need_joy:
		for prop in JOY_RADIUS_PROPS:
			if prop in scene:
				scene.set(prop, float(JOY_RADIUS_PROPS[prop]) * js)
	_walk(tree.root, ts, js, need_text, need_joy)
	_text_dirty = false
	_joy_dirty = false

func _walk(n: Node, ts: float, js: float, do_text: bool, do_joy: bool) -> void:
	if do_text and n is Control:
		if n is RichTextLabel:
			for p in TEXT_PROPS_RICH:
				_scale_font(n, p, ts)
		elif n is Label or n is Button or n is LineEdit:
			_scale_font(n, "font_size", ts)
	if do_joy and n is TextureRect:
		var tr = n as TextureRect
		if tr.texture and (tr.texture.resource_path.contains("joystick_circle_pad") or tr.texture.resource_path.contains("joystick_circle_nub")):
			if not tr.has_meta("_joy_base_scale"):
				tr.set_meta("_joy_base_scale", tr.scale)
			var bs: Vector2 = tr.get_meta("_joy_base_scale")
			tr.pivot_offset = tr.size / 2.0
			tr.scale = bs * js
	for c in n.get_children():
		_walk(c, ts, js, do_text, do_joy)

func _scale_font(n: Control, prop: String, s: float) -> void:
	var key_b = "_fs_b_" + prop
	var key_a = "_fs_a_" + prop
	var cur = n.get_theme_font_size(prop)
	if cur <= 0:
		return
	var base = cur
	if n.has_meta(key_b):
		base = int(n.get_meta(key_b))
		# Kode level mengubah ukuran sendiri -> anggap itu ukuran dasar yang baru
		if cur != int(n.get_meta(key_a)):
			base = cur
	elif s == 1.0:
		return
	var target = max(8, int(round(float(base) * s)))
	n.set_meta(key_b, base)
	n.set_meta(key_a, target)
	if target != cur or not n.has_theme_font_size_override(prop):
		n.add_theme_font_size_override(prop, target)
