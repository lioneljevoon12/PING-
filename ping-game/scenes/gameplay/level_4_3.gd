extends Control

# ==============================================================================
# PING! - LEVEL 4.3: MEMPERBAIKI TOPOLOGI RING DAN MESH
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

# Ring Topology (4 segments: top, right, bottom, left)
# In mockup: left-bottom segment between PC-04 and PC-03 is disconnected.
var ring_connected: Dictionary = {
	"top_right": true,
	"bottom_right": true,
	"bottom_left": false,
	"top_left": true
}

# Mesh Topology (6 lines: top, bottom, left, right, diag1, diag2)
# In mockup: top (R01-PC01), left (R01-PC02), bottom (PC02-PC03) are green.
# right (PC01-PC03), diag1 (R01-PC03), diag2 (PC01-PC02) are disconnected (red).
var mesh_connected: Dictionary = {
	"top": true,
	"left": true,
	"bottom": true,
	"right": false,
	"diag1": false, # R-01 to PC-03
	"diag2": false  # PC-01 to PC-02
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
var modal_ring_draw: Control
var modal_mesh_draw: Control
var modal_status_lbl: Label

# Room Elements
var room_world: Control
var ring_draw_node: Control
var mesh_draw_node: Control
var ring_packet: Control
var ring_nodes: Dictionary = {}
var mesh_nodes: Dictionary = {}

var char_sprite: TextureRect
var tex_pc_red = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PC_MERAH.png")
var tex_pc_green = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PC_HIJAU.png")
var tex_desk_pc = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/meja_pc.png")
var obstacles: Array = []   # kotak tabrakan (koordinat layar)
var walk_frames: Array[Texture2D] = []
var walk_idx: float = 0.0
const CHAR_W := 220.0
const CHAR_H := 121.0
var char_pos: Vector2 = Vector2(780, 580)
var char_target_pos: Vector2 = Vector2(780, 580)
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
		_process_ring_packet(delta)

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
		
	# Level 4.3 Badge
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
	num_lbl.text = "4.3"
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

func _on_back_pressed() -> void:
	_play_synth_sequence([350.0], 0.08)
	get_tree().change_scene_to_file("res://scenes/level_path.tscn")

func _on_pause_pressed() -> void:
	_play_synth_sequence([500.0], 0.08)
	var pause_modal = pause_modal_scene.instantiate()
	pause_modal.z_index = 300
	add_child(pause_modal)

func _process_timer(delta: float) -> void:
	timer_seconds -= delta
	if timer_seconds <= 0.0:
		timer_seconds = 0.0
		_trigger_game_over("Waktu Habis! Kamu gagal menyelesaikan perbaikan Topologi Ring & Mesh.")
	var mins = int(timer_seconds) / 60
	var secs = int(timer_seconds) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]

