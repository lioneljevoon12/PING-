extends Control

# Level 3.2 - Mencocokkan Subnet Mask dan CIDR (Ruang Kontrol Subnet)
# Sesuai Proposal & Desain Figma 100%:
# - Ruang Kontrol Subnet: Cyan Wall (#84ffff), Gerbang pink, Papan Konfigurasi 3.2, 4 PC Klien di 2 Meja, Meja Teknisi Subnet, Rak Subnet & Switch
# - Alur Misi: Cocokkan Subnet Mask (255.255.255.0 s/d .224) dengan kartu notasi CIDR (/24, /25, /26, /27) yang tepat
#   - PC-01 (255.255.255.0)   -> /24
#   - PC-02 (255.255.255.224) -> /27
#   - PC-03 (255.255.255.192) -> /26
#   - PC-04 (255.255.255.128) -> /25
# - Drag-and-Drop & Tap-to-Place support untuk kenyamanan desktop & mobile
# - Transisi GAGAL -> SUKSES: 4 PC tersenyum hijau ("VALID"), kabel merah berubah menjadi hijau/biru solid aktif, monitor teknisi berubah "ALL 4 SUBNETS VALID"
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
var tex_vector_heart = preload("res://art/assets/PING! Assets/asset-gameplay/generals/vector-hearts.png")
var tex_dpad_base = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_pad_a.png")
var tex_dpad_knob = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_nub_a.png")

# Stage 3 Textures
var tex_pc_hijau = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PC_HIJAU.png")
var tex_pc_merah = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PC_MERAH.png")
var tex_meja_panjang = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.3/meja-panjang.png")
var tex_warning = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/warning.png")
var tex_hint_card = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/TaskHint32_Card.png")
var tex_workstation = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/32_Technician_Workstation.png")
var tex_prompt_btn = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/32_Prompt_Btn.png")
var tex_alert_wb = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/Alert_Badge_WB32.png")
var tex_whiteboard_focus = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/32_Main_Whiteboard_Focus.png")

# Popup Task 32 Textures
var tex_popup_window = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/Puzzle_Window_Base.png")
var tex_popup_banner = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/Puzzle32_Header_Banner.png")
var tex_row_1 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/Row_Match_1.png")
var tex_row_2 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/Row_Match_2.png")
var tex_row_3 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/Row_Match_3.png")
var tex_row_4 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/Row_Match_4.png")
var tex_cards_tray = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/CIDR_Cards_Tray.png")
var tex_card_24 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/Draggable_CIDR_24.png")
var tex_card_25 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/Draggable_CIDR_25.png")
var tex_card_26 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/Draggable_CIDR_26.png")
var tex_card_27 = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/Draggable_CIDR_27.png")
var tex_close_btn = preload("res://art/assets/PING! Assets/asset-gameplay/stage3/Assets Stage 3/PopupTask/32/Close_Button.png")

# Scene References
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer
@onready var background: TextureRect = %Background
@onready var floor_carpet: Panel = %FloorCarpet
@onready var door_arch: TextureRect = %DoorArch
@onready var potted_plant: TextureRect = %PottedPlant
@onready var whiteboard_container: Control = %WhiteboardContainer
@onready var whiteboard_texture: TextureRect = %WhiteboardTexture
@onready var alert_badge_wb: TextureRect = %AlertBadgeWB
@onready var cidr_prompt_btn: TextureButton = %CidrPromptBtn
@onready var cables_container: Control = %CablesContainer
@onready var workstation_node: Control = %WorkstationNode
@onready var desk1_container: Control = %Desk1Container
@onready var desk2_container: Control = %Desk2Container
@onready var rack_node: TextureRect = %RackNode
@onready var character_node: Control = %CharacterNode
@onready var mobile_controls_root: Control = %MobileControlsRoot

# Dynamic Subnodes for Desks & PCs
var pc_monitors: Dictionary = {}
var pc_pills: Dictionary = {}
var desk_alert_badges: Array[TextureRect] = []
var workstation_texture: TextureRect
var workstation_status_label: Label
var wb_placed_tags: Dictionary = {}

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

