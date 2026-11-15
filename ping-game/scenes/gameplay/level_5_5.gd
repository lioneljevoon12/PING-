extends Control

# ==============================================================================
# PING! - LEVEL 5.5 (FINAL): TCP THREE-WAY HANDSHAKE
# Sesuai Proposal (Stage 5) & mockup Figma Level 5.5
# Interaksi: Drag-and-Drop kartu ke slot, atau klik kartu lalu klik slot tujuan.
# ==============================================================================

# --- FONTS ---
var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var font_extrabold = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_semibold = preload("res://art/assets/PING! Assets/Fonts/Nunito-SemiBold.ttf")

# --- TEXTURES ---
var tex_char_idle = preload("res://art/assets/PING! Assets/Character/main-char-router.png")
var tex_vector_heart = preload("res://art/assets/PING! Assets/asset-gameplay/generals/vector-hearts.png")
var tex_dpad_base = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_pad_a.png")
var tex_dpad_knob = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_nub_a.png")
var tex_technician_avatar = preload("res://art/ui-ux/icons/figma_avatar_karakter.png")

# --- DATA 3 TAHAP HANDSHAKE (sesuai level_5_5_config.json) ---
const HS: Array = [
	{ "code": "SYN", "short": "Sinyal Koneksi #1", "mission": "Tahap 1: Komputer CLIENT memulai koneksi dengan mengirim permintaan sinkronisasi (Seq=100) ke SERVER." },
	{ "code": "SYN/ACK", "short": "Respons Koneksi #2", "mission": "Tahap 2: SERVER merespons permintaan dengan mengirim SYN/ACK (Seq=300, Ack=101) kembali ke CLIENT." },
	{ "code": "ACK", "short": "Konfirmasi Akhir #3", "mission": "Tahap 3: CLIENT memberikan konfirmasi terakhir ACK (Seq=101, Ack=301) ke SERVER hingga koneksi siap." },
]

# Background tiga kondisi jalur: merah (default), kuning (proses), hijau (terhubung)
const BG_YELLOW := preload("res://art/assets/PING! Assets/asset-gameplay/stage 5/stage 5/level 5.5/01_backgrounds_clean/bg_level_5_5_yellow_clean.png")
const BG_GREEN := preload("res://art/assets/PING! Assets/asset-gameplay/stage 5/stage 5/level 5.5/01_backgrounds_clean/bg_level_5_5_green_clean.png")

# Posisi jembatan handshake pada background 1920x1080 (untuk hotspot interaktif)
const RACK_RECT_BG := Rect2(650, 372, 620, 134)

# Rintangan (collision) pada background 1920x1080
const OBSTACLES_BG: Array = [
	Rect2(0, 0, 1920, 330),       # dinding belakang
	Rect2(650, 372, 620, 134),    # Jembatan handshake
	Rect2(560, 580, 800, 212),    # Papan status "Final Connection Required"
	Rect2(85, 410, 262, 200),     # meja PC Client
	Rect2(1575, 410, 262, 200),   # meja PC Server
]

# --- ONREADY NODES ---
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer
@onready var background: TextureRect = %Background

# --- GAME STATE ---
var hearts: int = 3
var timer_seconds: float = 180.0
var is_game_active: bool = false
var is_modal_open: bool = false
var is_solved: bool = false

# Status penempatan: layer_num -> true bila sudah benar
var placed: Dictionary = {}
var phase: int = 0   # 0 = Bagian A (Encapsulation), 1 = Bagian B (Decapsulation)
var selected_layer: int = 0
var drag_layer: int = 0
var drag_active: bool = false
var drag_press_pos: Vector2 = Vector2.ZERO
var drag_ghost: Control = null

# --- UI REFS ---
var header_ui: Control
var hearts_rects: Array[TextureRect] = []
var timer_label: Label
var pause_modal_scene = preload("res://scenes/pause_modal.tscn")
var game_dialog_scene = preload("res://scenes/game_dialog.tscn")
var game_dialog_instance = null

var intro_overlay: ColorRect

# Task Modal
var task_modal_overlay: ColorRect
var task_card: PanelContainer
var modal_status_lbl: Label
var card_nodes: Dictionary = {}   # layer_num -> Panel (kartu di kolom kiri)
var slot_nodes: Dictionary = {}   # layer_num -> Panel (slot di kolom kanan)
var slot_pills: Dictionary = {}   # layer_num -> Label (pill hasil penempatan)
var slot_styles: Dictionary = {}  # layer_num -> StyleBoxFlat
var phase_root: Control
var hdr_style: StyleBoxFlat
var modal_title_lbl: Label
var modal_hint_lbl: Label
var viz_style: StyleBoxFlat
var card_states: Dictionary = {}  # idx -> Label status kartu
var lane_counts: Dictionary = {}
var lane_zones: Dictionary = {}
var lane_hints: Dictionary = {}
var progress_lbl: Panel
var progress_text: Label
var viz_title: Label
var viz_formula: Label
var viz_note: Label

# Room
var room_world: Control
var rack_hotspot: Control
var rack_badge: Label
var char_sprite: TextureRect
var char_pos: Vector2 = Vector2(780, 640)
var char_target_pos: Vector2 = Vector2(780, 640)
var char_speed: float = 260.0
var char_placed: bool = false
var last_layout_size: Vector2 = Vector2.ZERO
const CHAR_W := 300.0
const CHAR_H := 165.0
var walk_frames: Array[Texture2D] = []
var walk_idx: float = 0.0
var char_is_moving: bool = false

# Mobile Joystick
var joystick_base: TextureRect
var joystick_knob: TextureRect
var joystick_touch_id: int = -1
var joystick_center: Vector2 = Vector2(110, 610)
var joystick_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	call_deferred("_setup_help_button")
	_setup_room()
	_setup_header_ui()
	_setup_mobile_joystick()
	_setup_task_modal()
	_setup_intro_modal()
	_setup_game_dialog()
	resized.connect(_layout_hotspot)
	_layout_hotspot()

func _process(delta: float) -> void:
	if is_game_active and not is_modal_open:
		_process_timer(delta)
		_process_character_movement(delta)
	if rack_hotspot and is_game_active and not is_solved:
		var t = Time.get_ticks_msec() / 1000.0
		rack_hotspot.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(t * 3.0))

# ==============================================================================
# AUDIO GENERATOR
# ==============================================================================
func _play_synth_sequence(freqs: Array, step_duration: float = 0.08, wave_type: String = "sine") -> void:
	if not audio_player:
		return
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = step_duration * freqs.size() + 0.1
	audio_player.stream = gen
	audio_player.play()
	var playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
	var sample_rate = 22050.0
	for freq in freqs:
		var n_samples = int(step_duration * sample_rate)
		for i in range(n_samples):
			var t = float(i) / sample_rate
			var sample = 0.0
			var phase = fmod(t * freq, 1.0)
			if wave_type == "sine":
				sample = sin(phase * TAU)
			elif wave_type == "square":
				sample = 0.6 if phase < 0.5 else -0.6
			elif wave_type == "triangle":
				sample = 4.0 * abs(phase - 0.5) - 1.0
			var env = 1.0 - (float(i) / float(n_samples))
			playback.push_frame(Vector2(sample * env * 0.4, sample * env * 0.4))