# ==============================================================================
# ROOM SETUP (100% Sesuai Gambar 5 Mockup Level 4.3)
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
	
	# Center vertical dashed separator line
	var sep_node = Control.new()
	sep_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	sep_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_world.add_child(sep_node)
	sep_node.draw.connect(func():
		var p1 = Vector2(745, 300)
		var p2 = Vector2(745, 700)
		_draw_dashed_line(sep_node, p1, p2, Color("#78716c"), 2.5, 10.0)
	)
	
	# ----------------- ZONE 1: TOPOLOGI RING (LEFT) -----------------
	var ring_zone = Panel.new()
	ring_zone.position = Vector2(80, 310)
	ring_zone.size = Vector2(620, 380)
	var sb_rz = StyleBoxFlat.new()
	sb_rz.bg_color = Color(0.9, 0.98, 0.95, 0.35)
	sb_rz.border_color = Color("#86efac")
	sb_rz.set_border_width_all(2)
	sb_rz.set_corner_radius_all(22)
	ring_zone.add_theme_stylebox_override("panel", sb_rz)
	room_world.add_child(ring_zone)
	
	# Header badge Zone 1
	var ring_hdr = PanelContainer.new()
	ring_hdr.position = Vector2(250, 305)
	ring_hdr.size = Vector2(240, 32)
	var sb_rh = StyleBoxFlat.new()
	sb_rh.bg_color = Color("#e0e7ff")
	sb_rh.border_color = Color("#4338ca")
	sb_rh.set_border_width_all(2)
	sb_rh.set_corner_radius_all(10)
	ring_hdr.add_theme_stylebox_override("panel", sb_rh)
	room_world.add_child(ring_hdr)
	
	var r_lbl = Label.new()
	r_lbl.text = "ZONA 1: TOPOLOGI RING"
	r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r_lbl.add_theme_font_override("font", font_black)
	r_lbl.add_theme_font_size_override("font_size", 11)
	r_lbl.add_theme_color_override("font_color", Color("#312e81"))
	ring_hdr.add_child(r_lbl)
	
	# Ring Cable Draw Node
	ring_draw_node = Control.new()
	ring_draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_world.add_child(ring_draw_node)
	ring_draw_node.draw.connect(_on_draw_room_ring)
	
	# 4 PC Desks in Ring:
	# Center = (370, 520), Radius ~130
	# Top: PC-01 (370, 390)
	# Right: PC-02 (500, 520)
	# Bottom: PC-03 (370, 650)
	# Left: PC-04 (240, 520)
	ring_nodes["pc01"] = _create_room_desk("PC-01", Vector2(370, 390), false, true)
	ring_nodes["pc02"] = _create_room_desk("PC-02", Vector2(500, 520), false, true)
	ring_nodes["pc03"] = _create_room_desk("PC-03", Vector2(370, 650), false, false) # sad
	ring_nodes["pc04"] = _create_room_desk("PC-04", Vector2(240, 520), false, false) # sad
	
	# Ring animated mail packet
	ring_packet = Control.new()
	ring_packet.position = Vector2(460, 430)
	ring_packet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_world.add_child(ring_packet)
	var pkt_tex = load("res://art/assets/PING! Assets/Sprite animation/paket data/1.png")
	if pkt_tex is Texture2D:
		var pkt_rect = TextureRect.new()
		pkt_rect.texture = pkt_tex
		pkt_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pkt_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pkt_rect.custom_minimum_size = Vector2(64, 46)
		pkt_rect.size = Vector2(64, 46)
		pkt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring_packet.add_child(pkt_rect)
	else:
		var pkt_lbl = Label.new()
		pkt_lbl.text = "💌"
		pkt_lbl.add_theme_font_size_override("font_size", 20)
		ring_packet.add_child(pkt_lbl)
	
	# ----------------- ZONE 2: TOPOLOGI MESH (RIGHT) -----------------
	var mesh_zone = Panel.new()
	mesh_zone.position = Vector2(780, 310)
	mesh_zone.size = Vector2(620, 380)
	var sb_mz = StyleBoxFlat.new()
	sb_mz.bg_color = Color(0.96, 0.93, 0.99, 0.35)
	sb_mz.border_color = Color("#c084fc")
	sb_mz.set_border_width_all(2)
	sb_mz.set_corner_radius_all(22)
	mesh_zone.add_theme_stylebox_override("panel", sb_mz)
	room_world.add_child(mesh_zone)
	
	# Header badge Zone 2
	var mesh_hdr = PanelContainer.new()
	mesh_hdr.position = Vector2(970, 305)
	mesh_hdr.size = Vector2(240, 32)
	var sb_mh = StyleBoxFlat.new()
	sb_mh.bg_color = Color("#f3e8ff")
	sb_mh.border_color = Color("#7e22ce")
	sb_mh.set_border_width_all(2)
	sb_mh.set_corner_radius_all(10)
	mesh_hdr.add_theme_stylebox_override("panel", sb_mh)
	room_world.add_child(mesh_hdr)
	
	var m_lbl = Label.new()
	m_lbl.text = "ZONA 2: TOPOLOGI MESH"
	m_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	m_lbl.add_theme_font_override("font", font_black)
	m_lbl.add_theme_font_size_override("font_size", 11)
	m_lbl.add_theme_color_override("font_color", Color("#581c87"))
	mesh_hdr.add_child(m_lbl)
	
	# Mesh Cable Draw Node
	mesh_draw_node = Control.new()
	mesh_draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	mesh_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_world.add_child(mesh_draw_node)
	mesh_draw_node.draw.connect(_on_draw_room_mesh)
	
	# 4 Nodes in Mesh:
	# Top-Left: R-01 (890, 420)
	# Top-Right: PC-01 (1280, 420)
	# Bottom-Left: PC-02 (890, 620)
	# Bottom-Right: PC-03 (1280, 620)
	mesh_nodes["r01"] = _create_room_desk("R-01", Vector2(890, 420), true, true)
	mesh_nodes["pc01"] = _create_room_desk("PC-01", Vector2(1280, 420), false, false)
	mesh_nodes["pc02"] = _create_room_desk("PC-02", Vector2(890, 620), false, false)
	mesh_nodes["pc03"] = _create_room_desk("PC-03", Vector2(1280, 620), false, false)
	
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