# Task 3.2 State:
# Slot mapping: Row 1 (PC-01), Row 2 (PC-02), Row 3 (PC-03), Row 4 (PC-04)
# Cards: "24", "25", "26", "27"
# Correct: Row 1 = "24", Row 2 = "27", Row 3 = "26", Row 4 = "25"
var slot_assignment: Dictionary = {
	1: "",
	2: "",
	3: "",
	4: ""
}
var selected_card_id: String = ""
var card_nodes: Dictionary = {}
var row_nodes: Dictionary = {}
var verify_button: Button

# Drag state
var dragging_card_id: String = ""
var drag_touch_id: int = -1
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	_setup_floor_carpet()
	_load_character_frames()
	_setup_character()
	_setup_workstation()
	_setup_pc_desks()
	_setup_whiteboard_overlay()
	_setup_cables()
	_setup_header_ui()
	_setup_mobile_controls()
	_setup_toast_ui()
	_setup_intro_modal()
	_setup_task_modal()
	_setup_pause_and_dialog()
	
	# Open Intro Modal at start
	_open_intro_modal()
	
	# Screenshot helper for visual testing
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
	char_sprite.texture = tex_char_idle
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	char_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_node.add_child(char_sprite)
	
	char_pos = character_node.position

func _setup_workstation() -> void:
	workstation_texture = TextureRect.new()
	workstation_texture.texture = tex_workstation
	workstation_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	workstation_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	workstation_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	workstation_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	workstation_node.add_child(workstation_texture)
	
	# Interactive click button for workstation
	var ws_btn = Button.new()
	ws_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	ws_btn.flat = true
	ws_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ws_btn.pressed.connect(_open_task_modal)
	workstation_node.add_child(ws_btn)
	
	# Monitor status text overlay on workstation screen
	workstation_status_label = Label.new()
	workstation_status_label.text = "4 CIDR MISMATCH!"
	workstation_status_label.position = Vector2(110, 88)
	workstation_status_label.size = Vector2(145, 20)
	workstation_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	workstation_status_label.add_theme_font_override("font", font_extrabold)
	workstation_status_label.add_theme_font_size_override("font_size", 10)
	workstation_status_label.add_theme_color_override("font_color", Color("#f87171"))
	workstation_node.add_child(workstation_status_label)

func _setup_pc_desks() -> void:
	# --- Desk 1: PC-01 & PC-02 ---
	var desk1_bg = TextureRect.new()
	desk1_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desk1_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	desk1_bg.custom_minimum_size = Vector2(580, 160)
	desk1_bg.size = Vector2(580, 160)
	desk1_bg.position = Vector2(0, 10)
	desk1_bg.texture = tex_meja_panjang
	desk1_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desk1_container.add_child(desk1_bg)
	
	# PC-01 (Left)
	_setup_single_pc(1, "PC-01", "255.255.255.0", Vector2(70, -10), desk1_container)
	# PC-02 (Right)
	_setup_single_pc(2, "PC-02", "255.255.255.224", Vector2(330, -10), desk1_container)
	
	# Desk 1 Alert Badge
	var b1 = TextureRect.new()
	b1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	b1.custom_minimum_size = Vector2(38, 38)
	b1.size = Vector2(38, 38)
	b1.position = Vector2(550, 45)
	b1.texture = tex_warning
	desk1_container.add_child(b1)
	desk_alert_badges.append(b1)
	
	# --- Desk 2: PC-03 & PC-04 ---
	var desk2_bg = TextureRect.new()
	desk2_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desk2_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	desk2_bg.custom_minimum_size = Vector2(580, 160)
	desk2_bg.size = Vector2(580, 160)
	desk2_bg.position = Vector2(0, 10)
	desk2_bg.texture = tex_meja_panjang
	desk2_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desk2_container.add_child(desk2_bg)
	
	# PC-03 (Left)
	_setup_single_pc(3, "PC-03", "255.255.255.192", Vector2(70, -10), desk2_container)
	# PC-04 (Right)
	_setup_single_pc(4, "PC-04", "255.255.255.128", Vector2(330, -10), desk2_container)
	
	# Desk 2 Alert Badge
	var b2 = TextureRect.new()
	b2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	b2.custom_minimum_size = Vector2(38, 38)
	b2.size = Vector2(38, 38)
	b2.position = Vector2(550, 45)
	b2.texture = tex_warning
	desk2_container.add_child(b2)
	desk_alert_badges.append(b2)
	
	# Click handler for entire desk rows
	var btn_desk1 = Button.new()
	btn_desk1.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn_desk1.flat = true
	btn_desk1.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_desk1.pressed.connect(_open_task_modal)
	desk1_container.add_child(btn_desk1)
	
	var btn_desk2 = Button.new()
	btn_desk2.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn_desk2.flat = true
	btn_desk2.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_desk2.pressed.connect(_open_task_modal)
	desk2_container.add_child(btn_desk2)

