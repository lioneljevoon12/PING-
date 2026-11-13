extends Control

# ==============================================================================
# PING! - LEVEL 5.3: MENENTUKAN PROTOKOL TRANSPORT (TCP vs UDP)
# Sesuai Proposal (Stage 5) & mockup Figma Level 5.3
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

# --- DATA 6 SITUASI KOMUNIKASI (sesuai level_5_3_config.json) ---
# lane: 1 = Jalur TCP, 2 = Jalur UDP
const SCEN: Array = [
	{ "title": "Email Laporan Keuangan", "cond": "Data harus sampai dengan lengkap dan urut tanpa satu huruf pun hilang", "proto": "TCP", "lane": 1, "color": "#A8E6CF", "tag": "+ACK/Urut" },
	{ "title": "Unduh File Dokumen Arsip", "cond": "Membutuhkan pengiriman file utuh 100% tanpa kerusakan bit", "proto": "TCP", "lane": 1, "color": "#A8E6CF", "tag": "+ACK/Urut" },
	{ "title": "Siaran Video Langsung (Live)", "cond": "Lebih mengutamakan kelancaran & dapat menoleransi sebagian paket hilang", "proto": "UDP", "lane": 2, "color": "#A2D2FF", "tag": "Real-Time" },
	{ "title": "Panggilan Suara Real-Time (VoIP)", "cond": "Mengutamakan pengiriman cepat & latensi rendah tanpa jeda tunggu", "proto": "UDP", "lane": 2, "color": "#A2D2FF", "tag": "Real-Time" },
	{ "title": "Sinkronisasi Database Server", "cond": "Komunikasi membutuhkan mekanisme acknowledgment (ACK) & retransmission", "proto": "TCP", "lane": 1, "color": "#E2CBF7", "tag": "+ACK/Urut" },
	{ "title": "Sensor Telemetri Cepat", "cond": "Komunikasi membutuhkan pengiriman ringan dengan overhead lebih rendah", "proto": "UDP", "lane": 2, "color": "#FFF3B0", "tag": "Real-Time" },
]

# Posisi konsol TCP & UDP pada background 1920x1080 (untuk hotspot interaktif)
const RACK_RECT_BG := Rect2(567, 410, 783, 400)

