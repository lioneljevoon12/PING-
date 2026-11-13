extends Control

# Level 3.4 - Memperbaiki Routing Table (Ruang Kontrol Subnet & Routing)
# Sesuai Proposal & Desain Figma 100%:
# - Ruang Kontrol Subnet: Cyan Wall (#84ffff), Gerbang pink, Monitor Topologi & Routing Table di dinding
# - Meja Teknisi Routing di tengah ("MEJA TEKNISI ROUTING"), Tombol "Perbaiki Routing"
# - Klien: PC-01 (192.168.10.10) & PC-02 (192.168.10.11) -> Switch (SW-01) -> Router 1 (R-01)
# - Router 1 (R-01): Status "CEK ROUTING!" (Gagal) -> "ROUTE ACTIVE" (Sukses)
# - Router 2 (R-02 Hop: 10.10.10.2) -> Server Utama (192.168.20.0/24)
# - Server Utama: STANDBY (Gagal) -> ONLINE (UP) (Sukses)
# - Popup Task: Melengkapi Baris ke-2 Routing Table Router R-01:
#   Slot 1: Destination Network -> 192.168.20.0
#   Slot 2: Subnet Mask -> 255.255.255.0
#   Slot 3: Next-Hop -> 10.10.10.2
#   Slot 4: Interface -> eth1
# - Transisi GAGAL -> SUKSES:
#   - Topology Map dinding: ROUTE ERR -> ROUTE OK (garis hijau solid)
#   - Monitor Routing Table dinding: Row 2 terisi lengkap, status hijau "ALUR PC - SW - R1 - R2 - SERVER TERHUBUNG!"
#   - R-01: Aura merah pulsating -> Aura hijau "R-01 : ROUTE ACTIVE"
#   - Kabel R1 - R2: Garis putus-putus merah -> Garis hijau solid
#   - Server Zone: STANDBY -> ONLINE (UP)
#   - Pesan Monitor Sistem muncul di bagian bawah:
#     "PESAN MONITOR SISTEM (STAGE 3 SELESAI — LANJUT KE STAGE 4): \"Alamat jaringan sudah benar. Periksa struktur dan koneksi perangkat jaringan.\""
#   - Sistem bintang terintegrasi PlayerData & membuka Stage 4!

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
var tex_vector_heart = preload("res://art/assets/PING! Assets/asset-gameplay/generals/vector-hearts.png")
var tex_dpad_base = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_pad_a.png")
var tex_dpad_knob = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_nub_a.png")

# Stage 3 Room Textures
var tex_pc_hijau = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PC_HIJAU.png")
var tex_meja_pc = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/meja_pc.png")
var tex_warning = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/warning.png")
var tex_hint_card = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/TaskHint34_Card.png")
var tex_topo_wall = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/34_Wall_Network_Topology_Map.png")
var tex_rt_wall = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/34_Wall_Routing_Table_Monitor.png")
var tex_alert_rt = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/34_Alert_Badge_WallRT.png")
var tex_main_desk = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/34_Main_Technician_Desk.png")
var tex_server_zone = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/34_Server_Destination_Zone.png")
var tex_server_zone_up = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/34_Server_Destination_Zone1.png")

# Popup Task 34 Textures
var tex_popup_window = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/34/Puzzle_Window_Base.png")
var tex_topo_bar = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/34/Topology_Reference_Bar.png")
var tex_rt_grid = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/34/Routing_Table_Main_Grid.png")
var tex_tray_34 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/34/Routing_Cards_Tray.png")
var tex_close_btn = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/31/Close_Button.png")

# Preloaded card textures for filled rows
var tex_card_dest_fill = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/34/Card34_Dest_20_0.png")
var tex_card_mask_fill = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/34/Card34_Mask_24.png")
var tex_card_hop_fill = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/34/Card34_NextHop_R2.png")
var tex_card_iface_fill = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/34/Card34_Interface_Eth1.png")

# Scene References
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer
@onready var background: TextureRect = %Background
@onready var floor_carpet: Panel = %FloorCarpet
@onready var door_arch: TextureRect = %DoorArch
@onready var potted_plant: TextureRect = %PottedPlant
@onready var wall_topo_map: TextureRect = %WallTopologyMap
@onready var wall_rt_monitor: TextureRect = %WallRoutingMonitor
@onready var cables_container: Control = %CablesContainer
@onready var main_technician_desk: Control = %MainTechnicianDesk
@onready var pc1_desk: Control = %PC1Desk
@onready var pc2_desk: Control = %PC2Desk
@onready var switch_station: Control = %SwitchStation
@onready var router1_station: Control = %Router1Station
@onready var router2_station: Control = %Router2Station
@onready var server_zone: Control = %ServerZone
@onready var character_node: Control = %CharacterNode
@onready var mobile_controls_root: Control = %MobileControlsRoot

# Wall dynamic elements
var wall_rt_alert_badge: TextureRect
var wall_topo_overlay: Control
var wall_rt_row2_overlay: Control
var desk_prompt_pill: PanelContainer

# Station subnodes
var r1_circle_outline: Control
var r1_status_pill: PanelContainer
var r1_status_label: Label
var r1_warning_badge: TextureRect
var r2_status_pill: PanelContainer
var r2_status_label: Label
var server_zone_tex: TextureRect
var bottom_system_banner: PanelContainer

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
var hearts_container: HBoxContainer
var hearts_rects: Array[TextureRect] = []
var toast_panel: PanelContainer
var toast_label: Label
var toast_tween: Tween

# Modals
var intro_modal: Control
var task_modal: Control
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

# Task 3.4 State:
# Slot keys: "dest", "mask", "hop", "iface"
# Correct targets:
#   "dest"  -> "192.168.20.0"
#   "mask"  -> "255.255.255.0"
#   "hop"   -> "10.10.10.2"
#   "iface" -> "eth1"
const CORRECT_SLOTS: Dictionary = {
	"dest": "dest",
	"mask": "mask",
	"hop": "hop",
	"iface": "iface"
}

const CARDS_DATA: Dictionary = {
	"dest": {
		"id": "dest",
		"val": "192.168.20.0",
		"sub": "Destination Network",
		"bg_color": Color("#c2f0e0"),
		"border_color": Color("#1b4332"),
		"text_color": Color("#081c15"),
		"tag_color": Color("#2d6a4f")
	},
	"mask": {
		"id": "mask",
		"val": "255.255.255.0",
		"sub": "Subnet Mask (/24)",
		"bg_color": Color("#fed7aa"),
		"border_color": Color("#7c2d12"),
		"text_color": Color("#431407"),
		"tag_color": Color("#9a3412")
	},
	"hop": {
		"id": "hop",
		"val": "10.10.10.2",
		"sub": "Next-Hop (Router R-02)",
		"bg_color": Color("#e9d5ff"),
		"border_color": Color("#581c87"),
		"text_color": Color("#3b0764"),
		"tag_color": Color("#7e22ce")
	},
	"iface": {
		"id": "iface",
		"val": "eth1",
		"sub": "Interface Keluar",
		"bg_color": Color("#fef08a"),
		"border_color": Color("#713f12"),
		"text_color": Color("#422006"),
		"tag_color": Color("#a16207")
	}
}

var slot_assignment: Dictionary = {
	"dest": "",
	"mask": "",
	"hop": "",
	"iface": ""
}
var selected_card_id: String = ""
var card_nodes: Dictionary = {}
var slot_nodes: Dictionary = {}
var verify_button: Button

# Drag state
var dragging_card_id: String = ""
var drag_touch_id: int = -1
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	call_deferred("_setup_help_button")
	_setup_floor_carpet()
	_load_character_frames()
	_setup_character()
	_setup_wall_monitors()
	_setup_main_technician_desk()
	_setup_pc_clients()
	_setup_switch_and_routers()
	_setup_server_destination_zone()
	_setup_cables()
	_setup_easter_eggs()
	_build_header_ui()
	_build_toast_ui()
	_build_mobile_controls()
	_setup_intro_modal()
	_setup_task_modal()
	_setup_game_dialog()
	
	_open_intro_modal()
	_check_screenshot_args()

