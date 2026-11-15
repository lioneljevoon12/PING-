extends Control

# ==============================================================================
# PING! - LEVEL 4.2: MEMPERBAIKI PUSAT TOPOLOGI STAR
# 100% Sesuai Figma & Proposal
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

var tex_decor_router = preload("res://art/assets/PING! Assets/asset-gameplay/stage4/decor-router.png")
var tex_card_lan = preload("res://art/assets/PING! Assets/asset-gameplay/stage4/Card_Situation_LAN.png")

# --- ONREADY NODES ---
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer
@onready var background: TextureRect = %Background
@onready var door_arch: TextureRect = %DoorArch
@onready var plant_decor: TextureRect = %PlantDecor

# --- GAME STATE ---
var hearts: int = 3
var timer_seconds: float = 165.0
var is_game_active: bool = false
var is_modal_open: bool = false

# Topologi Star Cables status: [PC-01, PC-02, PC-03, PC-04]
var cable_connected: Dictionary = {
	"pc01": false,
	"pc02": false,
	"pc03": false,
	"pc04": false
}

# --- UI REFS ---
var header_ui: Control
var hearts_container: HBoxContainer
var hearts_rects: Array[TextureRect] = []
var timer_label: Label
var pause_modal_scene = preload("res://scenes/pause_modal.tscn")
var game_dialog_scene = preload("res://scenes/game_dialog.tscn")
var game_dialog_instance = null

# Intro Modal
var intro_overlay: ColorRect

# Task Modal
var task_modal_overlay: ColorRect
var modal_cable_lines: Dictionary = {}
var modal_status_lbl: Label

# Room Elements
var room_world: Control
var cable_draw_node: Control
var flying_packet: Control
var pc_desks: Dictionary = {}
var switch_desk: Control
var char_sprite: TextureRect
var tex_pc_red = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PC_MERAH.png")
var tex_pc_green = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PC_HIJAU.png")
var tex_desk_pc = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/meja_pc.png")
var obstacles: Array = []   # kotak tabrakan (koordinat layar)
var walk_frames: Array[Texture2D] = []
var walk_idx: float = 0.0
const CHAR_W := 220.0
const CHAR_H := 121.0
var char_pos: Vector2 = Vector2(780, 650)
var char_target_pos: Vector2 = Vector2(780, 650)
var char_speed: float = 240.0
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