# Rintangan (collision) pada background 1920x1080: dinding, konsol, meja Client & Server
const OBSTACLES_BG: Array = [
	Rect2(0, 0, 1920, 330),       # dinding belakang
	Rect2(567, 410, 783, 400),    # Konsol TCP & UDP
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
	var n_lbl = _make_label("5.3", font_black, 16, Color("#4a2e2b"))
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
		_trigger_game_over("Waktu Habis! Kamu belum selesai mengarahkan situasi ke jalur TCP/UDP.")
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
	intro_overlay = ColorRect.new()
	intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_overlay.color = Color(0, 0, 0, 0.65)
	intro_overlay.z_index = 200
	add_child(intro_overlay)

	var card = Panel.new()
	card.size = Vector2(740, 640)
	card.position = Vector2((1560 - 740) / 2.0, (720 - 640) / 2.0)
	var sb = _make_box(Color("#fef3c7"), Color("#4a2e2b"), 4, 22)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", sb)
	intro_overlay.add_child(card)

	var ring = Panel.new()
	ring.size = Vector2(26, 26)
	ring.position = Vector2(357, 14)
	ring.add_theme_stylebox_override("panel", _make_box(Color("#ffffff"), Color("#4a2e2b"), 3, 13))
	card.add_child(ring)

	var title = _make_label("⚡ Level 5.3 — Menentukan Protokol Transport: TCP vs UDP", font_black, 20, Color("#4a2e2b"))
	title.position = Vector2(0, 46)
	title.size = Vector2(740, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)

	var line = ColorRect.new()
	line.position = Vector2(70, 84)
	line.size = Vector2(600, 2.5)
	line.color = Color("#d9b84a")
	card.add_child(line)

	_intro_section(card, "⚠️ MASALAH SAAT INI", Color("#fecaca"), Color("#fffdf6"), [
		{ "t": "Berbagai trafik komunikasi memiliki kebutuhan yang berbeda—ada yang wajib utuh 100%, ada yang butuh cepat dan ringan!", "f": font_extrabold },
		{ "t": "🎯 Tugas: Baca kebutuhan komunikasi pada setiap kartu situasi terlebih dahulu, lalu arahkan ke Jalur TCP atau Jalur UDP.", "f": font_extrabold, "c": Color("#166534") },
	], 98, 118)

	_intro_section(card, "📘 PANDUAN & CONTOH MATERI", Color("#bfdbfe"), Color("#fffdf6"), [
		{ "t": "• Pilih TCP jika: Data harus sampai lengkap & urut, serta membutuhkan mekanisme Acknowledgment (ACK) & Retransmission." },
		{ "t": "• Pilih UDP jika: Pengiriman harus ringan, cepat, overhead rendah, dan dapat menoleransi sebagian paket hilang." },
		{ "t": "🖱️ Interaksi: Drag-and-Drop kartu ke slot, atau Klik Kartu lalu Klik Slot Tujuan.", "f": font_extrabold, "c": Color("#7e22ce") },
	], 226, 150)

	var goal = Panel.new()
	goal.position = Vector2(34, 386)
	goal.size = Vector2(672, 86)
	goal.add_theme_stylebox_override("panel", _make_box(Color("#d9eac3"), Color("#4a2e2b"), 3, 16))
	card.add_child(goal)
	var g1 = _make_label("🏆 TUJUAN AKHIR LEVEL 5.3", font_black, 14, Color("#14532d"))
	g1.position = Vector2(0, 12)
	g1.size = Vector2(672, 22)
	g1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal.add_child(g1)
	var g2 = _make_label("Seluruh 6 situasi komunikasi berhasil diarahkan ke jalur protokol Transport (TCP/UDP) yang paling sesuai.", font_extrabold, 12, Color("#14532d"))
	g2.position = Vector2(16, 42)
	g2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_anchor_wide(g2, 16, 42, 16, 36)
	goal.add_child(g2)

	var mulai_btn = Button.new()
	mulai_btn.text = "MULAI"
	mulai_btn.position = Vector2(265, 510)
	mulai_btn.size = Vector2(210, 60)
	var sb_m = _make_box(Color("#a7f3d0"), Color("#4a2e2b"), 3, 22)
	mulai_btn.add_theme_stylebox_override("normal", sb_m)
	var sb_mh = sb_m.duplicate() as StyleBoxFlat
	sb_mh.bg_color = Color("#6ee7b7")
	mulai_btn.add_theme_stylebox_override("hover", sb_mh)
	mulai_btn.add_theme_stylebox_override("pressed", sb_mh)
	mulai_btn.add_theme_font_override("font", font_black)
	mulai_btn.add_theme_font_size_override("font_size", 18)
	mulai_btn.add_theme_color_override("font_color", Color("#14532d"))
	mulai_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mulai_btn.pressed.connect(_on_mulai_pressed)
	card.add_child(mulai_btn)

	var avatar = TextureRect.new()
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.size = Vector2(80, 80)
	avatar.position = Vector2(20, 545)
	avatar.texture = tex_technician_avatar
	card.add_child(avatar)

func _on_mulai_pressed() -> void:
	_play_synth_sequence([523.25, 659.25, 783.99], 0.08)
	intro_overlay.visible = false
	_start_after_tutorial()

# ==============================================================================
# TASK MODAL (Simulator Lalu Lintas Protokol Transport: Jalur TCP vs Jalur UDP)
# ==============================================================================
const CARD_W := 336.0
const CARD_H := 96.0

# Pill/label berlatar (Panel + Label anchor penuh agar ukuran label stabil)
func _pill(parent: Control, text: String, bg: Color, border: Color, fsize: int, fcol: Color, x: float, y: float, w: float, h: float, align: int = HORIZONTAL_ALIGNMENT_CENTER, font: Font = null) -> Panel:
	var p = Panel.new()
	p.position = Vector2(x, y)
	p.size = Vector2(w, h)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _make_box(bg, border, 2, int(h / 2.0) if h <= 26.0 else 12))
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