# ==============================================================================
# HELPERS
# ==============================================================================
func _make_box(bg: Color, border: Color, bw: float, radius: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(int(bw))
	sb.set_corner_radius_all(radius)
	return sb

func _make_label(txt: String, font: Font, size: int, col: Color) -> Label:
	var l = Label.new()
	l.text = txt
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# Menempatkan Label melebar mengikuti parent (anchor kiri-kanan) agar tidak membengkak
func _anchor_wide(l: Label, left: float, top: float, right: float, h: float) -> void:
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.anchor_top = 0.0
	l.anchor_bottom = 0.0
	l.offset_left = left
	l.offset_right = -right
	l.offset_top = top
	l.offset_bottom = top + h

# ==============================================================================
# HEADER UI
# ==============================================================================
func _header_panel(pos: Vector2, sz: Vector2) -> PanelContainer:
	var p = PanelContainer.new()
	p.position = pos
	p.size = sz
	p.add_theme_stylebox_override("panel", _make_box(Color("#fdf4eb"), Color("#4a2e2b"), 3, 14))
	header_ui.add_child(p)
	return p

func _setup_header_ui() -> void:
	header_ui = Control.new()
	header_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_ui)

	var back_btn = Button.new()
	back_btn.text = "<"
	back_btn.position = Vector2(30, 20)
	back_btn.size = Vector2(64, 64)
	back_btn.add_theme_stylebox_override("normal", _make_box(Color("#fdf4eb"), Color("#4a2e2b"), 3, 14))
	back_btn.add_theme_font_override("font", font_black)
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UiKit.style_back_button(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	header_ui.add_child(back_btn)

	# Hearts
	var hearts_panel = _header_panel(Vector2(110, 20), Vector2(140, 64))
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	hearts_panel.add_child(hbox)
	hearts_rects.clear()
	for i in range(3):
		var h = TextureRect.new()
		h.texture = tex_vector_heart
		h.custom_minimum_size = Vector2(34, 34)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(h)
		hearts_rects.append(h)
		HeartsStyle.schedule_normalize(hearts_rects)

	# Level badge
	var lvl_panel = _header_panel(Vector2(265, 20), Vector2(80, 64))
	var lvl_vbox = VBoxContainer.new()
	lvl_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lvl_vbox.add_theme_constant_override("separation", -2)
	lvl_panel.add_child(lvl_vbox)
	var l_lbl = _make_label("Level", font_semibold, 10, Color("#7c5e58"))
	l_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_vbox.add_child(l_lbl)
	var n_lbl = _make_label("5.5", font_black, 16, Color("#4a2e2b"))
	n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_vbox.add_child(n_lbl)

	# Timer
	var timer_panel = _header_panel(Vector2(1150, 20), Vector2(170, 64))
	var thbox = HBoxContainer.new()
	thbox.alignment = BoxContainer.ALIGNMENT_CENTER
	thbox.add_theme_constant_override("separation", 10)
	timer_panel.add_child(thbox)
	thbox.add_child(_make_label("⏱", font_black, 22, Color("#4a2e2b")))
	timer_label = _make_label("03:00", font_black, 20, Color("#4a2e2b"))
	thbox.add_child(timer_label)

	# Pause
	var pause_btn = Button.new()
	pause_btn.text = "☰"
	pause_btn.position = Vector2(1335, 20)
	pause_btn.size = Vector2(64, 64)
	pause_btn.add_theme_stylebox_override("normal", _make_box(Color("#fdf4eb"), Color("#4a2e2b"), 3, 14))
	pause_btn.add_theme_font_override("font", font_black)
	pause_btn.add_theme_font_size_override("font_size", 24)
	pause_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pause_btn.pressed.connect(_on_pause_pressed)
	header_ui.add_child(pause_btn)

func _update_hearts_ui() -> void:
	HeartsStyle.refresh(hearts_rects, hearts)

var pause_modal_node: Control = null
var pause_prev_active: bool = false

func _on_back_pressed() -> void:
	_on_pause_pressed()

func _on_pause_pressed() -> void:
	_play_synth_sequence([500.0], 0.08)
	if pause_modal_node and is_instance_valid(pause_modal_node) and pause_modal_node.visible:
		return
	pause_prev_active = is_game_active
	is_game_active = false
	if pause_modal_node == null or not is_instance_valid(pause_modal_node):
		pause_modal_node = pause_modal_scene.instantiate()
		pause_modal_node.z_index = 300
		add_child(pause_modal_node)
		pause_modal_node.resume_requested.connect(func(): is_game_active = pause_prev_active)
	pause_modal_node.open()

func _process_timer(delta: float) -> void:
	timer_seconds -= delta
	if timer_seconds <= 0.0:
		timer_seconds = 0.0
		_update_timer_label()
		_trigger_game_over("Waktu Habis! TCP Three-Way Handshake belum selesai.")
		return
	_update_timer_label()

func _update_timer_label() -> void:
	timer_label.text = "%02d:%02d" % [int(timer_seconds) / 60, int(timer_seconds) % 60]
	timer_label.add_theme_color_override("font_color", Color("#e11d48") if timer_seconds <= 30.0 else Color("#4a2e2b"))

# ==============================================================================
# ROOM (background sudah memuat konsol TCP & UDP, PC Client & Server)
# ==============================================================================
func _setup_room() -> void:
	room_world = Control.new()
	room_world.set_anchors_preset(Control.PRESET_FULL_RECT)
	room_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(room_world)

	# Hotspot interaktif di atas Papan Konveyor Paket (posisi dihitung ulang di _layout_hotspot)
	rack_hotspot = Panel.new()
	var sb = _make_box(Color(1, 1, 1, 0.0), Color("#ef4444"), 4, 24)
	rack_hotspot.add_theme_stylebox_override("panel", sb)
	rack_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	rack_hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	rack_hotspot.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_task_modal()
	)
	room_world.add_child(rack_hotspot)

	rack_badge = _make_label("", font_black, 15, Color("#14532d"))
	rack_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rack_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rack_badge.visible = false
	var sbb = _make_box(Color("#bbf7d0"), Color("#15803d"), 3, 14)
	rack_badge.add_theme_stylebox_override("normal", sbb)
	room_world.add_child(rack_badge)

	# Karakter pemain
	char_sprite = TextureRect.new()
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_load_walk_frames()
	char_sprite.texture = walk_frames[0] if walk_frames.size() > 0 else tex_char_idle
	char_sprite.custom_minimum_size = Vector2(CHAR_W, CHAR_H)
	char_sprite.size = Vector2(CHAR_W, CHAR_H)
	char_sprite.pivot_offset = Vector2(CHAR_W, CHAR_H) * 0.5
	char_sprite.position = char_pos - Vector2(CHAR_W, CHAR_H) * 0.5
	char_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_world.add_child(char_sprite)
	var _pd = get_node_or_null("/root/PlayerData")
	if _pd and _pd.has_method("apply_to_character"):
		_pd.apply_to_character(char_sprite)

# Mengubah koordinat background (1920x1080, mode cover) ke koordinat layar
func _load_walk_frames() -> void:
	walk_frames.clear()
	for i in range(1, 33):
		var wp = "res://art/assets/PING! Assets/Sprite animation/router walk/%d.png" % i
		if ResourceLoader.exists(wp):
			var tex = load(wp)
			if tex is Texture2D:
				walk_frames.append(tex)

