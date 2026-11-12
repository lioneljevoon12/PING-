extends Control

# Level 3.1 - Menentukan NetID dan HostID (Subnetting & Routing - Ruang Kontrol Subnet)
# Sesuai Proposal & Desain Figma 100%:
# - Ruang Kontrol Subnet: Cyan Wall (#84ffff), Gerbang pink, Papan Materi 3.1, Monitor Topologi, Rak Jaringan, Meja Teknisi Utama, PC 1 (Online) & PC 2 (Cek IP)
# - Alur Misi: Buka komputer klien (PC 2) / Meja Teknisi yang mengalami masalah IP (10.20.30.55/24)
# - Pisahkan NetID (10.20.30.0/24) dan HostID (Host: 55) ke dropzone yang tepat
# - Drag-and-Drop & Tap-to-Place support untuk kenyamanan desktop & mobile
# - Transisi GAGAL -> SUKSES: PC 2 tersenyum hijau ("PC 2 ONLINE"), kabel berubah hijau solid, NetID & HostID terpasang di meja teknisi
# - Sistem 3 Bintang terintegrasi dengan PlayerData

const CloseButtonScene = preload("res://scenes/close_button.tscn")
const PauseModalScene = preload("res://scenes/pause_modal.tscn")
const GameDialogScene = preload("res://scenes/game_dialog.tscn")

const MOVE_SPEED = 240.0
const TIME_LIMIT = 165.0 # 02:45

# --- FONTS ---
var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_extrabold = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var font_semibold = preload("res://art/assets/PING! Assets/Fonts/Nunito-SemiBold.ttf")

# --- TEXTURES ---
var tex_char_idle = preload("res://art/assets/PING! Assets/Character/main-char-router.png")
var tex_star_gold = preload("res://art/ui-ux/levelpath/star_gold.png")
var tex_vector_heart = preload("res://art/assets/PING! Assets/asset-gameplay/generals/vector-hearts.png")
var tex_dpad_base = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_pad_a.png")
var tex_dpad_knob = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_nub_a.png")

# Stage 3 Specific Textures
var tex_pc_hijau = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PC_HIJAU.png")
var tex_pc_merah = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PC_MERAH.png")
var tex_meja_pc = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/meja_pc.png")
var tex_meja_teknisi = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/31_meja_teknisi.png")
var tex_warning = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/warning.png")
var tex_hint_card = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/TaskHint31_Card.png")
var tex_papan_materi = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/31_papan_materi.png")
var tex_papan_topologi = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/31_papan_topologi.png")

# Popup Task 31 Textures
var tex_popup_window = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/31/window.png")
var tex_popup_panel = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/31/IPv4_Source_Display_Panel.png")
var tex_drop_netid = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/31/DropZone_NetID.png")
var tex_drop_hostid = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/31/DropZone_HostID.png")
var tex_tray = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/31/Answer_Cards_Tray.png")
var tex_card_a = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/31/Draggable_Card_Option_A.png")
var tex_card_b = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/31/Draggable_Card_Option_B.png")
var tex_card_c = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/31/Draggable_Card_Option_C.png")
var tex_close_btn = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/31/Close_Button.png")

# Scene Node References
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer
@onready var background: TextureRect = %Background
@onready var floor_carpet: Panel = %FloorCarpet
@onready var door_arch: TextureRect = %DoorArch
@onready var whiteboard_node: TextureRect = %WhiteboardNode
@onready var topology_monitor: TextureRect = %TopologyMonitor
@onready var server_cabinet: TextureRect = %ServerCabinet
@onready var cables_container: Control = %CablesContainer
@onready var left_rack: TextureRect = %LeftRack
@onready var chair_node: TextureRect = %ChairNode
@onready var meja_teknisi: Control = %MejaTeknisi
@onready var pc1_desk: Control = %PC1Desk
@onready var pc2_desk: Control = %PC2Desk
@onready var character_node: Control = %CharacterNode
@onready var mobile_controls_root: Control = %MobileControlsRoot

# Dynamic Subnodes for Desks & Stations
var pc1_monitor: TextureRect
var pc1_pill: PanelContainer
var pc2_monitor: TextureRect
var pc2_pill: PanelContainer
var pc2_warning_badge: TextureRect
var pc2_alert_circle: Control
var meja_monitor: TextureRect
var meja_placed_net: TextureRect
var meja_placed_host: TextureRect
var meja_prompt_pill: PanelContainer
var pc2_prompt_pill: PanelContainer

# Character & Movement
var walk_frames: Array[Texture2D] = []
var walk_frame_index: float = 0.0
var char_sprite: TextureRect
var char_pos: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO
var footstep_timer: float = 0.0

# Mobile Controls (Joystick)
var dpad_touch_id: int = -1
var dpad_center: Vector2 = Vector2.ZERO
var dpad_knob_sprite: TextureRect
var dpad_radius: float = 55.0

# UI Elements
var header_ui: Control
var timer_label: Label
var clock_icon: TextureRect
var hearts_container: HBoxContainer
var hearts_rects: Array[TextureRect] = []
var toast_panel: PanelContainer
var toast_label: Label
var toast_tween: Tween

# Modals
var intro_modal: Control
var task_modal: Control
var whiteboard_modal: Control
var pause_modal: Control
var game_dialog: Control

# Gameplay State
var is_game_active: bool = false
var is_modal_open: bool = false
var is_completed: bool = false
var is_game_over: bool = false
var time_remaining: float = TIME_LIMIT
var hearts: int = 3
var error_count: int = 0
var anim_pulse_time: float = 0.0

# Task 3.1 State:
# Card IDs: "A" (NetID: 10.20.30.0/24), "B" (HostID: Host 55), "C" (10.20.0.0/16)
var slot_netid: String = ""   # Expects "A"
var slot_hostid: String = ""  # Expects "B"
var selected_card_id: String = "" # For tap-to-place
var card_nodes: Dictionary = {}
var dropzone_net_node: Control
var dropzone_host_node: Control
var tray_node: Control
var verify_button: Button

# Drag state
var dragging_card_id: String = ""
var drag_touch_id: int = -1
var drag_offset: Vector2 = Vector2.ZERO
var drag_start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	_setup_floor_carpet()
	_load_character_frames()
	_setup_character()
	_setup_stations()
	_setup_cables()
	_setup_whiteboard_interaction()
	_setup_header_ui()
	_setup_mobile_controls()
	_setup_toast_ui()
	_setup_intro_modal()
	_setup_task_modal()
	_setup_pause_and_dialog()
	
	# Open Intro Modal at start
	_open_intro_modal()
	
	# Screenshot helper for visual verification
	_check_screenshot_args()