func _process(delta: float) -> void:
	if is_game_active and not is_modal_open:
		_process_timer(delta)
		_process_character_movement(delta)
		_process_flying_packet(delta)

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
# HEADER UI
# ==============================================================================
func _setup_header_ui() -> void:
	header_ui = Control.new()
	header_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_ui)
	
	# Back Button (<)
	var back_btn = Button.new()
	back_btn.text = "<"
	back_btn.position = Vector2(30, 20)
	back_btn.size = Vector2(64, 64)
	var sb_b = StyleBoxFlat.new()
	sb_b.bg_color = Color("#fdf4eb")
	sb_b.border_color = Color("#4a2e2b")
	sb_b.set_border_width_all(3)
	sb_b.set_corner_radius_all(14)
	back_btn.add_theme_stylebox_override("normal", sb_b)
	back_btn.add_theme_font_override("font", font_black)
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UiKit.style_back_button(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	header_ui.add_child(back_btn)
	
	# Hearts Container (3 Nyawa)
	var hearts_panel = PanelContainer.new()
	hearts_panel.position = Vector2(110, 20)
	hearts_panel.size = Vector2(140, 64)
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color("#fdf4eb")
	sb_h.border_color = Color("#4a2e2b")
	sb_h.set_border_width_all(3)
	sb_h.set_corner_radius_all(14)
	hearts_panel.add_theme_stylebox_override("panel", sb_h)
	header_ui.add_child(hearts_panel)
	
	hearts_container = HBoxContainer.new()
	hearts_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hearts_container.add_theme_constant_override("separation", 6)
	hearts_panel.add_child(hearts_container)
	
	hearts_rects.clear()
	for i in range(3):
		var h = TextureRect.new()
		h.texture = tex_vector_heart
		h.custom_minimum_size = Vector2(34, 34)
		h.size = Vector2(34, 34)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_container.add_child(h)
		hearts_rects.append(h)
		HeartsStyle.schedule_normalize(hearts_rects)
		
	# Level 4.2 Badge
	var lvl_panel = PanelContainer.new()
	lvl_panel.position = Vector2(265, 20)
	lvl_panel.size = Vector2(80, 64)
	var sb_l = StyleBoxFlat.new()
	sb_l.bg_color = Color("#fdf4eb")
	sb_l.border_color = Color("#4a2e2b")
	sb_l.set_border_width_all(3)
	sb_l.set_corner_radius_all(14)
	lvl_panel.add_theme_stylebox_override("panel", sb_l)
	header_ui.add_child(lvl_panel)
	
	var lvl_vbox = VBoxContainer.new()
	lvl_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lvl_vbox.add_theme_constant_override("separation", -2)
	lvl_panel.add_child(lvl_vbox)
	
	var l_lbl = Label.new()
	l_lbl.text = "Level"
	l_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_lbl.add_theme_font_override("font", font_semibold)
	l_lbl.add_theme_font_size_override("font_size", 10)
	l_lbl.add_theme_color_override("font_color", Color("#7c5e58"))
	lvl_vbox.add_child(l_lbl)
	
	var num_lbl = Label.new()
	num_lbl.text = "4.2"
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_override("font", font_black)
	num_lbl.add_theme_font_size_override("font_size", 16)
	num_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	lvl_vbox.add_child(num_lbl)
	
	# Timer Badge
	var timer_panel = PanelContainer.new()
	timer_panel.position = Vector2(1150, 20)
	timer_panel.size = Vector2(170, 64)
	var sb_t = StyleBoxFlat.new()
	sb_t.bg_color = Color("#fdf4eb")
	sb_t.border_color = Color("#4a2e2b")
	sb_t.set_border_width_all(3)
	sb_t.set_corner_radius_all(14)
	timer_panel.add_theme_stylebox_override("panel", sb_t)
	header_ui.add_child(timer_panel)
	
	var timer_hbox = HBoxContainer.new()
	timer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_hbox.add_theme_constant_override("separation", 10)
	timer_panel.add_child(timer_hbox)
	
	var clock_icon = Label.new()
	clock_icon.text = "⏱"
	clock_icon.add_theme_font_override("font", font_black)
	clock_icon.add_theme_font_size_override("font_size", 22)
	clock_icon.add_theme_color_override("font_color", Color("#4a2e2b"))
	timer_hbox.add_child(clock_icon)
	
	timer_label = Label.new()
	timer_label.text = "02:45"
	timer_label.add_theme_font_override("font", font_black)
	timer_label.add_theme_font_size_override("font_size", 20)
	timer_label.add_theme_color_override("font_color", Color("#4a2e2b"))
	timer_hbox.add_child(timer_label)
	
	# Pause Button (☰)
	var pause_btn = Button.new()
	pause_btn.text = "☰"
	pause_btn.position = Vector2(1335, 20)
	pause_btn.size = Vector2(64, 64)
	var sb_p = StyleBoxFlat.new()
	sb_p.bg_color = Color("#fdf4eb")
	sb_p.border_color = Color("#4a2e2b")
	sb_p.set_border_width_all(3)
	sb_p.set_corner_radius_all(14)
	pause_btn.add_theme_stylebox_override("normal", sb_p)
	pause_btn.add_theme_font_override("font", font_black)
	pause_btn.add_theme_font_size_override("font_size", 24)
	pause_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pause_btn.pressed.connect(_on_pause_pressed)
	header_ui.add_child(pause_btn)

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
		_trigger_game_over("Waktu Habis! Kamu gagal menghubungkan topologi star tepat waktu.")
	var mins = int(timer_seconds) / 60
	var secs = int(timer_seconds) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]