func _setup_task_modal() -> void:
	task_modal_overlay = ColorRect.new()
	task_modal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	task_modal_overlay.color = Color(0, 0, 0, 0.65)
	task_modal_overlay.z_index = 250
	task_modal_overlay.visible = false
	add_child(task_modal_overlay)

	task_card = PanelContainer.new()
	task_card.size = Vector2(1100, 676)
	task_card.position = Vector2((1560 - 1100) / 2.0, 22.0)
	var sb = _make_box(Color("#fdf8ef"), Color("#4a2e2b"), 4, 22)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	task_card.add_theme_stylebox_override("panel", sb)
	task_modal_overlay.add_child(task_card)

	var root = Control.new()
	root.custom_minimum_size = Vector2(1100, 676)
	task_card.add_child(root)

	# Header kuning krem
	var hdr_bg = Panel.new()
	hdr_bg.size = Vector2(1100, 58)
	hdr_style = StyleBoxFlat.new()
	hdr_style.bg_color = Color("#fff1b8")
	hdr_style.corner_radius_top_left = 20
	hdr_style.corner_radius_top_right = 20
	hdr_bg.add_theme_stylebox_override("panel", hdr_style)
	root.add_child(hdr_bg)

	modal_title_lbl = _make_label("Simulator Lalu Lintas Protokol Transport: Jalur TCP vs Jalur UDP", font_black, 18, Color("#3b3358"))
	modal_title_lbl.position = Vector2(0, 15)
	modal_title_lbl.size = Vector2(1100, 28)
	modal_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(modal_title_lbl)

	var close_btn = preload("res://scenes/close_button.tscn").instantiate()
	close_btn.position = Vector2(1100 - 52, 10)
	close_btn.custom_minimum_size = Vector2(38, 38)
	close_btn.size = Vector2(38, 38)
	if close_btn.has_signal("pressed"):
		close_btn.pressed.connect(_on_task_modal_close_pressed)
	elif close_btn.has_signal("clicked"):
		close_btn.clicked.connect(_on_task_modal_close_pressed)
	elif close_btn.has_signal("closed"):
		close_btn.closed.connect(_on_task_modal_close_pressed)
	root.add_child(close_btn)

	var body = Panel.new()
	body.position = Vector2(18, 70)
	body.size = Vector2(1064, 570)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", _make_box(Color("#f9f3e7"), Color("#d8cbb0"), 2, 18))
	root.add_child(body)

	# Bagian 1: kartu situasi
	modal_hint_lbl = _make_label("1. ANALISIS 3 PARAMETER PADA 6 KARTU SITUASI KOMUNIKASI (KLIK ATAU SERET KARTU):", font_black, 13, Color("#4a2e2b"))
	modal_hint_lbl.position = Vector2(34, 78)
	modal_hint_lbl.custom_minimum_size = Vector2(900, 20)
	root.add_child(modal_hint_lbl)

	for i in range(SCEN.size()):
		var c = _build_scenario_card(i + 1)
		c.position = Vector2(32 + (i % 3) * (CARD_W + 14.0), 102 + (i / 3) * (CARD_H + 10.0))
		root.add_child(c)
		card_nodes[i + 1] = c

	# Bagian 2: jalur protokol
	var h2 = _make_label("2. ARAHKAN KARTU KE JALUR PROTOKOL TRANSPORT YANG SESUAI:", font_black, 13, Color("#4a2e2b"))
	h2.position = Vector2(34, 322)
	h2.custom_minimum_size = Vector2(700, 20)
	root.add_child(h2)

	progress_lbl = _pill(root, "Progres: 0/6 Situasi", Color("#bfe9d3"), Color("#15803d"), 11, Color("#14532d"), 904, 318, 168, 24, HORIZONTAL_ALIGNMENT_CENTER, font_bold)
	progress_text = progress_lbl.get_child(0) as Label

	_build_lane(root, 1, Vector2(30, 348))
	_build_lane(root, 2, Vector2(550, 348))

	modal_status_lbl = _make_label("Pilih kartu situasi lalu arahkan ke Jalur TCP atau Jalur UDP.", font_extrabold, 12, Color("#7c5843"))
	modal_status_lbl.position = Vector2(30, 648)
	modal_status_lbl.size = Vector2(1040, 22)
	modal_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(modal_status_lbl)