func _check_screenshot_args() -> void:
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-31-intro" in all_args:
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/31_intro_render.png")
		get_tree().quit()
	elif "--screenshot-31-room" in all_args:
		intro_modal.visible = false
		is_modal_open = false
		is_game_active = true
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/31_room_render.png")
		get_tree().quit()
	elif "--screenshot-31-popup" in all_args:
		intro_modal.visible = false
		_open_task_modal()
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/31_popup_render.png")
		get_tree().quit()
	elif "--screenshot-31-sukses" in all_args:
		intro_modal.visible = false
		is_modal_open = false
		_apply_room_success_state()
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/31_sukses_render.png")
		get_tree().quit()

func _setup_floor_carpet() -> void:
	if floor_carpet:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.83, 0.96, 0.96, 0.75) # Soft translucent cyan runner matching Figma
		sb.border_color = Color(0.68, 0.90, 0.92, 0.9)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(32)
		floor_carpet.add_theme_stylebox_override("panel", sb)
		floor_carpet.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _load_character_frames() -> void:
	for i in range(1, 33):
		var p = "res://art/assets/PING! Assets/Sprite animation/router walk/%d.png" % i
		if ResourceLoader.exists(p):
			var tex = load(p) as Texture2D
			if tex:
				walk_frames.append(tex)
	if walk_frames.is_empty():
		walk_frames.append(tex_char_idle)

func _setup_character() -> void:
	character_node.custom_minimum_size = Vector2(140, 90)
	character_node.size = Vector2(140, 90)
	character_node.pivot_offset = Vector2(70, 45)
	
	# Character Shadow
	var shadow = Panel.new()
	shadow.size = Vector2(100, 24)
	shadow.position = Vector2(20, 68)
	var sb_shadow = StyleBoxFlat.new()
	sb_shadow.bg_color = Color(0.1, 0.15, 0.2, 0.25)
	sb_shadow.set_corner_radius_all(12)
	shadow.add_theme_stylebox_override("panel", sb_shadow)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_node.add_child(shadow)
	
	char_sprite = TextureRect.new()
	char_sprite.name = "CharSprite"
	char_sprite.texture = tex_char_idle
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	char_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_node.add_child(char_sprite)
	
	char_pos = character_node.position

func _setup_stations() -> void:
	# 1. Meja Teknisi Utama
	meja_teknisi.custom_minimum_size = Vector2(480, 210)
	meja_teknisi.size = Vector2(480, 210)
	
	var meja_tex = TextureRect.new()
	meja_tex.texture = tex_meja_teknisi
	meja_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meja_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	meja_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	meja_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meja_teknisi.add_child(meja_tex)
	
	# Placed NetID Card placeholder on Meja Teknisi
	meja_placed_net = TextureRect.new()
	meja_placed_net.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meja_placed_net.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	meja_placed_net.custom_minimum_size = Vector2(100, 26)
	meja_placed_net.size = Vector2(100, 26)
	meja_placed_net.position = Vector2(360, 40)
	meja_placed_net.texture = tex_card_a
	meja_placed_net.visible = false
	meja_teknisi.add_child(meja_placed_net)
	
	# Placed HostID Card placeholder on Meja Teknisi
	meja_placed_host = TextureRect.new()
	meja_placed_host.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meja_placed_host.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	meja_placed_host.custom_minimum_size = Vector2(100, 26)
	meja_placed_host.size = Vector2(100, 26)
	meja_placed_host.position = Vector2(360, 85)
	meja_placed_host.texture = tex_card_b
	meja_placed_host.visible = false
	meja_teknisi.add_child(meja_placed_host)
	
	# Pill label on Meja: "MEJA TEKNISI UTAMA"
	var meja_pill = _create_pill("MEJA TEKNISI UTAMA", Color("#593e38"), Color("#fef3c7"), Color("#d97706"))
	meja_pill.position = Vector2(150, 182)
	meja_teknisi.add_child(meja_pill)
	
	# Click button for Meja Teknisi
	var meja_btn = Button.new()
	meja_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	meja_btn.flat = true
	meja_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	meja_btn.pressed.connect(_on_station_clicked)
	meja_teknisi.add_child(meja_btn)
	
	# Proximity Prompt Pill for Meja
	meja_prompt_pill = _create_pill("! Periksa NetID & HostID", Color("#ffffff"), Color("#0284c7"), Color("#38bdf8"))
	meja_prompt_pill.position = Vector2(140, -32)
	meja_prompt_pill.visible = false
	meja_teknisi.add_child(meja_prompt_pill)
	
	# 2. PC 1 Desk (Station Kiri Bawah - Online)
	pc1_desk.custom_minimum_size = Vector2(200, 180)
	pc1_desk.size = Vector2(200, 180)
	
	var pc1_table = TextureRect.new()
	pc1_table.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc1_table.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc1_table.set_anchors_preset(Control.PRESET_FULL_RECT)
	pc1_table.texture = tex_meja_pc
	pc1_table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc1_desk.add_child(pc1_table)
	
	pc1_monitor = TextureRect.new()
	pc1_monitor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc1_monitor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc1_monitor.custom_minimum_size = Vector2(120, 110)
	pc1_monitor.size = Vector2(120, 110)
	pc1_monitor.position = Vector2(40, -10)
	pc1_monitor.texture = tex_pc_hijau
	pc1_monitor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc1_desk.add_child(pc1_monitor)
	
	pc1_pill = _create_pill("PC 1 ONLINE", Color("#14532d"), Color("#dcfce7"), Color("#22c55e"))
	pc1_pill.position = Vector2(38, 140)
	pc1_desk.add_child(pc1_pill)
	
	# 3. PC 2 Desk (Station Kanan Bawah - Problem IP)
	pc2_desk.custom_minimum_size = Vector2(200, 180)
	pc2_desk.size = Vector2(200, 180)
	
	# Dotted circle floor indicator for PC 2 (pulsing)
	pc2_alert_circle = Control.new()
	pc2_alert_circle.size = Vector2(240, 220)
	pc2_alert_circle.position = Vector2(-20, -20)
	pc2_alert_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc2_alert_circle.draw.connect(_draw_pc2_alert_circle)
	pc2_desk.add_child(pc2_alert_circle)
	
	var pc2_table = TextureRect.new()
	pc2_table.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc2_table.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc2_table.set_anchors_preset(Control.PRESET_FULL_RECT)
	pc2_table.texture = tex_meja_pc
	pc2_table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc2_desk.add_child(pc2_table)
	
	pc2_monitor = TextureRect.new()
	pc2_monitor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc2_monitor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc2_monitor.custom_minimum_size = Vector2(120, 110)
	pc2_monitor.size = Vector2(120, 110)
	pc2_monitor.position = Vector2(40, -10)
	pc2_monitor.texture = tex_pc_merah
	pc2_monitor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc2_desk.add_child(pc2_monitor)
	
	# Warning Exclamation Badge on PC 2
	pc2_warning_badge = TextureRect.new()
	pc2_warning_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc2_warning_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc2_warning_badge.custom_minimum_size = Vector2(44, 44)
	pc2_warning_badge.size = Vector2(44, 44)
	pc2_warning_badge.position = Vector2(128, -25)
	pc2_warning_badge.texture = tex_warning
	pc2_warning_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc2_desk.add_child(pc2_warning_badge)
	
	pc2_pill = _create_pill("PC 2 (CEK IP!)", Color("#7f1d1d"), Color("#fee2e2"), Color("#ef4444"))
	pc2_pill.position = Vector2(34, 140)
	pc2_desk.add_child(pc2_pill)
	
	# Click button for PC 2
	var pc2_btn = Button.new()
	pc2_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	pc2_btn.flat = true
	pc2_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pc2_btn.pressed.connect(_on_station_clicked)
	pc2_desk.add_child(pc2_btn)
	
	# Proximity Prompt Pill for PC 2
	pc2_prompt_pill = _create_pill("! Buka Komputer PC 2", Color("#ffffff"), Color("#dc2626"), Color("#f87171"))
	pc2_prompt_pill.position = Vector2(25, -34)
	pc2_prompt_pill.visible = false
	pc2_desk.add_child(pc2_prompt_pill)