# ==============================================================================
# ROOM SETUP (100% Sesuai Gambar 2 Mockup Level 4.2)
# ==============================================================================
func _load_walk_frames() -> void:
	walk_frames.clear()
	for i in range(1, 33):
		var wp = "res://art/assets/PING! Assets/Sprite animation/router walk/%d.png" % i
		if ResourceLoader.exists(wp):
			var tex = load(wp)
			if tex is Texture2D:
				walk_frames.append(tex)

func _setup_room() -> void:
	room_world = Control.new()
	room_world.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(room_world)
	
	# Left Cabinet (Rak R-01 & Cable)
	var cabinet = PanelContainer.new()
	cabinet.position = Vector2(100, 260)
	cabinet.size = Vector2(140, 250)
	var sb_cab = StyleBoxFlat.new()
	sb_cab.bg_color = Color("#c7d2fe")
	sb_cab.border_color = Color("#4338ca")
	sb_cab.set_border_width_all(3.5)
	sb_cab.set_corner_radius_all(14)
	cabinet.add_theme_stylebox_override("panel", sb_cab)
	room_world.add_child(cabinet)
	obstacles.append(Rect2(cabinet.position, cabinet.size))
	
	var cab_vbox = VBoxContainer.new()
	cab_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cab_vbox.add_theme_constant_override("separation", 16)
	cabinet.add_child(cab_vbox)
	
	# Top shelf router
	var r_icon = TextureRect.new()
	r_icon.texture = preload("res://art/assets/PING! Assets/asset-gameplay/stage2/router objects 1.png")
	r_icon.custom_minimum_size = Vector2(80, 50)
	r_icon.size = Vector2(80, 50)
	r_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab_vbox.add_child(r_icon)
	
	# Shelf divider line
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(120, 2)
	div.color = Color("#4338ca")
	cab_vbox.add_child(div)
	
	# Bottom shelf cable
	var c_icon = TextureRect.new()
	c_icon.texture = tex_card_lan
	c_icon.custom_minimum_size = Vector2(60, 40)
	c_icon.size = Vector2(60, 40)
	c_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab_vbox.add_child(c_icon)
	
	var r_lbl = Label.new()
	r_lbl.text = "R-01"
	r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r_lbl.add_theme_font_override("font", font_bold)
	r_lbl.add_theme_font_size_override("font_size", 12)
	r_lbl.add_theme_color_override("font_color", Color("#1e1b4b"))
	cab_vbox.add_child(r_lbl)
	
	# Light dashed boundary zone for Star Topology
	var star_zone = Panel.new()
	star_zone.position = Vector2(280, 310)
	star_zone.size = Vector2(860, 380)
	var sb_sz = StyleBoxFlat.new()
	sb_sz.bg_color = Color(0.9, 0.98, 0.94, 0.35)
	sb_sz.border_color = Color("#86efac")
	sb_sz.set_border_width_all(2)
	sb_sz.set_corner_radius_all(24)
	star_zone.add_theme_stylebox_override("panel", sb_sz)
	room_world.add_child(star_zone)
	
	# Cable drawing layer
	cable_draw_node = Control.new()
	cable_draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	cable_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_world.add_child(cable_draw_node)
	cable_draw_node.draw.connect(_on_draw_room_cables)
	
	# PC Desks around switch:
	# Center Switch: (710, 520)
	# PC-01: Top-Left (370, 380)
	# PC-02: Bottom-Left (370, 600)
	# PC-04: Top-Right (980, 380)
	# PC-03: Bottom-Right (980, 600)
	pc_desks["pc01"] = _create_room_pc_desk("PC-01", Vector2(370, 380))
	pc_desks["pc02"] = _create_room_pc_desk("PC-02", Vector2(370, 600))
	pc_desks["pc04"] = _create_room_pc_desk("PC-04", Vector2(980, 380))
	pc_desks["pc03"] = _create_room_pc_desk("PC-03", Vector2(980, 600))
	
	# Switch SW-01 (PUSAT)
	switch_desk = _create_room_switch_desk(Vector2(650, 520))
	
	# Flying mail packet with wings
	flying_packet = Control.new()
	flying_packet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying_packet.position = Vector2(560, 420)
	room_world.add_child(flying_packet)
	
	var mail_tex = load("res://art/assets/PING! Assets/Sprite animation/paket data/1.png")
	if mail_tex is Texture2D:
		var mail_rect = TextureRect.new()
		mail_rect.texture = mail_tex
		mail_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mail_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mail_rect.custom_minimum_size = Vector2(70, 50)
		mail_rect.size = Vector2(70, 50)
		mail_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flying_packet.add_child(mail_rect)
	else:
		var mail_lbl = Label.new()
		mail_lbl.text = "💌"
		mail_lbl.add_theme_font_size_override("font_size", 24)
		flying_packet.add_child(mail_lbl)
	
	# Character Avatar
	char_sprite = TextureRect.new()
	char_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_walk_frames()
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.texture = walk_frames[0] if walk_frames.size() > 0 else tex_char_idle
	char_sprite.custom_minimum_size = Vector2(CHAR_W, CHAR_H)
	char_sprite.size = Vector2(CHAR_W, CHAR_H)
	char_sprite.pivot_offset = Vector2(CHAR_W, CHAR_H) * 0.5
	char_sprite.position = char_pos - Vector2(CHAR_W, CHAR_H) * 0.5
	room_world.add_child(char_sprite)
	var _pd = get_node_or_null("/root/PlayerData")
	if _pd and _pd.has_method("apply_to_character"):
		_pd.apply_to_character(char_sprite)

