extends Control

# Level 3.3 - Menentukan IP Usable (Ruang Kontrol Subnet)
# Sesuai Proposal & Desain Figma 100%:
# - Ruang Kontrol Subnet: Cyan Wall (#84ffff), Gerbang pink, Papan Informasi Jaringan 3.3 (Network .0, Usable .1-.254, Broadcast .255)
# - Rak Jaringan, Panel & Monitor Konfigurasi IP (IPUseableChecker), 3 PC Klien (PC-01 Online, PC-02 Konflik Network .0, PC-03 Konflik Broadcast .255)
# - Alur Misi: Ganti IP PC-02 dan PC-03 dengan alamat dari rentang IP Usable (192.168.10.25 dan 192.168.10.180)
#   Hindari Network Address (.0) dan Broadcast Address (.255)!
# - Drag-and-Drop & Tap-to-Place support untuk mobile & desktop
# - Transisi GAGAL -> SUKSES: PC-02 & PC-03 tersenyum hijau ("VALID"), kabel berubah hijau solid, monitor checker berubah "ALL HOST IPs USABLE"
# - Sistem 3 Bintang terintegrasi dengan PlayerData

const CloseButtonScene = preload("res://scenes/close_button.tscn")
const PauseModalScene = preload("res://scenes/pause_modal.tscn")
const GameDialogScene = preload("res://scenes/game_dialog.tscn")

const MOVE_SPEED = 240.0
const ROOM_DX = 220.0 # geser seluruh ruangan ke tengah layar
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

# Stage 3 Textures
var tex_pc_hijau = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PC_HIJAU.png")
var tex_pc_merah = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PC_MERAH.png")
var tex_meja_pc = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/meja_pc.png")
var tex_warning = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/warning.png")
var tex_hint_card = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/TaskHint33_Card.png")
var tex_checker_gagal = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/IPUseableChecker.png")
var tex_checker_sukses = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/SuksesIPUseableChecker.png")
var tex_wall_info = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/33_Wall_Info_Boards.png")

# Popup Task 33 Textures
var tex_popup_window = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/33/Puzzle_Window_Base.png")
var tex_popup_info_panel = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/33/Puzzle33_Network_Info_Panel.png")
var tex_slot_pc02 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/33/TargetSlot_PC02.png")
var tex_slot_pc03 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/33/TargetSlot_PC03.png")
var tex_tray_33 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/33/IP_Choice_Cards_Tray_33.png")
var tex_card_0 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/33/ChoiceCard33_10_0.png")
var tex_card_25 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/33/ChoiceCard33_10_25.png")
var tex_card_180 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/33/ChoiceCard33_10_180.png")
var tex_card_255 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/33/ChoiceCard33_10_255.png")
var tex_close_btn = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/33/Close_Button.png")

# Scene References
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer
@onready var background: TextureRect = %Background
@onready var floor_carpet: Panel = %FloorCarpet
@onready var door_arch: TextureRect = %DoorArch
@onready var potted_plant: TextureRect = %PottedPlant
@onready var whiteboard_texture: TextureRect = %WhiteboardTexture
@onready var cables_container: Control = %CablesContainer
@onready var rack_node: TextureRect = %RackNode
@onready var checker_station: Control = %CheckerStation
@onready var pc1_desk: Control = %PC1Desk
@onready var pc2_desk: Control = %PC2Desk
@onready var pc3_desk: Control = %PC3Desk
@onready var character_node: Control = %CharacterNode
@onready var mobile_controls_root: Control = %MobileControlsRoot

# Dynamic Subnodes for Desks & PCs
var checker_texture: TextureRect
var pc1_monitor: TextureRect
var pc1_pill: PanelContainer
var pc2_monitor: TextureRect
var pc2_pill: PanelContainer
var pc2_warning_badge: TextureRect
var pc2_alert_circle: Control
var pc3_monitor: TextureRect
var pc3_pill: PanelContainer
var pc3_warning_badge: TextureRect
var pc3_alert_circle: Control
var checker_prompt_pill: PanelContainer

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

# Task 3.3 State:
# Slot mapping: "pc2" and "pc3"
# Available Cards: "0", "25", "180", "255"
# Correct: both slots must be filled by valid usable IPs ("25" and "180") in either order!
var slot_assignment: Dictionary = {
	"pc2": "",
	"pc3": ""
}
var selected_card_id: String = ""
var card_nodes: Dictionary = {}
var slot_pc02_node: Control
var slot_pc03_node: Control
var verify_button: Button

# Drag state
var dragging_card_id: String = ""
var drag_touch_id: int = -1
var drag_offset: Vector2 = Vector2.ZERO
var drag_origin_pos: Vector2 = Vector2.ZERO
var drag_origin_scale: Vector2 = Vector2.ONE
var drag_press_global: Vector2 = Vector2.ZERO
var drag_moved: bool = false