func _draw_pc2_alert_circle() -> void:
	if is_completed or not pc2_alert_circle.visible:
		return
	var center = Vector2(120, 110)
	var radius = 100.0 + sin(anim_pulse_time * 4.0) * 4.0
	var col = Color(0.95, 0.25, 0.25, 0.35 + sin(anim_pulse_time * 4.0) * 0.15)
	pc2_alert_circle.draw_circle(center, radius, col)
	pc2_alert_circle.draw_arc(center, radius, 0, TAU, 36, Color(0.9, 0.2, 0.2, 0.8), 2.5, true)

func _setup_cables() -> void:
	cables_container.draw.connect(_draw_cables)

func _draw_cables() -> void:
	var green_c = Color("#22c55e")
	var red_c = Color("#ef4444")
	
	# Line 1: Rak Jaringan ke Meja Teknisi (Solid Green)
	var pts_meja = PackedVector2Array([
		Vector2(290, 390),
		Vector2(560, 390),
		Vector2(560, 360),
		Vector2(860, 360)
	])
	# Dark border for cable
	cables_container.draw_polyline(pts_meja, Color(0.1, 0.1, 0.1, 0.6), 10.0, true)
	cables_container.draw_polyline(pts_meja, green_c, 6.0, true)
	
	# Line 2: Rak Jaringan ke PC 1 (Solid Green)
	var pts_pc1 = PackedVector2Array([
		Vector2(240, 560),
		Vector2(240, 620),
		Vector2(460, 620)
	])
	cables_container.draw_polyline(pts_pc1, Color(0.1, 0.1, 0.1, 0.6), 10.0, true)
	cables_container.draw_polyline(pts_pc1, green_c, 6.0, true)
	
	# Line 3: Meja Teknisi ke PC 2
	# In GAGAL: Red dashed/striped
	# In SUKSES: Solid Green
	var pts_pc2 = PackedVector2Array([
		Vector2(1100, 470),
		Vector2(1100, 620),
		Vector2(1210, 620)
	])
	if is_completed:
		cables_container.draw_polyline(pts_pc2, Color(0.1, 0.1, 0.1, 0.6), 10.0, true)
		cables_container.draw_polyline(pts_pc2, green_c, 6.0, true)
	else:
		# Draw striped red cable
		cables_container.draw_polyline(pts_pc2, Color(0.2, 0.05, 0.05, 0.6), 10.0, true)
		cables_container.draw_polyline(pts_pc2, Color("#fee2e2"), 6.0, true)
		# Draw dashed red segments
		_draw_dashed_line(pts_pc2[0], pts_pc2[1], red_c, 6.0, 12.0)
		_draw_dashed_line(pts_pc2[1], pts_pc2[2], red_c, 6.0, 12.0)

func _draw_dashed_line(from: Vector2, to: Vector2, col: Color, width: float, dash_len: float) -> void:
	var total_dist = from.distance_to(to)
	var dir = (to - from).normalized()
	var cur = 0.0
	var draw_dash = true
	while cur < total_dist:
		var step = min(dash_len, total_dist - cur)
		if draw_dash:
			cables_container.draw_line(from + dir * cur, from + dir * (cur + step), col, width, true)
		cur += step
		draw_dash = not draw_dash

func _setup_whiteboard_interaction() -> void:
	if whiteboard_node:
		var wb_btn = Button.new()
		wb_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		wb_btn.flat = true
		wb_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		wb_btn.pressed.connect(_open_whiteboard_modal)
		whiteboard_node.add_child(wb_btn)