# Semua anak meja diabaikan oleh mouse agar klik langsung diterima meja
func _ignore_mouse_children(n: Node) -> void:
	for ch in n.get_children():
		if ch is Control:
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse_children(ch)

func _create_room_pc_desk(pc_name: String, pos: Vector2) -> Control:
	var desk = Control.new()
	desk.position = pos - Vector2(65, 45)
	desk.size = Vector2(130, 95)
	room_world.add_child(desk)
	desk.add_child(_tex_rect(tex_desk_pc, Vector2(0, 0), Vector2(130, 95)))
	var mon = _tex_rect(tex_pc_red, Vector2(17, -34), Vector2(96, 88))
	mon.name = "Monitor"
	desk.add_child(mon)
	desk.add_child(_name_pill(pc_name, Vector2(25, 68), Vector2(80, 20)))
	desk.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_task_modal()
	)
	obstacles.append(Rect2(desk.position + Vector2(6, -14), desk.size + Vector2(-12, 14)))
	return desk

func _create_room_switch_desk(pos: Vector2) -> Control:
	var desk = Control.new()
	desk.position = pos
	desk.size = Vector2(160, 95)
	room_world.add_child(desk)
	desk.add_child(_tex_rect(tex_desk_pc, Vector2(0, 0), Vector2(160, 95)))
	desk.add_child(_tex_rect(tex_decor_router, Vector2(25, -8), Vector2(110, 56)))
	desk.add_child(_name_pill("SW-01 (PUSAT)", Vector2(30, 68), Vector2(100, 20)))
	desk.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_task_modal()
	)
	obstacles.append(Rect2(desk.position + Vector2(6, -6), desk.size + Vector2(-12, 6)))
	return desk


# --- Tabrakan karakter dengan perabot ---
func _feet_rect(center: Vector2) -> Rect2:
	return Rect2(center.x - 30.0, center.y + CHAR_H * 0.22, 60.0, 20.0)

func _collides_at(center: Vector2) -> bool:
	var feet = _feet_rect(center)
	for ob in obstacles:
		if feet.intersects(ob):
			return true
	return false

func _tex_rect(tex: Texture2D, pos: Vector2, sz: Vector2) -> TextureRect:
	var tr = TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture = tex
	tr.position = pos
	tr.size = sz
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

func _name_pill(txt: String, pos: Vector2, sz: Vector2) -> Label:
	var l = Label.new()
	l.text = txt
	l.position = pos
	l.size = sz
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font_black)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color("#431407"))
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fffdf8")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	l.add_theme_stylebox_override("normal", sb)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _set_monitor_ok(desk: Control, ok: bool) -> void:
	var m = desk.get_node_or_null("Monitor") as TextureRect
	if m:
		m.texture = tex_pc_green if ok else tex_pc_red