func _ready() -> void:
	call_deferred("_setup_help_button")
	_setup_floor_carpet()
	_load_character_frames()
	_setup_character()
	_setup_checker_station()
	_setup_pc_desks()
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

func _setup_floor_carpet() -> void:
	if floor_carpet:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.83, 0.96, 0.96, 0.75)
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
	char_sprite.texture = (walk_frames[0] if walk_frames.size() > 0 else tex_char_idle)
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.custom_minimum_size = Vector2(300, 165)
	char_sprite.size = Vector2(300, 165)
	char_sprite.position = Vector2(-80, -37)
	char_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_node.add_child(char_sprite)
	var _pd = get_node_or_null("/root/PlayerData")
	if _pd and _pd.has_method("apply_to_character"):
		_pd.apply_to_character(char_sprite)
	
	char_pos = character_node.position

func _setup_checker_station() -> void:
	checker_station.custom_minimum_size = Vector2(390, 230)
	checker_station.size = Vector2(390, 230)
	
	checker_texture = TextureRect.new()
	checker_texture.texture = tex_checker_gagal
	checker_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	checker_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	checker_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	checker_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	checker_station.add_child(checker_texture)
	
	var checker_btn = Button.new()
	checker_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	checker_btn.flat = true
	checker_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	checker_btn.pressed.connect(_open_task_modal)
	checker_station.add_child(checker_btn)
	
	# Prompt pill floating above PC-02
	checker_prompt_pill = _create_pill("! Pilih IP Usable", Color("#ffffff"), Color("#0284c7"), Color("#38bdf8"))
	checker_prompt_pill.position = Vector2(120, -36)
	checker_prompt_pill.visible = true
	checker_station.add_child(checker_prompt_pill)

func _setup_pc_desks() -> void:
	# 1. PC 1 Desk (Station Kiri - Online)
	_setup_desk_base(pc1_desk)
	pc1_monitor = TextureRect.new()
	pc1_monitor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc1_monitor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc1_monitor.custom_minimum_size = Vector2(110, 100)
	pc1_monitor.size = Vector2(110, 100)
	pc1_monitor.position = Vector2(35, 0)
	pc1_monitor.texture = tex_pc_hijau
	pc1_monitor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc1_desk.add_child(pc1_monitor)
	
	pc1_pill = _create_pill("PC-01 : 192.168.10.1\nSTATUS: IP USABLE VALID (ONLINE)", Color("#14532d"), Color("#dcfce7"), Color("#22c55e"))
	pc1_pill.position = Vector2(-25, 110)
	pc1_desk.add_child(pc1_pill)
	
	# 2. PC 2 Desk (Station Tengah - Konflik Network .0)
	_setup_desk_base(pc2_desk)
	pc2_alert_circle = Control.new()
	pc2_alert_circle.size = Vector2(220, 200)
	pc2_alert_circle.position = Vector2(-20, -20)
	pc2_alert_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc2_alert_circle.draw.connect(func(): _draw_alert_circle(pc2_alert_circle))
	pc2_desk.add_child(pc2_alert_circle)
	
	pc2_monitor = TextureRect.new()
	pc2_monitor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc2_monitor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc2_monitor.custom_minimum_size = Vector2(110, 100)
	pc2_monitor.size = Vector2(110, 100)
	pc2_monitor.position = Vector2(35, 0)
	pc2_monitor.texture = tex_pc_merah
	pc2_monitor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc2_desk.add_child(pc2_monitor)
	
	pc2_warning_badge = TextureRect.new()
	pc2_warning_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc2_warning_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc2_warning_badge.custom_minimum_size = Vector2(38, 38)
	pc2_warning_badge.size = Vector2(38, 38)
	pc2_warning_badge.position = Vector2(115, -15)
	pc2_warning_badge.texture = tex_warning
	pc2_desk.add_child(pc2_warning_badge)
	
	pc2_pill = _create_pill("PC-02 : 192.168.10.0 (!)\nERROR: NETWORK ADDRESS!", Color("#7f1d1d"), Color("#fee2e2"), Color("#ef4444"))
	pc2_pill.position = Vector2(-25, 110)
	pc2_desk.add_child(pc2_pill)
	
	var pc2_btn = Button.new()
	pc2_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	pc2_btn.flat = true
	pc2_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pc2_btn.pressed.connect(_open_task_modal)
	pc2_desk.add_child(pc2_btn)
	
	# 3. PC 3 Desk (Station Kanan - Konflik Broadcast .255)
	_setup_desk_base(pc3_desk)
	pc3_alert_circle = Control.new()
	pc3_alert_circle.size = Vector2(220, 200)
	pc3_alert_circle.position = Vector2(-20, -20)
	pc3_alert_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc3_alert_circle.draw.connect(func(): _draw_alert_circle(pc3_alert_circle))
	pc3_desk.add_child(pc3_alert_circle)
	
	pc3_monitor = TextureRect.new()
	pc3_monitor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc3_monitor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc3_monitor.custom_minimum_size = Vector2(110, 100)
	pc3_monitor.size = Vector2(110, 100)
	pc3_monitor.position = Vector2(35, 0)
	pc3_monitor.texture = tex_pc_merah
	pc3_monitor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc3_desk.add_child(pc3_monitor)
	
	pc3_warning_badge = TextureRect.new()
	pc3_warning_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc3_warning_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc3_warning_badge.custom_minimum_size = Vector2(38, 38)
	pc3_warning_badge.size = Vector2(38, 38)
	pc3_warning_badge.position = Vector2(115, -15)
	pc3_warning_badge.texture = tex_warning
	pc3_desk.add_child(pc3_warning_badge)
	
	pc3_pill = _create_pill("PC-03 : 192.168.10.255 (!)\nERROR: BROADCAST ADDRESS!", Color("#7f1d1d"), Color("#fee2e2"), Color("#ef4444"))
	pc3_pill.position = Vector2(-25, 110)
	pc3_desk.add_child(pc3_pill)
	
	var pc3_btn = Button.new()
	pc3_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	pc3_btn.flat = true
	pc3_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pc3_btn.pressed.connect(_open_task_modal)
	pc3_desk.add_child(pc3_btn)