func _setup_floor_carpet() -> void:
	floor_carpet.visible = false

func _load_character_frames() -> void:
	walk_frames.clear()
	for i in range(1, 33):
		var path = "res://art/assets/PING! Assets/Sprite animation/router walk/%d.png" % i
		if ResourceLoader.exists(path):
			var tex = load(path)
			if tex:
				walk_frames.append(tex)

func _setup_character() -> void:
	char_sprite = TextureRect.new()
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.custom_minimum_size = Vector2(250, 138)
	char_sprite.size = Vector2(250, 138)
	char_sprite.position = Vector2(-65, -18)
	char_sprite.pivot_offset = Vector2(125, 69)
	char_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if walk_frames.size() > 0:
		char_sprite.texture = walk_frames[0]
	else:
		char_sprite.texture = tex_char_idle
	character_node.add_child(char_sprite)
	var _pd = get_node_or_null("/root/PlayerData")
	if _pd and _pd.has_method("apply_to_character"):
		_pd.apply_to_character(char_sprite)
	char_pos = character_node.position

func _setup_wall_monitors() -> void:
	# Topology Map
	wall_topo_map.mouse_filter = Control.MOUSE_FILTER_STOP
	wall_topo_map.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_task_modal()
	)
	
	wall_topo_overlay = Control.new()
	wall_topo_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	wall_topo_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wall_topo_map.add_child(wall_topo_overlay)
	
	# Routing Table Monitor
	wall_rt_monitor.mouse_filter = Control.MOUSE_FILTER_STOP
	wall_rt_monitor.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_task_modal()
	)
	
	# Alert badge at top right of routing table monitor
	wall_rt_alert_badge = TextureRect.new()
	wall_rt_alert_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wall_rt_alert_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wall_rt_alert_badge.custom_minimum_size = Vector2(44, 44)
	wall_rt_alert_badge.size = Vector2(44, 44)
	wall_rt_alert_badge.position = Vector2(wall_rt_monitor.size.x - 22, -18)
	wall_rt_alert_badge.pivot_offset = Vector2(22, 22)
	wall_rt_alert_badge.texture = tex_alert_rt
	wall_rt_monitor.add_child(wall_rt_alert_badge)
	
	# Row 2 overlay on Wall Routing Table Monitor
	wall_rt_row2_overlay = Control.new()
	wall_rt_row2_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	wall_rt_row2_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wall_rt_monitor.add_child(wall_rt_row2_overlay)

func _setup_main_technician_desk() -> void:
	var desk_tex = TextureRect.new()
	desk_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desk_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	desk_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	desk_tex.texture = tex_main_desk
	desk_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_technician_desk.add_child(desk_tex)
	
	# Clickable overlay button on the desk
	var desk_btn = Button.new()
	desk_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	desk_btn.flat = true
	desk_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	desk_btn.pressed.connect(_open_task_modal)
	main_technician_desk.add_child(desk_btn)
	
	# Prompt Button "Perbaiki Routing" right below desk
	desk_prompt_pill = PanelContainer.new()
	desk_prompt_pill.size = Vector2(130, 28)
	desk_prompt_pill.position = Vector2(main_technician_desk.position.x + (main_technician_desk.size.x - 130) / 2.0, main_technician_desk.position.y + main_technician_desk.size.y + 18)
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color("#ffffff")
	sb_btn.border_color = Color("#e11d48")
	sb_btn.set_border_width_all(2)
	sb_btn.set_corner_radius_all(14)
	sb_btn.shadow_color = Color(0, 0, 0, 0.12)
	sb_btn.shadow_size = 4
	desk_prompt_pill.add_theme_stylebox_override("panel", sb_btn)
	add_child(desk_prompt_pill)
	
	var prompt_btn = Button.new()
	prompt_btn.text = "Perbaiki Routing"
	prompt_btn.flat = true
	prompt_btn.add_theme_font_override("font", font_black)
	prompt_btn.add_theme_font_size_override("font_size", 11)
	prompt_btn.add_theme_color_override("font_color", Color("#e11d48"))
	prompt_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	prompt_btn.pressed.connect(_open_task_modal)
	desk_prompt_pill.add_child(prompt_btn)

func _setup_pc_clients() -> void:
	# PC-01
	_build_client_pc_desk(pc1_desk, "PC-01: 192.168.10.10", "PC-01")
	# PC-02
	_build_client_pc_desk(pc2_desk, "PC-02: 192.168.10.11", "PC-02")

func _build_client_pc_desk(parent: Control, ip_text: String, pc_name: String) -> void:
	var desk_bg = TextureRect.new()
	desk_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desk_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	desk_bg.custom_minimum_size = Vector2(parent.size.x, parent.size.y)
	desk_bg.size = Vector2(parent.size.x, parent.size.y)
	desk_bg.texture = tex_meja_pc
	parent.add_child(desk_bg)
	
	var monitor = TextureRect.new()
	monitor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monitor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monitor.custom_minimum_size = Vector2(76, 68)
	monitor.size = Vector2(76, 68)
	monitor.position = Vector2((parent.size.x - 76) / 2.0, 10)
	monitor.texture = tex_pc_hijau
	parent.add_child(monitor)
	
	var pill = PanelContainer.new()
	pill.size = Vector2(150, 22)
	pill.position = Vector2((parent.size.x - 150) / 2.0, parent.size.y - 28)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	pill.add_theme_stylebox_override("panel", sb)
	parent.add_child(pill)
	
	var lbl = Label.new()
	lbl.text = ip_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_bold)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color("#1e293b"))
	pill.add_child(lbl)