func _setup_header_ui() -> void:
	header_ui = Control.new()
	header_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_ui)
	
	# Top Left Container: Back Button + Hearts + Level Tag
	var left_box = HBoxContainer.new()
	left_box.position = Vector2(30, 25)
	left_box.add_theme_constant_override("separation", 14)
	header_ui.add_child(left_box)
	
	# Back Button (Circular)
	var back_btn = Button.new()
	back_btn.custom_minimum_size = Vector2(50, 50)
	var sb_back = StyleBoxFlat.new()
	sb_back.bg_color = Color("#fecdd3")
	sb_back.border_color = Color("#593e38")
	sb_back.set_border_width_all(3)
	sb_back.set_corner_radius_all(25)
	back_btn.add_theme_stylebox_override("normal", sb_back)
	back_btn.add_theme_stylebox_override("hover", sb_back)
	back_btn.add_theme_stylebox_override("pressed", sb_back)
	back_btn.text = "<"
	back_btn.add_theme_font_override("font", font_black)
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.add_theme_color_override("font_color", Color("#593e38"))
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.pressed.connect(_on_back_pressed)
	left_box.add_child(back_btn)
	
	# Hearts Panel (3 Hearts)
	var hearts_panel = PanelContainer.new()
	hearts_panel.custom_minimum_size = Vector2(130, 50)
	var sb_hearts = StyleBoxFlat.new()
	sb_hearts.bg_color = Color("#fecdd3")
	sb_hearts.border_color = Color("#593e38")
	sb_hearts.set_border_width_all(3)
	sb_hearts.set_corner_radius_all(20)
	sb_hearts.content_margin_left = 14
	sb_hearts.content_margin_right = 14
	hearts_panel.add_theme_stylebox_override("panel", sb_hearts)
	
	hearts_container = HBoxContainer.new()
	hearts_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hearts_container.add_theme_constant_override("separation", 8)
	for i in range(3):
		var h_rect = TextureRect.new()
		h_rect.texture = tex_vector_heart
		h_rect.custom_minimum_size = Vector2(28, 28)
		h_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_container.add_child(h_rect)
		hearts_rects.append(h_rect)
	hearts_panel.add_child(hearts_container)
	left_box.add_child(hearts_panel)
	
	# Level Tag Badge ("Level 3.1")
	var level_badge = PanelContainer.new()
	level_badge.custom_minimum_size = Vector2(90, 50)
	var sb_badge = StyleBoxFlat.new()
	sb_badge.bg_color = Color("#ffffff")
	sb_badge.border_color = Color("#593e38")
	sb_badge.set_border_width_all(3)
	sb_badge.set_corner_radius_all(16)
	level_badge.add_theme_stylebox_override("panel", sb_badge)
	
	var badge_vbox = VBoxContainer.new()
	badge_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_vbox.add_theme_constant_override("separation", -2)
	var b_top = Label.new()
	b_top.text = "Level"
	b_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b_top.add_theme_font_override("font", font_semibold)
	b_top.add_theme_font_size_override("font_size", 11)
	b_top.add_theme_color_override("font_color", Color("#8b5cf6"))
	badge_vbox.add_child(b_top)
	var b_num = Label.new()
	b_num.text = "3.1"
	b_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b_num.add_theme_font_override("font", font_black)
	b_num.add_theme_font_size_override("font_size", 18)
	b_num.add_theme_color_override("font_color", Color("#593e38"))
	badge_vbox.add_child(b_num)
	level_badge.add_child(badge_vbox)
	left_box.add_child(level_badge)
	
	# Top Right Container: Timer + Pause Button
	var right_box = HBoxContainer.new()
	right_box.position = Vector2(1330, 25)
	right_box.add_theme_constant_override("separation", 14)
	header_ui.add_child(right_box)
	
	# Timer Panel
	var timer_panel = PanelContainer.new()
	timer_panel.custom_minimum_size = Vector2(125, 50)
	var sb_timer = StyleBoxFlat.new()
	sb_timer.bg_color = Color("#ffffff")
	sb_timer.border_color = Color("#593e38")
	sb_timer.set_border_width_all(3)
	sb_timer.set_corner_radius_all(20)
	sb_timer.content_margin_left = 12
	sb_timer.content_margin_right = 14
	timer_panel.add_theme_stylebox_override("panel", sb_timer)
	
	var timer_hbox = HBoxContainer.new()
	timer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_hbox.add_theme_constant_override("separation", 6)
	
	var timer_ico = Label.new()
	timer_ico.text = "⏱"
	timer_ico.add_theme_font_size_override("font_size", 18)
	timer_hbox.add_child(timer_ico)
	
	timer_label = Label.new()
	timer_label.text = "02:45"
	timer_label.add_theme_font_override("font", font_extrabold)
	timer_label.add_theme_font_size_override("font_size", 20)
	timer_label.add_theme_color_override("font_color", Color("#593e38"))
	timer_hbox.add_child(timer_label)
	timer_panel.add_child(timer_hbox)
	right_box.add_child(timer_panel)
	
	# Pause Button (Hamburger ≡)
	var pause_btn = Button.new()
	pause_btn.custom_minimum_size = Vector2(50, 50)
	var sb_pause = StyleBoxFlat.new()
	sb_pause.bg_color = Color("#ffffff")
	sb_pause.border_color = Color("#593e38")
	sb_pause.set_border_width_all(3)
	sb_pause.set_corner_radius_all(16)
	pause_btn.add_theme_stylebox_override("normal", sb_pause)
	pause_btn.add_theme_stylebox_override("hover", sb_pause)
	pause_btn.add_theme_stylebox_override("pressed", sb_pause)
	pause_btn.text = "≡"
	pause_btn.add_theme_font_override("font", font_black)
	pause_btn.add_theme_font_size_override("font_size", 26)
	pause_btn.add_theme_color_override("font_color", Color("#593e38"))
	pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pause_btn.pressed.connect(_on_pause_pressed)
	right_box.add_child(pause_btn)

func _setup_mobile_controls() -> void:
	mobile_controls_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var base_rect = TextureRect.new()
	base_rect.texture = tex_dpad_base
	base_rect.size = Vector2(130, 130)
	base_rect.position = Vector2(50, 540)
	base_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	base_rect.modulate = Color(1, 1, 1, 0.7)
	base_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_controls_root.add_child(base_rect)
	
	dpad_knob_sprite = TextureRect.new()
	dpad_knob_sprite.texture = tex_dpad_knob
	dpad_knob_sprite.size = Vector2(60, 60)
	dpad_knob_sprite.position = Vector2(85, 575)
	dpad_knob_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dpad_knob_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dpad_knob_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_controls_root.add_child(dpad_knob_sprite)
	
	dpad_center = Vector2(115, 605)

func _setup_toast_ui() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.z_index = 300
	toast_panel.size = Vector2(640, 50)
	toast_panel.position = Vector2(460, 24)
	toast_panel.modulate.a = 0.0
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.16, 0.22, 0.95)
	sb.border_color = Color("#38bdf8")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	toast_panel.add_theme_stylebox_override("panel", sb)
	
	toast_label = Label.new()
	toast_label.text = "Notifikasi Game"
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_override("font", font_bold)
	toast_label.add_theme_font_size_override("font_size", 14)
	toast_label.add_theme_color_override("font_color", Color("#ffffff"))
	toast_panel.add_child(toast_label)
	add_child(toast_panel)

func show_toast(text: String, duration: float = 3.0) -> void:
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
	toast_label.text = text
	toast_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	toast_tween.tween_interval(duration)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)

func _setup_intro_modal() -> void:
	intro_modal = Control.new()
	intro_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_modal.z_index = 200
	intro_modal.visible = false
	add_child(intro_modal)
	
	# Dimmed backdrop
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	intro_modal.add_child(dim)
	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_on_mulai_pressed()
	)
	
	# Intro Card Container
	var card_rect = TextureRect.new()
	card_rect.name = "IntroCardRect"
	card_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_rect.custom_minimum_size = Vector2(740, 460)
	card_rect.size = Vector2(740, 460)
	card_rect.anchor_left = 0.5
	card_rect.anchor_top = 0.5
	card_rect.anchor_right = 0.5
	card_rect.anchor_bottom = 0.5
	card_rect.offset_left = -370.0
	card_rect.offset_top = -230.0
	card_rect.offset_right = 370.0
	card_rect.offset_bottom = 230.0
	card_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	card_rect.texture = tex_hint_card
	intro_modal.add_child(card_rect)
	
	# Transparent Clickable "MULAI" Button positioned directly over the mint green button
	var mulai_btn = Button.new()
	mulai_btn.size = Vector2(190, 56)
	mulai_btn.position = Vector2((740.0 - 190.0) / 2.0, 356.0)
	mulai_btn.flat = true
	mulai_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mulai_btn.pressed.connect(_on_mulai_pressed)
	card_rect.add_child(mulai_btn)

func _open_intro_modal() -> void:
	is_modal_open = true
	is_game_active = false
	intro_modal.visible = true
	intro_modal.modulate.a = 0.0
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(intro_modal, "modulate:a", 1.0, 0.25)

func _on_mulai_pressed() -> void:
	_play_synth_sequence([523.25, 659.25, 783.99], 0.08)
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(intro_modal, "modulate:a", 0.0, 0.2)
	tw.finished.connect(func():
		intro_modal.visible = false
		is_modal_open = false
		is_game_active = true
	)