func _setup_desk_base(parent: Control) -> void:
	var table = TextureRect.new()
	table.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	table.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	table.set_anchors_preset(Control.PRESET_FULL_RECT)
	table.texture = tex_meja_pc
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(table)

func _draw_alert_circle(node: Control) -> void:
	if is_completed or not node.visible:
		return
	var center = Vector2(110, 100)
	var radius = 78.0 + sin(anim_pulse_time * 4.0) * 3.0
	var col = Color(0.95, 0.25, 0.25, 0.16 + sin(anim_pulse_time * 4.0) * 0.06)
	node.draw_circle(center, radius, col)
	node.draw_arc(center, radius, 0, TAU, 36, Color(0.9, 0.2, 0.2, 0.8), 2.5, true)

func _setup_whiteboard_interaction() -> void:
	if whiteboard_texture:
		var wb_btn = Button.new()
		wb_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		wb_btn.flat = true
		wb_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		wb_btn.pressed.connect(_open_whiteboard_modal)
		whiteboard_texture.add_child(wb_btn)

func _setup_cables() -> void:
	cables_container.draw.connect(_draw_cables)

func _prect(n: Control) -> Rect2:
	return Rect2(n.position, n.size * n.scale)

func _draw_cables() -> void:
	var green_c = Color("#22c55e")
	var red_c = Color("#ef4444")
	var rk = _prect(rack_node)
	var ck = _prect(checker_station)
	var q1 = _prect(pc1_desk)
	var q2 = _prect(pc2_desk)
	var q3 = _prect(pc3_desk)
	var ck_y = ck.position.y + ck.size.y * 0.62
	
	# Line 1: Rak Jaringan ke Checker Station (Solid Green)
	var pts_rack = PackedVector2Array([Vector2(rk.end.x, ck_y), Vector2(ck.position.x, ck_y)])
	cables_container.draw_polyline(pts_rack, Color(0.1, 0.1, 0.1, 0.5), 9.0, true)
	cables_container.draw_polyline(pts_rack, green_c, 5.0, true)
	
	# Line 2: Switch ke PC-01 (Solid Green)
	var pts_pc1 = PackedVector2Array([Vector2(q1.get_center().x, ck.end.y - 4.0), Vector2(q1.get_center().x, q1.position.y)])
	cables_container.draw_polyline(pts_pc1, Color(0.1, 0.1, 0.1, 0.5), 9.0, true)
	cables_container.draw_polyline(pts_pc1, green_c, 5.0, true)
	
	# Line 3: Switch ke PC-02
	var pts_pc2 = PackedVector2Array([Vector2(q2.get_center().x, ck.end.y - 4.0), Vector2(q2.get_center().x, q2.position.y)])
	if is_completed:
		cables_container.draw_polyline(pts_pc2, Color(0.1, 0.1, 0.1, 0.5), 9.0, true)
		cables_container.draw_polyline(pts_pc2, green_c, 5.0, true)
	else:
		cables_container.draw_polyline(pts_pc2, Color(0.2, 0.05, 0.05, 0.5), 9.0, true)
		cables_container.draw_polyline(pts_pc2, Color("#fee2e2"), 5.0, true)
		_draw_dashed_line(pts_pc2[0], pts_pc2[1], red_c, 5.0, 8.0)
		
	# Line 4: Switch ke PC-03
	var pts_pc3 = PackedVector2Array([Vector2(ck.end.x - 6.0, ck_y), Vector2(q3.get_center().x, ck_y), Vector2(q3.get_center().x, q3.position.y)])
	if is_completed:
		cables_container.draw_polyline(pts_pc3, Color(0.1, 0.1, 0.1, 0.5), 9.0, true)
		cables_container.draw_polyline(pts_pc3, green_c, 5.0, true)
	else:
		cables_container.draw_polyline(pts_pc3, Color(0.2, 0.05, 0.05, 0.5), 9.0, true)
		cables_container.draw_polyline(pts_pc3, Color("#fee2e2"), 5.0, true)
		_draw_dashed_line(pts_pc3[0], pts_pc3[1], red_c, 5.0, 10.0)
		_draw_dashed_line(pts_pc3[1], pts_pc3[2], red_c, 5.0, 10.0)

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