func _setup_switch_and_routers() -> void:
	# Switch Station (SW-01)
	var sw_panel = PanelContainer.new()
	sw_panel.size = Vector2(switch_station.size.x, 80)
	sw_panel.position = Vector2(0, 10)
	var sb_sw = StyleBoxFlat.new()
	sb_sw.bg_color = Color("#f8fafc")
	sb_sw.border_color = Color("#4a2e2b")
	sb_sw.set_border_width_all(3)
	sb_sw.set_corner_radius_all(16)
	sw_panel.add_theme_stylebox_override("panel", sb_sw)
	switch_station.add_child(sw_panel)
	
	# Switch box graphic inside
	var sw_box = Panel.new()
	sw_box.size = Vector2(150, 42)
	sw_box.position = Vector2(20, 14)
	var sb_box = StyleBoxFlat.new()
	sb_box.bg_color = Color("#93c5fd")
	sb_box.border_color = Color("#2563eb")
	sb_box.set_border_width_all(2)
	sb_box.set_corner_radius_all(8)
	sw_box.add_theme_stylebox_override("panel", sb_box)
	sw_panel.add_child(sw_box)
	
	# Port ports row
	var ports_row = HBoxContainer.new()
	ports_row.position = Vector2(10, 16)
	ports_row.add_theme_constant_override("separation", 6)
	sw_box.add_child(ports_row)
	for p in range(8):
		var port_dot = Panel.new()
		port_dot.custom_minimum_size = Vector2(10, 10)
		var sb_p = StyleBoxFlat.new()
		sb_p.bg_color = Color("#1e3a8a")
		sb_p.set_corner_radius_all(2)
		port_dot.add_theme_stylebox_override("panel", sb_p)
		ports_row.add_child(port_dot)
		
	var sw_lbl_pill = PanelContainer.new()
	sw_lbl_pill.size = Vector2(140, 22)
	sw_lbl_pill.position = Vector2((switch_station.size.x - 140) / 2.0, switch_station.size.y - 18)
	var sb_sw_p = StyleBoxFlat.new()
	sb_sw_p.bg_color = Color("#ffffff")
	sb_sw_p.border_color = Color("#4a2e2b")
	sb_sw_p.set_border_width_all(2)
	sb_sw_p.set_corner_radius_all(10)
	sw_lbl_pill.add_theme_stylebox_override("panel", sb_sw_p)
	switch_station.add_child(sw_lbl_pill)
	
	var sw_lbl = Label.new()
	sw_lbl.text = "SWITCH (SW-01)"
	sw_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sw_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sw_lbl.add_theme_font_override("font", font_extrabold)
	sw_lbl.add_theme_font_size_override("font_size", 9)
	sw_lbl.add_theme_color_override("font_color", Color("#1e293b"))
	sw_lbl_pill.add_child(sw_lbl)
	
	# --- ROUTER 1 (R-01) ---
	r1_circle_outline = Control.new()
	r1_circle_outline.size = Vector2(140, 95)
	r1_circle_outline.position = Vector2((router1_station.size.x - 140) / 2.0, 5)
	router1_station.add_child(r1_circle_outline)
	
	var r1_sprite = TextureRect.new()
	r1_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r1_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r1_sprite.custom_minimum_size = Vector2(90, 75)
	r1_sprite.size = Vector2(90, 75)
	r1_sprite.position = Vector2((router1_station.size.x - 90) / 2.0, 15)
	r1_sprite.texture = tex_char_idle
	router1_station.add_child(r1_sprite)
	
	r1_warning_badge = TextureRect.new()
	r1_warning_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r1_warning_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r1_warning_badge.custom_minimum_size = Vector2(28, 28)
	r1_warning_badge.size = Vector2(28, 28)
	r1_warning_badge.position = Vector2(router1_station.size.x - 36, 12)
	r1_warning_badge.texture = tex_warning
	router1_station.add_child(r1_warning_badge)
	
	r1_status_pill = PanelContainer.new()
	r1_status_pill.size = Vector2(150, 22)
	r1_status_pill.position = Vector2((router1_station.size.x - 150) / 2.0, router1_station.size.y - 20)
	var sb_r1 = StyleBoxFlat.new()
	sb_r1.bg_color = Color("#ffffff")
	sb_r1.border_color = Color("#ef4444")
	sb_r1.set_border_width_all(2)
	sb_r1.set_corner_radius_all(10)
	r1_status_pill.add_theme_stylebox_override("panel", sb_r1)
	router1_station.add_child(r1_status_pill)
	
	r1_status_label = Label.new()
	r1_status_label.text = "R-01 : CEK ROUTING!"
	r1_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r1_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r1_status_label.add_theme_font_override("font", font_black)
	r1_status_label.add_theme_font_size_override("font_size", 9)
	r1_status_label.add_theme_color_override("font_color", Color("#ef4444"))
	r1_status_pill.add_child(r1_status_label)
	
	# Click R1 opens task modal
	var r1_btn = Button.new()
	r1_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	r1_btn.flat = true
	r1_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	r1_btn.pressed.connect(_open_task_modal)
	router1_station.add_child(r1_btn)
	
	# --- ROUTER 2 (R-02) ---
	var r2_sprite = TextureRect.new()
	r2_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r2_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r2_sprite.custom_minimum_size = Vector2(90, 75)
	r2_sprite.size = Vector2(90, 75)
	r2_sprite.position = Vector2((router2_station.size.x - 90) / 2.0, 15)
	r2_sprite.texture = tex_char_idle
	router2_station.add_child(r2_sprite)
	
	r2_status_pill = PanelContainer.new()
	r2_status_pill.size = Vector2(160, 22)
	r2_status_pill.position = Vector2((router2_station.size.x - 160) / 2.0, router2_station.size.y - 20)
	var sb_r2 = StyleBoxFlat.new()
	sb_r2.bg_color = Color("#ffffff")
	sb_r2.border_color = Color("#4a2e2b")
	sb_r2.set_border_width_all(2)
	sb_r2.set_corner_radius_all(10)
	r2_status_pill.add_theme_stylebox_override("panel", sb_r2)
	router2_station.add_child(r2_status_pill)
	
	r2_status_label = Label.new()
	r2_status_label.text = "R-02 (Hop: 10.10.10.2)"
	r2_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r2_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r2_status_label.add_theme_font_override("font", font_bold)
	r2_status_label.add_theme_font_size_override("font_size", 9)
	r2_status_label.add_theme_color_override("font_color", Color("#1e293b"))
	r2_status_pill.add_child(r2_status_label)

func _setup_server_destination_zone() -> void:
	server_zone_tex = TextureRect.new()
	server_zone_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	server_zone_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	server_zone_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	server_zone_tex.texture = tex_server_zone
	server_zone.add_child(server_zone_tex)
	
	var srv_btn = Button.new()
	srv_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	srv_btn.flat = true
	srv_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	srv_btn.pressed.connect(func():
		if is_completed:
			show_toast("✅ Server Utama (192.168.20.0/24) telah ONLINE dan terhubung!")
		else:
			show_toast("⚠️ Server Utama (192.168.20.0/24) masih STANDBY! Rute dari R-01 belum dikonfigurasi.")
	)
	server_zone.add_child(srv_btn)

func _setup_cables() -> void:
	# Drawn dynamically in _draw_cables()
	cables_container.draw.connect(_draw_cables)

func _draw_cables() -> void:
	# Cable 1: PC-01 to Switch
	var p1_out = pc1_desk.position + Vector2((pc1_desk.size * pc1_desk.scale).x, (pc1_desk.size * pc1_desk.scale).y * 0.5)
	var sw_in1 = switch_station.position + Vector2(0, (switch_station.size * switch_station.scale).y * 0.4)
	cables_container.draw_line(p1_out, Vector2(sw_in1.x - 15, p1_out.y), Color("#4ade80"), 4.0)
	cables_container.draw_line(Vector2(sw_in1.x - 15, p1_out.y), Vector2(sw_in1.x - 15, sw_in1.y), Color("#4ade80"), 4.0)
	cables_container.draw_line(Vector2(sw_in1.x - 15, sw_in1.y), sw_in1, Color("#4ade80"), 4.0)
	
	# Cable 2: PC-02 to Switch
	var p2_out = pc2_desk.position + Vector2((pc2_desk.size * pc2_desk.scale).x, (pc2_desk.size * pc2_desk.scale).y * 0.5)
	var sw_in2 = switch_station.position + Vector2(0, (switch_station.size * switch_station.scale).y * 0.7)
	cables_container.draw_line(p2_out, Vector2(sw_in2.x - 15, p2_out.y), Color("#4ade80"), 4.0)
	cables_container.draw_line(Vector2(sw_in2.x - 15, p2_out.y), Vector2(sw_in2.x - 15, sw_in2.y), Color("#4ade80"), 4.0)
	cables_container.draw_line(Vector2(sw_in2.x - 15, sw_in2.y), sw_in2, Color("#4ade80"), 4.0)
	
	# Cable 3: Switch to R-01
	var sw_out = switch_station.position + Vector2((switch_station.size * switch_station.scale).x, (switch_station.size * switch_station.scale).y * 0.5)
	var r1_in = router1_station.position + Vector2(0, (router1_station.size * router1_station.scale).y * 0.5)
	cables_container.draw_line(sw_out, Vector2(r1_in.x - 25, sw_out.y), Color("#4ade80"), 4.0)
	cables_container.draw_line(Vector2(r1_in.x - 25, sw_out.y), Vector2(r1_in.x - 25, r1_in.y), Color("#4ade80"), 4.0)
	cables_container.draw_line(Vector2(r1_in.x - 25, r1_in.y), r1_in, Color("#4ade80"), 4.0)
	
	# Cable 5: R-01 to R-02
	var r1_out = router1_station.position + Vector2((router1_station.size * router1_station.scale).x, (router1_station.size * router1_station.scale).y * 0.55)
	var r2_in = router2_station.position + Vector2(0, (router2_station.size * router2_station.scale).y * 0.55)
	if is_completed:
		cables_container.draw_line(r1_out, r2_in, Color("#22c55e"), 6.0)
	else:
		# Striped dashed red cable
		_draw_dashed_line(r1_out, r2_in, Color("#ef4444"), Color("#fee2e2"), 6.0, 10.0)
		
	# Cable 6: R-02 to Server Zone
	var r2_out = router2_station.position + Vector2((router2_station.size * router2_station.scale).x, (router2_station.size * router2_station.scale).y * 0.5)
	var srv_in = server_zone.position + Vector2(0, (server_zone.size * server_zone.scale).y * 0.5)
	var cable_srv_col = Color("#22c55e") if is_completed else Color("#67e8f9")
	cables_container.draw_line(r2_out, Vector2(r2_out.x + 30, r2_out.y), cable_srv_col, 5.0)
	cables_container.draw_line(Vector2(r2_out.x + 30, r2_out.y), Vector2(r2_out.x + 30, srv_in.y), cable_srv_col, 5.0)
	cables_container.draw_line(Vector2(r2_out.x + 30, srv_in.y), srv_in, cable_srv_col, 5.0)