func _create_room_desk(node_name: String, pos: Vector2, is_router: bool, is_happy: bool) -> Control:
	var desk = Control.new()
	desk.position = pos - Vector2(55, 40)
	desk.size = Vector2(110, 80)
	room_world.add_child(desk)
	desk.add_child(_tex_rect(tex_desk_pc, Vector2(0, 0), Vector2(110, 80)))
	if is_router:
		var router_tex = load("res://art/assets/PING! Assets/asset-gameplay/stage2/router objects 1.png")
		desk.add_child(_tex_rect(router_tex, Vector2(14, -10), Vector2(82, 56)))
	else:
		var mon = _tex_rect(tex_pc_green if is_happy else tex_pc_red, Vector2(13, -28), Vector2(84, 78))
		mon.name = "Monitor"
		desk.add_child(mon)
	desk.add_child(_name_pill(node_name, Vector2(15, 57), Vector2(80, 18)))
	desk.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_task_modal()
	)
	obstacles.append(Rect2(desk.position + Vector2(4, -12), desk.size + Vector2(-8, 12)))
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

# Semua anak meja diabaikan oleh mouse agar klik langsung diterima meja
func _ignore_mouse_children(n: Node) -> void:
	for ch in n.get_children():
		if ch is Control:
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse_children(ch)

func _on_draw_room_ring() -> void:
	var pts = {
		"top": Vector2(370, 390),
		"right": Vector2(500, 520),
		"bottom": Vector2(370, 650),
		"left": Vector2(240, 520)
	}
	# Arcs/Lines:
	# top -> right: green
	ring_draw_node.draw_line(pts["top"], pts["right"], Color("#22c55e"), 4.5, true)
	# right -> bottom: green
	ring_draw_node.draw_line(pts["right"], pts["bottom"], Color("#22c55e"), 4.5, true)
	# top -> left: green
	ring_draw_node.draw_line(pts["top"], pts["left"], Color("#22c55e"), 4.5, true)
	
	# bottom -> left: disconnected in mockup
	if ring_connected["bottom_left"]:
		ring_draw_node.draw_line(pts["left"], pts["bottom"], Color("#22c55e"), 4.5, true)
	else:
		_draw_dashed_line(ring_draw_node, pts["left"], pts["bottom"], Color("#fb7185"), 3.5, 12.0)
		# loose connector plug
		var plug_pt = pts["left"].lerp(pts["bottom"], 0.25)
		ring_draw_node.draw_circle(plug_pt, 6.0, Color("#fb7185"))