func _on_draw_room_cables() -> void:
	var sw_center = Vector2(730, 565)
	var targets = {
		"pc01": Vector2(435, 425),
		"pc02": Vector2(435, 645),
		"pc04": Vector2(915, 425),
		"pc03": Vector2(915, 645)
	}
	for id in targets:
		var target_pt = targets[id]
		var is_conn = cable_connected[id]
		var col = Color("#22c55e") if is_conn else Color("#fb7185")
		var w = 5.0 if is_conn else 4.5
		if is_conn:
			cable_draw_node.draw_line(sw_center, target_pt, col, w, true)
			cable_draw_node.draw_circle(target_pt, 7.0, Color("#ffffff"))
			cable_draw_node.draw_circle(target_pt, 4.5, col)
		else:
			# Dashed line
			_draw_dashed_line(cable_draw_node, sw_center, target_pt, col, w, 12.0)
			# Unplugged connector jack near PC
			var jack_pos = target_pt.lerp(sw_center, 0.28)
			cable_draw_node.draw_circle(jack_pos, 9.0, Color("#ffffff"))
			cable_draw_node.draw_circle(jack_pos, 6.0, col)

func _draw_dashed_line(canvas: Control, from: Vector2, to: Vector2, col: Color, width: float, dash_len: float) -> void:
	var length = from.distance_to(to)
	var dir = (to - from).normalized()
	var curr = 0.0
	var drawing = true
	while curr < length:
		var step = min(dash_len, length - curr)
		if drawing:
			canvas.draw_line(from + dir * curr, from + dir * (curr + step), col, width, true)
		curr += step
		drawing = not drawing