func _draw_dashed_line(from: Vector2, to: Vector2, col1: Color, col2: Color, width: float, dash_len: float) -> void:
	var total_dist = from.distance_to(to)
	var dir = (to - from).normalized()
	var steps = int(total_dist / dash_len)
	for s in range(steps):
		var p_start = from + dir * (s * dash_len)
		var p_end = from + dir * min((s + 1) * dash_len, total_dist)
		var c = col1 if (s % 2 == 0) else col2
		cables_container.draw_line(p_start, p_end, c, width)

func _setup_easter_eggs() -> void:
	potted_plant.mouse_filter = Control.MOUSE_FILTER_STOP
	potted_plant.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_play_synth_sequence([523.25, 659.25], 0.08)
			var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tw.tween_property(potted_plant, "scale", Vector2(1.2, 0.85), 0.1)
			tw.chain().tween_property(potted_plant, "scale", Vector2(0.9, 1.15), 0.15)
			tw.chain().tween_property(potted_plant, "scale", Vector2.ONE, 0.1)
			show_toast("🌿 Tanaman ruang kontrol segar dan terawat!")
	)
	
	door_arch.mouse_filter = Control.MOUSE_FILTER_STOP
	door_arch.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			if is_completed:
				_play_synth_sequence([523.25, 659.25, 783.99, 1046.5], 0.09)
				show_toast("🚪 Gerbang Stage 4 Terbuka! Selamat datang di Topologi & Infrastruktur!")
			else:
				_play_synth_sequence([220.0, 196.0], 0.12)
				show_toast("🚪 Gerbang terkunci! Perbaiki tabel routing R-01 agar paket data dapat mencapai Server!")
	)

func _build_header_ui() -> void:
	header_ui = Control.new()
	header_ui.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header_ui.offset_bottom = 100.0
	header_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_ui)
	
	# Back Button
	var back_btn = TextureButton.new()
	back_btn.texture_normal = preload("res://art/ui-ux/levelpath/crisp_back.png")
	back_btn.size = Vector2(64, 64)
	back_btn.position = Vector2(30, 20)
	back_btn.ignore_texture_size = true
	back_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back_btn.pressed.connect(func():
		_play_synth_sequence([440.0, 392.0], 0.08)
		get_tree().change_scene_to_file("res://scenes/level_path.tscn")
	)
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
		h.custom_minimum_size = Vector2(32, 32)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_container.add_child(h)
		hearts_rects.append(h)
		HeartsStyle.schedule_normalize(hearts_rects)
		
	# Level 3.4 Badge
	var lvl_badge = PanelContainer.new()
	lvl_badge.position = Vector2(265, 20)
	lvl_badge.size = Vector2(75, 64)
	var sb_l = StyleBoxFlat.new()
	sb_l.bg_color = Color("#fdf4eb")
	sb_l.border_color = Color("#4a2e2b")
	sb_l.set_border_width_all(3)
	sb_l.set_corner_radius_all(14)
	lvl_badge.add_theme_stylebox_override("panel", sb_l)
	header_ui.add_child(lvl_badge)
	
	var lvl_vbox = VBoxContainer.new()
	lvl_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lvl_vbox.add_theme_constant_override("separation", -2)
	lvl_badge.add_child(lvl_vbox)
	
	var tag1 = Label.new()
	tag1.text = "Level"
	tag1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag1.add_theme_font_override("font", font_extrabold)
	tag1.add_theme_font_size_override("font_size", 11)
	tag1.add_theme_color_override("font_color", Color("#7c5843"))
	lvl_vbox.add_child(tag1)
	
	var tag2 = Label.new()
	tag2.text = "3.4"
	tag2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag2.add_theme_font_override("font", font_black)
	tag2.add_theme_font_size_override("font_size", 15)
	tag2.add_theme_color_override("font_color", Color("#4a2e2b"))
	lvl_vbox.add_child(tag2)
	
	# Timer Panel (02:45)
	var timer_panel = PanelContainer.new()
	timer_panel.position = Vector2(1270, 20)
	timer_panel.size = Vector2(140, 64)
	var sb_t = StyleBoxFlat.new()
	sb_t.bg_color = Color("#fdf4eb")
	sb_t.border_color = Color("#4a2e2b")
	sb_t.set_border_width_all(3)
	sb_t.set_corner_radius_all(14)
	timer_panel.add_theme_stylebox_override("panel", sb_t)
	header_ui.add_child(timer_panel)
	
	var timer_hbox = HBoxContainer.new()
	timer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_hbox.add_theme_constant_override("separation", 6)
	timer_panel.add_child(timer_hbox)
	
	var clock_lbl = Label.new()
	clock_lbl.text = "⏱️"
	clock_lbl.add_theme_font_size_override("font_size", 18)
	timer_hbox.add_child(clock_lbl)
	
	timer_label = Label.new()
	timer_label.text = "02:45"
	timer_label.add_theme_font_override("font", font_black)
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_label.add_theme_color_override("font_color", Color("#4a2e2b"))
	timer_hbox.add_child(timer_label)
	
	# Pause Button (Hamburger ☰)
	var pause_btn = Button.new()
	pause_btn.text = "☰"
	pause_btn.position = Vector2(1425, 20)
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