func _setup_header_ui() -> void:
	header_ui = Control.new()
	header_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_ui)
	
	var left_box = HBoxContainer.new()
	left_box.position = Vector2(30, 25)
	left_box.add_theme_constant_override("separation", 14)
	header_ui.add_child(left_box)
	
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
		HeartsStyle.schedule_normalize(hearts_rects)
	hearts_panel.add_child(hearts_container)
	left_box.add_child(hearts_panel)
	
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
	b_num.text = "3.3"
	b_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b_num.add_theme_font_override("font", font_black)
	b_num.add_theme_font_size_override("font_size", 18)
	b_num.add_theme_color_override("font_color", Color("#593e38"))
	badge_vbox.add_child(b_num)
	level_badge.add_child(badge_vbox)
	left_box.add_child(level_badge)
	
	var right_box = HBoxContainer.new()
	right_box.position = Vector2(1330, 25)
	right_box.add_theme_constant_override("separation", 14)
	header_ui.add_child(right_box)
	
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
	
	# Top Network Info Panel
	var info_panel = TextureRect.new()
	info_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	info_panel.custom_minimum_size = Vector2(880, 118)
	info_panel.size = Vector2(880, 118)
	info_panel.position = Vector2(50, 55)
	info_panel.texture = tex_popup_info_panel
	info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_container.add_child(info_panel)
	var info_data = [
		["1. NETWORK ADDRESS", "192.168.10.0", "✕ Bukan untuk host PC", Color("#fee2e2"), Color("#ef4444"), Color("#991b1b")],
		["2. IP USABLE (RENTANG HOST)", "192.168.10.1 – .254", "✓ Valid untuk PC klien", Color("#dcfce7"), Color("#22c55e"), Color("#166534")],
		["3. BROADCAST ADDRESS", "192.168.10.255", "✕ Bukan untuk host PC", Color("#fee2e2"), Color("#ef4444"), Color("#991b1b")],
	]
	for ci in range(3):
		var d = info_data[ci]
		var chip = PanelContainer.new()
		chip.position = Vector2(70 + ci * 280, 88)
		chip.size = Vector2(260, 74)
		var sb_chip = StyleBoxFlat.new()
		sb_chip.bg_color = d[3]
		sb_chip.border_color = d[4]
		sb_chip.set_border_width_all(2)
		sb_chip.set_corner_radius_all(12)
		sb_chip.set_content_margin_all(6)
		chip.add_theme_stylebox_override("panel", sb_chip)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		win_container.add_child(chip)
		var cvb = VBoxContainer.new()
		cvb.alignment = BoxContainer.ALIGNMENT_CENTER
		cvb.add_theme_constant_override("separation", 1)
		cvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(cvb)
		for li in range(3):
			var cl = Label.new()
			cl.text = d[li]
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cl.add_theme_font_override("font", font_black if li == 1 else font_bold)
			cl.add_theme_font_size_override("font_size", 14 if li == 1 else 9)
			cl.add_theme_color_override("font_color", d[5])
			cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cvb.add_child(cl)
	
	# Middle Drop Slots: Slot PC-02 & Slot PC-03
	# Slot PC-02
	slot_pc02_node = Control.new()
	slot_pc02_node.name = "SlotPC02"
	slot_pc02_node.size = Vector2(430, 145)
	slot_pc02_node.position = Vector2(50, 185)
	win_container.add_child(slot_pc02_node)
	
	var slot2_bg = TextureRect.new()
	slot2_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot2_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot2_bg.custom_minimum_size = Vector2(430, 145)
	slot2_bg.size = Vector2(430, 145)
	slot2_bg.texture = tex_slot_pc02
	slot2_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_pc02_node.add_child(slot2_bg)
	slot_cover_pc02 = _make_slot_cover(slot_pc02_node, Rect2(20, 56, 390, 72), Color("#fff5f5"))
	
	var slot2_click = Button.new()
	slot2_click.size = Vector2(410, 85)
	slot2_click.position = Vector2(10, 50)
	slot2_click.flat = true
	slot2_click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot2_click.pressed.connect(func(): _on_slot_tapped("pc2"))
	slot_pc02_node.add_child(slot2_click)
	
	# Slot PC-03
	slot_pc03_node = Control.new()
	slot_pc03_node.name = "SlotPC03"
	slot_pc03_node.size = Vector2(430, 145)
	slot_pc03_node.position = Vector2(500, 185)
	win_container.add_child(slot_pc03_node)
	
	var slot3_bg = TextureRect.new()
	slot3_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot3_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot3_bg.custom_minimum_size = Vector2(430, 145)
	slot3_bg.size = Vector2(430, 145)
	slot3_bg.texture = tex_slot_pc03
	slot3_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_pc03_node.add_child(slot3_bg)
	slot_cover_pc03 = _make_slot_cover(slot_pc03_node, Rect2(20, 56, 390, 72), Color("#fff5f5"))
	
	var slot3_click = Button.new()
	slot3_click.size = Vector2(410, 85)
	slot3_click.position = Vector2(10, 50)
	slot3_click.flat = true
	slot3_click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot3_click.pressed.connect(func(): _on_slot_tapped("pc3"))
	slot_pc03_node.add_child(slot3_click)
	
	# Bottom Section: Card Tray
	var tray_rect = TextureRect.new()
	tray_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tray_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tray_rect.custom_minimum_size = Vector2(880, 120)
	tray_rect.size = Vector2(880, 120)
	tray_rect.position = Vector2(50, 345)
	tray_rect.texture = tex_tray_33
	tray_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_container.add_child(tray_rect)
	
	# 4 Draggable Cards: A (.0), B (.25), C (.180), D (.255)
	var card_data = [
		{ "id": "0", "tex": tex_card_0, "pos": Vector2(70, 385) },
		{ "id": "25", "tex": tex_card_25, "pos": Vector2(285, 385) },
		{ "id": "180", "tex": tex_card_180, "pos": Vector2(500, 385) },
		{ "id": "255", "tex": tex_card_255, "pos": Vector2(715, 385) }
	]
	for c in card_data:
		_create_draggable_ip_card(c["id"], c["tex"], c["pos"], win_container)
		
	# Verify Button
	verify_button = Button.new()
	verify_button.text = "VERIFIKASI & AKTIFKAN PC KLIEN"
	verify_button.size = Vector2(380, 50)
	verify_button.position = Vector2((win_w - 380) / 2.0, 485)
	var sb_v_norm = StyleBoxFlat.new()
	sb_v_norm.bg_color = Color("#86efac")
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

	# Geser konten ke bawah agar tidak menimpa header jendela
	for ch in win_container.get_children():
		if ch == win_bg or ch == close_btn or ch == info_panel:
			continue
		ch.position.y += 16.0
	for cid in card_nodes:
		card_nodes[cid]["initial_pos"].y += 16.0
	info_panel.position.y += 10.0