func _on_draw_room_mesh() -> void:
	var r01 = Vector2(890, 420)
	var pc01 = Vector2(1280, 420)
	var pc02 = Vector2(890, 620)
	var pc03 = Vector2(1280, 620)
	
	# Top link (R01 - PC01): Green
	mesh_draw_node.draw_line(r01, pc01, Color("#22c55e"), 4.5, true)
	# Left link (R01 - PC02): Green
	mesh_draw_node.draw_line(r01, pc02, Color("#22c55e"), 4.5, true)
	# Bottom link (PC02 - PC03): Green
	mesh_draw_node.draw_line(pc02, pc03, Color("#22c55e"), 4.5, true)
	
	# Right vertical link (PC01 - PC03)
	if mesh_connected["right"]:
		mesh_draw_node.draw_line(pc01, pc03, Color("#22c55e"), 4.5, true)
	else:
		_draw_dashed_line(mesh_draw_node, pc01, pc03, Color("#fb7185"), 3.5, 12.0)
		var plug = pc03.lerp(pc01, 0.15)
		mesh_draw_node.draw_circle(plug, 6.0, Color("#fb7185"))
		
	# Diag1 (R01 - PC03)
	if mesh_connected["diag1"]:
		mesh_draw_node.draw_line(r01, pc03, Color("#22c55e"), 4.5, true)
	else:
		_draw_dashed_line(mesh_draw_node, r01, pc03, Color("#fb7185"), 3.5, 12.0)
		
	# Diag2 (PC01 - PC02)
	if mesh_connected["diag2"]:
		mesh_draw_node.draw_line(pc01, pc02, Color("#22c55e"), 4.5, true)
	else:
		_draw_dashed_line(mesh_draw_node, pc01, pc02, Color("#fb7185"), 3.5, 12.0)

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

func _process_ring_packet(delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	if ring_connected["bottom_left"]:
		# Ring lengkap: paket berputar mengelilingi siklus
		var a = t * 2.0
		var center = Vector2(370, 520)
		ring_packet.position = center + Vector2(cos(a), sin(a)) * 100.0 - Vector2(32, 23)
	else:
		# Ring putus: paket tersangkut di jalur yang terputus
		ring_packet.position = Vector2(268, 565 + sin(t * 5.0) * 5.0)

# ==============================================================================
# CHARACTER MOVEMENT
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
	var max_r = 50.0
	if diff.length() > max_r:
		diff = diff.normalized() * max_r
	joystick_vector = diff / max_r
	joystick_knob.position = joystick_center + diff - Vector2(30, 30)

func _reset_joystick() -> void:
	joystick_touch_id = -1
	joystick_vector = Vector2.ZERO
	joystick_knob.position = joystick_center - Vector2(30, 30)

# ==============================================================================
# INTRO MODAL (100% Sesuai Gambar 4 Mockup Level 4.3)
# ==============================================================================
func _setup_intro_modal() -> void:
	intro_overlay = ColorRect.new()
	intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_overlay.color = Color(0, 0, 0, 0.65)
	intro_overlay.z_index = 200
	add_child(intro_overlay)
	
	var card = Panel.new()
	card.custom_minimum_size = Vector2(740, 390)
	card.size = Vector2(740, 390)
	card.position = Vector2((1560 - 740) / 2.0, (720 - 390) / 2.0)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fef3c7")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(22)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", sb)
	intro_overlay.add_child(card)
	
	# Top Hanging Ring
	var ring = Panel.new()
	ring.custom_minimum_size = Vector2(26, 26)
	ring.size = Vector2(26, 26)
	ring.position = Vector2(357, 16)
	var sb_r = StyleBoxFlat.new()
	sb_r.bg_color = Color("#fef3c7")
	sb_r.border_color = Color("#4a2e2b")
	sb_r.set_border_width_all(3.5)
	sb_r.set_corner_radius_all(13)
	ring.add_theme_stylebox_override("panel", sb_r)
	card.add_child(ring)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_theme_constant_override("separation", 14)
	inner_vbox.offset_left = 40
	inner_vbox.offset_right = 700
	inner_vbox.offset_top = 50
	inner_vbox.offset_bottom = 350
	card.add_child(inner_vbox)
	
	# Title
	var title = Label.new()
	title.text = "Level 4.3 Memperbaiki Topologi Ring dan Mesh"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font_black)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#4a2e2b"))
	inner_vbox.add_child(title)
	
	# Underline
	var line = ColorRect.new()
	line.custom_minimum_size = Vector2(360, 2.5)
	line.color = Color("#d97706")
	var line_center = CenterContainer.new()
	line_center.add_child(line)
	inner_vbox.add_child(line_center)
	
	# Description
	var desc = Label.new()
	desc.text = "Masih ada dua zona topologi di ruangan ini yang mengalami gangguan!\nDi Zona Kiri (Topologi Ring), satu segmen kabel melingkar terlepas sehingga\npaket data gagal berputar. Di Zona Kanan (Topologi Mesh), perbaiki jalur koneksi\nsilang antar PC dan Router R-01 agar memiliki rute redundan yang valid!"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_override("font", font_bold)
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color("#4a2e2b"))
	inner_vbox.add_child(desc)
	
	# MULAI Button
	var mulai_btn = Button.new()
	mulai_btn.text = "MULAI"
	mulai_btn.custom_minimum_size = Vector2(210, 50)
	var sb_m = StyleBoxFlat.new()
	sb_m.bg_color = Color("#a7f3d0")
	sb_m.border_color = Color("#4a2e2b")
	sb_m.set_border_width_all(3)
	sb_m.set_corner_radius_all(18)
	mulai_btn.add_theme_stylebox_override("normal", sb_m)
	
	var sb_mh = sb_m.duplicate() as StyleBoxFlat
	sb_mh.bg_color = Color("#6ee7b7")
	mulai_btn.add_theme_stylebox_override("hover", sb_mh)
	
	mulai_btn.add_theme_font_override("font", font_black)
	mulai_btn.add_theme_font_size_override("font_size", 16)
	mulai_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	mulai_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mulai_btn.pressed.connect(_on_mulai_pressed)
	
	var btn_center = CenterContainer.new()
	btn_center.add_child(mulai_btn)
	inner_vbox.add_child(btn_center)
	
	# Bottom Left Avatar
	var avatar = TextureRect.new()
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.custom_minimum_size = Vector2(80, 80)
	avatar.size = Vector2(80, 80)
	avatar.position = Vector2(20, 290)
	avatar.texture = tex_technician_avatar
	card.add_child(avatar)