func _build_toast_ui() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.size = Vector2(500, 50)
	toast_panel.position = Vector2((1560 - 500) / 2.0, 640)
	toast_panel.modulate.a = 0.0
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.z_index = 300
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.15, 0.94)
	sb.border_color = Color("#f59e0b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	toast_panel.add_theme_stylebox_override("panel", sb)
	add_child(toast_panel)
	
	toast_label = Label.new()
	toast_label.text = ""
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_override("font", font_bold)
	toast_label.add_theme_font_size_override("font_size", 13)
	toast_label.add_theme_color_override("font_color", Color("#fef3c7"))
	toast_panel.add_child(toast_label)

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
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	intro_modal.add_child(dim)
	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_on_mulai_pressed()
	)
	
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
		_start_after_tutorial()
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
	
	var win_w = 980.0
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
	
	# Top Topology Reference Bar
	var topo_bar = TextureRect.new()
	topo_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	topo_bar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	topo_bar.custom_minimum_size = Vector2(880, 75)
	topo_bar.size = Vector2(880, 75)
	topo_bar.position = Vector2(50, 52)
	topo_bar.texture = tex_topo_bar
	topo_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_container.add_child(topo_bar)
	
	# Middle Routing Table Grid
	var rt_grid = TextureRect.new()
	rt_grid.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rt_grid.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rt_grid.custom_minimum_size = Vector2(880, 175)
	rt_grid.size = Vector2(880, 175)
	rt_grid.position = Vector2(50, 138)
	rt_grid.texture = tex_rt_grid
	rt_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_container.add_child(rt_grid)
	
	# 4 Drop Slots on Row 2 of Grid
	# Col 1: Destination Network -> dest
	# Col 2: Subnet Mask -> mask
	# Col 3: Next-Hop -> hop
	# Col 4: Interface -> iface
	var slot_keys = ["dest", "mask", "hop", "iface"]
	var slot_w = 210.0
	var slot_h = 75.0
	var slot_y = 226.0
	
	slot_nodes.clear()
	for i in range(4):
		var k = slot_keys[i]
		var s_ctrl = Control.new()
		s_ctrl.name = "Slot_" + k
		s_ctrl.size = Vector2(slot_w, slot_h)
		s_ctrl.position = Vector2(55 + i * 220, slot_y)
		win_container.add_child(s_ctrl)
		
		# Transparent hit box button
		var s_btn = Button.new()
		s_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		s_btn.flat = true
		s_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		s_btn.pressed.connect(func(): _on_slot_tapped(k))
		s_ctrl.add_child(s_btn)
		
		slot_nodes[k] = s_ctrl
		
	# Bottom Cards Tray
	var cards_tray = TextureRect.new()
	cards_tray.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cards_tray.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cards_tray.custom_minimum_size = Vector2(880, 135)
	cards_tray.size = Vector2(880, 135)
	cards_tray.position = Vector2(50, 325)
	cards_tray.texture = tex_tray_34
	cards_tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_container.add_child(cards_tray)
	
	# 4 Draggable / Tappable Parameter Cards in Tray
	card_nodes.clear()
	var card_order = ["dest", "mask", "hop", "iface"]
	var card_w = 205.0
	var card_h = 80.0
	var tray_card_y = 365.0
	
	for i in range(4):
		var c_id = card_order[i]
		var c_data = CARDS_DATA[c_id]
		
		var c_ctrl = Control.new()
		c_ctrl.name = "Card_" + c_id
		c_ctrl.size = Vector2(card_w, card_h)
		c_ctrl.position = Vector2(60 + i * 220, tray_card_y)
		win_container.add_child(c_ctrl)
		
		var card_panel = PanelContainer.new()
		card_panel.name = "CardPanel"
		card_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		var sb_c = StyleBoxFlat.new()
		sb_c.bg_color = c_data["bg_color"]
		sb_c.border_color = c_data["border_color"]
		sb_c.set_border_width_all(3)
		sb_c.set_corner_radius_all(12)
		sb_c.shadow_color = Color(0, 0, 0, 0.18)
		sb_c.shadow_size = 5
		sb_c.shadow_offset = Vector2(0, 3)
		card_panel.add_theme_stylebox_override("panel", sb_c)
		c_ctrl.add_child(card_panel)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)
		card_panel.add_child(vbox)
		
		var val_lbl = Label.new()
		val_lbl.text = c_data["val"]
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_lbl.add_theme_font_override("font", font_black)
		val_lbl.add_theme_font_size_override("font_size", 14)
		val_lbl.add_theme_color_override("font_color", c_data["text_color"])
		vbox.add_child(val_lbl)
		
		var sub_lbl = Label.new()
		sub_lbl.text = c_data["sub"]
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_lbl.add_theme_font_override("font", font_extrabold)
		sub_lbl.add_theme_font_size_override("font_size", 10)
		sub_lbl.add_theme_color_override("font_color", c_data["tag_color"])
		vbox.add_child(sub_lbl)
		
		# Input handling for Drag & Tap
		var c_btn = Button.new()
		c_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		c_btn.flat = true
		c_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		c_btn.gui_input.connect(func(ev: InputEvent): _on_card_input(c_id, ev))
		c_ctrl.add_child(c_btn)
		
		card_nodes[c_id] = {
			"ctrl": c_ctrl,
			"orig_pos": c_ctrl.position,
			"panel": card_panel,
			"in_slot": ""
		}
		
	# Verify Button at Bottom: "VERIFIKASI & TERAPKAN RUTE"
	verify_button = Button.new()
	verify_button.text = "VERIFIKASI & TERAPKAN RUTE"
	verify_button.size = Vector2(340, 48)
	verify_button.position = Vector2((win_w - 340) / 2.0, 495)
	var sb_v = StyleBoxFlat.new()
	sb_v.bg_color = Color("#059669")
	sb_v.border_color = Color("#064e3b")
	sb_v.set_border_width_all(3)
	sb_v.set_corner_radius_all(14)
	sb_v.shadow_color = Color(0, 0, 0, 0.2)
	sb_v.shadow_size = 6
	sb_v.shadow_offset = Vector2(0, 3)
	verify_button.add_theme_stylebox_override("normal", sb_v)
	
	var sb_vh = sb_v.duplicate() as StyleBoxFlat
	sb_vh.bg_color = Color("#10b981")
	verify_button.add_theme_stylebox_override("hover", sb_vh)
	
	verify_button.add_theme_font_override("font", font_black)
	verify_button.add_theme_font_size_override("font_size", 14)
	verify_button.add_theme_color_override("font_color", Color("#ffffff"))
	verify_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	verify_button.pressed.connect(_on_verify_pressed)
	win_container.add_child(verify_button)

var modal_shifted: bool = false

func _shift_task_modal_content() -> void:
	var win_container = task_modal.get_node("WinContainer") as Control
	for ch in win_container.get_children():
		if ch.position.y < 40.0:
			continue
		ch.position.y += 16.0
	for cid in card_nodes:
		card_nodes[cid]["orig_pos"].y += 16.0

func _open_task_modal() -> void:
	if not modal_shifted:
		modal_shifted = true
		_shift_task_modal_content()
	if is_completed:
		show_toast("✅ Routing Table R-01 sudah sempurna dan rute aktif!")
		return
	is_modal_open = true
	is_game_active = false
	task_modal.visible = true
	task_modal.modulate.a = 0.0
	_play_synth_sequence([523.25, 659.25], 0.08)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(task_modal, "modulate:a", 1.0, 0.2)

func _close_task_modal() -> void:
	if not task_modal or not task_modal.visible:
		return
	_play_synth_sequence([440.0, 392.0], 0.08)
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(task_modal, "modulate:a", 0.0, 0.15)
	tw.finished.connect(func():
		task_modal.visible = false
		is_modal_open = false
		if not is_completed and not is_game_over:
			is_game_active = true
	)

var drag_moved: bool = false
var drag_press_global: Vector2 = Vector2.ZERO
var drag_origin_pos: Vector2 = Vector2.ZERO
var card_tweens: Dictionary = {}

func _card_parent_local(c_node: Control, global_pos: Vector2) -> Vector2:
	var par = c_node.get_parent() as Control
	if par == null:
		return global_pos
	return par.get_global_transform().affine_inverse() * global_pos

func _on_card_input(card_id: String, event: InputEvent) -> void:
	var c_node = card_nodes[card_id]["ctrl"] as Control
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_card_press(card_id, event.global_position)
		else:
			_card_release(card_id)
	elif event is InputEventScreenTouch:
		if event.pressed:
			if drag_touch_id == -1:
				drag_touch_id = event.index
			_card_press(card_id, c_node.get_global_transform() * event.position)
		else:
			if drag_touch_id == event.index:
				drag_touch_id = -1
				_card_release(card_id)
	elif event is InputEventMouseMotion:
		if dragging_card_id == card_id:
			_card_motion(card_id, event.global_position)
	elif event is InputEventScreenDrag:
		if dragging_card_id == card_id and event.index == drag_touch_id:
			_card_motion(card_id, c_node.get_global_transform() * event.position)

func _card_press(card_id: String, global_pos: Vector2) -> void:
	if dragging_card_id != "":
		return
	var c_node = card_nodes[card_id]["ctrl"] as Control
	dragging_card_id = card_id
	drag_moved = false
	drag_press_global = global_pos
	drag_origin_pos = c_node.position
	drag_offset = c_node.position - _card_parent_local(c_node, global_pos)
	c_node.z_index = 50

func _card_motion(card_id: String, global_pos: Vector2) -> void:
	var c_node = card_nodes[card_id]["ctrl"] as Control
	if not drag_moved and global_pos.distance_to(drag_press_global) > 8.0:
		drag_moved = true
		if card_tweens.has(card_id) and card_tweens[card_id] != null and card_tweens[card_id].is_valid():
			card_tweens[card_id].kill()
		# Kartu yang diseret keluar dari slot: kosongkan slotnya (tanpa animasi)
		if card_nodes[card_id]["in_slot"] != "":
			for sk in slot_assignment.keys():
				if slot_assignment[sk] == card_id:
					slot_assignment[sk] = ""
			card_nodes[card_id]["in_slot"] = ""
		_play_synth_sequence([440.0], 0.05)
	if drag_moved:
		c_node.position = _card_parent_local(c_node, global_pos) + drag_offset