func _build_scenario_card(idx: int) -> Panel:
	var d = SCEN[idx - 1]
	var p = Panel.new()
	p.size = Vector2(CARD_W, CARD_H)
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.add_theme_stylebox_override("panel", _make_box(Color("#fffdf8"), Color("#5a3a33"), 3, 14))

	_pill(p, d["title"], Color(d["color"]), Color("#5a3a33"), 11, Color("#3b3358"), 10, 8, 236, 24)
	var state = _make_label("Pilih", font_bold, 11, Color("#4a2e2b"))
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	state.clip_text = true
	_anchor_wide(state, 252, 10, 10, 20)
	p.add_child(state)
	card_states[idx] = state

	var cond = _make_label(d["cond"], font_bold, 10, Color("#3b3358"))
	cond.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_anchor_wide(cond, 12, 33, 12, 30)
	p.add_child(cond)

	var sep = ColorRect.new()
	sep.color = Color("#d8cbb0")
	sep.position = Vector2(12, 68)
	sep.size = Vector2(CARD_W - 24, 1.5)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(sep)

	_pill(p, d["tag"], Color("#fff6e5"), Color("#8a7a70"), 10, Color("#4a2e2b"), 10, 71, 104, 21, HORIZONTAL_ALIGNMENT_CENTER, font_bold)

	var b_tcp = _lane_button("🛡 TCP", Color("#a8e6cf"), Color("#15803d"))
	b_tcp.position = Vector2(CARD_W - 170.0, 70)
	b_tcp.pressed.connect(func(): _try_place(idx, 1))
	p.add_child(b_tcp)
	var b_udp = _lane_button("⚡ UDP", Color("#a2d2ff"), Color("#1d4ed8"))
	b_udp.position = Vector2(CARD_W - 86.0, 70)
	b_udp.pressed.connect(func(): _try_place(idx, 2))
	p.add_child(b_udp)

	p.gui_input.connect(func(ev: InputEvent): _on_card_gui_input(ev, idx))
	return p

func _lane_button(txt: String, bg: Color, border: Color) -> Button:
	var b = Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(76, 24)
	b.size = Vector2(76, 24)
	b.add_theme_stylebox_override("normal", _make_box(bg, border, 2, 8))
	b.add_theme_stylebox_override("hover", _make_box(bg.lightened(0.25), border, 2, 8))
	b.add_theme_stylebox_override("pressed", _make_box(bg.darkened(0.1), border, 2, 8))
	b.add_theme_font_override("font", font_black)
	b.add_theme_font_size_override("font_size", 10)
	b.add_theme_color_override("font_color", Color("#1f2937"))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