# Penutup opak di atas teks petunjuk bawaan tekstur dropzone agar tidak tertimpa kartu
func _make_slot_cover(parent: Control, rect: Rect2, col: Color) -> Panel:
	var p = Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(12)
	p.add_theme_stylebox_override("panel", sb)
	p.visible = false
	parent.add_child(p)
	return p

var slot_cover_pc02: Panel
var slot_cover_pc03: Panel

func _refresh_slot_covers() -> void:
	if slot_cover_pc02:
		slot_cover_pc02.visible = (slot_assignment["pc2"] != "")
	if slot_cover_pc03:
		slot_cover_pc03.visible = (slot_assignment["pc3"] != "")

func _create_draggable_ip_card(id: String, tex: Texture2D, initial_pos: Vector2, parent: Control) -> void:
	var card_root = Control.new()
	card_root.name = "CardIP_" + id
	card_root.size = Vector2(200, 70)
	card_root.position = initial_pos
	card_root.pivot_offset = Vector2(100, 35)
	parent.add_child(card_root)
	
	var tr = TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(200, 70)
	tr.size = Vector2(200, 70)
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(tr)
	
	var hl = Panel.new()
	hl.name = "Highlight"
	hl.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb_hl = StyleBoxFlat.new()
	sb_hl.bg_color = Color(0, 0, 0, 0)
	sb_hl.border_color = Color("#38bdf8")
	sb_hl.set_border_width_all(3)
	sb_hl.set_corner_radius_all(12)
	hl.add_theme_stylebox_override("panel", sb_hl)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hl.visible = false
	card_root.add_child(hl)
	
	card_nodes[id] = {
		"root": card_root,
		"initial_pos": initial_pos,
		"current_slot": "", # "", "pc2", "pc3"
		"highlight": hl
	}
	
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
				_start_card_drag(id, _card_event_global(id, st.position))
		else:
			if drag_touch_id == st.index:
				drag_touch_id = -1
				_end_card_drag(id, _card_event_global(id, st.position))
	elif event is InputEventMouseMotion:
		var mm = event as InputEventMouseMotion
		if dragging_card_id == id:
			_update_card_drag(id, mm.global_position)
	elif event is InputEventScreenDrag:
		var sd = event as InputEventScreenDrag
		if dragging_card_id == id and drag_touch_id == sd.index:
			_update_card_drag(id, _card_event_global(id, sd.position))