func _bg_to_screen(r: Rect2) -> Rect2:
	var s = max(size.x / 1920.0, size.y / 1080.0)
	var off = (size - Vector2(1920.0, 1080.0) * s) * 0.5
	return Rect2(off + r.position * s, r.size * s)

func _layout_hotspot() -> void:
	if not rack_hotspot:
		return
	var r = _bg_to_screen(RACK_RECT_BG)
	rack_hotspot.position = r.position
	rack_hotspot.size = r.size
	rack_hotspot.pivot_offset = r.size * 0.5
	rack_badge.position = r.position + Vector2(r.size.x * 0.5 - 130.0, r.size.y * 0.5 - 22.0)
	rack_badge.size = Vector2(260, 44)

	# Posisi awal karakter (di lantai kiri-bawah rak), dan skala ulang saat ukuran layar berubah
	if not char_placed:
		var start = _bg_to_screen(Rect2(430, 880, 1, 1)).position
		char_pos = start
		char_target_pos = start
		char_placed = true
	elif last_layout_size.x > 0.0 and last_layout_size != size:
		var k = Vector2(size.x / last_layout_size.x, size.y / last_layout_size.y)
		char_pos *= k
		char_target_pos *= k
	last_layout_size = size
	if char_sprite:
		char_sprite.position = char_pos - Vector2(CHAR_W, CHAR_H) * 0.5

# Kotak "kaki" karakter untuk deteksi tabrakan
func _feet_rect(center: Vector2) -> Rect2:
	return Rect2(center.x - 28.0, center.y + CHAR_H * 0.22, 56.0, 20.0)

func _collides_at(center: Vector2) -> bool:
	var feet = _feet_rect(center)
	if feet.position.x < 0.0 or feet.end.x > size.x or feet.end.y > size.y:
		return true
	for ob in OBSTACLES_BG:
		if feet.intersects(_bg_to_screen(ob)):
			return true
	return false

# ==============================================================================
# CHARACTER MOVEMENT & CONTROLS
# ==============================================================================
func _process_character_movement(delta: float) -> void:
	var input_vec = Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vec.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vec.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vec.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vec.y += 1.0
	if joystick_vector.length() > 0.1:
		input_vec = joystick_vector
	if input_vec.length() > 0.05:
		input_vec = input_vec.normalized()
		var step = input_vec * char_speed * delta
		# Gerak per sumbu agar karakter bisa "menyusur" dinding/perabot
		var try_x = char_target_pos + Vector2(step.x, 0.0)
		if not _collides_at(try_x):
			char_target_pos = try_x
		var try_y = char_target_pos + Vector2(0.0, step.y)
		if not _collides_at(try_y):
			char_target_pos = try_y
		char_is_moving = true
		if input_vec.x < -0.1:
			char_sprite.flip_h = true
		elif input_vec.x > 0.1:
			char_sprite.flip_h = false
		if walk_frames.size() > 0:
			walk_idx += delta * 24.0
			char_sprite.texture = walk_frames[int(walk_idx) % walk_frames.size()]
	else:
		char_is_moving = false
		walk_idx = 0.0
		if walk_frames.size() > 0:
			char_sprite.texture = walk_frames[0]
	char_pos = char_pos.lerp(char_target_pos, 15.0 * delta)
	char_sprite.position = char_pos - Vector2(CHAR_W, CHAR_H) * 0.5

func _setup_mobile_joystick() -> void:
	joystick_base = TextureRect.new()
	joystick_base.texture = tex_dpad_base
	joystick_base.size = Vector2(130, 130)
	joystick_base.position = joystick_center - Vector2(65, 65)
	joystick_base.modulate = Color(1, 1, 1, 0.7)
	joystick_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(joystick_base)

	joystick_knob = TextureRect.new()
	joystick_knob.texture = tex_dpad_knob
	joystick_knob.size = Vector2(60, 60)
	joystick_knob.position = joystick_center - Vector2(30, 30)
	joystick_knob.modulate = Color(1, 1, 1, 0.9)
	joystick_knob.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(joystick_knob)

func _input(event: InputEvent) -> void:
	# --- Joystick ---
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(joystick_center) < 90.0:
				joystick_touch_id = event.index
				_update_joystick(event.position)
		elif event.index == joystick_touch_id:
			_reset_joystick()
	elif event is InputEventScreenDrag and event.index == joystick_touch_id:
		_update_joystick(event.position)

	# --- Drag & drop kartu OSI ---
	if drag_layer > 0:
		if event is InputEventMouseMotion:
			var mp = get_global_mouse_position()
			if not drag_active and mp.distance_to(drag_press_pos) > 8.0:
				_begin_drag(drag_layer)
			if drag_active and drag_ghost:
				drag_ghost.position = mp - drag_ghost.size * 0.5
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var layer = drag_layer
			var was_drag = drag_active
			drag_layer = 0
			drag_active = false
			if drag_ghost:
				drag_ghost.queue_free()
				drag_ghost = null
			if was_drag:
				var mp2 = get_global_mouse_position()
				for ln in slot_nodes:
					if (slot_nodes[ln] as Control).get_global_rect().has_point(mp2):
						_try_place(layer, ln)
						return
				# dilepas di luar slot -> hanya batal, tanpa penalti
				if card_nodes.has(layer):
					(card_nodes[layer] as Control).modulate.a = 1.0

func _update_joystick(pos: Vector2) -> void:
	var diff = pos - joystick_center
	var max_r = 50.0 * SettingsManager.get_joystick_scale()
	if diff.length() > max_r:
		diff = diff.normalized() * max_r
	joystick_vector = diff / max_r
	joystick_knob.position = joystick_center + diff - Vector2(30, 30)

func _reset_joystick() -> void:
	joystick_touch_id = -1
	joystick_vector = Vector2.ZERO
	joystick_knob.position = joystick_center - Vector2(30, 30)

# ==============================================================================
# INTRO MODAL (Masalah Saat Ini / Panduan & Contoh Materi / Tujuan Akhir)
# ==============================================================================
func _intro_section(parent: Control, tag_text: String, tag_bg: Color, body_bg: Color, lines: Array, ypos: float, h: float) -> void:
	var box = Panel.new()
	box.position = Vector2(34, ypos)
	box.size = Vector2(672, h)
	box.add_theme_stylebox_override("panel", _make_box(body_bg, Color("#4a2e2b"), 3, 16))
	parent.add_child(box)

	var tag = Label.new()
	tag.text = tag_text
	tag.position = Vector2(14, 10)
	tag.add_theme_font_override("font", font_black)
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", Color("#4a2e2b"))
	tag.add_theme_stylebox_override("normal", _make_box(tag_bg, Color("#4a2e2b"), 2, 8))
	box.add_child(tag)

	var vb = VBoxContainer.new()
	vb.position = Vector2(16, 40)
	vb.size = Vector2(640, h - 46)
	vb.add_theme_constant_override("separation", 4)
	box.add_child(vb)
	for ln in lines:
		var l = _make_label(ln["t"], ln.get("f", font_bold), ln.get("s", 11), ln.get("c", Color("#4a2e2b")))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 640
		vb.add_child(l)

func _setup_intro_modal() -> void:
	intro_overlay = IntroCard.build(self, "Level 5.5 (Final) — TCP Three-Way Handshake", "Selesaikan proses TCP Three-Way Handshake secara berurutan melalui 3 tahap pertukaran paket: SYN, SYN/ACK, lalu ACK.", _on_mulai_pressed, 200, true)