func _build_lane(root: Control, lane: int, pos: Vector2) -> void:
	var is_tcp = (lane == 1)
	var lp = Panel.new()
	lp.position = pos
	lp.size = Vector2(520, 292)
	lp.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	lp.add_theme_stylebox_override("panel", _make_box(Color("#d6f2e4") if is_tcp else Color("#d8e8fb"), Color("#5a3a33"), 3, 20))
	root.add_child(lp)
	slot_nodes[lane] = lp
	lane_counts[lane] = 0
	lp.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			if selected_layer > 0 and not placed.has(selected_layer):
				_try_place(selected_layer, lane)
	)

	_pill(lp, "🛡 JALUR TCP (Connection-Oriented • Andal, Urut & ACK)" if is_tcp else "⚡ JALUR UDP (Connectionless • Ringan, Cepat & Low Overhead)",
		Color("#a8e6cf") if is_tcp else Color("#a2d2ff"), Color("#5a3a33"), 13, Color("#14532d") if is_tcp else Color("#1e3a8a"), 14, 12, 492, 38)
	_pill(lp, "[Paket #1 ✓ ACK] ➜ [Paket #2 ✓ ACK] ➜ [Paket #3 ✓ ACK]" if is_tcp else "[Datagram #1 ⚡] ➜ [Datagram #2 ⚡] ➜ [Datagram #3 ⚡]",
		Color("#ffffff"), Color("#5a3a33"), 11, Color("#14532d") if is_tcp else Color("#1e3a8a"), 14, 58, 492, 34, HORIZONTAL_ALIGNMENT_CENTER, font_bold)

	var dz = Panel.new()
	dz.position = Vector2(14, 102)
	dz.size = Vector2(492, 176)
	dz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dz.add_theme_stylebox_override("panel", _make_box(Color(1, 1, 1, 0.35), Color("#7c6f68"), 2, 14))
	lp.add_child(dz)
	lane_zones[lane] = dz

	var hint = _make_label("Seret / klik kartu situasi ke jalur ini", font_extrabold, 12, Color("#7c7a85"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	dz.add_child(hint)
	lane_hints[lane] = hint

func _on_card_gui_input(ev: InputEvent, id: int) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if placed.has(id):
			return
		_select_card(id)
		drag_layer = id
		drag_active = false
		drag_press_pos = get_global_mouse_position()

func _card_style(idx: int, selected: bool) -> StyleBoxFlat:
	if selected:
		return _make_box(Color("#fffdf8"), Color("#22d3ee"), 5, 14)
	return _make_box(Color("#fffdf8"), Color("#5a3a33"), 3, 14)

func _reset_card_styles() -> void:
	for ln in card_nodes:
		if placed.has(ln):
			continue
		(card_nodes[ln] as Panel).add_theme_stylebox_override("panel", _card_style(ln, false))
		(card_states[ln] as Label).text = "Pilih"

func _select_card(id: int) -> void:
	selected_layer = id
	_play_synth_sequence([660.0], 0.05)
	_reset_card_styles()
	(card_nodes[id] as Panel).add_theme_stylebox_override("panel", _card_style(id, true))
	(card_states[id] as Label).text = "👆 Dipilih"
	modal_status_lbl.text = "\"%s\" dipilih — klik Jalur TCP/UDP atau tombol TCP/UDP pada kartu." % SCEN[id - 1]["title"]
	modal_status_lbl.add_theme_color_override("font_color", Color("#7c5843"))

func _begin_drag(id: int) -> void:
	drag_active = true
	var d = SCEN[id - 1]
	drag_ghost = Panel.new()
	drag_ghost.size = Vector2(300, 46)
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_ghost.z_index = 100
	drag_ghost.modulate.a = 0.93
	drag_ghost.add_theme_stylebox_override("panel", _make_box(Color(d["color"]), Color("#22d3ee"), 4, 14))
	var l = _make_label(d["title"], font_black, 13, Color("#3b3358"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.offset_left = 8
	l.offset_right = -8
	drag_ghost.add_child(l)
	task_modal_overlay.add_child(drag_ghost)
	drag_ghost.position = get_global_mouse_position() - drag_ghost.size * 0.5
	(card_nodes[id] as Control).modulate.a = 0.4
	_select_card(id)

# card_id = indeks situasi (1..6), lane_id = 1 (TCP) / 2 (UDP)
func _try_place(card_id: int, lane_id: int) -> void:
	if placed.has(card_id):
		return
	if card_nodes.has(card_id):
		(card_nodes[card_id] as Control).modulate.a = 1.0
	if SCEN[card_id - 1]["lane"] == lane_id:
		_on_correct_place(card_id, lane_id)
	else:
		_on_wrong_place(card_id, lane_id)

func _on_correct_place(id: int, lane: int) -> void:
	placed[id] = true
	selected_layer = 0
	var d = SCEN[id - 1]
	var card = card_nodes[id] as Panel
	card.add_theme_stylebox_override("panel", _make_box(Color("#e3f6ea"), Color("#15803d"), 3, 14))
	card.modulate.a = 0.55
	card.mouse_default_cursor_shape = Control.CURSOR_ARROW
	(card_states[id] as Label).text = "✓ Terpasang"
	# Chip kecil di dalam jalur
	var n = int(lane_counts[lane])
	lane_counts[lane] = n + 1
	if lane_hints.has(lane):
		(lane_hints[lane] as Control).visible = false
	var zone = lane_zones[lane] as Control
	var chip = Panel.new()
	chip.position = Vector2(10, 8 + n * 54)
	chip.size = Vector2(472, 46)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _make_box(Color(d["color"]), Color("#15803d"), 3, 12))
	zone.add_child(chip)
	var cl = _make_label("✓ " + d["title"], font_black, 14, Color("#3b3358"))
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cl.clip_text = true
	cl.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.offset_left = 10
	cl.offset_right = -10
	chip.add_child(cl)
	chip.scale = Vector2(0.6, 0.6)
	chip.pivot_offset = chip.size * 0.5
	var tw = create_tween()
	tw.tween_property(chip, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_play_synth_sequence([587.33, 880.0], 0.08)
	progress_text.text = "Progres: %d/6 Situasi" % placed.size()
	var proto = "TCP" if lane == 1 else "UDP"
	modal_status_lbl.text = "✓ Tepat! \"%s\" memang cocok memakai %s." % [d["title"], proto]
	modal_status_lbl.add_theme_color_override("font_color", Color("#16a34a"))
	if placed.size() >= SCEN.size():
		_on_all_placed()

func _on_wrong_place(id: int, lane: int) -> void:
	hearts = max(0, hearts - 1)
	_update_hearts_ui()
	_play_synth_sequence([220.0, 165.0], 0.12, "square")
	var d = SCEN[id - 1]
	var card = card_nodes[id] as Control
	var lp = slot_nodes[lane] as Control
	# Jalur berkedip merah, kartu bergoyang
	var sb = lp.get_theme_stylebox("panel") as StyleBoxFlat
	var old_border = sb.border_color
	sb.border_color = Color("#e11d48")
	var ox = card.position.x
	var tw = create_tween()
	tw.tween_property(card, "position:x", ox - 8.0, 0.04)
	tw.tween_property(card, "position:x", ox + 8.0, 0.06)
	tw.tween_property(card, "position:x", ox - 4.0, 0.05)
	tw.tween_property(card, "position:x", ox, 0.04)
	tw.tween_callback(func(): sb.border_color = old_border)
	selected_layer = 0
	_reset_card_styles()
	var why = "membutuhkan data utuh, berurutan & ACK → cocok TCP" if d["lane"] == 1 else "mengutamakan kecepatan & overhead rendah → cocok UDP"
	modal_status_lbl.text = "✗ \"%s\" %s. (-1 ❤)" % [d["title"], why]
	modal_status_lbl.add_theme_color_override("font_color", Color("#e11d48"))
	_shake_card()
	if hearts <= 0:
		await get_tree().create_timer(0.5).timeout
		_on_task_modal_close_pressed()
		_trigger_game_over("Nyawa habis! Pemilihan protokol TCP/UDP belum tepat. Coba lagi!")

func _shake_card() -> void:
	var ox = task_card.position.x
	var tw = create_tween()
	tw.tween_property(task_card, "position:x", ox - 6.0, 0.04)
	tw.tween_property(task_card, "position:x", ox + 6.0, 0.06)
	tw.tween_property(task_card, "position:x", ox, 0.05)

func _on_all_placed() -> void:
	_play_synth_sequence([523.25, 659.25, 783.99, 1046.50], 0.1)
	modal_status_lbl.text = "✓ Seluruh 6 situasi berhasil diarahkan ke jalur protokol yang sesuai!"
	modal_status_lbl.add_theme_color_override("font_color", Color("#16a34a"))
	for lane in [1, 2]:
		var lp = slot_nodes[lane] as Control
		lp.pivot_offset = lp.size * 0.5
		var tw = create_tween()
		tw.tween_property(lp, "scale", Vector2(1.02, 1.02), 0.1)
		tw.tween_property(lp, "scale", Vector2.ONE, 0.12)
		await get_tree().create_timer(0.15).timeout
	await get_tree().create_timer(1.2).timeout
	_on_task_modal_close_pressed()
	_on_victory()

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
	rack_badge.text = "✓ GERBANG TCP & UDP AKTIF"
	rack_badge.visible = true

	var pd = get_node_or_null("/root/PlayerData")
	if pd and pd.has_method("set_level_stars"):
		pd.set_level_stars(5, 3, hearts)
	var time_str = "Waktu Tersisa: %02d:%02d" % [int(timer_seconds) / 60, int(timer_seconds) % 60]
	if game_dialog_instance:
		game_dialog_instance.show_win(
			"Jalur Protokol TCP & UDP Berhasil Dikonfigurasi!",
			"Misi Level 5.3 berhasil! Seluruh kebutuhan komunikasi telah dipasangkan dengan protokol Transport yang tepat.\n\n📌 TCP mengutamakan keandalan dan keutuhan data melalui nomor urut (sequence), ACK, dan retransmission.\n📌 UDP mengutamakan kecepatan real-time dan overhead rendah tanpa menunggu pengiriman ulang paket yang terlambat.\n🌐 Tidak ada protokol yang selalu lebih unggul: gunakan TCP saat mengunduh dokumen/email, dan gunakan UDP saat panggilan suara/video langsung.",
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
	get_tree().change_scene_to_file("res://scenes/gameplay/level_5_4.tscn")

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
		{ "title": "Misi Level 5.3", "text": "Tentukan protokol Transport yang tepat untuk tiap kebutuhan komunikasi: TCP atau UDP." },
		{ "title": "1. Konsol TCP dan UDP", "text": "Dekati konsol ini lalu klik. Arahkan kartu situasi ke Gerbang TCP bila butuh keandalan, atau ke Gerbang UDP bila butuh kecepatan real-time.", "target": rack_hotspot, "pointer": "both" },
		{ "title": "Siap?", "text": "Selesaikan misi sebelum waktu habis. Lupa caranya? Tekan tombol ? (kuning) di dekat pewaktu kapan saja untuk melihat panduan ini lagi." }
	]