func _on_mulai_pressed() -> void:
	_play_synth_sequence([523.25, 659.25, 783.99], 0.08)
	intro_overlay.visible = false
	_start_after_tutorial()

# ==============================================================================
# TASK MODAL (100% Sesuai Gambar 6 Mockup Level 4.3)
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
	title.text = "Level 4.3: Konfigurasi Jalur Topologi Ring & Mesh"
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
	
	# Content Body: Two columns (Zona 1: Ring & Zona 2: Mesh)
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
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 20)
	inner_box.add_child(hbox)
	
	# ----------------- PANEL 1: ZONA 1 SIKLUS RING -----------------
	var p1 = PanelContainer.new()
	p1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb_p1 = StyleBoxFlat.new()
	sb_p1.bg_color = Color("#eff6ff")
	sb_p1.border_color = Color("#60a5fa")
	sb_p1.set_border_width_all(2)
	sb_p1.set_corner_radius_all(16)
	p1.add_theme_stylebox_override("panel", sb_p1)
	hbox.add_child(p1)
	
	var p1_vbox = VBoxContainer.new()
	p1.add_child(p1_vbox)
	
	var p1_lbl = Label.new()
	p1_lbl.text = "ZONA 1: SIKLUS RING"
	p1_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_lbl.add_theme_font_override("font", font_black)
	p1_lbl.add_theme_font_size_override("font_size", 13)
	p1_lbl.add_theme_color_override("font_color", Color("#1e3a8a"))
	p1_vbox.add_child(p1_lbl)
	
	var p1_area = Control.new()
	p1_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p1_vbox.add_child(p1_area)
	
	modal_ring_draw = Control.new()
	modal_ring_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_ring_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p1_area.add_child(modal_ring_draw)
	modal_ring_draw.draw.connect(_on_draw_modal_ring)
	
	# 4 Ring circles
	# Center = (215, 170), Radius ~75
	var r_c = Vector2(215, 170)
	_build_modal_node_circle(p1_area, r_c + Vector2(0, -75), false, "PC1") # top
	_build_modal_node_circle(p1_area, r_c + Vector2(75, 0), false, "PC2")  # right
	_build_modal_node_circle(p1_area, r_c + Vector2(0, 75), false, "PC3")  # bottom
	_build_modal_node_circle(p1_area, r_c + Vector2(-75, 0), false, "PC4") # left
	
	# Interactive button on broken bottom-left link
	var btn_fix_ring = Button.new()
	btn_fix_ring.text = "🔌 Sambung Jalur"
	btn_fix_ring.position = Vector2(30, 205)
	btn_fix_ring.custom_minimum_size = Vector2(120, 32)
	var sb_br = StyleBoxFlat.new()
	sb_br.bg_color = Color("#fef08a")
	sb_br.border_color = Color("#ca8a04")
	sb_br.set_border_width_all(2)
	sb_br.set_corner_radius_all(10)
	btn_fix_ring.add_theme_stylebox_override("normal", sb_br)
	btn_fix_ring.add_theme_font_override("font", font_bold)
	btn_fix_ring.add_theme_font_size_override("font_size", 11)
	btn_fix_ring.add_theme_color_override("font_color", Color("#854d0e"))
	btn_fix_ring.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_fix_ring.pressed.connect(_on_toggle_ring_link)
	p1_area.add_child(btn_fix_ring)
	
	# ----------------- PANEL 2: ZONA 2 PERSILANGAN MESH -----------------
	var p2 = PanelContainer.new()
	p2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb_p2 = StyleBoxFlat.new()
	sb_p2.bg_color = Color("#faf5ff")
	sb_p2.border_color = Color("#c084fc")
	sb_p2.set_border_width_all(2)
	sb_p2.set_corner_radius_all(16)
	p2.add_theme_stylebox_override("panel", sb_p2)
	hbox.add_child(p2)
	
	var p2_vbox = VBoxContainer.new()
	p2.add_child(p2_vbox)
	
	var p2_lbl = Label.new()
	p2_lbl.text = "ZONA 2: PERSILANGAN MESH"
	p2_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_lbl.add_theme_font_override("font", font_black)
	p2_lbl.add_theme_font_size_override("font_size", 13)
	p2_lbl.add_theme_color_override("font_color", Color("#581c87"))
	p2_vbox.add_child(p2_lbl)
	
	var p2_area = Control.new()
	p2_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p2_vbox.add_child(p2_area)
	
	modal_mesh_draw = Control.new()
	modal_mesh_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_mesh_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p2_area.add_child(modal_mesh_draw)
	modal_mesh_draw.draw.connect(_on_draw_modal_mesh)
	
	# 4 Mesh circles:
	# Top-Left: (140, 95) [Router - darker cyan]
	# Top-Right: (290, 95)
	# Bottom-Left: (140, 245)
	# Bottom-Right: (290, 245)
	_build_modal_node_circle(p2_area, Vector2(140, 95), true, "R-01")
	_build_modal_node_circle(p2_area, Vector2(290, 95), false, "PC1")
	_build_modal_node_circle(p2_area, Vector2(140, 245), false, "PC2")
	_build_modal_node_circle(p2_area, Vector2(290, 245), false, "PC3")
	
	# Interactive buttons for Mesh broken links:
	# 1. Right vertical
	var btn_m_right = Button.new()
	btn_m_right.text = "🔌 Kanan"
	btn_m_right.position = Vector2(318, 156)
	btn_m_right.size = Vector2(80, 28)
	_style_mesh_btn(btn_m_right)
	btn_m_right.pressed.connect(func(): _on_toggle_mesh_link("right"))
	p2_area.add_child(btn_m_right)
	
	# 2. Diagonal 1 (R01 - PC03)
	var btn_m_d1 = Button.new()
	btn_m_d1.text = "Silang 1"
	btn_m_d1.position = Vector2(138, 124)
	btn_m_d1.size = Vector2(72, 26)
	_style_mesh_btn(btn_m_d1)
	btn_m_d1.pressed.connect(func(): _on_toggle_mesh_link("diag1"))
	p2_area.add_child(btn_m_d1)
	
	# 3. Diagonal 2 (PC01 - PC02)
	var btn_m_d2 = Button.new()
	btn_m_d2.text = "Silang 2"
	btn_m_d2.position = Vector2(220, 124)
	btn_m_d2.size = Vector2(72, 26)
	_style_mesh_btn(btn_m_d2)
	btn_m_d2.pressed.connect(func(): _on_toggle_mesh_link("diag2"))
	p2_area.add_child(btn_m_d2)

