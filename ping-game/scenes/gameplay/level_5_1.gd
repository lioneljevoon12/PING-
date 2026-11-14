extends Control

# ==============================================================================
# PING! - LEVEL 5.1: MENYUSUN 7 LAPISAN MODEL OSI
# Sesuai Proposal (Stage 5) & mockup Figma Level 5.1
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

# --- DATA 7 LAPISAN OSI (sesuai level_5_1_config.json) ---
const LAYERS: Array = [
	{ "num": 1, "name": "Physical", "color": "#E2CBF7", "ex": "Kabel dan Sinyal", "desc": "Transmisi bit fisik lewat media kabel" },
	{ "num": 2, "name": "Data Link", "color": "#A2D2FF", "ex": "Ethernet & MAC Address", "desc": "Pengalamatan fisik & frame switch" },
	{ "num": 3, "name": "Network", "color": "#43D8DF", "ex": "IP Address", "desc": "Pengalamatan logis & penentuan rute" },
	{ "num": 4, "name": "Transport", "color": "#A8E6CF", "ex": "TCP dan UDP", "desc": "Pengiriman end-to-end & nomor port" },
	{ "num": 5, "name": "Session", "color": "#FFF3B0", "ex": "Pengelolaan Sesi", "desc": "Membuka & menjaga sesi komunikasi" },
	{ "num": 6, "name": "Presentation", "color": "#FFD6A5", "ex": "Format & Encoding Data", "desc": "Format, enkripsi & kompresi" },
	{ "num": 7, "name": "Application", "color": "#FFB5A7", "ex": "HTTP, DNS, SMTP", "desc": "Layanan aplikasi pengguna" },
]

# Posisi rak OSI pada background 1920x1080 (untuk hotspot interaktif)
const RACK_RECT_BG := Rect2(607, 370, 688, 545)