func _card_to_parent_local(node: Control, global_pos: Vector2) -> Vector2:
	var par = node.get_parent() as Control
	if par == null:
		return global_pos
	return par.get_global_transform().affine_inverse() * global_pos

# Posisi event sentuh pada gui_input bersifat lokal terhadap kartu -> ubah ke koordinat global
func _card_event_global(id: String, local_pos: Vector2) -> Vector2:
	var node = card_nodes[id]["root"] as Control
	return node.get_global_transform() * local_pos

func _start_card_drag(id: String, global_pos: Vector2) -> void:
	if dragging_card_id != "":
		return
	dragging_card_id = id
	var node = card_nodes[id]["root"] as Control
	drag_origin_pos = node.position
	drag_origin_scale = node.scale
	drag_press_global = global_pos
	drag_moved = false
	drag_offset = node.position - _card_to_parent_local(node, global_pos)
	node.z_index = 50
	node.scale = Vector2(1.06, 1.06)
	_play_synth_sequence([440.0], 0.05)

func _update_card_drag(id: String, global_pos: Vector2) -> void:
	if dragging_card_id != id:
		return
	var node = card_nodes[id]["root"] as Control
	if not drag_moved and global_pos.distance_to(drag_press_global) > 8.0:
		drag_moved = true
	if drag_moved:
		node.position = _card_to_parent_local(node, global_pos) + drag_offset

func _end_card_drag(id: String, global_pos: Vector2) -> void:
	if dragging_card_id != id:
		return
	dragging_card_id = ""
	var node = card_nodes[id]["root"] as Control
	node.z_index = 10
	if not drag_moved:
		# Ketukan biasa (tanpa geser): kartu tetap di tempatnya, hanya pilih / batal pilih
		node.position = drag_origin_pos
		node.scale = drag_origin_scale
		_toggle_card_selection(id)
		return
	# Geser sungguhan: seleksi ketuk dibersihkan agar tidak "menempel"
	if selected_card_id != "" and selected_card_id in card_nodes:
		card_nodes[selected_card_id]["highlight"].visible = false
	selected_card_id = ""
	node.scale = Vector2(1.0, 1.0)
	
	var card_center = node.position + node.size / 2.0
	var rect_pc2 = Rect2(slot_pc02_node.position, slot_pc02_node.size)
	var rect_pc3 = Rect2(slot_pc03_node.position, slot_pc03_node.size)
	
	if rect_pc2.has_point(card_center):
		_place_card_in_slot(id, "pc2")
	elif rect_pc3.has_point(card_center):
		_place_card_in_slot(id, "pc3")
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

func _on_slot_tapped(slot_name: String) -> void:
	if selected_card_id != "":
		_place_card_in_slot(selected_card_id, slot_name)
		selected_card_id = ""
	else:
		if slot_assignment[slot_name] != "":
			_return_card_to_tray(slot_assignment[slot_name])

func _place_card_in_slot(card_id: String, slot_name: String) -> void:
	# If this card was in another slot, clear it
	for s in ["pc2", "pc3"]:
		if slot_assignment[s] == card_id:
			slot_assignment[s] = ""
			
	# If this slot already had another card, return old to tray
	if slot_assignment[slot_name] != "" and slot_assignment[slot_name] != card_id:
		_return_card_to_tray(slot_assignment[slot_name])
		
	slot_assignment[slot_name] = card_id
	card_nodes[card_id]["current_slot"] = slot_name
	card_nodes[card_id]["highlight"].visible = false
	
	var target_slot_node = slot_pc02_node if slot_name == "pc2" else slot_pc03_node
	var target_pos = target_slot_node.position + Vector2((target_slot_node.size.x - 200) / 2.0, 56)
	
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_nodes[card_id]["root"], "position", target_pos, 0.2)
	_play_synth_sequence([587.33, 880.0], 0.06)
	_refresh_slot_covers()

func _return_card_to_tray(card_id: String) -> void:
	for s in ["pc2", "pc3"]:
		if slot_assignment[s] == card_id:
			slot_assignment[s] = ""
	card_nodes[card_id]["current_slot"] = ""
	card_nodes[card_id]["highlight"].visible = false
	
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_nodes[card_id]["root"], "position", card_nodes[card_id]["initial_pos"], 0.22)
	_play_synth_sequence([440.0, 330.0], 0.05)
	_refresh_slot_covers()