func _setup_single_pc(num: int, tag: String, mask: String, pos: Vector2, parent: Control) -> void:
	var pc_root = Control.new()
	pc_root.size = Vector2(170, 140)
	pc_root.position = pos
	pc_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pc_root)
	
	var mon = TextureRect.new()
	mon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mon.custom_minimum_size = Vector2(110, 100)
	mon.size = Vector2(110, 100)
	mon.position = Vector2(30, 0)
	mon.texture = tex_pc_merah
	mon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc_root.add_child(mon)
	pc_monitors[num] = mon
	
	var pill = _create_pc_pill("%s : %s\nCIDR: Belum Sesuai (!)" % [tag, mask], Color("#7f1d1d"), Color("#fee2e2"), Color("#ef4444"))
	pill.position = Vector2(-15, 105)
	pc_root.add_child(pill)
	pc_pills[num] = {
		"pill": pill,
		"tag": tag,
		"mask": mask
	}

func _create_pc_pill(text: String, text_col: Color, bg_col: Color, border_col: Color) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var lbl = Label.new()
	lbl.name = "Label"
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_bold)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", text_col)
	p.add_child(lbl)
	return p

func _setup_whiteboard_overlay() -> void:
	# Whiteboard click button
	var wb_btn = Button.new()
	wb_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	wb_btn.flat = true
	wb_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	wb_btn.pressed.connect(_open_task_modal)
	whiteboard_container.add_child(wb_btn)
	
	# Prompt Button under Whiteboard ("Cocokkan CIDR")
	cidr_prompt_btn.pressed.connect(_open_task_modal)
	
	# Create 4 tags overlayed on whiteboard showing empty slots [ / ?? ] initially
	var slot_positions = [
		Vector2(185, 38), # PC-01 slot
		Vector2(185, 88), # PC-02 slot
		Vector2(420, 38), # PC-03 slot
		Vector2(420, 88)  # PC-04 slot
	]
	for i in range(4):
		var lbl = Label.new()
		lbl.text = "/ ??"
		lbl.size = Vector2(40, 24)
		lbl.position = slot_positions[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", font_black)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color("#f87171"))
		whiteboard_container.add_child(lbl)
		wb_placed_tags[i + 1] = lbl

func _setup_cables() -> void:
	cables_container.draw.connect(_draw_cables)

func _draw_cables() -> void:
	var blue_c = Color("#38bdf8")
	var green_c = Color("#22c55e")
	var red_c = Color("#ef4444")
	
	# Blue Line from Workstation across to Rack Subnet
	var pts_workstation = PackedVector2Array([
		Vector2(240, 310),
		Vector2(240, 260),
		Vector2(1100, 260),
		Vector2(1100, 390),
		Vector2(1200, 390)
	])
	cables_container.draw_polyline(pts_workstation, Color(0.1, 0.1, 0.1, 0.5), 9.0, true)
	cables_container.draw_polyline(pts_workstation, blue_c, 5.0, true)
	
	# Line from Desk 1 to Rack Subnet
	var pts_d1 = PackedVector2Array([
		Vector2(1080, 420),
		Vector2(1200, 420)
	])
	# Line from Desk 2 to Rack Subnet
	var pts_d2 = PackedVector2Array([
		Vector2(1080, 600),
		Vector2(1200, 600)
	])
	
	if is_completed:
		cables_container.draw_polyline(pts_d1, Color(0.1, 0.1, 0.1, 0.5), 9.0, true)
		cables_container.draw_polyline(pts_d1, green_c, 5.0, true)
		cables_container.draw_polyline(pts_d2, Color(0.1, 0.1, 0.1, 0.5), 9.0, true)
		cables_container.draw_polyline(pts_d2, green_c, 5.0, true)
	else:
		cables_container.draw_polyline(pts_d1, Color(0.2, 0.05, 0.05, 0.5), 9.0, true)
		cables_container.draw_polyline(pts_d1, Color("#fee2e2"), 5.0, true)
		_draw_dashed_line(pts_d1[0], pts_d1[1], red_c, 5.0, 10.0)
		
		cables_container.draw_polyline(pts_d2, Color(0.2, 0.05, 0.05, 0.5), 9.0, true)
		cables_container.draw_polyline(pts_d2, Color("#fee2e2"), 5.0, true)
		_draw_dashed_line(pts_d2[0], pts_d2[1], red_c, 5.0, 10.0)

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
	
	# Left box: Back Button + Hearts + Level Tag
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
	b_num.text = "3.2"
	b_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b_num.add_theme_font_override("font", font_black)
	b_num.add_theme_font_size_override("font_size", 18)
	b_num.add_theme_color_override("font_color", Color("#593e38"))
	badge_vbox.add_child(b_num)
	level_badge.add_child(badge_vbox)
	left_box.add_child(level_badge)
	
	# Right box: Timer + Pause Button
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
	
	# Header instructions banner
	var banner_rect = TextureRect.new()
	banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner_rect.custom_minimum_size = Vector2(880, 62)
	banner_rect.size = Vector2(880, 62)
	banner_rect.position = Vector2(50, 60)
	banner_rect.texture = tex_popup_banner
	banner_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_container.add_child(banner_rect)
	
	# Left Column: 4 Match Rows
	var row_textures = [tex_row_1, tex_row_2, tex_row_3, tex_row_4]
	for i in range(4):
		var row_idx = i + 1
		var row_root = Control.new()
		row_root.name = "Row_%d" % row_idx
		row_root.size = Vector2(590, 76)
		row_root.position = Vector2(50, 132 + i * 82)
		win_container.add_child(row_root)
		
		var row_bg = TextureRect.new()
		row_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		row_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row_bg.custom_minimum_size = Vector2(590, 76)
		row_bg.size = Vector2(590, 76)
		row_bg.texture = row_textures[i]
		row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_root.add_child(row_bg)
		
		# Dropzone / click target for this row (right half)
		var drop_btn = Button.new()
		drop_btn.size = Vector2(210, 58)
		drop_btn.position = Vector2(365, 9)
		drop_btn.flat = true
		drop_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		drop_btn.pressed.connect(func(): _on_row_dropzone_tapped(row_idx))
		row_root.add_child(drop_btn)
		
		row_nodes[row_idx] = {
			"root": row_root,
			"drop_pos": row_root.position + drop_btn.position + Vector2(10, 4),
			"drop_rect": Rect2(row_root.position + drop_btn.position, drop_btn.size)
		}
	
	# Right Column: CIDR Cards Tray
	var tray_rect = TextureRect.new()
	tray_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tray_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tray_rect.custom_minimum_size = Vector2(270, 335)
	tray_rect.size = Vector2(270, 335)
	tray_rect.position = Vector2(660, 132)
	tray_rect.texture = tex_cards_tray
	tray_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_container.add_child(tray_rect)
	
	# 4 Draggable CIDR Cards: /26, /24, /27, /25 (in Figma Tray Order)
	var card_data = [
		{ "id": "26", "tex": tex_card_26, "pos": Vector2(685, 186) },
		{ "id": "24", "tex": tex_card_24, "pos": Vector2(685, 250) },
		{ "id": "27", "tex": tex_card_27, "pos": Vector2(685, 314) },
		{ "id": "25", "tex": tex_card_25, "pos": Vector2(685, 378) }
	]
	for c in card_data:
		_create_draggable_cidr_card(c["id"], c["tex"], c["pos"], win_container)
		
	# Verify Button
	verify_button = Button.new()
	verify_button.text = "VERIFIKASI & AKTIFKAN SUBNET"
	verify_button.size = Vector2(380, 50)
	verify_button.position = Vector2((win_w - 380) / 2.0, 480)
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

func _create_draggable_cidr_card(id: String, tex: Texture2D, initial_pos: Vector2, parent: Control) -> void:
	var card_root = Control.new()
	card_root.name = "CardCIDR_" + id
	card_root.size = Vector2(220, 52)
	card_root.position = initial_pos
	card_root.pivot_offset = Vector2(110, 26)
	parent.add_child(card_root)
	
	var tr = TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(220, 52)
	tr.size = Vector2(220, 52)
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
		"current_row": 0, # 0 = tray, 1..4 = row slots
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
	drag_offset = node.global_position - global_pos
	node.z_index = 50
	node.scale = Vector2(1.06, 1.06)
	_play_synth_sequence([440.0], 0.05)
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
	
	var card_center = node.position + node.size / 2.0
	var placed_in_row = 0
	for r in range(1, 5):
		var rect = row_nodes[r]["drop_rect"] as Rect2
		if rect.has_point(card_center):
			placed_in_row = r
			break
			
	if placed_in_row > 0:
		_place_card_in_row(id, placed_in_row)
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

func _on_row_dropzone_tapped(row_idx: int) -> void:
	if selected_card_id != "":
		_place_card_in_row(selected_card_id, row_idx)
		selected_card_id = ""
	else:
		# If a card is already placed in this row, tapping it returns it to tray
		if slot_assignment[row_idx] != "":
			_return_card_to_tray(slot_assignment[row_idx])

func _place_card_in_row(card_id: String, row_idx: int) -> void:
	# If this card was in another row, clear that row
	for r in range(1, 5):
		if slot_assignment[r] == card_id:
			slot_assignment[r] = ""
			
	# If this row already had a different card, return old card to tray
	if slot_assignment[row_idx] != "" and slot_assignment[row_idx] != card_id:
		_return_card_to_tray(slot_assignment[row_idx])
		
	slot_assignment[row_idx] = card_id
	card_nodes[card_id]["current_row"] = row_idx
	card_nodes[card_id]["highlight"].visible = false
	
	var target_pos = row_nodes[row_idx]["drop_pos"] as Vector2
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_nodes[card_id]["root"], "position", target_pos, 0.2)
	_play_synth_sequence([587.33, 880.0], 0.06)