func _on_mulai_pressed() -> void:
	_play_synth_sequence([523.25, 659.25, 783.99], 0.08)
	intro_overlay.visible = false
	_start_after_tutorial()

# ==============================================================================
# TASK MODAL (Konsol Final TCP Three-Way Handshake: SYN -> SYN/ACK -> ACK)
# ==============================================================================
const FLAGS: Array = [
	{ "name": "Paket SYN", "sub": "Synchronize (Seq=100)" },
	{ "name": "Paket SYN/ACK", "sub": "Sync + Ack (Seq=300, Ack=101)" },
	{ "name": "Paket ACK", "sub": "Acknowledge (Seq=101, Ack=301)" },
	{ "name": "Paket FIN (Putus)", "sub": "Finish (Tutup Koneksi)" },
]
const DIRS: Array = [
	{ "name": "CLIENT → SERVER", "sub": "🖥 Client (192.168.5.10) mengirim menuju 🖥 Server (192.168.5.100)" },
	{ "name": "SERVER → CLIENT", "sub": "🖥 Server (192.168.5.100) membalas menuju 🖥 Client (192.168.5.10)" },
]

var hs_step: int = 0
var sel_flag: int = -1
var sel_dir: int = -1
var is_sending: bool = false
var cable_state: int = 0   # 0 = merah (putus), 1 = kuning (proses), 2 = hijau (terhubung)
var diag: Control
var diag_draw: Control
var bridge_chips: Array = []      # tiap elemen: { "panel": Panel, "top": Label, "sub": Label }
var flag_cards: Array = []
var dir_cards: Array = []
var head_a: Label
var head_b: Label
var mission_pill: Panel
var mission_text: Label
var main_panel: Control
var select_lbl: Label
var send_btn: Button
var monitor_box: Control
var summary_box: Control
var summary_stars: Label
var packet_pill: Panel
var recap_overlay: ColorRect

func _hs_flag(step: int) -> int:
	return step          # SYN, SYN/ACK, ACK
func _hs_dir(step: int) -> int:
	return 1 if step == 1 else 0   # 0 = Client -> Server, 1 = Server -> Client

# Pill/label berlatar (Panel + Label anchor penuh agar ukuran label stabil)
func _pill(parent: Control, text: String, bg: Color, border: Color, fsize: int, fcol: Color, x: float, y: float, w: float, h: float, align: int = HORIZONTAL_ALIGNMENT_CENTER, font: Font = null) -> Panel:
	var p = Panel.new()
	p.position = Vector2(x, y)
	p.size = Vector2(w, h)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _make_box(bg, border, 2, int(h / 2.0) if h <= 28.0 else 12))
	parent.add_child(p)
	var l = _make_label(text, font if font else font_black, fsize, fcol)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.offset_left = 8
	l.offset_right = -8
	p.add_child(l)
	return p

func _lane_button(txt: String, bg: Color, border: Color) -> Button:
	var b = Button.new()
	b.text = txt
	b.add_theme_stylebox_override("normal", _make_box(bg, border, 2, 8))
	b.add_theme_stylebox_override("hover", _make_box(bg.lightened(0.25), border, 2, 8))
	b.add_theme_stylebox_override("pressed", _make_box(bg.darkened(0.1), border, 2, 8))
	b.add_theme_font_override("font", font_black)
	b.add_theme_font_size_override("font_size", 10)
	b.add_theme_color_override("font_color", Color("#1f2937"))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

func _setup_task_modal() -> void:
	task_modal_overlay = ColorRect.new()
	task_modal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	task_modal_overlay.color = Color(0, 0, 0, 0.65)
	task_modal_overlay.z_index = 250
	task_modal_overlay.visible = false
	add_child(task_modal_overlay)

	task_card = PanelContainer.new()
	task_card.size = Vector2(1100, 650)
	task_card.position = Vector2((1560 - 1100) / 2.0, 36.0)
	var sb = _make_box(Color("#fdf8ef"), Color("#4a2e2b"), 4, 22)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	task_card.add_theme_stylebox_override("panel", sb)
	task_modal_overlay.add_child(task_card)

	var root = Control.new()
	root.custom_minimum_size = Vector2(1100, 650)
	task_card.add_child(root)

	var hdr_bg = Panel.new()
	hdr_bg.size = Vector2(1100, 58)
	hdr_style = StyleBoxFlat.new()
	hdr_style.bg_color = Color("#43d8df")
	hdr_style.corner_radius_top_left = 20
	hdr_style.corner_radius_top_right = 20
	hdr_bg.add_theme_stylebox_override("panel", hdr_style)
	root.add_child(hdr_bg)

	modal_title_lbl = _make_label("Konsol Final TCP Three-Way Handshake (SYN ➜ SYN/ACK ➜ ACK)", font_black, 18, Color("#1f3a4d"))
	modal_title_lbl.position = Vector2(0, 15)
	modal_title_lbl.size = Vector2(1100, 28)
	modal_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(modal_title_lbl)

	var close_btn = preload("res://scenes/close_button.tscn").instantiate()
	close_btn.position = Vector2(1100 - 52, 10)
	close_btn.custom_minimum_size = Vector2(38, 38)
	close_btn.size = Vector2(38, 38)
	if close_btn.has_signal("pressed"):
		close_btn.pressed.connect(_on_modal_close_x)
	elif close_btn.has_signal("clicked"):
		close_btn.clicked.connect(_on_modal_close_x)
	elif close_btn.has_signal("closed"):
		close_btn.closed.connect(_on_modal_close_x)
	root.add_child(close_btn)

	var body = Panel.new()
	body.position = Vector2(14, 68)
	body.size = Vector2(1072, 536)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", _make_box(Color("#f9f3e7"), Color("#d8cbb0"), 2, 18))
	root.add_child(body)

	_build_diagram(root)

	# Misi tahap
	mission_pill = _pill(root, "", Color("#fff6d6"), Color("#5a3a33"), 12, Color("#4a2e2b"), 30, 236, 1040, 34, HORIZONTAL_ALIGNMENT_LEFT, font_bold)
	mission_text = mission_pill.get_child(0) as Label

	# Panel pilihan (flag + arah)
	main_panel = Panel.new()
	main_panel.position = Vector2(30, 278)
	main_panel.size = Vector2(1040, 318)
	main_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.add_theme_stylebox_override("panel", _make_box(Color("#fffdf8"), Color("#5a3a33"), 3, 18))
	root.add_child(main_panel)

	head_a = _make_label("", font_black, 12, Color("#4a2e2b"))
	head_a.position = Vector2(24, 14)
	head_a.custom_minimum_size = Vector2(480, 18)
	main_panel.add_child(head_a)
	head_b = _make_label("", font_black, 12, Color("#4a2e2b"))
	head_b.position = Vector2(548, 14)
	head_b.custom_minimum_size = Vector2(460, 18)
	main_panel.add_child(head_b)

	flag_cards.clear()
	for i in range(4):
		var c = _choice_card(FLAGS[i]["name"], FLAGS[i]["sub"], Vector2(24 + (i % 2) * 262, 42 + (i / 2) * 72), Vector2(250, 62), true)
		main_panel.add_child(c)
		c.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_on_flag_chosen(i)
		)
		flag_cards.append(c)
	dir_cards.clear()
	for j in range(2):
		var c2 = _choice_card(DIRS[j]["name"], DIRS[j]["sub"], Vector2(548, 42 + j * 72), Vector2(468, 62), false)
		main_panel.add_child(c2)
		c2.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_on_dir_chosen(j)
		)
		dir_cards.append(c2)

	select_lbl = _make_label("", font_bold, 11, Color("#4a2e2b"))
	select_lbl.position = Vector2(24, 196)
	select_lbl.custom_minimum_size = Vector2(700, 18)
	main_panel.add_child(select_lbl)

	var sep = ColorRect.new()
	sep.color = Color("#d8cbb0")
	sep.position = Vector2(24, 232)
	sep.size = Vector2(992, 2)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.add_child(sep)

	send_btn = Button.new()
	send_btn.add_theme_stylebox_override("normal", _make_box(Color("#a7f3d0"), Color("#4a2e2b"), 3, 16))
	send_btn.add_theme_stylebox_override("hover", _make_box(Color("#6ee7b7"), Color("#4a2e2b"), 3, 16))
	send_btn.add_theme_stylebox_override("pressed", _make_box(Color("#6ee7b7"), Color("#4a2e2b"), 3, 16))
	send_btn.add_theme_font_override("font", font_black)
	send_btn.add_theme_font_size_override("font_size", 14)
	send_btn.add_theme_color_override("font_color", Color("#14532d"))
	send_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	send_btn.custom_minimum_size = Vector2(250, 48)
	send_btn.size = Vector2(250, 48)
	send_btn.position = Vector2(766, 248)
	send_btn.pressed.connect(_on_send_pressed)
	main_panel.add_child(send_btn)

	modal_status_lbl = _make_label("", font_extrabold, 12, Color("#7c5843"))
	modal_status_lbl.position = Vector2(30, 612)
	modal_status_lbl.size = Vector2(1040, 24)
	modal_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(modal_status_lbl)

	_build_result_boxes(root)
	_refresh_step_ui()