func _on_verify_pressed() -> void:
	if slot_assignment["pc2"] == "" or slot_assignment["pc3"] == "":
		show_toast("Pasang kartu IP Usable pada PC-02 dan PC-03!")
		_play_buzz_error()
		return
		
	# Check correctness:
	# Both PC-02 and PC-03 must use valid usable host IPs ("25" and "180") in either order!
	# Neither should be "0" (Network Address) or "255" (Broadcast Address)
	var card2 = slot_assignment["pc2"]
	var card3 = slot_assignment["pc3"]
	
	var is_correct = (card2 in ["25", "180"]) and (card3 in ["25", "180"]) and (card2 != card3)
	
	if is_correct:
		_solve_level_success()
	else:
		_solve_level_failed()

func _solve_level_success() -> void:
	is_completed = true
	is_game_active = false
	_play_win_fanfare()
	show_toast("Semua PC Terhubung dengan IP Usable yang Valid!", 3.0)
	
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
	
	var win_container = task_modal.get_node("WinContainer") as Control
	var orig_pos = win_container.position
	var tw = create_tween()
	for i in range(4):
		var offset = Vector2((randf() - 0.5) * 16.0, 0)
		tw.tween_property(win_container, "position", orig_pos + offset, 0.05)
	tw.tween_property(win_container, "position", orig_pos, 0.05)
	
	show_toast("Alamat .0 (Network) dan .255 (Broadcast) tidak boleh dipakai host! Pilih kartu rentang IP Usable (.25 dan .180).", 4.0)
	
	if hearts <= 0:
		_game_over()

func _apply_room_success_state() -> void:
	# Transform room into level 3.3_SUKSES
	# 1. Checker station texture switches to SuksesIPUseableChecker
	checker_texture.texture = tex_checker_sukses
	checker_prompt_pill.visible = false
	
	# 2. PC-02 turns smiling green and online
	pc2_monitor.texture = tex_pc_hijau
	pc2_warning_badge.visible = false
	pc2_alert_circle.visible = false
	var lbl2 = pc2_pill.get_node_or_null("Label") as Label
	if lbl2:
		var ip2 = "192.168.10.25" if slot_assignment["pc2"] == "25" else "192.168.10.180"
		lbl2.text = "PC-02 : %s\nSTATUS: IP USABLE VALID (ONLINE)" % ip2
		lbl2.add_theme_color_override("font_color", Color("#14532d"))
	var sb2 = pc2_pill.get_theme_stylebox("panel") as StyleBoxFlat
	if sb2:
		sb2.bg_color = Color("#dcfce7")
		sb2.border_color = Color("#22c55e")
		
	# 3. PC-03 turns smiling green and online
	pc3_monitor.texture = tex_pc_hijau
	pc3_warning_badge.visible = false
	pc3_alert_circle.visible = false
	var lbl3 = pc3_pill.get_node_or_null("Label") as Label
	if lbl3:
		var ip3 = "192.168.10.180" if slot_assignment["pc3"] == "180" else "192.168.10.25"
		lbl3.text = "PC-03 : %s\nSTATUS: IP USABLE VALID (ONLINE)" % ip3
		lbl3.add_theme_color_override("font_color", Color("#14532d"))
	var sb3 = pc3_pill.get_theme_stylebox("panel") as StyleBoxFlat
	if sb3:
		sb3.bg_color = Color("#dcfce7")
		sb3.border_color = Color("#22c55e")
		
	# 4. Redraw cables to solid green
	cables_container.queue_redraw()
	
	# 5. Save progression to PlayerData
	var pd = get_node_or_null("/root/PlayerData")
	if pd:
		pd.set_level_stars(3, 3, hearts)
			
	# 6. Show GameDialog Victory
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
		get_tree().change_scene_to_file("res://scenes/gameplay/level_3_4.tscn")
	var act_map = func():
		get_tree().change_scene_to_file("res://scenes/level_path.tscn")
		
	var time_str = "Skor: %d | Waktu Tersisa: %02d:%02d" % [max(10, 100 - error_count * 15), int(time_remaining) / 60, int(time_remaining) % 60]
	var msg = "Luar biasa! Kamu berhasil mengonfigurasi IP Usable valid untuk PC-02 dan PC-03 tanpa menyentuh Network Address (.0) maupun Broadcast Address (.255). Semua komputer kini online dan aktif!"
	
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
		"LANJUT KE 3.4"
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
		reason = cause + " Ingat: Alamat pertama (.0) dan alamat terakhir (.255) tidak boleh diberikan kepada PC klien!"
		
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
	HeartsStyle.refresh(hearts_rects, hearts)

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
		wb_rect.custom_minimum_size = Vector2(880, 260)
		wb_rect.size = Vector2(880, 260)
		wb_rect.anchor_left = 0.5
		wb_rect.anchor_top = 0.5
		wb_rect.anchor_right = 0.5
		wb_rect.anchor_bottom = 0.5
		wb_rect.offset_left = -440.0
		wb_rect.offset_top = -150.0
		wb_rect.offset_right = 440.0
		wb_rect.offset_bottom = 110.0
		wb_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
		wb_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
		wb_rect.texture = tex_wall_info
		whiteboard_modal.add_child(wb_rect)
		
		var wb_close_btn = CloseButtonScene.instantiate()
		wb_close_btn.position = Vector2(880 - 52, 14)
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
		close_b.text = "TUTUP INFORMASI JARINGAN"
		close_b.size = Vector2(240, 46)
		close_b.position = Vector2(320, 290)
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
	# Sama seperti level lain: tombol kembali membuka menu "PERMAINAN DIJEDA"
	_on_pause_pressed()