# Rintangan (collision) pada background 1920x1080: dinding, rak OSI, meja Client & Server
const OBSTACLES_BG: Array = [
	Rect2(0, 0, 1920, 330),       # dinding belakang
	Rect2(607, 370, 688, 545),    # Rak Menara OSI
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

func _layer_data(num: int) -> Dictionary:
	return LAYERS[num - 1]

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
	var n_lbl = _make_label("5.1", font_black, 16, Color("#4a2e2b"))
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
		_trigger_game_over("Waktu Habis! Kamu belum selesai menyusun 7 lapisan model OSI.")
		return
	_update_timer_label()

func _update_timer_label() -> void:
	timer_label.text = "%02d:%02d" % [int(timer_seconds) / 60, int(timer_seconds) % 60]
	timer_label.add_theme_color_override("font_color", Color("#e11d48") if timer_seconds <= 30.0 else Color("#4a2e2b"))

# ==============================================================================
# ROOM (background sudah memuat rak OSI, PC Client & Server)
# ==============================================================================
func _setup_room() -> void:
	room_world = Control.new()
	room_world.set_anchors_preset(Control.PRESET_FULL_RECT)
	room_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(room_world)

	# Hotspot interaktif di atas Rak Menara OSI (posisi dihitung ulang di _layout_hotspot)
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
		var start = _bg_to_screen(Rect2(470, 760, 1, 1)).position
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
	intro_overlay = IntroCard.build(self, "Level 5.1 — Menyusun 7 Lapisan Model OSI", "Sistem komunikasi error karena 7 panel lapisan OSI tersusun acak! Susun ketujuh kartu dari Lapisan 1 (Physical) di bawah hingga Lapisan 7 (Application) di atas. Seret kartu ke slot, atau klik kartu lalu klik slot tujuannya.", _on_mulai_pressed, 200, true)

func _on_mulai_pressed() -> void:
	_play_synth_sequence([523.25, 659.25, 783.99], 0.08)
	intro_overlay.visible = false
	_start_after_tutorial()

# ==============================================================================
# TASK MODAL (Mini-game susun 7 OSI Layer)
# ==============================================================================
func _setup_task_modal() -> void:
	task_modal_overlay = ColorRect.new()
	task_modal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	task_modal_overlay.color = Color(0, 0, 0, 0.65)
	task_modal_overlay.z_index = 250
	task_modal_overlay.visible = false
	add_child(task_modal_overlay)

	task_card = PanelContainer.new()
	task_card.size = Vector2(1010, 620)
	task_card.position = Vector2((1560 - 1010) / 2.0, (720 - 620) / 2.0 + 10.0)
	var sb = _make_box(Color("#fdf8ef"), Color("#4a2e2b"), 4, 22)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	task_card.add_theme_stylebox_override("panel", sb)
	task_modal_overlay.add_child(task_card)

	# Konten absolut di dalam kartu
	var root = Control.new()
	root.custom_minimum_size = Vector2(1010, 620)
	task_card.add_child(root)

	# Header lavender
	var hdr_bg = Panel.new()
	hdr_bg.size = Vector2(1010, 58)
	var sb_hdr = StyleBoxFlat.new()
	sb_hdr.bg_color = Color("#e4cdfa")
	sb_hdr.corner_radius_top_left = 20
	sb_hdr.corner_radius_top_right = 20
	hdr_bg.add_theme_stylebox_override("panel", sb_hdr)
	root.add_child(hdr_bg)

	var title = _make_label("Level 5.1: Susun 7 Lapisan Model OSI (Dari Lapisan 1 Bawah ke Lapisan 7 Atas)", font_black, 17, Color("#3b2a5a"))
	title.position = Vector2(0, 16)
	title.size = Vector2(1010, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var close_btn = preload("res://scenes/close_button.tscn").instantiate()
	close_btn.position = Vector2(1010 - 52, 10)
	close_btn.custom_minimum_size = Vector2(38, 38)
	close_btn.size = Vector2(38, 38)
	if close_btn.has_signal("pressed"):
		close_btn.pressed.connect(_on_task_modal_close_pressed)
	elif close_btn.has_signal("clicked"):
		close_btn.clicked.connect(_on_task_modal_close_pressed)
	elif close_btn.has_signal("closed"):
		close_btn.closed.connect(_on_task_modal_close_pressed)
	root.add_child(close_btn)

	# Area isi
	var body = Panel.new()
	body.position = Vector2(20, 72)
	body.size = Vector2(970, 506)
	body.add_theme_stylebox_override("panel", _make_box(Color("#f9f3e7"), Color("#d8cbb0"), 2, 18))
	root.add_child(body)

	var h_left = _make_label("1. KARTU OSI ACAK (KLIK / GESER):", font_black, 13, Color("#4a2e2b"))
	h_left.position = Vector2(40, 82)
	h_left.size = Vector2(360, 22)
	h_left.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(h_left)

	var h_right = _make_label("2. PANEL URUTAN 7 OSI LAYER (L7 ATAS ➜ L1 BAWAH):", font_black, 13, Color("#4a2e2b"))
	h_right.position = Vector2(430, 82)
	h_right.size = Vector2(540, 22)
	h_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(h_right)

	# Kartu acak di kolom kiri
	var order: Array = [4, 1, 7, 3, 6, 2, 5]
	order.shuffle()
	# Hindari urutan acak yang kebetulan sama dengan urutan benar
	if order == [1, 2, 3, 4, 5, 6, 7] or order == [7, 6, 5, 4, 3, 2, 1]:
		order = [4, 1, 7, 3, 6, 2, 5]
	for i in range(order.size()):
		var layer: int = order[i]
		var c = _build_card(layer)
		c.position = Vector2(40, 112 + i * 66)
		root.add_child(c)
		card_nodes[layer] = c

	# Slot di kolom kanan (L7 paling atas -> L1 paling bawah)
	for i in range(7):
		var layer = 7 - i
		var s = _build_slot(layer)
		s.position = Vector2(430, 112 + i * 66)
		root.add_child(s)
		slot_nodes[layer] = s

	# Status
	modal_status_lbl = _make_label("Seret kartu ke slot yang cocok dengan fungsinya, atau klik kartu lalu klik slot tujuan.", font_extrabold, 12, Color("#7c5843"))
	modal_status_lbl.position = Vector2(30, 582)
	modal_status_lbl.size = Vector2(950, 24)
	modal_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(modal_status_lbl)

func _build_card(layer: int) -> Panel:
	var d = _layer_data(layer)
	var p = Panel.new()
	p.size = Vector2(360, 58)
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.add_theme_stylebox_override("panel", _make_box(Color(d["color"]), Color("#5a3a33"), 3, 14))
	var name_l = _make_label("📇 " + d["name"], font_black, 15, Color("#3b3358"))
	name_l.position = Vector2(14, 6)
	p.add_child(name_l)
	var ex_l = _make_label(d["ex"], font_bold, 11, Color("#3b3358"))
	ex_l.position = Vector2(34, 32)
	p.add_child(ex_l)
	p.gui_input.connect(func(ev: InputEvent): _on_card_gui_input(ev, layer))
	return p

func _build_slot(layer: int) -> Panel:
	var d = _layer_data(layer)
	var p = Panel.new()
	p.size = Vector2(540, 58)
	var sb = _make_box(Color("#fffdf8"), Color("#5a3a33"), 2, 12)
	p.add_theme_stylebox_override("panel", sb)
	slot_styles[layer] = sb

	var tag = Label.new()
	tag.text = "Lapisan %d" % layer
	tag.position = Vector2(10, 11)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.add_theme_font_override("font", font_black)
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color("#3b3358"))
	tag.add_theme_stylebox_override("normal", _make_box(Color(d["color"]), Color("#5a3a33"), 2, 8))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tag)

	var fn_l = _make_label("Fungsi: " + d["desc"], font_extrabold, 12, Color("#4a2e2b"))
	fn_l.position = Vector2(114, 8)
	p.add_child(fn_l)
	var ex_l = _make_label("Contoh: " + d["ex"], font_bold, 11, Color("#2563eb"))
	ex_l.position = Vector2(114, 32)
	p.add_child(ex_l)

	var pill = Label.new()
	pill.text = "?"
	pill.position = Vector2(404, 11)
	pill.size = Vector2(126, 36)
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_theme_font_override("font", font_black)
	pill.add_theme_font_size_override("font_size", 13)
	pill.add_theme_color_override("font_color", Color("#a8a29e"))
	pill.add_theme_stylebox_override("normal", _make_box(Color("#f1ebde"), Color("#d6cbb5"), 2, 10))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(pill)
	slot_pills[layer] = pill

	p.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			if selected_layer > 0 and not placed.has(layer):
				_try_place(selected_layer, layer)
	)
	return p