func _choice_card(title: String, sub: String, pos: Vector2, sz: Vector2, mono: bool) -> Panel:
	var p = Panel.new()
	p.position = pos
	p.size = sz
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.add_theme_stylebox_override("panel", _choice_style(false))
	var t = _make_label(title, font_black, 14, Color("#3b3358"))
	t.clip_text = true
	_anchor_wide(t, 14, 10, 10, 22)
	p.add_child(t)
	var s = _make_label(sub, font_semibold, 10, Color("#6b6475"))
	s.clip_text = true
	_anchor_wide(s, 14, 36, 10, 18)
	p.add_child(s)
	return p

func _choice_style(selected: bool) -> StyleBoxFlat:
	if selected:
		return _make_box(Color("#e6fbfc"), Color("#22d3ee"), 4, 14)
	return _make_box(Color("#f8f4ea"), Color("#5a3a33"), 3, 14)

# Diagram atas: Client -- jembatan 3 tahap -- Server
func _build_diagram(root: Control) -> void:
	diag = Panel.new()
	diag.position = Vector2(30, 78)
	diag.size = Vector2(1040, 150)
	diag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	diag.add_theme_stylebox_override("panel", _make_box(Color("#ffffff"), Color("#5a3a33"), 3, 18))
	root.add_child(diag)

	diag_draw = Control.new()
	diag_draw.size = diag.size
	diag_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	diag_draw.draw.connect(_on_draw_diag)
	diag.add_child(diag_draw)

	_build_pc(diag, Vector2(70, 22), Color("#a2d2ff"), "CLIENT: 192.168.5.10")
	_build_pc(diag, Vector2(800, 22), Color("#a8e6cf"), "SERVER: 192.168.5.100")

	var bridge = Panel.new()
	bridge.position = Vector2(332, 44)
	bridge.size = Vector2(376, 66)
	bridge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bridge.add_theme_stylebox_override("panel", _make_box(Color("#fffdf8"), Color("#5a3a33"), 3, 16))
	diag.add_child(bridge)
	bridge_chips.clear()
	for i in range(3):
		var cp = Panel.new()
		cp.position = Vector2(8 + i * 122, 8)
		cp.size = Vector2(116, 50)
		cp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bridge.add_child(cp)
		var top = _make_label("", font_black, 10, Color("#3b3358"))
		top.clip_text = true
		_anchor_wide(top, 24, 8, 4, 16)
		cp.add_child(top)
		var sub = _make_label("", font_semibold, 8, Color("#5b5566"))
		sub.clip_text = true
		_anchor_wide(sub, 24, 26, 4, 14)
		cp.add_child(sub)
		var dot = Panel.new()
		dot.position = Vector2(7, 17)
		dot.size = Vector2(13, 13)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cp.add_child(dot)
		bridge_chips.append({ "panel": cp, "top": top, "sub": sub, "dot": dot })

	packet_pill = _pill(diag, "DATA", Color("#fff3b0"), Color("#ca8a04"), 8, Color("#4a2e2b"), 236, 80, 46, 20, HORIZONTAL_ALIGNMENT_CENTER, font_black)
	packet_pill.visible = false
	_update_bridge()

func _build_pc(parent: Control, pos: Vector2, screen_col: Color, label: String) -> void:
	var desk = Panel.new()
	desk.position = pos + Vector2(0, 48)
	desk.size = Vector2(170, 70)
	desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desk.add_theme_stylebox_override("panel", _make_box(Color("#dcbc9a"), Color("#5a3a33"), 3, 14))
	parent.add_child(desk)
	var mon = Panel.new()
	mon.position = pos + Vector2(40, 0)
	mon.size = Vector2(90, 58)
	mon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mon.add_theme_stylebox_override("panel", _make_box(screen_col, Color("#5a3a33"), 3, 12))
	parent.add_child(mon)
	var face = _make_label(">‿<", font_black, 18, Color("#1f3a4d"))
	face.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	face.set_anchors_preset(Control.PRESET_FULL_RECT)
	mon.add_child(face)
	_pill(desk, label, Color("#ffffff"), Color("#5a3a33"), 9, Color("#4a2e2b"), 14, 28, 142, 24, HORIZONTAL_ALIGNMENT_CENTER, font_bold)

func _on_draw_diag() -> void:
	var col = Color("#ff6b6b") if cable_state == 0 else (Color("#fbbf24") if cable_state == 1 else Color("#22c55e"))
	for seg in [[236.0, 334.0], [706.0, 804.0]]:
		var x = seg[0]
		while x < seg[1]:
			var x2 = min(x + 16.0, seg[1])
			diag_draw.draw_line(Vector2(x, 90), Vector2(x2, 90), col, 12.0, true)
			x += 21.0 if cable_state == 0 else 16.0