func _style_mesh_btn(btn: Button) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fef08a")
	sb.border_color = Color("#ca8a04")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_font_override("font", font_bold)
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color("#854d0e"))
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _build_modal_node_circle(parent: Control, pos: Vector2, is_router: bool, label_txt: String = "") -> void:
	var c = Panel.new()
	c.position = pos - Vector2(22, 22)
	c.size = Vector2(44, 44)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#06b6d4") if is_router else Color("#a7f3d0")
	sb.border_color = Color("#0f766e")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(22)
	c.add_theme_stylebox_override("panel", sb)
	parent.add_child(c)
	if label_txt != "":
		var nl = Label.new()
		nl.text = label_txt
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.set_anchors_preset(Control.PRESET_FULL_RECT)
		nl.add_theme_font_override("font", font_black)
		nl.add_theme_font_size_override("font_size", 10)
		nl.add_theme_color_override("font_color", Color("#134e4a"))
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(nl)

func _on_draw_modal_ring() -> void:
	var r_c = Vector2(215, 170)
	var top = r_c + Vector2(0, -75)
	var right = r_c + Vector2(75, 0)
	var bottom = r_c + Vector2(0, 75)
	var left = r_c + Vector2(-75, 0)
	
	modal_ring_draw.draw_line(top, right, Color("#22c55e"), 5.0, true)
	modal_ring_draw.draw_line(right, bottom, Color("#22c55e"), 5.0, true)
	modal_ring_draw.draw_line(top, left, Color("#22c55e"), 5.0, true)
	
	if ring_connected["bottom_left"]:
		modal_ring_draw.draw_line(left, bottom, Color("#22c55e"), 5.0, true)
	else:
		_draw_dashed_line(modal_ring_draw, left, bottom, Color("#fb7185"), 4.0, 10.0)