func _process(delta: float) -> void:
	anim_pulse_time += delta
	
	if not is_completed:
		if pc2_alert_circle and pc2_alert_circle.visible:
			pc2_alert_circle.queue_redraw()
		if pc3_alert_circle and pc3_alert_circle.visible:
			pc3_alert_circle.queue_redraw()
		if pc2_warning_badge and pc2_warning_badge.visible:
			pc2_warning_badge.position.y = -15.0 + sin(anim_pulse_time * 5.0) * 3.0
		if pc3_warning_badge and pc3_warning_badge.visible:
			pc3_warning_badge.position.y = -15.0 + sin(anim_pulse_time * 5.0) * 3.0
			
	if not is_game_active or is_game_over or is_completed:
		return
		
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_game_over("Waktu misi telah habis! Waktu penentuan rentang IP Usable telah berakhir.")
		return
	_update_timer_display()
	
	_handle_movement(delta)

func _update_timer_display() -> void:
	var mins = int(time_remaining) / 60
	var secs = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	if time_remaining <= 30.0:
		timer_label.add_theme_color_override("font_color", Color("#dc2626"))
	else:
		timer_label.add_theme_color_override("font_color", Color("#593e38"))

func _handle_movement(delta: float) -> void:
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
		char_pos.x = clamp(char_pos.x, 140.0, 1380.0)
		char_pos.y = clamp(char_pos.y, 240.0, 580.0)
		character_node.position = char_pos
		
		if final_dir.x < -0.1:
			char_sprite.flip_h = true
		elif final_dir.x > 0.1:
			char_sprite.flip_h = false
			
		if walk_frames.size() > 0:
			walk_frame_index += delta * 14.0
			var idx = int(walk_frame_index) % walk_frames.size()
			char_sprite.texture = walk_frames[idx]
			
		footstep_timer += delta
		if footstep_timer >= 0.28:
			footstep_timer = 0.0
			_play_footstep()
	else:
		if char_sprite:
			char_sprite.texture = (walk_frames[0] if walk_frames.size() > 0 else tex_char_idle)
		walk_frame_index = 0.0

func _input(event: InputEvent) -> void:
	if not is_game_active:
		return
	if task_modal and task_modal.visible:
		return
		
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
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var lbl = Label.new()
	lbl.name = "Label"
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_bold)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", text_col)
	p.add_child(lbl)
	return p

func _check_screenshot_args() -> void:
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-33-intro" in all_args:
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/33_intro_render.png")
		get_tree().quit()
	elif "--screenshot-33-room" in all_args:
		intro_modal.visible = false
		is_modal_open = false
		is_game_active = true
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/33_room_render.png")
		get_tree().quit()
	elif "--screenshot-33-popup" in all_args:
		intro_modal.visible = false
		_open_task_modal()
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/33_popup_render.png")
		get_tree().quit()
	elif "--screenshot-33-sukses" in all_args:
		intro_modal.visible = false
		is_modal_open = false
		slot_assignment["pc2"] = "25"
		slot_assignment["pc3"] = "180"
		_apply_room_success_state()
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/33_sukses_render.png")
		get_tree().quit()

# --- SYNTH SOUNDS ---
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
		{ "title": "Misi Level 3.3", "text": "Tentukan IP host yang valid: bukan alamat Network (angka host 0) dan bukan Broadcast (angka host 255)." },
		{ "title": "1. Panel Informasi", "text": "Baca rentang jaringan di papan ini: Network ujungnya .0, host valid .1 sampai .254, Broadcast ujungnya .255.", "target": whiteboard_texture, "pointer": "hand" },
		{ "title": "2. IP Usable Checker", "text": "Klik mesin pemeriksa ini untuk membuka tugas. Di pop up, seret kartu IP ke slot yang tepat.", "target": checker_station, "pointer": "both" },
		{ "title": "3. PC Bermasalah", "text": "PC merah memakai IP yang tidak valid. Klik PC untuk membuka tugas memperbaikinya.", "target": (func(): return TutorialOverlay.union_of([pc2_desk, pc3_desk])), "pointer": "arrow" },
		{ "title": "Siap?", "text": "Selesaikan misi sebelum waktu habis. Lupa caranya? Tekan tombol ? (kuning) di dekat pewaktu kapan saja untuk melihat panduan ini lagi." }
	]