func _update_bridge() -> void:
	for i in range(bridge_chips.size()):
		var ch = bridge_chips[i]
		var p = ch["panel"] as Panel
		var dot = ch["dot"] as Panel
		var h = HS[i]
		if i < hs_step:
			p.add_theme_stylebox_override("panel", _make_box(Color("#a8e6cf"), Color("#15803d"), 2, 10))
			dot.add_theme_stylebox_override("panel", _make_box(Color("#22c55e"), Color("#15803d"), 2, 7))
			(ch["top"] as Label).text = "%d. %s ✓" % [i + 1, h["code"]]
		elif i == hs_step:
			p.add_theme_stylebox_override("panel", _make_box(Color("#ffb5a7"), Color("#5a3a33"), 2, 10))
			dot.add_theme_stylebox_override("panel", _make_box(Color("#ef4444"), Color("#7f1d1d"), 2, 7))
			(ch["top"] as Label).text = "TAHAP %d (?)" % (i + 1)
		else:
			p.add_theme_stylebox_override("panel", _make_box(Color("#e8e0d4"), Color("#8a7a70"), 2, 10))
			dot.add_theme_stylebox_override("panel", _make_box(Color("#9aa5b8"), Color("#5b6477"), 2, 7))
			(ch["top"] as Label).text = "TAHAP %d (?)" % (i + 1)
		(ch["sub"] as Label).text = h["short"]

func _refresh_step_ui() -> void:
	var n = hs_step + 1
	sel_flag = -1
	sel_dir = -1
	head_a.text = "A. PILIH BENDERA PAKET TCP (FLAG) UNTUK TAHAP %d:" % n
	head_b.text = "B. PILIH ARAH PENGIRIMAN PAKET TAHAP %d:" % n
	mission_text.text = "🎯 Misi Tahap %d/3: %s" % [n, HS[hs_step]["mission"]]
	send_btn.text = "🚀 Kirim Paket Tahap %d!" % n
	for c in flag_cards:
		(c as Panel).add_theme_stylebox_override("panel", _choice_style(false))
	for c in dir_cards:
		(c as Panel).add_theme_stylebox_override("panel", _choice_style(false))
	_update_select_label()
	_update_bridge()
	modal_status_lbl.text = "Pilih bendera paket TCP dan arah pengiriman, lalu tekan Kirim Paket."
	modal_status_lbl.add_theme_color_override("font_color", Color("#7c5843"))

func _update_select_label() -> void:
	var f = FLAGS[sel_flag]["name"] if sel_flag >= 0 else "(belum dipilih)"
	var d = DIRS[sel_dir]["name"] if sel_dir >= 0 else "(belum dipilih)"
	select_lbl.text = "Pilihan saat ini → Flag: %s • Arah: %s" % [f, d]

func _on_flag_chosen(i: int) -> void:
	if is_sending or is_solved:
		return
	sel_flag = i
	_play_synth_sequence([660.0], 0.05)
	for k in range(flag_cards.size()):
		(flag_cards[k] as Panel).add_theme_stylebox_override("panel", _choice_style(k == i))
	_update_select_label()

func _on_dir_chosen(j: int) -> void:
	if is_sending or is_solved:
		return
	sel_dir = j
	_play_synth_sequence([740.0], 0.05)
	for k in range(dir_cards.size()):
		(dir_cards[k] as Panel).add_theme_stylebox_override("panel", _choice_style(k == j))
	_update_select_label()

func _on_send_pressed() -> void:
	if is_sending or is_solved:
		return
	if sel_flag < 0 or sel_dir < 0:
		modal_status_lbl.text = "Pilih bendera paket (A) dan arah pengiriman (B) terlebih dahulu!"
		modal_status_lbl.add_theme_color_override("font_color", Color("#e11d48"))
		return
	var flag_ok = (sel_flag == _hs_flag(hs_step))
	var dir_ok = (sel_dir == _hs_dir(hs_step))
	if flag_ok and dir_ok:
		_on_step_ok()
	else:
		_on_step_wrong(flag_ok, dir_ok)

func _on_step_wrong(flag_ok: bool, dir_ok: bool) -> void:
	hearts = max(0, hearts - 1)
	_update_hearts_ui()
	_play_synth_sequence([220.0, 165.0], 0.12, "square")
	var msg = ""
	if not flag_ok and not dir_ok:
		msg = "Bendera paket DAN arah pengiriman keliru untuk Tahap %d." % (hs_step + 1)
	elif not flag_ok:
		msg = "Arah sudah benar, tetapi bendera paket TCP untuk Tahap %d keliru." % (hs_step + 1)
	else:
		msg = "Bendera sudah benar, tetapi arah pengiriman Tahap %d keliru." % (hs_step + 1)
	modal_status_lbl.text = "✗ %s Ingat urutan: SYN (Client→Server), SYN/ACK (Server→Client), ACK (Client→Server). (-1 ❤)" % msg
	modal_status_lbl.add_theme_color_override("font_color", Color("#e11d48"))
	# Kabel berkedip merah + getar
	var bad = (cable_state == 0)
	_shake_card()
	sel_flag = -1
	sel_dir = -1
	for c in flag_cards:
		(c as Panel).add_theme_stylebox_override("panel", _choice_style(false))
	for c in dir_cards:
		(c as Panel).add_theme_stylebox_override("panel", _choice_style(false))
	_update_select_label()
	if hearts <= 0:
		await get_tree().create_timer(0.5).timeout
		_on_task_modal_close_pressed()
		_trigger_game_over("Nyawa habis! Urutan TCP Three-Way Handshake belum tepat. Coba lagi!")

func _shake_card() -> void:
	var ox = task_card.position.x
	var tw = create_tween()
	tw.tween_property(task_card, "position:x", ox - 6.0, 0.04)
	tw.tween_property(task_card, "position:x", ox + 6.0, 0.06)
	tw.tween_property(task_card, "position:x", ox, 0.05)