func _process_flying_packet(delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	var hover = sin(t * 4.0) * 8.0
	flying_packet.position.y = 420.0 + hover

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
		var try_x = char_target_pos + Vector2(step.x, 0.0)
		try_x.x = clamp(try_x.x, 150.0, 1350.0)
		if not _collides_at(try_x):
			char_target_pos = try_x
		var try_y = char_target_pos + Vector2(0.0, step.y)
		try_y.y = clamp(try_y.y, 350.0, 650.0)
		if not _collides_at(try_y):
			char_target_pos = try_y
		char_is_moving = true
		if input_vec.x < -0.05:
			char_sprite.flip_h = true
		elif input_vec.x > 0.05:
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
	joystick_base.custom_minimum_size = Vector2(130, 130)
	joystick_base.position = joystick_center - Vector2(65, 65)
	joystick_base.modulate = Color(1, 1, 1, 0.7)
	joystick_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(joystick_base)
	
	joystick_knob = TextureRect.new()
	joystick_knob.texture = tex_dpad_knob
	joystick_knob.size = Vector2(60, 60)
	joystick_knob.custom_minimum_size = Vector2(60, 60)
	joystick_knob.position = joystick_center - Vector2(30, 30)
	joystick_knob.modulate = Color(1, 1, 1, 0.9)
	joystick_knob.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(joystick_knob)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(joystick_center) < 90.0:
				joystick_touch_id = event.index
				_update_joystick(event.position)
		elif event.index == joystick_touch_id:
			_reset_joystick()
	elif event is InputEventScreenDrag and event.index == joystick_touch_id:
		_update_joystick(event.position)

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
# INTRO MODAL (100% Sesuai Gambar 1 Mockup)
# ==============================================================================
func _setup_intro_modal() -> void:
	intro_overlay = IntroCard.build(self, "Level 4.2 Memperbaiki Pusat Topologi Star", "Gawat! Keempat komputer kantor (PC-01 s/d PC-04) tidak dapat berkomunikasi! Switch Pusat (SW-01) mengalami gangguan dan jalur kabel UTP ke setiap komputer terputus. Aktifkan kembali switch pusat dan sambungkan keempat kabel hingga menyala hijau!", _on_mulai_pressed, 200, true)

func _on_mulai_pressed() -> void:
	_play_synth_sequence([523.25, 659.25, 783.99], 0.08)
	intro_overlay.visible = false
	_start_after_tutorial()

# ==============================================================================
# TASK MODAL (100% Sesuai Gambar 3 Mockup Level 4.2)
# ==============================================================================
func _setup_task_modal() -> void:
	task_modal_overlay = ColorRect.new()
	task_modal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	task_modal_overlay.color = Color(0, 0, 0, 0.65)
	task_modal_overlay.z_index = 250
	task_modal_overlay.visible = false
	add_child(task_modal_overlay)
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(960, 520)
	card.size = Vector2(960, 520)
	card.position = Vector2((1560 - 960) / 2.0, (720 - 520) / 2.0)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fafaf9")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(22)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", sb)
	task_modal_overlay.add_child(card)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(vbox)
	
	# Top Lavender Header Strip
	var header_strip = Control.new()
	header_strip.custom_minimum_size = Vector2(960, 58)
	header_strip.size = Vector2(960, 58)
	vbox.add_child(header_strip)
	
	var sb_bg = Panel.new()
	sb_bg.size = Vector2(960, 58)
	var sb_hdr = StyleBoxFlat.new()
	sb_hdr.bg_color = Color("#e9d5ff")
	sb_hdr.corner_radius_top_left = 18
	sb_hdr.corner_radius_top_right = 18
	sb_bg.add_theme_stylebox_override("panel", sb_hdr)
	header_strip.add_child(sb_bg)
	
	var title = Label.new()
	title.text = "Level 4.2: Perbaikan Switch Pusat Topologi Star"
	title.position = Vector2(0, 15)
	title.size = Vector2(960, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font_black)
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("#3b0764"))
	header_strip.add_child(title)
	
	# Universal Close Button
	var close_btn_scene = preload("res://scenes/close_button.tscn")
	var close_btn = close_btn_scene.instantiate()
	close_btn.position = Vector2(960 - 52, 10)
	close_btn.custom_minimum_size = Vector2(38, 38)
	close_btn.size = Vector2(38, 38)
	if close_btn.has_signal("pressed"):
		close_btn.pressed.connect(_on_task_modal_close_pressed)
	elif close_btn.has_signal("clicked"):
		close_btn.clicked.connect(_on_task_modal_close_pressed)
	elif close_btn.has_signal("closed"):
		close_btn.closed.connect(_on_task_modal_close_pressed)
	header_strip.add_child(close_btn)
	
	# Content Body with Dashed Border
	var body_margin = MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 24)
	body_margin.add_theme_constant_override("margin_right", 24)
	body_margin.add_theme_constant_override("margin_top", 16)
	body_margin.add_theme_constant_override("margin_bottom", 16)
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body_margin)
	
	var inner_box = Panel.new()
	var sb_in = StyleBoxFlat.new()
	sb_in.bg_color = Color("#ffffff")
	sb_in.border_color = Color("#d6d3d1")
	sb_in.set_border_width_all(2.5)
	sb_in.set_corner_radius_all(18)
	inner_box.add_theme_stylebox_override("panel", sb_in)
	body_margin.add_child(inner_box)
	
	# Star diagram container inside inner box
	var diagram = Control.new()
	diagram.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner_box.add_child(diagram)
	
	# Draw lines node for diagram
	var line_draw = Control.new()
	line_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	line_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	diagram.add_child(line_draw)
	line_draw.draw.connect(_on_draw_modal_star_lines)
	modal_cable_lines["draw"] = line_draw
	
	# Center Switch SW-01
	var sw_center_box = VBoxContainer.new()
	sw_center_box.position = Vector2(385, 155)
	sw_center_box.size = Vector2(140, 105)
	sw_center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	sw_center_box.add_theme_constant_override("separation", 6)
	diagram.add_child(sw_center_box)
	
	var sw_img = TextureRect.new()
	sw_img.texture = tex_decor_router
	sw_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sw_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sw_img.custom_minimum_size = Vector2(130, 60)
	sw_img.size = Vector2(130, 60)
	sw_center_box.add_child(sw_img)
	
	var sw_lbl_box = PanelContainer.new()
	var sb_lbl = StyleBoxFlat.new()
	sb_lbl.bg_color = Color("#fef08a")
	sb_lbl.border_color = Color("#ca8a04")
	sb_lbl.set_border_width_all(2)
	sb_lbl.set_corner_radius_all(8)
	sw_lbl_box.add_theme_stylebox_override("panel", sb_lbl)
	sw_center_box.add_child(sw_lbl_box)
	
	var sw_lbl = Label.new()
	sw_lbl.text = "SW-01 (PUSAT)"
	sw_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sw_lbl.add_theme_font_override("font", font_black)
	sw_lbl.add_theme_font_size_override("font_size", 11)
	sw_lbl.add_theme_color_override("font_color", Color("#854d0e"))
	sw_lbl_box.add_child(sw_lbl)
	
	# 4 PC Buttons in Modal:
	# PC-01 (120, 110)
	# PC-02 (120, 270)
	# PC-04 (660, 110)
	# PC-03 (660, 270)
	_build_modal_pc_btn(diagram, "pc01", "PC-01", Vector2(120, 110))
	_build_modal_pc_btn(diagram, "pc02", "PC-02", Vector2(120, 270))
	_build_modal_pc_btn(diagram, "pc04", "PC-04", Vector2(660, 110))
	_build_modal_pc_btn(diagram, "pc03", "PC-03", Vector2(660, 270))
	
	# Interactive click zones on the 4 cable paths
	_build_modal_cable_click_area(diagram, "pc01", Vector2(250, 145))
	_build_modal_cable_click_area(diagram, "pc02", Vector2(250, 260))
	_build_modal_cable_click_area(diagram, "pc04", Vector2(590, 145))
	_build_modal_cable_click_area(diagram, "pc03", Vector2(590, 260))
	
	# Status instruction label
	modal_status_lbl = Label.new()
	modal_status_lbl.text = "Klik kabel merah muda atau kotak PC untuk menyambungkan kabel UTP ke Switch Pusat (SW-01)!"
	modal_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_status_lbl.position = Vector2(0, 380)
	modal_status_lbl.size = Vector2(910, 30)
	modal_status_lbl.add_theme_font_override("font", font_extrabold)
	modal_status_lbl.add_theme_font_size_override("font_size", 13)
	modal_status_lbl.add_theme_color_override("font_color", Color("#b91c1c"))
	diagram.add_child(modal_status_lbl)