func _on_card_gui_input(ev: InputEvent, layer: int) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if placed.has(layer):
			return
		_select_card(layer)
		drag_layer = layer
		drag_active = false
		drag_press_pos = get_global_mouse_position()

func _select_card(layer: int) -> void:
	selected_layer = layer
	_play_synth_sequence([660.0], 0.05)
	for ln in card_nodes:
		var c = card_nodes[ln] as Panel
		if placed.has(ln):
			continue
		var d = _layer_data(ln)
		var is_sel = (ln == layer)
		c.add_theme_stylebox_override("panel", _make_box(Color(d["color"]), Color("#e11d48") if is_sel else Color("#5a3a33"), 5 if is_sel else 3, 14))
		c.scale = Vector2(1.03, 1.03) if is_sel else Vector2.ONE
		c.pivot_offset = c.size * 0.5
	modal_status_lbl.text = "Kartu \"%s\" dipilih — klik slot lapisan yang fungsinya cocok." % _layer_data(layer)["name"]
	modal_status_lbl.add_theme_color_override("font_color", Color("#7c5843"))

func _begin_drag(layer: int) -> void:
	drag_active = true
	var d = _layer_data(layer)
	drag_ghost = Panel.new()
	drag_ghost.size = Vector2(300, 52)
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_ghost.z_index = 100
	drag_ghost.modulate.a = 0.92
	drag_ghost.add_theme_stylebox_override("panel", _make_box(Color(d["color"]), Color("#e11d48"), 4, 14))
	var l = _make_label(d["name"], font_black, 16, Color("#3b3358"))
	l.position = Vector2(16, 12)
	drag_ghost.add_child(l)
	task_modal_overlay.add_child(drag_ghost)
	drag_ghost.position = get_global_mouse_position() - drag_ghost.size * 0.5
	if card_nodes.has(layer):
		(card_nodes[layer] as Control).modulate.a = 0.35
	_select_card(layer)

func _try_place(card_layer: int, slot_layer: int) -> void:
	if placed.has(slot_layer) or placed.has(card_layer):
		return
	if card_nodes.has(card_layer):
		(card_nodes[card_layer] as Control).modulate.a = 1.0
	if card_layer == slot_layer:
		_on_correct_place(card_layer)
	else:
		_on_wrong_place(card_layer, slot_layer)

func _on_correct_place(layer: int) -> void:
	placed[layer] = true
	selected_layer = 0
	var d = _layer_data(layer)
	(card_nodes[layer] as Control).visible = false
	# Slot menyala hijau
	var sb = slot_styles[layer] as StyleBoxFlat
	sb.bg_color = Color("#d9f5e6")
	sb.border_color = Color("#15803d")
	var pill = slot_pills[layer] as Label
	pill.text = "✓ " + d["name"]
	pill.add_theme_color_override("font_color", Color("#14532d"))
	pill.add_theme_stylebox_override("normal", _make_box(Color("#a7e8cc"), Color("#15803d"), 2, 10))
	_play_synth_sequence([587.33, 880.0], 0.08)
	var s = slot_nodes[layer] as Control
	s.pivot_offset = s.size * 0.5
	var tw = create_tween()
	tw.tween_property(s, "scale", Vector2(1.03, 1.03), 0.08)
	tw.tween_property(s, "scale", Vector2.ONE, 0.1)

	modal_status_lbl.text = "✓ Lapisan %d (%s) tepat! Sisa %d kartu." % [layer, d["name"], 7 - placed.size()]
	modal_status_lbl.add_theme_color_override("font_color", Color("#16a34a"))
	if placed.size() >= 7:
		_on_all_placed()