func _on_step_ok() -> void:
	is_sending = true
	var code = HS[hs_step]["code"]
	var to_server = (_hs_dir(hs_step) == 0)
	_play_synth_sequence([523.25, 659.25], 0.08)
	modal_status_lbl.text = "📦 Paket %s terkirim %s ..." % [code, "CLIENT ➜ SERVER" if to_server else "SERVER ➜ CLIENT"]
	modal_status_lbl.add_theme_color_override("font_color", Color("#16a34a"))
	# Animasi paket "DATA" menyusuri kabel
	(packet_pill.get_child(0) as Label).text = code
	packet_pill.visible = true
	var x_from = 236.0 if to_server else 760.0
	var x_to = 760.0 if to_server else 236.0
	packet_pill.position = Vector2(x_from, 80)
	var tw = create_tween()
	tw.tween_property(packet_pill, "position:x", x_to, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	packet_pill.visible = false
	hs_step += 1
	cable_state = 1 if hs_step < 3 else 2
	diag_draw.queue_redraw()
	_update_bridge()
	_play_synth_sequence([587.33, 880.0], 0.08)
	if hs_step == 1:
		background.texture = BG_YELLOW
	if hs_step >= 3:
		_on_all_done()
	else:
		is_sending = false
		_refresh_step_ui()
		modal_status_lbl.text = "✓ %s diterima! Lanjut ke Tahap %d." % [code, hs_step + 1]
		modal_status_lbl.add_theme_color_override("font_color", Color("#16a34a"))

func _build_result_boxes(root: Control) -> void:
	monitor_box = Panel.new()
	monitor_box.position = Vector2(30, 236)
	monitor_box.size = Vector2(1040, 92)
	monitor_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	monitor_box.visible = false
	monitor_box.add_theme_stylebox_override("panel", _make_box(Color("#1d3a2e"), Color("#5a3a33"), 3, 18))
	root.add_child(monitor_box)
	var m1 = _make_label("MONITOR UTAMA NETWORK COMMUNICATION CENTER", font_bold, 9, Color("#bfe9d3"))
	m1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor_wide(m1, 0, 8, 0, 14)
	monitor_box.add_child(m1)
	var m2 = _make_label("CONNECTION ESTABLISHED  •  NETWORK RESTORED", font_black, 26, Color("#4ade80"))
	m2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor_wide(m2, 0, 26, 0, 36)
	monitor_box.add_child(m2)
	var m3 = _make_label("🏆 MISSION COMPLETE — SELURUH SISTEM JARINGAN PERUSAHAAN NORMAL! 🏆", font_extrabold, 12, Color("#fff3b0"))
	m3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor_wide(m3, 0, 66, 0, 18)
	monitor_box.add_child(m3)

	summary_box = Panel.new()
	summary_box.position = Vector2(30, 338)
	summary_box.size = Vector2(1040, 262)
	summary_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_box.visible = false
	summary_box.add_theme_stylebox_override("panel", _make_box(Color("#c9ebdb"), Color("#5a3a33"), 3, 18))
	root.add_child(summary_box)

	_pill(summary_box, "🎉 LEVEL 5.5 SELESAI — RINGKASAN PEMBELAJARAN", Color("#ffffff"), Color("#5a3a33"), 11, Color("#14532d"), 10, 10, 410, 28, HORIZONTAL_ALIGNMENT_CENTER, font_black)
	summary_stars = _make_label("", font_bold, 12, Color("#4a2e2b"))
	summary_stars.position = Vector2(436, 14)
	summary_stars.custom_minimum_size = Vector2(160, 20)
	summary_box.add_child(summary_stars)
	var b_replay = _lane_button("🔄 Mainkan Ulang 5.5", Color("#ffffff"), Color("#5a3a33"))
	b_replay.custom_minimum_size = Vector2(180, 28)
	b_replay.size = Vector2(180, 28)
	b_replay.position = Vector2(summary_box.size.x - 410.0, 10)
	b_replay.pressed.connect(_on_restart_level)
	summary_box.add_child(b_replay)
	var b_next = _lane_button("🏆 Rekapitulasi Stage 5 ➜", Color("#fff3b0"), Color("#ca8a04"))
	b_next.custom_minimum_size = Vector2(210, 28)
	b_next.size = Vector2(210, 28)
	b_next.position = Vector2(summary_box.size.x - 220.0, 10)
	b_next.pressed.connect(_show_recap)
	summary_box.add_child(b_next)

	var boxes = [
		["📘 Apa yang Baru Dipelajari:", "Urutan baku TCP Three-Way Handshake: (1) SYN dari Client ke Server, (2) SYN/ACK dari Server ke Client, dan (3) ACK dari Client ke Server.", Color("#14532d")],
		["🎯 Mengapa Tugas Ini Penting:", "Memastikan kedua komputer sama-sama siap mengirim dan menerima data serta menyinkronkan nomor urut paket sebelum transfer dimulai.", Color("#1d4ed8")],
		["🌐 Contoh di Kehidupan Nyata:", "Seperti menelepon teman: (1) 'Halo, bisa dengar?' [SYN], (2) 'Ya, terdengar jelas, kamu dengar aku?' [SYN/ACK], (3) 'Ya, jelas!' [ACK].", Color("#7e22ce")],
		["⚠️ Kesalahan Umum yang Perlu Dihindari:", "Membalik arah pengiriman SYN/ACK (seharusnya dari Server ke Client) atau langsung mengirim ACK sebelum SYN.", Color("#b91c1c")],
	]
	for i in range(4):
		var bx = Panel.new()
		bx.position = Vector2(12 + (i % 2) * 508, 50 + (i / 2) * 102)
		bx.size = Vector2(496, 94)
		bx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bx.add_theme_stylebox_override("panel", _make_box(Color("#fffdf8"), Color("#5a3a33"), 2, 12))
		summary_box.add_child(bx)
		var t = _make_label(boxes[i][0], font_black, 12, boxes[i][2])
		t.clip_text = true
		_anchor_wide(t, 12, 8, 12, 18)
		bx.add_child(t)
		var tx = _make_label(boxes[i][1], font_semibold, 11, Color("#3b3358"))
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_anchor_wide(tx, 12, 32, 12, 56)
		bx.add_child(tx)

func _on_all_done() -> void:
	is_game_active = false
	is_solved = true
	_play_synth_sequence([523.25, 659.25, 783.99, 1046.50], 0.1)
	background.texture = BG_GREEN
	modal_title_lbl.text = "Konsol Final TCP Three-Way Handshake — Connection Established!"
	modal_status_lbl.text = "✓ Handshake selesai: SYN ➜ SYN/ACK ➜ ACK. Jalur komunikasi kini HIJAU!"
	modal_status_lbl.add_theme_color_override("font_color", Color("#16a34a"))
	var pd = get_node_or_null("/root/PlayerData")
	if pd and pd.has_method("set_level_stars"):
		pd.set_level_stars(5, 5, hearts)
	rack_hotspot.modulate.a = 0.0
	rack_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rack_badge.text = "✓ CONNECTION ESTABLISHED"
	rack_badge.visible = true
	# Seperti level sebelumnya: tutup konsol lalu tampilkan pop up "berhasil" dengan tombol Lanjut
	await get_tree().create_timer(1.6).timeout
	_on_task_modal_close_pressed()
	_on_victory()

# Rekapitulasi akhir Stage 5 (mockup "Mission Complete")
func _show_recap() -> void:
	if recap_overlay:
		recap_overlay.visible = true
		return
	recap_overlay = ColorRect.new()
	recap_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	recap_overlay.color = Color(0, 0, 0, 0.7)
	recap_overlay.z_index = 280
	add_child(recap_overlay)
	var card = Panel.new()
	card.size = Vector2(980, 600)
	card.position = Vector2((1560 - 980) / 2.0, 60.0)
	card.add_theme_stylebox_override("panel", _make_box(Color("#fdf8ef"), Color("#4a2e2b"), 4, 24))
	recap_overlay.add_child(card)
	var hdr = Panel.new()
	hdr.size = Vector2(980, 76)
	var sbh = StyleBoxFlat.new()
	sbh.bg_color = Color("#a8e6cf")
	sbh.corner_radius_top_left = 22
	sbh.corner_radius_top_right = 22
	hdr.add_theme_stylebox_override("panel", sbh)
	card.add_child(hdr)
	var ht = _make_label("🏆  MISSION COMPLETE — NETWORK RESTORED!  🏆", font_black, 26, Color("#14532d"))
	ht.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ht.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ht.set_anchors_preset(Control.PRESET_FULL_RECT)
	hdr.add_child(ht)

	var panels = [["CONNECTION ESTABLISHED", "CLIENT (192.168.5.10) ⇄ SERVER (.100)", Color("#a8e6cf")], ["NETWORK RESTORED", "ALL 7 OSI LAYERS & PORTS ONLINE", Color("#fff3b0")]]
	for i in range(2):
		var pp = Panel.new()
		pp.position = Vector2(30 + i * 462, 96)
		pp.size = Vector2(458, 96)
		pp.add_theme_stylebox_override("panel", _make_box(Color("#1d3a2e"), Color("#5a3a33"), 3, 16))
		card.add_child(pp)
		var a = _make_label("● " + panels[i][0], font_black, 16, panels[i][2])
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_anchor_wide(a, 0, 20, 0, 24)
		pp.add_child(a)
		var b = _make_label(panels[i][1], font_extrabold, 11, Color("#e6fff1"))
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_anchor_wide(b, 0, 58, 0, 18)
		pp.add_child(b)

	var rp = Panel.new()
	rp.position = Vector2(30, 206)
	rp.size = Vector2(920, 280)
	rp.add_theme_stylebox_override("panel", _make_box(Color("#f9f3e7"), Color("#5a3a33"), 3, 18))
	card.add_child(rp)
	var rt = _make_label("🌟 REKAPITULASI KEBERHASILAN TEKNISI STAGE 5 🌟", font_black, 16, Color("#4a2e2b"))
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor_wide(rt, 0, 14, 0, 24)
	rp.add_child(rt)
	var lines = [
		"Level 5.1 (7 OSI Layer): Physical ➜ Data Link ➜ Network ➜ Transport ➜ Session ➜ Presentation ➜ Application",
		"Level 5.2 (Encapsulation & Decapsulation): Data ⇄ Segment ⇄ Packet ⇄ Frame ⇄ Bits",
		"Level 5.3 (Protokol Transport): Jalur TCP (Andal, Urut, ACK) vs Jalur UDP (Cepat, Overhead Rendah)",
		"Level 5.4 (Port Server): HTTP:80 • HTTPS:443 • DNS:53 • SSH:22 • FTP:21 Aktif",
		"Level 5.5 (TCP Handshake): SYN (Client➜Server) ➜ SYN/ACK (Server➜Client) ➜ ACK (Client➜Server)",
	]
	for k in range(lines.size()):
		var ll = _make_label("✅  " + lines[k], font_bold, 12, Color("#14532d"))
		ll.clip_text = true
		_anchor_wide(ll, 24, 56 + k * 40, 24, 22)
		rp.add_child(ll)

	var fin = Button.new()
	fin.text = "🎉  SELESAIKAN STAGE 5"
	fin.add_theme_stylebox_override("normal", _make_box(Color("#fff3b0"), Color("#4a2e2b"), 4, 24))
	fin.add_theme_stylebox_override("hover", _make_box(Color("#ffe98a"), Color("#4a2e2b"), 4, 24))
	fin.add_theme_stylebox_override("pressed", _make_box(Color("#ffe98a"), Color("#4a2e2b"), 4, 24))
	fin.add_theme_font_override("font", font_black)
	fin.add_theme_font_size_override("font_size", 22)
	fin.add_theme_color_override("font_color", Color("#4a2e2b"))
	fin.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	fin.custom_minimum_size = Vector2(380, 62)
	fin.size = Vector2(380, 62)
	fin.position = Vector2(300, 506)
	fin.pressed.connect(_on_map_pressed)
	card.add_child(fin)

# Level ini memakai klik (tanpa drag); stub agar handler _input dasar tetap valid
func _begin_drag(_id: int) -> void:
	pass

func _try_place(_a: int, _b: int) -> void:
	pass

func _open_task_modal() -> void:
	if not is_game_active or is_solved:
		return
	_play_synth_sequence([440.0], 0.08)
	task_modal_overlay.visible = true
	is_modal_open = true

func _on_task_modal_close_pressed() -> void:
	_play_synth_sequence([350.0], 0.08)
	task_modal_overlay.visible = false
	is_modal_open = false
	drag_layer = 0
	drag_active = false
	if drag_ghost:
		drag_ghost.queue_free()
		drag_ghost = null

# Tombol X: bila level sudah selesai, tampilkan dialog hasil seperti level lain
func _on_modal_close_x() -> void:
	if is_sending:
		return
	var was_solved = is_solved
	_on_task_modal_close_pressed()
	if was_solved:
		_on_victory()

# ==============================================================================
# VICTORY & GAME OVER
# ==============================================================================
func _setup_game_dialog() -> void:
	game_dialog_instance = game_dialog_scene.instantiate()
	game_dialog_instance.z_index = 350
	add_child(game_dialog_instance)

func _on_victory() -> void:
	is_game_active = false
	is_solved = true
	rack_hotspot.modulate.a = 0.0
	rack_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rack_badge.text = "✓ 5/5 PORT TERPASANG"
	rack_badge.visible = true

	var pd = get_node_or_null("/root/PlayerData")
	if pd and pd.has_method("set_level_stars"):
		pd.set_level_stars(5, 5, hearts)
	var time_str = "Waktu Tersisa: %02d:%02d" % [int(timer_seconds) / 60, int(timer_seconds) % 60]
	if game_dialog_instance:
		game_dialog_instance.show_win(
			"TCP Three-Way Handshake Selesai — Connection Established!",
			"Misi Level 5.5 berhasil! Pertukaran SYN ➜ SYN/ACK ➜ ACK antara Client dan Server berhasil diverifikasi.\n\n📌 TCP Three-Way Handshake memastikan kedua perangkat siap berkomunikasi sebelum data sesungguhnya dikirim.\n📌 Urutan baku: (1) Client mengirim SYN, (2) Server membalas SYN/ACK, (3) Client mengirim konfirmasi ACK.\n🌐 Ibarat menelepon seseorang: 'Halo, dengar suara saya?' (SYN) ➜ 'Ya, saya dengar, kamu dengar saya?' (SYN/ACK) ➜ 'Ya, jelas!' (ACK).",
			hearts,
			time_str,
			Callable(self, "_on_next_level"),
			Callable(self, "_on_map_pressed"),
			"LANJUT"
		)

func _trigger_game_over(msg: String) -> void:
	is_game_active = false
	if game_dialog_instance:
		game_dialog_instance.show_game_over(
			msg,
			Callable(self, "_on_restart_level"),
			Callable(self, "_on_map_pressed")
		)

func _on_next_level() -> void:
	# Level final: tampilkan rekapitulasi Stage 5
	_show_recap()

func _on_restart_level() -> void:
	get_tree().reload_current_scene()

func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_path.tscn")


# ==============================================================================
# PANDUAN BERMAIN (hint pop up dengan tangan/panah) - bisa dibuka lagi lewat tombol "?"
# ==============================================================================
var help_btn: Button

func _setup_help_button() -> void:
	if header_ui and timer_label:
		help_btn = TutorialOverlay.attach_help_button(header_ui, timer_label, _on_help_pressed)

func _on_help_pressed() -> void:
	if TutorialOverlay.can_open_help(self):
		TutorialOverlay.start(self, _tutorial_steps(), Callable(), true)

# Dipanggil saat intro selesai: tampilkan panduan dulu, permainan baru aktif setelahnya
func _start_after_tutorial() -> void:
	TutorialOverlay.start(self, _tutorial_steps(), func(): is_game_active = true)

func _tutorial_steps() -> Array:
	return [
		{ "title": "Misi Level 5.5", "text": "Selesaikan TCP Three-Way Handshake secara berurutan dalam 3 tahap." },
		{ "title": "1. Konsol Handshake", "text": "Dekati konsol ini lalu klik. Urutannya: SYN (Client ke Server), SYN/ACK (Server ke Client), lalu ACK (Client ke Server).", "target": rack_hotspot, "pointer": "both" },
		{ "title": "Siap?", "text": "Selesaikan misi sebelum waktu habis. Lupa caranya? Tekan tombol ? (kuning) di dekat pewaktu kapan saja untuk melihat panduan ini lagi." }
	]