func _setup_task_modal() -> void:
	task_modal = Control.new()
	task_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	task_modal.z_index = 220
	task_modal.visible = false
	add_child(task_modal)
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	task_modal.add_child(dim)
	
	# Window Base
	var win_w = 960.0
	var win_h = 580.0
	
	var win_container = Control.new()
	win_container.name = "WinContainer"
	win_container.anchor_left = 0.5
	win_container.anchor_top = 0.5
	win_container.anchor_right = 0.5
	win_container.anchor_bottom = 0.5
	win_container.offset_left = -win_w / 2.0
	win_container.offset_top = -win_h / 2.0
	win_container.offset_right = win_w / 2.0
	win_container.offset_bottom = win_h / 2.0
	win_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	win_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	win_container.custom_minimum_size = Vector2(win_w, win_h)
	win_container.size = Vector2(win_w, win_h)
	task_modal.add_child(win_container)
	
	var win_bg = TextureRect.new()
	win_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	win_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	win_bg.custom_minimum_size = Vector2(win_w, win_h)
	win_bg.size = Vector2(win_w, win_h)
	win_bg.texture = tex_popup_window
	win_container.add_child(win_bg)
	
	# Close Button (Universal CloseButtonScene)
	var close_btn = CloseButtonScene.instantiate()
	close_btn.position = Vector2(win_w - 52, 14)
	if close_btn.has_signal("closed"):
		close_btn.closed.connect(_close_task_modal)
	close_btn.pressed.connect(_close_task_modal)
	win_container.add_child(close_btn)
	
	# Top IPv4 Source Display Panel
	var panel_rect = TextureRect.new()
	panel_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel_rect.custom_minimum_size = Vector2(860, 118)
	panel_rect.size = Vector2(860, 118)
	panel_rect.position = Vector2(50, 54)
	panel_rect.texture = tex_popup_panel
	panel_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_container.add_child(panel_rect)
	
	# Drop Zone 1: NetID (Left)
	dropzone_net_node = Control.new()
	dropzone_net_node.name = "DropNetID"
	dropzone_net_node.size = Vector2(415, 160)
	dropzone_net_node.position = Vector2(50, 184)
	win_container.add_child(dropzone_net_node)
	
	var dnet_bg = TextureRect.new()
	dnet_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dnet_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dnet_bg.custom_minimum_size = Vector2(415, 160)
	dnet_bg.size = Vector2(415, 160)
	dnet_bg.texture = tex_drop_netid
	dnet_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dropzone_net_node.add_child(dnet_bg)
	
	var dnet_click = Button.new()
	dnet_click.set_anchors_preset(Control.PRESET_FULL_RECT)
	dnet_click.flat = true
	dnet_click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	dnet_click.pressed.connect(func(): _on_dropzone_tapped("netid"))
	dropzone_net_node.add_child(dnet_click)
	
	# Drop Zone 2: HostID (Right)
	dropzone_host_node = Control.new()
	dropzone_host_node.name = "DropHostID"
	dropzone_host_node.size = Vector2(415, 160)
	dropzone_host_node.position = Vector2(495, 184)
	win_container.add_child(dropzone_host_node)
	
	var dhost_bg = TextureRect.new()
	dhost_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dhost_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dhost_bg.custom_minimum_size = Vector2(415, 160)
	dhost_bg.size = Vector2(415, 160)
	dhost_bg.texture = tex_drop_hostid
	dhost_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dropzone_host_node.add_child(dhost_bg)
	
	var dhost_click = Button.new()
	dhost_click.set_anchors_preset(Control.PRESET_FULL_RECT)
	dhost_click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	dhost_click.flat = true
	dhost_click.pressed.connect(func(): _on_dropzone_tapped("hostid"))
	dropzone_host_node.add_child(dhost_click)
	
	# Answer Cards Tray (Bottom)
	tray_node = Control.new()
	tray_node.name = "CardsTray"
	tray_node.size = Vector2(860, 105)
	tray_node.position = Vector2(50, 356)
	win_container.add_child(tray_node)
	
	var tray_bg = TextureRect.new()
	tray_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tray_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tray_bg.custom_minimum_size = Vector2(860, 105)
	tray_bg.size = Vector2(860, 105)
	tray_bg.texture = tex_tray
	tray_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray_node.add_child(tray_bg)
	
	# 3 Answer Cards: A (10.20.30.0/24), B (Host: 55), C (10.20.0.0/16)
	_create_draggable_card("A", tex_card_a, Vector2(70, 375), win_container)
	_create_draggable_card("B", tex_card_b, Vector2(350, 375), win_container)
	_create_draggable_card("C", tex_card_c, Vector2(630, 375), win_container)
	
	# Verify / Activate Button
	verify_button = Button.new()
	verify_button.text = "VERIFIKASI & AKTIFKAN JARINGAN"
	verify_button.size = Vector2(380, 52)
	verify_button.position = Vector2((win_w - 380) / 2.0, 485)
	var sb_v_norm = StyleBoxFlat.new()
	sb_v_norm.bg_color = Color("#86efac") # Mint green
	sb_v_norm.border_color = Color("#593e38")
	sb_v_norm.set_border_width_all(3)
	sb_v_norm.set_corner_radius_all(20)
	verify_button.add_theme_stylebox_override("normal", sb_v_norm)
	var sb_v_hover = sb_v_norm.duplicate()
	sb_v_hover.bg_color = Color("#bbf7d0")
	verify_button.add_theme_stylebox_override("hover", sb_v_hover)
	var sb_v_pressed = sb_v_norm.duplicate()
	sb_v_pressed.bg_color = Color("#4ade80")
	verify_button.add_theme_stylebox_override("pressed", sb_v_pressed)
	verify_button.add_theme_font_override("font", font_black)
	verify_button.add_theme_font_size_override("font_size", 16)
	verify_button.add_theme_color_override("font_color", Color("#593e38"))
	verify_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	verify_button.pressed.connect(_on_verify_pressed)
	win_container.add_child(verify_button)

func _create_draggable_card(id: String, tex: Texture2D, initial_pos: Vector2, parent: Control) -> void:
	var card_root = Control.new()
	card_root.name = "Card_" + id
	card_root.size = Vector2(260, 67)
	card_root.position = initial_pos
	card_root.pivot_offset = Vector2(130, 33.5)
	parent.add_child(card_root)
	
	var tr = TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(260, 67)
	tr.size = Vector2(260, 67)
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(tr)
	
	# Card selection highlight border
	var hl = Panel.new()
	hl.name = "Highlight"
	hl.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb_hl = StyleBoxFlat.new()
	sb_hl.bg_color = Color(0, 0, 0, 0)
	sb_hl.border_color = Color("#38bdf8")
	sb_hl.set_border_width_all(3)
	sb_hl.set_corner_radius_all(14)
	hl.add_theme_stylebox_override("panel", sb_hl)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hl.visible = false
	card_root.add_child(hl)
	
	card_nodes[id] = {
		"root": card_root,
		"initial_pos": initial_pos,
		"current_slot": "tray", # "tray", "netid", "hostid"
		"highlight": hl
	}
	
	# Input handler for Drag and Tap
	card_root.gui_input.connect(func(event: InputEvent): _on_card_gui_input(id, event))