func _build_modal_pc_btn(parent: Control, id: String, title: String, pos: Vector2) -> void:
	var btn = Button.new()
	btn.text = title
	btn.position = pos
	btn.custom_minimum_size = Vector2(130, 48)
	btn.size = Vector2(130, 48)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ccfbf1")
	sb.border_color = Color("#0f766e")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_font_override("font", font_black)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color("#134e4a"))
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func(): _on_toggle_cable(id))
	parent.add_child(btn)

func _build_modal_cable_click_area(parent: Control, id: String, pos: Vector2) -> void:
	var btn = Button.new()
	btn.flat = true
	btn.text = ""
	btn.position = pos - Vector2(5, 0)
	btn.custom_minimum_size = Vector2(120, 38)
	btn.size = Vector2(120, 38)
	var sb_n = StyleBoxFlat.new()
	sb_n.bg_color = Color(1, 1, 1, 0)
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color(1.0, 0.72, 0.78, 0.45)
	sb_h.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	btn.add_theme_stylebox_override("focus", sb_n)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func(): _on_toggle_cable(id))
	parent.add_child(btn)

func _on_draw_modal_star_lines() -> void:
	var draw_node = modal_cable_lines.get("draw") as Control
	if not draw_node:
		return
	var sw_pt = Vector2(455, 210)
	var pts = {
		"pc01": Vector2(250, 134),
		"pc02": Vector2(250, 294),
		"pc04": Vector2(660, 134),
		"pc03": Vector2(660, 294)
	}
	for id in pts:
		var target = pts[id]
		var is_conn = cable_connected[id]
		var col = Color("#22c55e") if is_conn else Color("#fda4af")
		var w = 7.0 if is_conn else 6.0
		draw_node.draw_line(sw_pt, target, col, w, true)
		var plug = target.lerp(sw_pt, 0.12)
		draw_node.draw_circle(plug, 8.0, Color("#ffffff"))
		draw_node.draw_circle(plug, 5.5, col)