func _on_draw_modal_mesh() -> void:
	var tl = Vector2(140, 95)
	var tr = Vector2(290, 95)
	var bl = Vector2(140, 245)
	var br = Vector2(290, 245)
	
	# Solid green lines:
	modal_mesh_draw.draw_line(tl, tr, Color("#22c55e"), 5.0, true) # Top
	modal_mesh_draw.draw_line(tl, bl, Color("#22c55e"), 5.0, true) # Left
	modal_mesh_draw.draw_line(bl, br, Color("#22c55e"), 5.0, true) # Bottom
	
	# Right vertical
	if mesh_connected["right"]:
		modal_mesh_draw.draw_line(tr, br, Color("#22c55e"), 5.0, true)
	else:
		_draw_dashed_line(modal_mesh_draw, tr, br, Color("#fb7185"), 4.0, 10.0)
		
	# Diag 1 (TL - BR)
	if mesh_connected["diag1"]:
		modal_mesh_draw.draw_line(tl, br, Color("#22c55e"), 5.0, true)
	else:
		_draw_dashed_line(modal_mesh_draw, tl, br, Color("#fb7185"), 4.0, 10.0)
		
	# Diag 2 (TR - BL)
	if mesh_connected["diag2"]:
		modal_mesh_draw.draw_line(tr, bl, Color("#22c55e"), 5.0, true)
	else:
		_draw_dashed_line(modal_mesh_draw, tr, bl, Color("#fb7185"), 4.0, 10.0)