func _on_card_gui_input(id: String, event: InputEvent) -> void:
	if not task_modal.visible:
		return
	
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_card_drag(id, mb.global_position)
			else:
				_end_card_drag(id, mb.global_position)
	elif event is InputEventScreenTouch:
		var st = event as InputEventScreenTouch
		if st.pressed:
			if drag_touch_id == -1:
				drag_touch_id = st.index
				_start_card_drag(id, st.position)
		else:
			if drag_touch_id == st.index:
				drag_touch_id = -1
				_end_card_drag(id, st.position)
	elif event is InputEventMouseMotion:
		var mm = event as InputEventMouseMotion
		if dragging_card_id == id:
			_update_card_drag(id, mm.global_position)
	elif event is InputEventScreenDrag:
		var sd = event as InputEventScreenDrag
		if dragging_card_id == id and drag_touch_id == sd.index:
			_update_card_drag(id, sd.position)

func _start_card_drag(id: String, global_pos: Vector2) -> void:
	dragging_card_id = id
	var node = card_nodes[id]["root"] as Control
	drag_start_pos = node.position
	drag_offset = node.global_position - global_pos
	node.z_index = 50
	node.scale = Vector2(1.08, 1.08)
	_play_synth_sequence([440.0], 0.05)
	
	# Also toggle tap selection
	_toggle_card_selection(id)

func _update_card_drag(id: String, global_pos: Vector2) -> void:
	var node = card_nodes[id]["root"] as Control
	var win_container = task_modal.get_node("WinContainer") as Control
	var local_pos = win_container.get_local_mouse_position() + drag_offset
	node.position = local_pos

func _end_card_drag(id: String, global_pos: Vector2) -> void:
	if dragging_card_id != id:
		return
	dragging_card_id = ""
	var node = card_nodes[id]["root"] as Control
	node.z_index = 10
	node.scale = Vector2(1.0, 1.0)
	
	var drop_rect_net = Rect2(dropzone_net_node.position, dropzone_net_node.size)
	var drop_rect_host = Rect2(dropzone_host_node.position, dropzone_host_node.size)
	var card_center = node.position + node.size / 2.0
	
	if drop_rect_net.has_point(card_center):
		_place_card_in_slot(id, "netid")
	elif drop_rect_host.has_point(card_center):
		_place_card_in_slot(id, "hostid")
	else:
		_return_card_to_tray(id)

func _toggle_card_selection(id: String) -> void:
	if selected_card_id == id:
		selected_card_id = ""
		card_nodes[id]["highlight"].visible = false
	else:
		if selected_card_id != "" and selected_card_id in card_nodes:
			card_nodes[selected_card_id]["highlight"].visible = false
		selected_card_id = id
		card_nodes[id]["highlight"].visible = true

func _on_dropzone_tapped(slot: String) -> void:
	if selected_card_id != "":
		_place_card_in_slot(selected_card_id, slot)
		selected_card_id = ""
	else:
		# If a card is already in this slot, tapping it returns it to tray
		if slot == "netid" and slot_netid != "":
			_return_card_to_tray(slot_netid)
		elif slot == "hostid" and slot_hostid != "":
			_return_card_to_tray(slot_hostid)

func _place_card_in_slot(id: String, slot: String) -> void:
	# Clear previous card in this slot
	if slot == "netid":
		if slot_netid != "" and slot_netid != id:
			_return_card_to_tray(slot_netid)
		if slot_hostid == id:
			slot_hostid = ""
		slot_netid = id
	elif slot == "hostid":
		if slot_hostid != "" and slot_hostid != id:
			_return_card_to_tray(slot_hostid)
		if slot_netid == id:
			slot_netid = ""
		slot_hostid = id
		
	card_nodes[id]["current_slot"] = slot
	card_nodes[id]["highlight"].visible = false
	
	# Target position inside drop zone (centered at dropzone bottom half)
	var target_pos = Vector2.ZERO
	if slot == "netid":
		target_pos = dropzone_net_node.position + Vector2((dropzone_net_node.size.x - 260) / 2.0, 85)
	else:
		target_pos = dropzone_host_node.position + Vector2((dropzone_host_node.size.x - 260) / 2.0, 85)
		
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_nodes[id]["root"], "position", target_pos, 0.2)
	_play_synth_sequence([587.33, 880.0], 0.06)

func _return_card_to_tray(id: String) -> void:
	if slot_netid == id:
		slot_netid = ""
	if slot_hostid == id:
		slot_hostid = ""
	card_nodes[id]["current_slot"] = "tray"
	card_nodes[id]["highlight"].visible = false
	
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_nodes[id]["root"], "position", card_nodes[id]["initial_pos"], 0.22)
	_play_synth_sequence([440.0, 330.0], 0.05)

func _on_verify_pressed() -> void:
	if slot_netid == "" or slot_hostid == "":
		show_toast("Tempatkan kartu pada kedua kategori: NetID dan HostID!")
		_play_buzz_error()
		return
		
	# Check correctness:
	# Card A is 10.20.30.0/24 -> Target for NetID
	# Card B is Host: 55 (10.20.30.55) -> Target for HostID
	if slot_netid == "A" and slot_hostid == "B":
		_solve_level_success()
	else:
		_solve_level_failed()

func _solve_level_success() -> void:
	is_completed = true
	is_game_active = false
	_play_win_fanfare()
	show_toast("Alamat IP Valid! NetID dan HostID Terverifikasi!", 3.0)
	
	# Close task modal smoothly
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(task_modal, "modulate:a", 0.0, 0.3)
	tw.finished.connect(func():
		task_modal.visible = false
		_apply_room_success_state()
	)

func _solve_level_failed() -> void:
	error_count += 1
	hearts = max(0, hearts - 1)
	_update_hearts_ui()
	_play_buzz_error()
	
	# Shake window
	var win_container = task_modal.get_node("WinContainer") as Control
	var orig_pos = win_container.position
	var tw = create_tween()
	for i in range(4):
		var offset = Vector2((randf() - 0.5) * 16.0, 0)
		tw.tween_property(win_container, "position", orig_pos + offset, 0.05)
	tw.tween_property(win_container, "position", orig_pos, 0.05)
	
	show_toast("NetID atau HostID keliru! Prefix /24: 3 oktet pertama adalah NetID (10.20.30.0/24) & HostID adalah 55.", 4.0)
	
	if hearts <= 0:
		_game_over()