func _return_card_to_tray(card_id: String) -> void:
	for r in range(1, 5):
		if slot_assignment[r] == card_id:
			slot_assignment[r] = ""
	card_nodes[card_id]["current_row"] = 0
	card_nodes[card_id]["highlight"].visible = false
	
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_nodes[card_id]["root"], "position", card_nodes[card_id]["initial_pos"], 0.22)
	_play_synth_sequence([440.0, 330.0], 0.05)

func _on_verify_pressed() -> void:
	for r in range(1, 5):
		if slot_assignment[r] == "":
			show_toast("Pasang kartu CIDR pada semua 4 komputer!")
			_play_buzz_error()
			return
			
	# Target matches:
	# Row 1 (PC-01 .0)   -> /24
	# Row 2 (PC-02 .224) -> /27
	# Row 3 (PC-03 .192) -> /26
	# Row 4 (PC-04 .128) -> /25
	var is_correct = (slot_assignment[1] == "24" and 
					  slot_assignment[2] == "27" and 
					  slot_assignment[3] == "26" and 
					  slot_assignment[4] == "25")
					
	if is_correct:
		_solve_level_success()
	else:
		_solve_level_failed()

func _solve_level_success() -> void:
	is_completed = true
	is_game_active = false
	_play_win_fanfare()
	show_toast("Konfigurasi Subnet Valid! Semua CIDR Cocok Sempurna!", 3.0)
	
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
	
	show_toast("Kombinasi CIDR belum sesuai! Periksa bit oktet ke-4: .0=/24, .128=/25, .192=/26, .224=/27.", 4.0)
	
	if hearts <= 0:
		_game_over()