func _on_wrong_place(card_layer: int, slot_layer: int) -> void:
	hearts = max(0, hearts - 1)
	_update_hearts_ui()
	_play_synth_sequence([220.0, 165.0], 0.12, "square")
	# Slot goyang & berkedip coral
	var s = slot_nodes[slot_layer] as Control
	var sb = slot_styles[slot_layer] as StyleBoxFlat
	sb.bg_color = Color("#ffd6d1")
	sb.border_color = Color("#e11d48")
	var ox = s.position.x
	var tw = create_tween()
	tw.tween_property(s, "position:x", ox - 8.0, 0.04)
	tw.tween_property(s, "position:x", ox + 8.0, 0.06)
	tw.tween_property(s, "position:x", ox - 4.0, 0.05)
	tw.tween_property(s, "position:x", ox, 0.04)
	tw.tween_callback(func():
		sb.bg_color = Color("#fffdf8")
		sb.border_color = Color("#5a3a33")
	)
	# Kartu kembali ke gaya normal
	selected_layer = 0
	for ln in card_nodes:
		if not placed.has(ln):
			var d = _layer_data(ln)
			var c = card_nodes[ln] as Panel
			c.add_theme_stylebox_override("panel", _make_box(Color(d["color"]), Color("#5a3a33"), 3, 14))
			c.scale = Vector2.ONE
	modal_status_lbl.text = "✗ Kartu \"%s\" bukan untuk Lapisan %d. Baca lagi fungsi & contohnya! (-1 ❤)" % [_layer_data(card_layer)["name"], slot_layer]
	modal_status_lbl.add_theme_color_override("font_color", Color("#e11d48"))
	_shake_card()
	if hearts <= 0:
		await get_tree().create_timer(0.5).timeout
		_on_task_modal_close_pressed()
		_trigger_game_over("Nyawa habis! Urutan 7 lapisan OSI belum tersusun dengan benar. Coba lagi!")

func _shake_card() -> void:
	var ox = task_card.position.x
	var tw = create_tween()
	tw.tween_property(task_card, "position:x", ox - 6.0, 0.04)
	tw.tween_property(task_card, "position:x", ox + 6.0, 0.06)
	tw.tween_property(task_card, "position:x", ox, 0.05)

func _on_all_placed() -> void:
	modal_status_lbl.text = "✓ Semua 7 lapisan OSI menyala hijau secara berurutan! Sistem komunikasi pulih!"
	_play_synth_sequence([523.25, 659.25, 783.99, 1046.50], 0.1)
	# Nyalakan panel secara berurutan Lapisan 1 -> 7 (efek pulse)
	for layer in range(1, 8):
		var s = slot_nodes[layer] as Control
		s.pivot_offset = s.size * 0.5
		var tw = create_tween()
		tw.tween_property(s, "scale", Vector2(1.04, 1.04), 0.1)
		tw.tween_property(s, "scale", Vector2.ONE, 0.12)
		await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(0.5).timeout
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
	rack_badge.text = "✓ 7/7 LAPISAN OSI AKTIF"
	rack_badge.visible = true

	var pd = get_node_or_null("/root/PlayerData")
	if pd and pd.has_method("set_level_stars"):
		pd.set_level_stars(5, 1, hearts)
	var time_str = "Waktu Tersisa: %02d:%02d" % [int(timer_seconds) / 60, int(timer_seconds) % 60]
	if game_dialog_instance:
		game_dialog_instance.show_win(
			"7 Lapisan Model OSI Aktif & Terurut!",
			"Misi Level 5.1 berhasil! Lapisan 1 (Physical) hingga Lapisan 7 (Application) telah menyala hijau.\n\n📌 Model OSI membagi komunikasi jaringan menjadi 7 lapisan, dari fisik kabel (L1) hingga aplikasi pengguna (L7).\n🌐 Tips teknisi: saat jaringan bermasalah, periksa dari Lapisan 1 (apakah kabel UTP terpasang?) sebelum memeriksa IP (L3) atau aplikasi (L7).",
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
	get_tree().change_scene_to_file("res://scenes/gameplay/level_5_2.tscn")

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
		{ "title": "Misi Level 5.1", "text": "Susun ketujuh kartu lapisan OSI dari Lapisan 1 (Physical) sampai Lapisan 7 (Application)." },
		{ "title": "1. Rak Menara OSI", "text": "Dekati rak ini lalu klik untuk membuka tugas. Di pop up, tekan Klik Susun dan atur kartu dari Lapisan 1 di bawah sampai Lapisan 7 di atas.", "target": rack_hotspot, "pointer": "both" },
		{ "title": "Siap?", "text": "Selesaikan misi sebelum waktu habis. Lupa caranya? Tekan tombol ? (kuning) di dekat pewaktu kapan saja untuk melihat panduan ini lagi." }
	]