func _apply_room_success_state() -> void:
	# Transform room into level 3.1_SUKSES
	# 1. PC 2 turns green and smiling
	pc2_monitor.texture = tex_pc_hijau
	pc2_warning_badge.visible = false
	pc2_alert_circle.visible = false
	pc2_prompt_pill.visible = false
	
	# Update PC 2 pill to "PC 2 ONLINE"
	var lbl = pc2_pill.get_node_or_null("Label") as Label
	if lbl:
		lbl.text = "PC 2 ONLINE"
		lbl.add_theme_color_override("font_color", Color("#14532d"))
	var sb = pc2_pill.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		sb.bg_color = Color("#dcfce7")
		sb.border_color = Color("#22c55e")
		
	# 2. Show placed cards on Meja Teknisi
	meja_placed_net.visible = true
	meja_placed_host.visible = true
	meja_prompt_pill.visible = false
	
	# 3. Cable to PC 2 turns solid green
	cables_container.queue_redraw()
	
	# 4. Save progression to PlayerData
	var pd = get_node_or_null("/root/PlayerData")
	if pd:
		pd.set_level_stars(3, 1, hearts)
			
	# 5. Show GameDialog Victory
	await get_tree().create_timer(1.2).timeout
	_show_victory_dialog()

func _show_victory_dialog() -> void:
	if is_game_over:
		return
	is_completed = true
	is_game_active = false
	if task_modal and is_instance_valid(task_modal):
		task_modal.visible = false
	if whiteboard_modal and is_instance_valid(whiteboard_modal):
		whiteboard_modal.visible = false
	is_modal_open = false
	
	var act_retry = func():
		get_tree().reload_current_scene()
	var act_next = func():
		get_tree().change_scene_to_file("res://scenes/gameplay/level_3_2.tscn")
	var act_map = func():
		get_tree().change_scene_to_file("res://scenes/level_path.tscn")
		
	var time_str = "Skor: %d | Waktu Tersisa: %02d:%02d" % [max(10, 100 - error_count * 15), int(time_remaining) / 60, int(time_remaining) % 60]
	var msg = "Luar biasa! Kamu berhasil memisahkan NetID (10.20.30.0/24) dan HostID (55). Koneksi PC 2 telah pulih dan aktif kembali secara normal!"
	
	if not game_dialog or not is_instance_valid(game_dialog):
		game_dialog = GameDialogScene.instantiate()
		game_dialog.z_index = 350
		add_child(game_dialog)
	else:
		game_dialog.z_index = 350
		
	game_dialog.show_win(
		"MISI SELESAI!",
		msg,
		hearts,
		time_str,
		act_next,
		act_map,
		"LANJUT KE 3.2"
	)

func _game_over(custom_reason: String = "") -> void:
	if is_game_over:
		return
	is_game_over = true
	is_game_active = false
	
	if task_modal and is_instance_valid(task_modal):
		task_modal.visible = false
	if whiteboard_modal and is_instance_valid(whiteboard_modal):
		whiteboard_modal.visible = false
	is_modal_open = false
	
	_play_synth_sequence([220.0, 196.0, 164.81, 130.81], 0.15)
	
	var reason = custom_reason
	if reason == "":
		var cause = "Nyawa teknisi telah habis!" if hearts <= 0 else "Waktu misi telah habis!"
		reason = cause + " Periksa kembali pembagian oktet IPv4 pada prefix /24!"
		
	if not game_dialog or not is_instance_valid(game_dialog):
		game_dialog = GameDialogScene.instantiate()
		game_dialog.z_index = 350
		add_child(game_dialog)
	else:
		game_dialog.z_index = 350
		
	game_dialog.show_game_over(
		reason,
		func(): get_tree().reload_current_scene(),
		func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn")
	)

func _update_hearts_ui() -> void:
	for i in range(3):
		if i < hearts:
			hearts_rects[i].modulate = Color(1, 1, 1, 1)
		else:
			hearts_rects[i].modulate = Color(0.3, 0.3, 0.3, 0.4)

func _open_task_modal() -> void:
	if is_modal_open:
		return
	is_modal_open = true
	is_game_active = false
	task_modal.visible = true
	task_modal.modulate.a = 0.0
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(task_modal, "modulate:a", 1.0, 0.25)
	_play_synth_sequence([523.25, 659.25], 0.08)

func _close_task_modal() -> void:
	if not task_modal.visible:
		return
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(task_modal, "modulate:a", 0.0, 0.2)
	tw.finished.connect(func():
		task_modal.visible = false
		is_modal_open = false
		if not is_completed and not is_game_over:
			is_game_active = true
	)

func _open_whiteboard_modal() -> void:
	if is_modal_open:
		return
	is_modal_open = true
	is_game_active = false
	
	if not whiteboard_modal:
		whiteboard_modal = Control.new()
		whiteboard_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
		whiteboard_modal.z_index = 210
		add_child(whiteboard_modal)
		
		var dim = ColorRect.new()
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.color = Color(0, 0, 0, 0.6)
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		whiteboard_modal.add_child(dim)
		
		var wb_rect = TextureRect.new()
		wb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wb_rect.custom_minimum_size = Vector2(800, 420)
		wb_rect.size = Vector2(800, 420)
		wb_rect.anchor_left = 0.5
		wb_rect.anchor_top = 0.5
		wb_rect.anchor_right = 0.5
		wb_rect.anchor_bottom = 0.5
		wb_rect.offset_left = -400.0
		wb_rect.offset_top = -210.0
		wb_rect.offset_right = 400.0
		wb_rect.offset_bottom = 210.0
		wb_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
		wb_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
		wb_rect.texture = tex_papan_materi
		whiteboard_modal.add_child(wb_rect)
		
		var wb_close_btn = CloseButtonScene.instantiate()
		wb_close_btn.position = Vector2(800 - 52, 14)
		if wb_close_btn.has_signal("closed"):
			wb_close_btn.closed.connect(func():
				whiteboard_modal.visible = false
				is_modal_open = false
				is_game_active = true
			)
		wb_close_btn.pressed.connect(func():
			whiteboard_modal.visible = false
			is_modal_open = false
			is_game_active = true
		)
		wb_rect.add_child(wb_close_btn)
		
		var close_b = Button.new()
		close_b.text = "TUTUP MATERI"
		close_b.size = Vector2(180, 44)
		close_b.position = Vector2(310, 360)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color("#593e38")
		sb.set_corner_radius_all(14)
		close_b.add_theme_stylebox_override("normal", sb)
		close_b.add_theme_color_override("font_color", Color("#ffffff"))
		close_b.add_theme_font_override("font", font_bold)
		close_b.pressed.connect(func():
			whiteboard_modal.visible = false
			is_modal_open = false
			is_game_active = true
		)
		wb_rect.add_child(close_b)
		
	whiteboard_modal.visible = true
	whiteboard_modal.modulate.a = 0.0
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(whiteboard_modal, "modulate:a", 1.0, 0.2)

func _setup_pause_and_dialog() -> void:
	pause_modal = PauseModalScene.instantiate()
	pause_modal.z_index = 250
	add_child(pause_modal)
	pause_modal.resume_requested.connect(func(): is_game_active = true)
	pause_modal.restart_requested.connect(func(): get_tree().reload_current_scene())
	pause_modal.exit_requested.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
	
	game_dialog = GameDialogScene.instantiate()
	game_dialog.z_index = 260
	add_child(game_dialog)