func _on_toggle_ring_link() -> void:
	ring_connected["bottom_left"] = not ring_connected["bottom_left"]
	_set_monitor_ok(ring_nodes["pc03"], ring_connected["bottom_left"])
	_set_monitor_ok(ring_nodes["pc04"], ring_connected["bottom_left"])
	if ring_connected["bottom_left"]:
		_play_synth_sequence([587.33, 880.0], 0.08)
	else:
		_play_synth_sequence([350.0], 0.08)
	modal_ring_draw.queue_redraw()
	ring_draw_node.queue_redraw()
	_check_all_topologies_solved()

func _on_toggle_mesh_link(link_key: String) -> void:
	mesh_connected[link_key] = not mesh_connected[link_key]
	if mesh_connected[link_key]:
		_play_synth_sequence([587.33, 880.0], 0.08)
	else:
		_play_synth_sequence([350.0], 0.08)
	modal_mesh_draw.queue_redraw()
	mesh_draw_node.queue_redraw()
	_check_all_topologies_solved()

func _check_all_topologies_solved() -> void:
	var ring_done = ring_connected["bottom_left"]
	var mesh_done = mesh_connected["right"] and mesh_connected["diag1"] and mesh_connected["diag2"]
	
	if ring_done and mesh_done:
		_play_synth_sequence([523.25, 659.25, 783.99, 1046.50], 0.1)
		await get_tree().create_timer(0.6).timeout
		_on_task_modal_close_pressed()
		_on_victory()

func _open_task_modal() -> void:
	_play_synth_sequence([440.0], 0.08)
	task_modal_overlay.visible = true
	is_modal_open = true
	if modal_ring_draw:
		modal_ring_draw.queue_redraw()
	if modal_mesh_draw:
		modal_mesh_draw.queue_redraw()

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
	for k in ring_nodes:
		_set_monitor_ok(ring_nodes[k], true)
	for k in mesh_nodes:
		_set_monitor_ok(mesh_nodes[k], true)

	var pd = get_node_or_null("/root/PlayerData")
	if pd and pd.has_method("set_level_stars"):
		pd.set_level_stars(4, 3, hearts)
		if pd.get("unlocked_stage") != null:
			pd.unlocked_stage = max(pd.unlocked_stage, 5)
	var time_str = "Waktu Tersisa: %02d:%02d" % [int(timer_seconds) / 60, int(timer_seconds) % 60]
	if game_dialog_instance:
		game_dialog_instance.show_win(
			"STAGE 4 SELESAI!",
			"Hebat sekali! Seluruh topologi jaringan (Ring & Mesh) telah berhasil dikonfigurasi dan rute redundan aktif.\n\nStage 5 kini telah TERBUKA!",
			hearts,
			time_str,
			Callable(self, "_on_next_level"),
			Callable(self, "_on_map_pressed"),
			"SELESAI"
		)

func _trigger_game_over(msg: String) -> void:
	is_game_active = false
	if game_dialog_instance:
		game_dialog_instance.show_game_over(
			msg if msg != "" else "Rute topologi belum valid atau waktu habis. Coba lagi!",
			Callable(self, "_on_restart_level"),
			Callable(self, "_on_map_pressed")
		)

func _on_next_level() -> void:
	get_tree().change_scene_to_file("res://scenes/level_path.tscn")

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
		{ "title": "Misi Level 4.3", "text": "Perbaiki dua topologi yang terganggu: Ring di zona kiri dan Mesh di zona kanan." },
		TutorialOverlay.step_move(self),
		{ "title": "1. Zona 1: Topologi Ring", "text": "Satu segmen kabel melingkar terlepas sehingga paket gagal berputar. Klik PC untuk membuka tugas.", "target": Rect2(80, 310, 620, 380), "pointer": "both" },
		{ "title": "2. Zona 2: Topologi Mesh", "text": "Jalur silang antar PC harus tersambung semua. Klik PC di zona ini untuk membuka tugasnya.", "target": Rect2(780, 310, 620, 380), "pointer": "both" },
		TutorialOverlay.step_hearts(self),
		{ "title": "Siap?", "text": "Selesaikan misi sebelum waktu habis. Lupa caranya? Tekan tombol ? (kuning) di dekat pewaktu kapan saja untuk melihat panduan ini lagi." }
	]