func _card_release(card_id: String) -> void:
	if dragging_card_id != card_id:
		return
	dragging_card_id = ""
	var c_node = card_nodes[card_id]["ctrl"] as Control
	c_node.z_index = 0
	if not drag_moved:
		# Ketukan biasa: kartu di slot dikembalikan ke tray, kartu di tray dipilih / batal dipilih
		c_node.position = drag_origin_pos
		if card_nodes[card_id]["in_slot"] != "":
			_remove_card_from_slot(card_id)
		else:
			_select_card(card_id)
		return
	# Geser sungguhan: seleksi ketuk dibersihkan agar tidak "menempel"
	if selected_card_id != "":
		selected_card_id = ""
		_update_card_styles()
	_handle_card_drop(card_id)

func _select_card(card_id: String) -> void:
	if selected_card_id == card_id:
		# Unselect
		selected_card_id = ""
		_update_card_styles()
	else:
		selected_card_id = card_id
		_play_synth_sequence([659.25], 0.06)
		_update_card_styles()

func _update_card_styles() -> void:
	for c_id in card_nodes.keys():
		var c_info = card_nodes[c_id]
		var panel = c_info["panel"] as PanelContainer
		var c_data = CARDS_DATA[c_id]
		var sb = StyleBoxFlat.new()
		sb.bg_color = c_data["bg_color"]
		sb.set_corner_radius_all(12)
		if c_id == selected_card_id:
			sb.border_color = Color("#facc15") # Glowing gold border
			sb.set_border_width_all(5)
			sb.shadow_color = Color(0.98, 0.8, 0.08, 0.45)
			sb.shadow_size = 10
		else:
			sb.border_color = c_data["border_color"]
			sb.set_border_width_all(3)
			sb.shadow_color = Color(0, 0, 0, 0.18)
			sb.shadow_size = 5
		sb.shadow_offset = Vector2(0, 3)
		panel.add_theme_stylebox_override("panel", sb)

func _on_slot_tapped(slot_key: String) -> void:
	if selected_card_id != "":
		_place_card_in_slot(selected_card_id, slot_key)
		selected_card_id = ""
		_update_card_styles()
	elif slot_assignment[slot_key] != "":
		# Remove placed card from slot
		var placed_card_id = slot_assignment[slot_key]
		_remove_card_from_slot(placed_card_id)

func _handle_card_drop(card_id: String) -> void:
	var c_node = card_nodes[card_id]["ctrl"]
	var card_center = c_node.global_position + c_node.size / 2.0
	
	var best_slot = ""
	var best_dist = 110.0
	for s_key in slot_nodes.keys():
		var s_ctrl = slot_nodes[s_key]
		var s_center = s_ctrl.global_position + s_ctrl.size / 2.0
		var dist = card_center.distance_to(s_center)
		if dist < best_dist:
			best_dist = dist
			best_slot = s_key
			
	if best_slot != "":
		_place_card_in_slot(card_id, best_slot)
	else:
		_animate_card_to(card_id, card_nodes[card_id]["orig_pos"])

func _place_card_in_slot(card_id: String, slot_key: String) -> void:
	_play_synth_sequence([587.33, 783.99], 0.08)
	
	# If slot already had a card, return old card to tray
	if slot_assignment[slot_key] != "" and slot_assignment[slot_key] != card_id:
		var old_card = slot_assignment[slot_key]
		card_nodes[old_card]["in_slot"] = ""
		_animate_card_to(old_card, card_nodes[old_card]["orig_pos"])
		
	# If this card was in another slot, clear that slot
	for sk in slot_assignment.keys():
		if slot_assignment[sk] == card_id:
			slot_assignment[sk] = ""
			
	slot_assignment[slot_key] = card_id
	card_nodes[card_id]["in_slot"] = slot_key
	
	var s_ctrl = slot_nodes[slot_key]
	var target_pos = s_ctrl.position + Vector2((s_ctrl.size.x - card_nodes[card_id]["ctrl"].size.x) / 2.0, (s_ctrl.size.y - card_nodes[card_id]["ctrl"].size.y) / 2.0)
	_animate_card_to(card_id, target_pos)

func _remove_card_from_slot(card_id: String) -> void:
	_play_synth_sequence([493.88, 392.0], 0.06)
	for sk in slot_assignment.keys():
		if slot_assignment[sk] == card_id:
			slot_assignment[sk] = ""
	card_nodes[card_id]["in_slot"] = ""
	_animate_card_to(card_id, card_nodes[card_id]["orig_pos"])

func _animate_card_to(card_id: String, target_pos: Vector2) -> void:
	var c_node = card_nodes[card_id]["ctrl"]
	if card_tweens.has(card_id) and card_tweens[card_id] != null and card_tweens[card_id].is_valid():
		card_tweens[card_id].kill()
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c_node, "position", target_pos, 0.22)
	card_tweens[card_id] = tw

func _on_verify_pressed() -> void:
	# Check if all 4 slots are filled
	var unfilled = []
	for sk in ["dest", "mask", "hop", "iface"]:
		if slot_assignment[sk] == "":
			unfilled.append(sk)
			
	if unfilled.size() > 0:
		_play_synth_sequence([240.0, 200.0], 0.1)
		show_toast("⚠️ Harap lengkapi semua 4 parameter routing sebelum verifikasi!")
		_shake_node(verify_button)
		return
		
	# Check correctness
	var is_correct = true
	var error_msg = ""
	
	if slot_assignment["dest"] != "dest":
		is_correct = false
		error_msg = "Destination Network harus alamat subnet tujuan Server (192.168.20.0)!"
	elif slot_assignment["mask"] != "mask":
		is_correct = false
		error_msg = "Subnet Mask harus 255.255.255.0 sesuai prefix /24 Server!"
	elif slot_assignment["hop"] != "hop":
		is_correct = false
		error_msg = "Next-Hop harus mengarah ke IP Router R-02 (10.10.10.2)!"
	elif slot_assignment["iface"] != "iface":
		is_correct = false
		error_msg = "Interface keluar dari R-01 ke R-02 adalah eth1!"
		
	if is_correct:
		_on_routing_success()
	else:
		_on_routing_error(error_msg)

func _on_routing_error(msg: String) -> void:
	error_count += 1
	hearts = max(0, hearts - 1)
	_update_hearts_ui()
	_play_synth_sequence([220.0, 185.0, 150.0], 0.12)
	show_toast("❌ Parameter Belum Sesuai: " + msg)
	_shake_node(task_modal.get_node("WinContainer"))
	
	if hearts <= 0:
		_game_over()

func _update_hearts_ui() -> void:
	HeartsStyle.refresh(hearts_rects, hearts)

func _shake_node(n: Control) -> void:
	var orig_x = n.position.x
	var tw = create_tween()
	tw.tween_property(n, "position:x", orig_x - 10, 0.04)
	tw.chain().tween_property(n, "position:x", orig_x + 10, 0.05)
	tw.chain().tween_property(n, "position:x", orig_x - 6, 0.04)
	tw.chain().tween_property(n, "position:x", orig_x + 6, 0.04)
	tw.chain().tween_property(n, "position:x", orig_x, 0.03)