func _apply_room_success_state() -> void:
	# Transform room into level 3.2_SUKSES
	# 1. Update Whiteboard tags to show valid CIDRs in green
	var valid_cidrs = { 1: "/24", 2: "/27", 3: "/26", 4: "/25" }
	for i in range(1, 5):
		if i in wb_placed_tags:
			wb_placed_tags[i].text = valid_cidrs[i]
			wb_placed_tags[i].add_theme_color_override("font_color", Color("#22c55e"))
	alert_badge_wb.visible = false
	
	# 2. Update Workstation monitor to "ALL 4 SUBNETS VALID!"
	if workstation_status_label:
		workstation_status_label.text = "ALL 4 SUBNETS VALID!"
		workstation_status_label.add_theme_color_override("font_color", Color("#4ade80"))
		
	# 3. Update all 4 PC monitors to green smiling and update pills
	var pc_valid_tags = {
		1: "PC-01 : 255.255.255.0\nCIDR: /24 (VALID)",
		2: "PC-02 : 255.255.255.224\nCIDR: /27 (VALID)",
		3: "PC-03 : 255.255.255.192\nCIDR: /26 (VALID)",
		4: "PC-04 : 255.255.255.128\nCIDR: /25 (VALID)"
	}
	for i in range(1, 5):
		if i in pc_monitors:
			pc_monitors[i].texture = tex_pc_hijau
		if i in pc_pills:
			var pill = pc_pills[i]["pill"] as PanelContainer
			var lbl = pill.get_node_or_null("Label") as Label
			if lbl:
				lbl.text = pc_valid_tags[i]
				lbl.add_theme_color_override("font_color", Color("#14532d"))
			var sb = pill.get_theme_stylebox("panel") as StyleBoxFlat
			if sb:
				sb.bg_color = Color("#dcfce7")
				sb.border_color = Color("#22c55e")
				
	# 4. Hide alert badges on desks
	for b in desk_alert_badges:
		b.visible = false
		
	# 5. Redraw cables to green
	cables_container.queue_redraw()
	
	# 6. Save progression to PlayerData
	var pd = get_node_or_null("/root/PlayerData")
	if pd:
		pd.set_level_stars(3, 2, hearts)
			
	# 7. Show GameDialog Victory
	await get_tree().create_timer(1.2).timeout
	_show_victory_dialog()