func _on_pause_pressed() -> void:
	is_game_active = false
	if pause_modal.has_method("open"):
		pause_modal.open()

func _on_back_pressed() -> void:
	is_game_active = false
	var act_yes = func():
		get_tree().change_scene_to_file("res://scenes/level_path.tscn")
	var act_no = func():
		is_game_active = true
		
	game_dialog.setup({
		"title": "KELUAR LEVEL?",
		"message": "Apakah kamu yakin ingin keluar ke peta level? Progres saat ini belum tersimpan.",
		"type": "konfirmasi",
		"buttons": [
			{ "text": "Keluar", "action": act_yes, "color": "orange" },
			{ "text": "Lanjut Main", "action": act_no, "color": "green" }
		]
	})
	game_dialog.open()

func _on_station_clicked() -> void:
	if not is_completed:
		_open_task_modal()

func _process(delta: float) -> void:
	anim_pulse_time += delta
	
	# Pulsing alert circle on PC 2
	if pc2_alert_circle and pc2_alert_circle.visible and not is_completed:
		pc2_alert_circle.queue_redraw()
		
	# Floating warning badge bobbing
	if pc2_warning_badge and pc2_warning_badge.visible:
		pc2_warning_badge.position.y = -25.0 + sin(anim_pulse_time * 5.0) * 4.0
		
	if not is_game_active or is_game_over or is_completed:
		return
		
	# Timer Countdown
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_game_over("Waktu misi telah habis! Waktu analisis NetID dan HostID telah berakhir.")
		return
	_update_timer_display()
	
	# Movement Processing
	_handle_movement(delta)
	
	# Proximity Detection with Stations
	_check_station_proximity()

func _update_timer_display() -> void:
	var mins = int(time_remaining) / 60
	var secs = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	if time_remaining <= 30.0:
		timer_label.add_theme_color_override("font_color", Color("#dc2626"))
	else:
		timer_label.add_theme_color_override("font_color", Color("#593e38"))

func _handle_movement(delta: float) -> void:
	# Read keyboard input
	var kb_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		kb_dir.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		kb_dir.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		kb_dir.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		kb_dir.y += 1.0
		
	var final_dir = kb_dir
	if input_dir.length_squared() > 0.01:
		final_dir = input_dir
	final_dir = final_dir.normalized()
	
	if final_dir.length_squared() > 0.01:
		char_pos += final_dir * MOVE_SPEED * delta
		# Clamp within room playable floor bounds
		char_pos.x = clamp(char_pos.x, 140.0, 1380.0)
		char_pos.y = clamp(char_pos.y, 240.0, 580.0)
		character_node.position = char_pos
		
		# Facing
		if final_dir.x < -0.1:
			char_sprite.flip_h = true
		elif final_dir.x > 0.1:
			char_sprite.flip_h = false
			
		# Animation Frames
		if walk_frames.size() > 0:
			walk_frame_index += delta * 14.0
			var idx = int(walk_frame_index) % walk_frames.size()
			char_sprite.texture = walk_frames[idx]
			
		# Footsteps sound
		footstep_timer += delta
		if footstep_timer >= 0.28:
			footstep_timer = 0.0
			_play_footstep()
	else:
		if char_sprite:
			char_sprite.texture = tex_char_idle
		walk_frame_index = 0.0

func _check_station_proximity() -> void:
	var char_center = character_node.position + character_node.size / 2.0
	var meja_center = meja_teknisi.position + meja_teknisi.size / 2.0
	var pc2_center = pc2_desk.position + pc2_desk.size / 2.0
	
	var dist_meja = char_center.distance_to(meja_center)
	var dist_pc2 = char_center.distance_to(pc2_center)
	
	if dist_meja < 180.0 and not is_completed:
		meja_prompt_pill.visible = true
	else:
		meja_prompt_pill.visible = false
		
	if dist_pc2 < 160.0 and not is_completed:
		pc2_prompt_pill.visible = true
	else:
		pc2_prompt_pill.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active:
		return
		
	# Mobile Joystick Input Processing
	if event is InputEventScreenTouch:
		var st = event as InputEventScreenTouch
		if st.pressed:
			if st.position.x < 500 and st.position.y > 400 and dpad_touch_id == -1:
				dpad_touch_id = st.index
				_update_dpad(st.position)
		else:
			if dpad_touch_id == st.index:
				dpad_touch_id = -1
				input_dir = Vector2.ZERO
				dpad_knob_sprite.position = dpad_center - dpad_knob_sprite.size / 2.0
	elif event is InputEventScreenDrag:
		var sd = event as InputEventScreenDrag
		if dpad_touch_id == sd.index:
			_update_dpad(sd.position)

func _update_dpad(touch_pos: Vector2) -> void:
	var diff = touch_pos - dpad_center
	var dist = diff.length()
	if dist > dpad_radius:
		diff = diff.normalized() * dpad_radius
	dpad_knob_sprite.position = dpad_center + diff - dpad_knob_sprite.size / 2.0
	input_dir = diff / dpad_radius

func _create_pill(text: String, text_col: Color, bg_col: Color, border_col: Color) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var lbl = Label.new()
	lbl.name = "Label"
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_extrabold)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", text_col)
	p.add_child(lbl)
	return p

# --- PROCEDURAL SYNTH SOUNDS ---

func _play_footstep() -> void:
	if footstep_player:
		var freqs = [180.0, 210.0, 195.0]
		var f = freqs[randi() % freqs.size()]
		_play_tone_on_player(footstep_player, f, 0.05, 0.15)

func _play_buzz_error() -> void:
	if audio_player:
		_play_tone_on_player(audio_player, 110.0, 0.22, 0.35)

func _play_win_fanfare() -> void:
	if audio_player:
		_play_synth_sequence([523.25, 659.25, 783.99, 1046.50], 0.14)

func _play_tone_on_player(player: AudioStreamPlayer, freq: float, duration: float, vol: float = 0.2) -> void:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var val = sin(TAU * freq * t) * vol
		var env = 1.0 - (float(i) / float(num_samples))
		val *= env
		var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, s16)
	stream.data = data
	player.stream = stream
	player.play()

func _play_synth_sequence(freqs: Array, step_time: float) -> void:
	var sample_rate = 22050
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = step_time * freqs.size() + 0.1
	audio_player.stream = gen
	audio_player.play()
	
	var playback: AudioStreamGeneratorPlayback = audio_player.get_stream_playback()
	if not playback:
		return
		
	for f in freqs:
		var n_frames = int(sample_rate * step_time)
		for i in range(n_frames):
			var t = float(i) / float(sample_rate)
			var env = 1.0 - (float(i) / float(n_frames)) * 0.5
			var s = sin(TAU * f * t) * 0.22 * env
			playback.push_frame(Vector2(s, s))