func _on_toggle_cable(id: String) -> void:
	cable_connected[id] = not cable_connected[id]
	if pc_desks.has(id):
		_set_monitor_ok(pc_desks[id], cable_connected[id])
	if cable_connected[id]:
		_play_synth_sequence([587.33, 880.0], 0.08)
	else:
		_play_synth_sequence([350.0], 0.08)
		
	# Redraw
	if modal_cable_lines.has("draw"):
		(modal_cable_lines["draw"] as Control).queue_redraw()
	if cable_draw_node:
		cable_draw_node.queue_redraw()
		
	# Check completion
	var all_done = true
	for k in cable_connected:
		if not cable_connected[k]:
			all_done = false
			break
			
	if all_done:
		modal_status_lbl.text = "✓ Semua kabel terhubung! Topologi Star kembali normal!"
		modal_status_lbl.add_theme_color_override("font_color", Color("#16a34a"))
		_play_synth_sequence([523.25, 659.25, 783.99, 1046.50], 0.1)
		await get_tree().create_timer(0.6).timeout
		_on_task_modal_close_pressed()
		_on_victory()

func _open_task_modal() -> void:
	_play_synth_sequence([440.0], 0.08)
	task_modal_overlay.visible = true
	is_modal_open = true
	if modal_cable_lines.has("draw"):
		(modal_cable_lines["draw"] as Control).queue_redraw()

func _on_task_modal_close_pressed() -> void:
	_play_synth_sequence([350.0], 0.08)
	task_modal_overlay.visible = false
	is_modal_open = false

# ==============================================================================
# VICTORY & GAME OVER
# ==============================================================================
func _setup_game_dialog() -> void:
	game_dialog_instance = game_dialog_scene.instantiate()
	game_dialog_instance.z_index = 350
	add_child(game_dialog_instance)

func _on_victory() -> void:
	is_game_active = false
	# Semua PC menyala hijau
	for id in pc_desks:
		_set_monitor_ok(pc_desks[id], true)

	var pd = get_node_or_null("/root/PlayerData")
	if pd and pd.has_method("set_level_stars"):
		pd.set_level_stars(4, 2, hearts)
	var time_str = "Waktu Tersisa: %02d:%02d" % [int(timer_seconds) / 60, int(timer_seconds) % 60]
	if game_dialog_instance:
		game_dialog_instance.show_win(
			"MISI SELESAI!",
			"Luar biasa! Switch Pusat (SW-01) dan seluruh kabel komputer PC-01 s/d PC-04 telah terhubung kembali secara sempurna dalam Topologi Star!",
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
			msg if msg != "" else "Koneksi kabel ke Switch Pusat belum terpasang dengan benar. Coba lagi!",
			Callable(self, "_on_restart_level"),
			Callable(self, "_on_map_pressed")
		)

func _on_next_level() -> void:
	get_tree().change_scene_to_file("res://scenes/gameplay/level_4_3.tscn")

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
		{ "title": "Misi Level 4.2", "text": "PC-01 sampai PC-04 tidak bisa saling berkomunikasi. Perbaiki Switch Pusat dan kabel UTP yang putus (merah)." },
		{ "title": "1. Switch Pusat", "text": "Klik meja SW-01 ini untuk membuka tugas perbaikan topologi Star.", "target": switch_desk, "pointer": "both" },
		{ "title": "2. Empat PC", "text": "Tiap PC harus tersambung ke switch lewat kabel UTP. Kabel merah = putus, hijau = tersambung. PC juga bisa diklik untuk membuka tugas.", "target": Rect2(310, 290, 760, 360), "pointer": "arrow" },
		{ "title": "Siap?", "text": "Selesaikan misi sebelum waktu habis. Lupa caranya? Tekan tombol ? (kuning) di dekat pewaktu kapan saja untuk melihat panduan ini lagi." }
	]