func _on_routing_success() -> void:
	is_completed = true
	is_game_active = false
	_close_task_modal()
	_apply_room_success_state()
	
	_play_synth_sequence([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.12)
	
	# Save progress and unlock Stage 4!
	var pd = get_node_or_null("/root/PlayerData")
	if pd:
		pd.set_level_stars(3, 4, hearts)
		
	# Show victory dialog after short delay
	await get_tree().create_timer(1.2).timeout
	_show_victory_dialog()

func _apply_room_success_state() -> void:
	is_completed = true
	
	# 1. Update Topology Map overlay
	wall_topo_overlay.queue_redraw()
	if not wall_topo_overlay.draw.is_connected(_draw_topo_success):
		wall_topo_overlay.draw.connect(_draw_topo_success)
	wall_topo_overlay.queue_redraw()
	
	# 2. Update Routing Table Monitor overlay
	if wall_rt_alert_badge:
		wall_rt_alert_badge.visible = false
	wall_rt_row2_overlay.queue_redraw()
	if not wall_rt_row2_overlay.draw.is_connected(_draw_rt_monitor_success):
		wall_rt_row2_overlay.draw.connect(_draw_rt_monitor_success)
	wall_rt_row2_overlay.queue_redraw()
	
	# 3. Router 1 Station turns into ROUTE ACTIVE
	if r1_warning_badge:
		r1_warning_badge.visible = false
	r1_status_label.text = "R-01 : ROUTE ACTIVE"
	r1_status_label.add_theme_color_override("font_color", Color("#15803d"))
	var sb_r1 = r1_status_pill.get_theme_stylebox("panel") as StyleBoxFlat
	if sb_r1:
		sb_r1.border_color = Color("#22c55e")
	r1_circle_outline.queue_redraw()
	if not r1_circle_outline.draw.is_connected(_draw_r1_green_circle):
		r1_circle_outline.draw.connect(_draw_r1_green_circle)
	r1_circle_outline.queue_redraw()
	
	# 4. Server Destination Zone turns ONLINE (UP)
	if server_zone_tex:
		server_zone_tex.texture = tex_server_zone_up
		
	# 5. Cables update to solid green
	cables_container.queue_redraw()
	
	# 6. Bottom System Monitor Message Banner
	_show_bottom_system_banner()

func _draw_topo_success() -> void:
	# Green solid link and ROUTE OK tag between R-01 and R-02 on topology monitor
	var w = wall_topo_map.size.x
	var h = wall_topo_map.size.y
	# Link between R1 and R2 on the monitor
	var p1 = Vector2(w * 0.47, h * 0.58)
	var p2 = Vector2(w * 0.59, h * 0.58)
	wall_topo_overlay.draw_line(p1, p2, Color("#22c55e"), 5.0)
	
	# Green status pill "ROUTE OK"
	var tag_rect = Rect2(Vector2(w * 0.44, h * 0.72), Vector2(65, 18))
	wall_topo_overlay.draw_rect(tag_rect, Color("#15803d"), true)
	wall_topo_overlay.draw_string(font_black, Vector2(w * 0.46, h * 0.83), "ROUTE OK", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color("#ffffff"))

func _draw_rt_monitor_success() -> void:
	var w = wall_rt_monitor.size.x
	var h = wall_rt_monitor.size.y
	# Overwrite Row 2 with valid parameters
	var r2_rect = Rect2(Vector2(w * 0.08, h * 0.48), Vector2(w * 0.84, 26))
	wall_rt_row2_overlay.draw_rect(r2_rect, Color("#f0fdf4"), true)
	wall_rt_row2_overlay.draw_rect(r2_rect, Color("#86efac"), false, 2.0)
	
	# 4 Columns of text
	wall_rt_row2_overlay.draw_string(font_bold, Vector2(w * 0.10, h * 0.58), "192.168.20.0", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#166534"))
	wall_rt_row2_overlay.draw_string(font_bold, Vector2(w * 0.33, h * 0.58), "255.255.255.0", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#166534"))
	wall_rt_row2_overlay.draw_string(font_bold, Vector2(w * 0.58, h * 0.58), "10.10.10.2", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#166534"))
	wall_rt_row2_overlay.draw_string(font_bold, Vector2(w * 0.78, h * 0.58), "eth1", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#166534"))
	
	# Green bottom status banner
	var stat_rect = Rect2(Vector2(w * 0.08, h * 0.76), Vector2(w * 0.84, 22))
	wall_rt_row2_overlay.draw_rect(stat_rect, Color("#15803d"), true)
	wall_rt_row2_overlay.draw_string(font_extrabold, Vector2(w * 0.12, h * 0.87), "STATUS: ALUR PC - SW - R1 - R2 - SERVER TERHUBUNG!", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color("#ffffff"))

func _draw_r1_green_circle() -> void:
	var c = r1_circle_outline.size / 2.0
	r1_circle_outline.draw_arc(c, 52.0, 0, TAU, 32, Color("#22c55e"), 3.0)

func _show_bottom_system_banner() -> void:
	if bottom_system_banner:
		return
	bottom_system_banner = PanelContainer.new()
	bottom_system_banner.size = Vector2(1360, 54)
	bottom_system_banner.position = Vector2((1560 - 1360) / 2.0, 650)
	bottom_system_banner.z_index = 100
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#0f172a") # dark slate
	sb.border_color = Color("#059669") # emerald
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 10
	bottom_system_banner.add_theme_stylebox_override("panel", sb)
	add_child(bottom_system_banner)
	
	var h = HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 10)
	bottom_system_banner.add_child(h)
	
	var icon_lbl = Label.new()
	icon_lbl.text = "🖥️"
	icon_lbl.add_theme_font_size_override("font_size", 18)
	h.add_child(icon_lbl)
	
	var msg_lbl = Label.new()
	msg_lbl.text = "PESAN MONITOR SISTEM (STAGE 3 SELESAI — LANJUT KE STAGE 4): \"Alamat jaringan sudah benar. Periksa struktur dan koneksi perangkat jaringan.\""
	msg_lbl.add_theme_font_override("font", font_extrabold)
	msg_lbl.add_theme_font_size_override("font_size", 12)
	msg_lbl.add_theme_color_override("font_color", Color("#6ee7b7"))
	h.add_child(msg_lbl)
	
	# Entry slide animation
	bottom_system_banner.position.y = 730
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(bottom_system_banner, "position:y", 650, 0.4)

func _setup_game_dialog() -> void:
	if game_dialog and is_instance_valid(game_dialog):
		return
	game_dialog = GameDialogScene.instantiate()
	game_dialog.z_index = 350
	add_child(game_dialog)

func _show_victory_dialog() -> void:
	if is_game_over:
		return
	is_completed = true
	is_game_active = false
	if task_modal and is_instance_valid(task_modal):
		task_modal.visible = false
	is_modal_open = false
	
	var time_str = "Waktu Tersisa: %02d:%02d" % [int(time_remaining) / 60, int(time_remaining) % 60]
	var desc = "Luar biasa! Tabel routing Router R-01 berhasil diperbaiki secara sempurna. Paket data dari PC Klien (192.168.10.0/24) kini berhasil melintasi Router R-02 dan mencapai Server Utama (192.168.20.0/24)!\n\nSeluruh misi Subnetting & Routing telah selesai. Stage 4: Topology & Infrastructure kini TERBUKA!"
	
	if not game_dialog or not is_instance_valid(game_dialog):
		_setup_game_dialog()
	else:
		game_dialog.z_index = 350
		
	game_dialog.show_win(
		"STAGE 3 SELESAI!",
		desc,
		hearts,
		time_str,
		func():
			_play_synth_sequence([523.25, 659.25, 783.99], 0.08)
			get_tree().change_scene_to_file("res://scenes/level_path.tscn"),
		func():
			get_tree().change_scene_to_file("res://scenes/level_path.tscn"),
		"SELESAI"
	)

func _game_over(custom_reason: String = "") -> void:
	if is_game_over:
		return
	is_game_over = true
	is_game_active = false
	if task_modal and is_instance_valid(task_modal):
		task_modal.visible = false
	is_modal_open = false
	
	_play_synth_sequence([220.0, 196.0, 164.81, 130.81], 0.15)
	
	if not game_dialog or not is_instance_valid(game_dialog):
		_setup_game_dialog()
	else:
		game_dialog.z_index = 350
		
	var reason = custom_reason
	if reason == "":
		var cause = "Nyawa teknisi telah habis!" if hearts <= 0 else "Waktu misi telah habis!"
		reason = cause + " Routing Table pada Router R-01 belum dikonfigurasi dengan benar sehingga jaringan Server belum terhubung. Coba lagi!"
		
	game_dialog.show_game_over(
		reason,
		func(): get_tree().reload_current_scene(),
		func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn")
	)

func _on_pause_pressed() -> void:
	_play_synth_sequence([440.0, 392.0], 0.08)
	pause_modal = PauseModalScene.instantiate()
	add_child(pause_modal)
	pause_modal.z_index = 350
	pause_modal.open()

func _process(delta: float) -> void:
	anim_pulse_time += delta
	
	if is_game_over or is_completed:
		return
		
	# Timer countdown
	if is_game_active and not is_modal_open:
		time_remaining -= delta
		if time_remaining <= 0.0:
			time_remaining = 0.0
			_game_over("Waktu misi telah habis! Konfigurasi rute jaringan Server belum terselesaikan tepat waktu.")
			return
		var m = int(time_remaining) / 60
		var s = int(time_remaining) % 60
		timer_label.text = "%02d:%02d" % [m, s]
		if time_remaining < 30.0:
			timer_label.add_theme_color_override("font_color", Color("#ef4444"))
			
	# Alert badge sine bob
	if wall_rt_alert_badge and wall_rt_alert_badge.visible:
		wall_rt_alert_badge.position.y = -18.0 + sin(anim_pulse_time * 5.0) * 4.0
		
	# Red circle pulse on Router 1 when fail
	if not is_completed and r1_circle_outline:
		r1_circle_outline.scale = Vector2.ONE * (1.0 + sin(anim_pulse_time * 4.0) * 0.04)
		
	# Character movement
	if is_game_active and not is_modal_open:
		_process_movement(delta)

func _process_movement(delta: float) -> void:
	var move_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_dir.x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_dir.x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_dir.y += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_dir.y -= 1.0
	if move_dir.length_squared() == 0.0 and input_dir.length_squared() > 0.01:
		move_dir = input_dir

	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()
		char_pos += move_dir * MOVE_SPEED * delta
		if move_dir.x < -0.1:
			char_sprite.flip_h = true
		elif move_dir.x > 0.1:
			char_sprite.flip_h = false
		
		# Clamp to room boundaries
		char_pos.x = clamp(char_pos.x, 70.0, 1430.0)
		char_pos.y = clamp(char_pos.y, 270.0, 640.0)
		character_node.position = char_pos
		
		# Walking animation
		walk_frame_index += delta * 24.0
		if walk_frames.size() > 0:
			var idx = int(walk_frame_index) % walk_frames.size()
			char_sprite.texture = walk_frames[idx]
			
		# Footstep sound
		footstep_timer += delta
		if footstep_timer >= 0.2:
			footstep_timer = 0.0
			_play_footstep()
	else:
		if walk_frames.size() > 0:
			char_sprite.texture = walk_frames[0]
		else:
			char_sprite.texture = tex_char_idle
		char_sprite.scale.y = 1.0 + sin(anim_pulse_time * 3.0) * 0.03

func _build_mobile_controls() -> void:
	var dpad_area = Control.new()
	dpad_area.size = Vector2(160, 160)
	dpad_area.position = Vector2(50, 520)
	mobile_controls_root.add_child(dpad_area)
	
	var dpad_base = TextureRect.new()
	dpad_base.texture = tex_dpad_base
	dpad_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	dpad_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dpad_base.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dpad_base.modulate = Color(1, 1, 1, 0.45)
	dpad_area.add_child(dpad_base)
	
	dpad_knob_sprite = TextureRect.new()
	dpad_knob_sprite.texture = tex_dpad_knob
	dpad_knob_sprite.size = Vector2(60, 60)
	dpad_knob_sprite.position = Vector2(50, 50)
	dpad_knob_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dpad_knob_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dpad_knob_sprite.modulate = Color(1, 1, 1, 0.7)
	dpad_area.add_child(dpad_knob_sprite)
	
	dpad_center = dpad_area.global_position + Vector2(80, 80)
	
	dpad_area_node = dpad_area

var dpad_area_node: Control

func _input(event: InputEvent) -> void:
	if not is_game_active or not dpad_area_node:
		return
	if task_modal and task_modal.visible:
		return
	if event is InputEventScreenTouch:
		var local_p = event.position - dpad_area_node.global_position
		if event.pressed:
			if dpad_touch_id == -1 and Rect2(Vector2(-20, -20), Vector2(200, 200)).has_point(local_p):
				dpad_touch_id = event.index
				_update_dpad(local_p)
		elif event.index == dpad_touch_id:
			dpad_touch_id = -1
			input_dir = Vector2.ZERO
			dpad_knob_sprite.position = Vector2(50, 50)
	elif event is InputEventScreenDrag and event.index == dpad_touch_id:
		_update_dpad(event.position - dpad_area_node.global_position)

func _update_dpad(local_pos: Vector2) -> void:
	var center = Vector2(80, 80)
	var offset = local_pos - center
	var dist = offset.length()
	if dist > dpad_radius:
		offset = offset.normalized() * dpad_radius
	dpad_knob_sprite.position = center + offset - Vector2(30, 30)
	if dist > 10.0:
		input_dir = offset.normalized()
	else:
		input_dir = Vector2.ZERO

func _play_footstep() -> void:
	if not footstep_player:
		return
	var sample_rate = 22050
	var num_samples = int(sample_rate * 0.035)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 90.0)
		var val = sin(t * 540.0 * TAU) * envelope * 0.12
		var int_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
	stream.data = data
	footstep_player.stream = stream
	footstep_player.play()

func _play_synth_sequence(notes: Array, note_dur: float) -> void:
	if not audio_player:
		return
	var sample_rate = 22050
	var total_dur = note_dur * notes.size()
	var num_samples = int(sample_rate * total_dur)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var note_idx = int(float(i) / (sample_rate * note_dur))
		note_idx = clamp(note_idx, 0, notes.size() - 1)
		var freq = float(notes[note_idx])
		var t_in_note = float(i % int(sample_rate * note_dur)) / sample_rate
		var envelope = exp(-t_in_note * 12.0)
		var val = sin(t_in_note * freq * TAU) * envelope * 0.22
		var int_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _check_screenshot_args() -> void:
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-34-intro" in all_args:
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/34_intro_render.png")
		get_tree().quit()
	elif "--screenshot-34-room-gagal" in all_args:
		intro_modal.visible = false
		is_modal_open = false
		is_game_active = true
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/34_room_gagal_render.png")
		get_tree().quit()
	elif "--screenshot-34-popup" in all_args:
		intro_modal.visible = false
		_open_task_modal()
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/34_popup_render.png")
		get_tree().quit()
	elif "--screenshot-34-room-sukses" in all_args:
		intro_modal.visible = false
		is_modal_open = false
		_apply_room_success_state()
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/34_room_sukses_render.png")
		get_tree().quit()


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
		{ "title": "Misi Level 3.4", "text": "Perbaiki tabel routing supaya paket dari PC bisa melewati Switch dan Router sampai ke Server Utama." },
		TutorialOverlay.step_move(self),
		{ "title": "1. Tabel Routing", "text": "Monitor ini menampilkan tabel routing. Baris merah berarti rute hilang atau salah. Klik untuk membuka tugas.", "target": wall_rt_monitor, "pointer": "both" },
		{ "title": "2. Router R1", "text": "Router yang routing-nya bermasalah ditandai merah. Klik router untuk memperbaikinya.", "target": router1_station, "pointer": "both" },
		{ "title": "3. Meja Teknisi Routing", "text": "Klik meja ini atau tombol Perbaiki Routing untuk membuka pop up tugas.", "target": main_technician_desk, "pointer": "hand" },
		{ "title": "4. Server Utama", "text": "Tujuan akhirnya: paket harus sampai ke server ini, jadi semua rute harus tersambung.", "target": server_zone, "pointer": "arrow" },
		TutorialOverlay.step_hearts(self),
		{ "title": "Siap?", "text": "Selesaikan misi sebelum waktu habis. Lupa caranya? Tekan tombol ? (kuning) di dekat pewaktu kapan saja untuk melihat panduan ini lagi." }
	]