func _show_victory_dialog() -> void:
	if is_game_over:
		return
	is_completed = true
	is_game_active = false
	if task_modal and is_instance_valid(task_modal):
		task_modal.visible = false
	is_modal_open = false
	
	var act_retry = func():
		get_tree().reload_current_scene()
	var act_next = func():
		get_tree().change_scene_to_file("res://scenes/gameplay/level_3_3.tscn")
	var act_map = func():
		get_tree().change_scene_to_file("res://scenes/level_path.tscn")
		
	var time_str = "Skor: %d | Waktu Tersisa: %02d:%02d" % [max(10, 100 - error_count * 15), int(time_remaining) / 60, int(time_remaining) % 60]
	var msg = "Hebat! Semua Subnet Mask komputer klien telah berhasil dicocokkan dengan notasi prefix CIDR yang tepat (/24, /25, /26, /27). Jaringan kini sinkron dan terhubung!"
	
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
		"LANJUT KE 3.3"
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
	
	var reason = custom_reason
	if reason == "":
		var cause = "Nyawa teknisi telah habis!" if hearts <= 0 else "Waktu misi telah habis!"
		reason = cause + " Cermati tabel referensi di Meja Teknisi untuk konversi bit Subnet Mask ke CIDR!"
		
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

func _process(delta: float) -> void:
	anim_pulse_time += delta
	
	# Bobbing alert badges
	if not is_completed:
		if alert_badge_wb:
			alert_badge_wb.position.y = -10.0 + sin(anim_pulse_time * 5.0) * 3.0
		for b in desk_alert_badges:
			b.position.y = 45.0 + sin(anim_pulse_time * 5.0) * 3.0
			
	if not is_game_active or is_game_over or is_completed:
		return
		
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_game_over("Waktu misi telah habis! Waktu analisis Subnet Mask dan CIDR telah berakhir.")
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
			char_sprite.texture = tex_char_idle
		walk_frame_index = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active:
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

func _check_screenshot_args() -> void:
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-32-intro" in all_args:
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/32_intro_render.png")
		get_tree().quit()
	elif "--screenshot-32-room" in all_args:
		intro_modal.visible = false
		is_modal_open = false
		is_game_active = true
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/32_room_render.png")
		get_tree().quit()
	elif "--screenshot-32-popup" in all_args:
		intro_modal.visible = false
		_open_task_modal()
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/32_popup_render.png")
		get_tree().quit()
	elif "--screenshot-32-sukses" in all_args:
		intro_modal.visible = false
		is_modal_open = false
		_apply_room_success_state()
		await get_tree().create_timer(0.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("art/32_sukses_render.png")
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
