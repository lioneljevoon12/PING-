extends Control

# --- PRELOAD SCENES & ASSETS ---
const CloseButtonScene = preload("res://scenes/close_button.tscn")
const PauseModalScene = preload("res://scenes/pause_modal.tscn")
const GameDialogScene = preload("res://scenes/game_dialog.tscn")

const MOVE_SPEED = 240.0
const TIME_LIMIT = 165.0 # 02:45

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

# Stage 4 specific textures
var tex_card_pan = preload("res://art/assets/PING! Assets/asset-gameplay/stage4/Card_Situation_PAN.png")
var tex_card_lan = preload("res://art/assets/PING! Assets/asset-gameplay/stage4/Card_Situation_LAN.png")
var tex_card_man = preload("res://art/assets/PING! Assets/asset-gameplay/stage4/Card_Situation_MAN.png")
var tex_card_wan = preload("res://art/assets/PING! Assets/asset-gameplay/stage4/Card_Situation_WAN.png")
var tex_decor_router = preload("res://art/assets/PING! Assets/asset-gameplay/stage4/decor-router.png")

# --- ONREADY NODES ---
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer
@onready var background: TextureRect = %Background
@onready var door_arch: TextureRect = %DoorArch
@onready var potted_plant: TextureRect = %PottedPlant
@onready var rack_container: Control = %RackContainer
@onready var whiteboard_container: Control = %WhiteboardContainer
@onready var tray_container: Control = %TrayContainer
@onready var character_node: Control = %CharacterNode
@onready var mobile_controls_root: Control = %MobileControlsRoot

# --- CHARACTER & MOVEMENT STATE ---
var char_sprite: TextureRect
var walk_frames: Array[Texture2D] = []
var walk_frame_index: int = 0
var walk_anim_timer: float = 0.0
var is_moving: bool = false
var facing_left: bool = false
var footstep_timer: float = 0.0

# Joystick / Mobile controls
var joystick_base: TextureRect
var joystick_knob: TextureRect
var joystick_touch_id: int = -1
var joystick_vector: Vector2 = Vector2.ZERO
var joystick_center: Vector2 = Vector2(160, 560)
var joystick_max_dist: float = 65.0

# --- HEADER UI ---
var header_ui: Control
var timer_label: Label
var hearts_container: HBoxContainer
var hearts_rects: Array[TextureRect] = []
var toast_panel: PanelContainer
var toast_label: Label
var interaction_prompt: PanelContainer

# --- MODALS ---
var intro_modal: Control
var task_modal: Control
var pause_modal: Control
var game_dialog: Control

# --- GAMEPLAY STATE ---
var is_game_active: bool = false
var is_modal_open: bool = false
var is_completed: bool = false
var is_game_over: bool = false
var time_remaining: float = TIME_LIMIT
var hearts: int = 3
var error_count: int = 0
var anim_pulse_time: float = 0.0

# Alert Badges in Room
var wb_alert_badge: PanelContainer
var tray_alert_badge: PanelContainer

# Room Whiteboard Slots & Tray Items
var room_wb_slots: Dictionary = {}
var room_tray_cards: Dictionary = {}

# --- CLASSIFICATION DATA ---
# Target mapping:
# "pan" -> "pan"
# "lan" -> "lan"
# "man" -> "man"
# "wan" -> "wan"
const CATEGORIES: Dictionary = {
	"pan": {
		"id": "pan",
		"name": "PAN (Pribadi)",
		"short": "PAN",
		"sub": "Personal Area",
		"desc": "HP, Laptop & Smartwatch",
		"icon": "📱",
		"color_hdr": Color("#ffe4e6"),
		"color_border": Color("#f43f5e"),
		"color_text": Color("#9f1239"),
		"color_tag": Color("#fb7185")
	},
	"lan": {
		"id": "lan",
		"name": "LAN (Gedung)",
		"short": "LAN",
		"sub": "Local Area",
		"desc": "Satu Rumah / Gedung Kantor",
		"icon": "🏢",
		"color_hdr": Color("#dbeafe"),
		"color_border": Color("#3b82f6"),
		"color_text": Color("#1e40af"),
		"color_tag": Color("#60a5fa")
	},
	"man": {
		"id": "man",
		"name": "MAN (Kota)",
		"short": "MAN",
		"sub": "Metropolitan Area",
		"desc": "Jaringan Satu Kota",
		"icon": "🏙️",
		"color_hdr": Color("#fef9c3"),
		"color_border": Color("#eab308"),
		"color_text": Color("#854d0e"),
		"color_tag": Color("#facc15")
	},
	"wan": {
		"id": "wan",
		"name": "WAN (Dunia)",
		"short": "WAN",
		"sub": "Wide Area",
		"desc": "Antarnegara / Wilayah Luas",
		"icon": "🌍",
		"color_hdr": Color("#dcfce7"),
		"color_border": Color("#22c55e"),
		"color_text": Color("#166534"),
		"color_tag": Color("#4ade80")
	}
}

const CARDS_DATA: Dictionary = {
	"pan": {
		"id": "pan",
		"title": "HP & Smartwatch",
		"subtitle": "(Jarak Pribadi)",
		"modal_text": "HP, Laptop & Smartwatch",
		"icon_emoji": "📱",
		"texture": preload("res://art/assets/PING! Assets/asset-gameplay/stage4/Card_Situation_PAN.png"),
		"correct_slot": "pan"
	},
	"lan": {
		"id": "lan",
		"title": "Gedung Kantor",
		"subtitle": "(1 Ruangan/Gedung)",
		"modal_text": "Satu Rumah / Gedung Kantor",
		"icon_emoji": "🏢",
		"texture": preload("res://art/assets/PING! Assets/asset-gameplay/stage4/Card_Situation_LAN.png"),
		"correct_slot": "lan"
	},
	"man": {
		"id": "man",
		"title": "Jaringan Antar",
		"subtitle": "Cabang Satu Kota",
		"modal_text": "Jaringan Satu Kota",
		"icon_emoji": "🏙️",
		"texture": preload("res://art/assets/PING! Assets/asset-gameplay/stage4/Card_Situation_MAN.png"),
		"correct_slot": "man"
	},
	"wan": {
		"id": "wan",
		"title": "Antarbenua &",
		"subtitle": "Antarnegara",
		"modal_text": "Antarnegara / Wilayah Luas",
		"icon_emoji": "🌍",
		"texture": preload("res://art/assets/PING! Assets/asset-gameplay/stage4/Card_Situation_WAN.png"),
		"correct_slot": "wan"
	}
}

# Current assignment inside Modal: slot_id -> card_id
var modal_assignments: Dictionary = {
	"pan": "",
	"lan": "",
	"man": "",
	"wan": ""
}
var selected_tray_card_id: String = ""
var modal_card_nodes: Dictionary = {}
var modal_slot_nodes: Dictionary = {}
var verify_button: Button

# Drag & drop state in modal
var dragging_card_id: String = ""
var drag_touch_id: int = -1
var drag_offset: Vector2 = Vector2.ZERO

# Rack cable draw canvas
var rack_cables_canvas: Control

# Urutan kartu di tray (diacak) & status interaksi
var tray_order: Array = ["pan", "lan", "man", "wan"]
var locked_slots: Dictionary = {}
var drag_pending_card: String = ""
var drag_press_pos: Vector2 = Vector2.ZERO
var drag_active: bool = false
var drag_ghost: Control = null
var room_validate_btn: Button

func _ready() -> void:
	call_deferred("_setup_help_button")
	tray_order.shuffle()
	if tray_order == ["pan", "lan", "man", "wan"]:
		tray_order = ["man", "pan", "wan", "lan"]
	_load_character_frames()
	_setup_character()
	_setup_door_and_plant()
	_setup_rack_infrastructure()
	_setup_room_whiteboard()
	_setup_room_tray()
	_build_header_ui()
	_build_toast_ui()
	_build_mobile_controls()
	_setup_interaction_prompt()
	_setup_intro_modal()
	_setup_task_modal()
	_setup_game_dialog()
	
	_open_intro_modal()

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
	char_sprite.texture = (walk_frames[0] if walk_frames.size() > 0 else tex_char_idle)
	character_node.add_child(char_sprite)
	var _pd = get_node_or_null("/root/PlayerData")
	if _pd and _pd.has_method("apply_to_character"):
		_pd.apply_to_character(char_sprite)
	character_node.position = Vector2(650, 480)

func _setup_door_and_plant() -> void:
	potted_plant.mouse_filter = Control.MOUSE_FILTER_STOP
	potted_plant.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_play_synth_sequence([523.25, 659.25], 0.08)
			var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tw.tween_property(potted_plant, "scale", Vector2(1.2, 0.85), 0.1)
			tw.chain().tween_property(potted_plant, "scale", Vector2(0.9, 1.15), 0.15)
			tw.chain().tween_property(potted_plant, "scale", Vector2.ONE, 0.1)
			show_toast("🌿 Tanaman ruang server segar dan terawat!")
	)

# ==============================================================================
# STATION 1: RAK INFRASTRUKTUR (KIRI)
# ==============================================================================
func _setup_rack_infrastructure() -> void:
	rack_container.mouse_filter = Control.MOUSE_FILTER_STOP
	rack_container.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_play_synth_sequence([440.0, 554.37], 0.08)
			show_toast("🗄️ Rak Infrastruktur: Router R-01, Switch SW-01, Patch Panel, dan Server aktif.")
	)
	
	# Blue rack body
	var rack_panel = Panel.new()
	rack_panel.position = Vector2.ZERO
	rack_panel.size = Vector2(300, 440)
	var sb_rack = StyleBoxFlat.new()
	sb_rack.bg_color = Color("#8fa9dd")
	sb_rack.border_color = Color("#4a2e2b")
	sb_rack.set_border_width_all(3.5)
	sb_rack.set_corner_radius_all(18)
	sb_rack.shadow_color = Color(0, 0, 0, 0.22)
	sb_rack.shadow_size = 8
	sb_rack.shadow_offset = Vector2(0, 4)
	rack_panel.add_theme_stylebox_override("panel", sb_rack)
	rack_container.add_child(rack_panel)
	
	# Top Header Pill "Rak Infrastruktur"
	var hdr_pill = PanelContainer.new()
	hdr_pill.position = Vector2(60, -18)
	hdr_pill.size = Vector2(180, 36)
	var sb_hp = StyleBoxFlat.new()
	sb_hp.bg_color = Color("#ffffff")
	sb_hp.border_color = Color("#4a2e2b")
	sb_hp.set_border_width_all(2.5)
	sb_hp.set_corner_radius_all(12)
	hdr_pill.add_theme_stylebox_override("panel", sb_hp)
	rack_container.add_child(hdr_pill)
	
	var hdr_lbl = Label.new()
	hdr_lbl.text = "Rak Infrastruktur"
	hdr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hdr_lbl.add_theme_font_override("font", font_black)
	hdr_lbl.add_theme_font_size_override("font_size", 12)
	hdr_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	hdr_pill.add_child(hdr_lbl)
	
	# Canvas for cables inside rack
	rack_cables_canvas = Control.new()
	rack_cables_canvas.position = Vector2.ZERO
	rack_cables_canvas.size = Vector2(300, 440)
	rack_cables_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rack_cables_canvas.draw.connect(_on_rack_cables_draw)
	rack_container.add_child(rack_cables_canvas)
	
	# Shelf 1: Router R-01 (decor router)
	_build_rack_shelf_1(rack_container)
	# Shelf 2: Switch SW-01
	_build_rack_shelf_2(rack_container)
	# Shelf 3: Patch Panel PATCH-01
	_build_rack_shelf_3(rack_container)
	# Shelf 4: Server SERVER-01
	_build_rack_shelf_4(rack_container)

func _build_rack_shelf_1(parent: Control) -> void:
	# Router with antenna
	var r_rect = TextureRect.new()
	r_rect.texture = preload("res://art/assets/PING! Assets/asset-gameplay/stage2/router objects 1.png")
	r_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r_rect.custom_minimum_size = Vector2(90, 60)
	r_rect.size = Vector2(90, 60)
	r_rect.position = Vector2(35, 35)
	parent.add_child(r_rect)
	
	# Badge R-01
	_add_shelf_badge(parent, Vector2(185, 48), "R-01")

func _build_rack_shelf_2(parent: Control) -> void:
	# Switch SW-01
	var sw_rect = TextureRect.new()
	sw_rect.texture = tex_decor_router
	sw_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sw_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sw_rect.custom_minimum_size = Vector2(125, 55)
	sw_rect.size = Vector2(125, 55)
	sw_rect.position = Vector2(25, 125)
	parent.add_child(sw_rect)
	
	# Badge SW-01
	_add_shelf_badge(parent, Vector2(185, 135), "SW-01")

func _build_rack_shelf_3(parent: Control) -> void:
	# Patch Panel PATCH-01
	var patch_box = Panel.new()
	patch_box.position = Vector2(20, 215)
	patch_box.size = Vector2(145, 48)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#1e293b")
	sb.border_color = Color("#0f172a")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(8)
	patch_box.add_theme_stylebox_override("panel", sb)
	parent.add_child(patch_box)
	
	# Ports and indicator dots
	for i in range(8):
		var port = Panel.new()
		port.position = Vector2(10 + i * 15, 18)
		port.size = Vector2(10, 18)
		var sb_p = StyleBoxFlat.new()
		sb_p.bg_color = Color("#0f172a")
		sb_p.border_color = Color("#334155")
		sb_p.set_border_width_all(1)
		sb_p.set_corner_radius_all(2)
		port.add_theme_stylebox_override("panel", sb_p)
		patch_box.add_child(port)
		
		# Amber LED dot above port
		var dot = Panel.new()
		dot.position = Vector2(12 + i * 15, 8)
		dot.size = Vector2(6, 4)
		var sb_d = StyleBoxFlat.new()
		sb_d.bg_color = Color("#fbbf24")
		sb_d.set_corner_radius_all(2)
		dot.add_theme_stylebox_override("panel", sb_d)
		patch_box.add_child(dot)
		
	# Badge PATCH-01
	_add_shelf_badge(parent, Vector2(185, 222), "PATCH-01")

func _build_rack_shelf_4(parent: Control) -> void:
	# Server Unit SERVER-01
	var srv_box = Panel.new()
	srv_box.position = Vector2(20, 305)
	srv_box.size = Vector2(145, 65)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#e2e8f0")
	sb.border_color = Color("#64748b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(8)
	srv_box.add_theme_stylebox_override("panel", sb)
	parent.add_child(srv_box)
	
	# Drive bay slots
	var bay1 = Panel.new()
	bay1.position = Vector2(10, 10)
	bay1.size = Vector2(85, 18)
	var sb_b = StyleBoxFlat.new()
	sb_b.bg_color = Color("#94a3b8")
	sb_b.set_corner_radius_all(4)
	bay1.add_theme_stylebox_override("panel", sb_b)
	srv_box.add_child(bay1)
	
	var bay2 = Panel.new()
	bay2.position = Vector2(10, 34)
	bay2.size = Vector2(85, 18)
	bay2.add_theme_stylebox_override("panel", sb_b)
	srv_box.add_child(bay2)
	
	# Indicator dots (green & yellow)
	var led_g = Panel.new()
	led_g.position = Vector2(110, 16)
	led_g.size = Vector2(10, 10)
	var sb_g = StyleBoxFlat.new()
	sb_g.bg_color = Color("#22c55e")
	sb_g.set_corner_radius_all(5)
	led_g.add_theme_stylebox_override("panel", sb_g)
	srv_box.add_child(led_g)
	
	var led_y = Panel.new()
	led_y.position = Vector2(110, 36)
	led_y.size = Vector2(10, 10)
	var sb_y = StyleBoxFlat.new()
	sb_y.bg_color = Color("#eab308")
	sb_y.set_corner_radius_all(5)
	led_y.add_theme_stylebox_override("panel", sb_y)
	srv_box.add_child(led_y)
	
	# Badge SERVER-01
	_add_shelf_badge(parent, Vector2(185, 318), "SERVER-01")

func _add_shelf_badge(parent: Control, pos: Vector2, text: String) -> void:
	var b_panel = PanelContainer.new()
	b_panel.position = pos
	b_panel.size = Vector2(90, 38)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(10)
	b_panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(b_panel)
	
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	b_panel.add_child(lbl)

func _on_rack_cables_draw() -> void:
	if not rack_cables_canvas:
		return
	# 1. Cyan cable: from SW-01 port 2 to PATCH-01 port 1
	var p_sw1 = Vector2(40, 175)
	var p_patch1 = Vector2(40, 240)
	_draw_curved_cable(rack_cables_canvas, p_sw1, p_patch1, Vector2(-25, 0), Color("#38bdf8"), 3.5)
	
	# 2. Mint cable: from SW-01 port 4 to PATCH-01 port 3
	var p_sw2 = Vector2(65, 175)
	var p_patch2 = Vector2(65, 240)
	_draw_curved_cable(rack_cables_canvas, p_sw2, p_patch2, Vector2(-20, 0), Color("#34d399"), 3.5)
	
	# 3. Orange cable: from PATCH-01 port 6 down into SERVER-01
	var p_patch3 = Vector2(100, 260)
	var p_srv = Vector2(100, 330)
	_draw_curved_cable(rack_cables_canvas, p_patch3, p_srv, Vector2(18, 0), Color("#fb923c"), 3.5)

func _draw_curved_cable(canvas: Control, from: Vector2, to: Vector2, curve_bias: Vector2, col: Color, width: float) -> void:
	var mid = (from + to) / 2.0 + curve_bias
	var points: PackedVector2Array = []
	var steps = 16
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		# Quadratic bezier
		var pt = (1.0 - t) * (1.0 - t) * from + 2.0 * (1.0 - t) * t * mid + t * t * to
		points.append(pt)
	canvas.draw_polyline(points, col, width, true)

# ==============================================================================
# STATION 2: PAPAN KLASIFIKASI WILAYAH (KANAN ATAS)
# ==============================================================================
func _setup_room_whiteboard() -> void:
	whiteboard_container.mouse_filter = Control.MOUSE_FILTER_STOP
	whiteboard_container.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_task_modal()
	)
	
	# Wooden legs underneath
	var leg_left = Panel.new()
	leg_left.position = Vector2(60, 230)
	leg_left.size = Vector2(16, 45)
	var sb_leg = StyleBoxFlat.new()
	sb_leg.bg_color = Color("#7c5843")
	sb_leg.set_corner_radius_all(3)
	leg_left.add_theme_stylebox_override("panel", sb_leg)
	whiteboard_container.add_child(leg_left)
	
	var leg_right = Panel.new()
	leg_right.position = Vector2(534, 230)
	leg_right.size = Vector2(16, 45)
	leg_right.add_theme_stylebox_override("panel", sb_leg)
	whiteboard_container.add_child(leg_right)
	
	# Whiteboard Body Panel
	var wb_panel = PanelContainer.new()
	wb_panel.position = Vector2.ZERO
	wb_panel.size = Vector2(610, 240)
	var sb_wb = StyleBoxFlat.new()
	sb_wb.bg_color = Color("#fefdf9")
	sb_wb.border_color = Color("#7c5843")
	sb_wb.set_border_width_all(3.5)
	sb_wb.set_corner_radius_all(18)
	sb_wb.shadow_color = Color(0, 0, 0, 0.2)
	sb_wb.shadow_size = 8
	sb_wb.shadow_offset = Vector2(0, 4)
	wb_panel.add_theme_stylebox_override("panel", sb_wb)
	whiteboard_container.add_child(wb_panel)
	
	# Top Header Pill "PAPAN KLASIFIKASI WILAYAH"
	var top_pill = PanelContainer.new()
	top_pill.position = Vector2(175, -16)
	top_pill.size = Vector2(260, 34)
	var sb_tp = StyleBoxFlat.new()
	sb_tp.bg_color = Color("#e9d5ff")
	sb_tp.border_color = Color("#4a2e2b")
	sb_tp.set_border_width_all(2.5)
	sb_tp.set_corner_radius_all(12)
	top_pill.add_theme_stylebox_override("panel", sb_tp)
	whiteboard_container.add_child(top_pill)
	
	var top_lbl = Label.new()
	top_lbl.text = "PAPAN KLASIFIKASI WILAYAH"
	top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_lbl.add_theme_font_override("font", font_black)
	top_lbl.add_theme_font_size_override("font_size", 12)
	top_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	top_pill.add_child(top_lbl)
	
	# Red Exclamation Badge (!) on top-right
	wb_alert_badge = _create_alert_badge(whiteboard_container, Vector2(585, -12))
	
	# Columns Container (PAN, LAN, MAN, WAN)
	var hbox = HBoxContainer.new()
	hbox.position = Vector2(18, 30)
	hbox.size = Vector2(574, 195)
	hbox.add_theme_constant_override("separation", 12)
	whiteboard_container.add_child(hbox)
	
	room_wb_slots.clear()
	for cat_id in ["pan", "lan", "man", "wan"]:
		var c_data = CATEGORIES[cat_id]
		var col = _build_room_wb_column(c_data)
		hbox.add_child(col)

func _build_room_wb_column(c_data: Dictionary) -> Control:
	var col = VBoxContainer.new()
	col.custom_minimum_size = Vector2(132, 190)
	col.size = Vector2(132, 190)
	col.add_theme_constant_override("separation", 4)
	
	# Header Pill
	var hdr = PanelContainer.new()
	hdr.custom_minimum_size = Vector2(132, 28)
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = c_data["color_hdr"]
	sb_h.border_color = c_data["color_border"]
	sb_h.set_border_width_all(2)
	sb_h.set_corner_radius_all(10)
	hdr.add_theme_stylebox_override("panel", sb_h)
	col.add_child(hdr)
	
	var lbl_h = Label.new()
	lbl_h.text = c_data["short"]
	lbl_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_h.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_h.add_theme_font_override("font", font_black)
	lbl_h.add_theme_font_size_override("font_size", 12)
	lbl_h.add_theme_color_override("font_color", c_data["color_text"])
	hdr.add_child(lbl_h)
	
	# Subtitle label
	var lbl_sub = Label.new()
	lbl_sub.text = c_data["sub"]
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_override("font", font_bold)
	lbl_sub.add_theme_font_size_override("font_size", 10)
	lbl_sub.add_theme_color_override("font_color", Color("#7c5843"))
	col.add_child(lbl_sub)
	
	# Card Slot Area
	var slot_panel = PanelContainer.new()
	slot_panel.custom_minimum_size = Vector2(132, 140)
	var sb_s = StyleBoxFlat.new()
	sb_s.bg_color = Color(1, 1, 1, 0.6)
	sb_s.border_color = c_data["color_tag"]
	sb_s.set_border_width_all(2)
	sb_s.set_corner_radius_all(10)
	slot_panel.add_theme_stylebox_override("panel", sb_s)
	col.add_child(slot_panel)
	
	var slot_lbl = Label.new()
	slot_lbl.text = "Taruh Kartu"
	slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot_lbl.add_theme_font_override("font", font_semibold)
	slot_lbl.add_theme_font_size_override("font_size", 11)
	slot_lbl.add_theme_color_override("font_color", Color("#94a3b8"))
	slot_panel.add_child(slot_lbl)
	
	# Placed card preview container (hidden until completed)
	var placed_box = VBoxContainer.new()
	placed_box.alignment = BoxContainer.ALIGNMENT_CENTER
	placed_box.visible = false
	slot_panel.add_child(placed_box)
	
	var icon_lbl = Label.new()
	icon_lbl.text = c_data["icon"]
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 26)
	placed_box.add_child(icon_lbl)
	
	var title_lbl = Label.new()
	title_lbl.text = c_data["desc"]
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_font_override("font", font_bold)
	title_lbl.add_theme_font_size_override("font_size", 10)
	title_lbl.add_theme_color_override("font_color", Color("#1e293b"))
	placed_box.add_child(title_lbl)
	
	var chk_lbl = Label.new()
	chk_lbl.text = "✓ Cocok"
	chk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chk_lbl.add_theme_font_override("font", font_black)
	chk_lbl.add_theme_font_size_override("font_size", 11)
	chk_lbl.add_theme_color_override("font_color", Color("#16a34a"))
	placed_box.add_child(chk_lbl)
	
	room_wb_slots[c_data["id"]] = {
		"panel": slot_panel,
		"placeholder": slot_lbl,
		"placed_box": placed_box,
		"icon_lbl": icon_lbl,
		"title_lbl": title_lbl,
		"chk_lbl": chk_lbl
	}
	var rid: String = c_data["id"]
	slot_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot_panel.gui_input.connect(func(ev: InputEvent): _on_slot_gui_input(ev, rid))
	
	return col

# ==============================================================================
# STATION 3: MEJA KARTU SITUASI / TRAY (KANAN BAWAH)
# ==============================================================================
func _setup_room_tray() -> void:
	tray_container.mouse_filter = Control.MOUSE_FILTER_STOP
	tray_container.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_task_modal()
	)
	
	# Tray Body Panel
	var tray_panel = PanelContainer.new()
	tray_panel.position = Vector2.ZERO
	tray_panel.size = Vector2(610, 150)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ebd7c5")
	sb.border_color = Color("#7c5843")
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	tray_panel.add_theme_stylebox_override("panel", sb)
	tray_container.add_child(tray_panel)
	
	# Red Exclamation Badge (!) on top-right
	tray_alert_badge = _create_alert_badge(tray_container, Vector2(585, -10))
	
	# Cards HBox
	var cards_box = HBoxContainer.new()
	cards_box.position = Vector2(16, 15)
	cards_box.size = Vector2(578, 120)
	cards_box.add_theme_constant_override("separation", 12)
	tray_container.add_child(cards_box)
	
	room_tray_cards.clear()
	for c_id in tray_order:
		var c_info = CARDS_DATA[c_id]
		var card_widget = _build_room_tray_card(c_info)
		cards_box.add_child(card_widget)
		room_tray_cards[c_id] = card_widget
		card_widget.gui_input.connect(func(ev: InputEvent): _on_card_gui_input(ev, c_id))

	# Tombol validasi di ruangan (muncul saat keempat kartu sudah terpasang)
	room_validate_btn = Button.new()
	room_validate_btn.text = "✓ VALIDASI JAWABAN"
	room_validate_btn.position = Vector2(180, -18)
	room_validate_btn.size = Vector2(250, 34)
	var sb_rv = StyleBoxFlat.new()
	sb_rv.bg_color = Color("#a7f3d0")
	sb_rv.border_color = Color("#064e3b")
	sb_rv.set_border_width_all(3)
	sb_rv.set_corner_radius_all(14)
	room_validate_btn.add_theme_stylebox_override("normal", sb_rv)
	room_validate_btn.add_theme_stylebox_override("hover", sb_rv)
	room_validate_btn.add_theme_stylebox_override("pressed", sb_rv)
	room_validate_btn.add_theme_font_override("font", font_black)
	room_validate_btn.add_theme_font_size_override("font_size", 13)
	room_validate_btn.add_theme_color_override("font_color", Color("#064e3b"))
	room_validate_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	room_validate_btn.visible = false
	room_validate_btn.z_index = 5
	room_validate_btn.pressed.connect(_on_verify_pressed)
	tray_container.add_child(room_validate_btn)

func _build_room_tray_card(c_info: Dictionary) -> Control:
	var card_btn = PanelContainer.new()
	card_btn.custom_minimum_size = Vector2(134, 118)
	card_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	card_btn.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	card_btn.add_child(vbox)
	
	# Icon texture if available, else emoji
	var icon_rect = TextureRect.new()
	icon_rect.texture = c_info["texture"]
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon_rect)
	
	var title = Label.new()
	title.text = c_info["title"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font_black)
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color("#1e293b"))
	vbox.add_child(title)
	
	var sub = Label.new()
	sub.text = c_info["subtitle"]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", font_bold)
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color("#64748b"))
	vbox.add_child(sub)
	
	return card_btn

func _create_alert_badge(parent: Control, pos: Vector2) -> PanelContainer:
	var badge = PanelContainer.new()
	badge.position = pos
	badge.size = Vector2(28, 28)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ef4444")
	sb.border_color = Color("#ffffff")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	badge.add_theme_stylebox_override("panel", sb)
	parent.add_child(badge)
	
	var lbl = Label.new()
	lbl.text = "!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color("#ffffff"))
	badge.add_child(lbl)
	
	return badge

# ==============================================================================
# HEADER UI: HEARTS, TIMER, PAUSE, BACK
# ==============================================================================
func _build_header_ui() -> void:
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
		
	# Level 4.1 Badge
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
	
	var tag1 = Label.new()
	tag1.text = "Level"
	tag1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag1.add_theme_font_override("font", font_extrabold)
	tag1.add_theme_font_size_override("font_size", 11)
	tag1.add_theme_color_override("font_color", Color("#7c5843"))
	lvl_vbox.add_child(tag1)
	
	var tag2 = Label.new()
	tag2.text = "4.1"
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
	toast_panel.size = Vector2(540, 50)
	toast_panel.position = Vector2((1560 - 540) / 2.0, 640)
	toast_panel.modulate.a = 0.0
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.z_index = 300
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.15, 0.94)
	sb.border_color = Color("#f59e0b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	toast_panel.add_theme_stylebox_override("panel", sb)
	add_child(toast_panel)
	
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_font_override("font", font_bold)
	toast_label.add_theme_font_size_override("font_size", 12)
	toast_label.add_theme_color_override("font_color", Color("#ffffff"))
	toast_panel.add_child(toast_label)

func show_toast(msg: String, duration: float = 2.5) -> void:
	toast_label.text = msg
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(toast_panel, "modulate:a", 1.0, 0.18)
	tw.tween_interval(duration)
	tw.tween_property(toast_panel, "modulate:a", 0.0, 0.25)

func _setup_interaction_prompt() -> void:
	interaction_prompt = PanelContainer.new()
	interaction_prompt.size = Vector2(260, 36)
	interaction_prompt.position = Vector2((1560 - 260) / 2.0, 590)
	interaction_prompt.visible = false
	interaction_prompt.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_size = 4
	interaction_prompt.add_theme_stylebox_override("panel", sb)
	add_child(interaction_prompt)
	
	var lbl = Label.new()
	lbl.text = "🔍 Klik untuk Buka Klasifikasi"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	interaction_prompt.add_child(lbl)
	
	interaction_prompt.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_task_modal()
	)

func _build_mobile_controls() -> void:
	joystick_base = TextureRect.new()
	joystick_base.texture = tex_dpad_base
	joystick_base.custom_minimum_size = Vector2(130, 130)
	joystick_base.size = Vector2(130, 130)
	joystick_base.position = joystick_center - Vector2(65, 65)
	joystick_base.modulate.a = 0.65
	mobile_controls_root.add_child(joystick_base)
	
	joystick_knob = TextureRect.new()
	joystick_knob.texture = tex_dpad_knob
	joystick_knob.custom_minimum_size = Vector2(55, 55)
	joystick_knob.size = Vector2(55, 55)
	joystick_knob.position = joystick_center - Vector2(27.5, 27.5)
	joystick_knob.modulate.a = 0.85
	mobile_controls_root.add_child(joystick_knob)

# ==============================================================================
# INTRO MODAL (POPUP PENJELASAN AWAL LEVEL 4.1)
# ==============================================================================
func _setup_intro_modal() -> void:
	intro_modal = Control.new()
	intro_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_modal.visible = false
	intro_modal.modulate.a = 0.0
	intro_modal.z_index = 200
	add_child(intro_modal)
	
	# Dim backdrop
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.45)
	intro_modal.add_child(dim)
	
	# Modal Box
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(740, 440)
	card.size = Vector2(740, 440)
	card.position = Vector2((1560 - 740) / 2.0, (720 - 440) / 2.0)
	var sb_card = StyleBoxFlat.new()
	sb_card.bg_color = Color("#fef5e7")
	sb_card.border_color = Color("#4a2e2b")
	sb_card.set_border_width_all(3.5)
	sb_card.set_corner_radius_all(24)
	sb_card.shadow_color = Color(0, 0, 0, 0.3)
	sb_card.shadow_size = 14
	sb_card.shadow_offset = Vector2(0, 6)
	sb_card.content_margin_left = 40
	sb_card.content_margin_right = 40
	sb_card.content_margin_top = 35
	sb_card.content_margin_bottom = 35
	card.add_theme_stylebox_override("panel", sb_card)
	intro_modal.add_child(card)
	
	# Hanging Ring Hole at Top
	var ring = Panel.new()
	ring.position = Vector2((740 - 24) / 2.0, 14)
	ring.size = Vector2(24, 24)
	var sb_r = StyleBoxFlat.new()
	sb_r.bg_color = Color("#ffffff")
	sb_r.border_color = Color("#4a2e2b")
	sb_r.set_border_width_all(3)
	sb_r.set_corner_radius_all(12)
	ring.add_theme_stylebox_override("panel", sb_r)
	card.add_child(ring)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	
	# Title
	var title_lbl = Label.new()
	title_lbl.text = "Level 4.1 Jangkauan Wilayah: PAN, LAN, MAN, dan WAN"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", font_black)
	title_lbl.add_theme_font_size_override("font_size", 21)
	title_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	vbox.add_child(title_lbl)
	
	# Thin Divider Line
	var sep = Panel.new()
	sep.custom_minimum_size = Vector2(480, 2)
	sep.size = Vector2(480, 2)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb_sep = StyleBoxFlat.new()
	sb_sep.bg_color = Color("#e2cbb5")
	sep.add_theme_stylebox_override("panel", sb_sep)
	vbox.add_child(sep)
	
	# Description Body Text
	var desc_lbl = Label.new()
	desc_lbl.text = "Supervisor memberikan beberapa kartu situasi jaringan di atas meja kerja!\nPeriksa Papan Informasi di sisi kanan ruangan, lalu cocokkan setiap kartu ilustrasi (HP/Smartwatch, Gedung Kantor, Satu Kota, hingga Antarnegara) ke dalam slot kategori PAN, LAN, MAN, atau WAN yang tepat sebelum waktu habis!"
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_override("font", font_bold)
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	vbox.add_child(desc_lbl)
	
	# Bottom controls container
	var bot_box = Control.new()
	bot_box.custom_minimum_size = Vector2(660, 75)
	vbox.add_child(bot_box)
	
	# Technician Avatar badge (Bottom Left)
	var av_circle = PanelContainer.new()
	av_circle.position = Vector2(20, 5)
	av_circle.size = Vector2(80, 80)
	var sb_av = StyleBoxFlat.new()
	sb_av.bg_color = Color("#ffffff")
	sb_av.border_color = Color("#4a2e2b")
	sb_av.set_border_width_all(3.5)
	sb_av.set_corner_radius_all(40)
	sb_av.shadow_color = Color(0, 0, 0, 0.15)
	sb_av.shadow_size = 4
	av_circle.add_theme_stylebox_override("panel", sb_av)
	bot_box.add_child(av_circle)
	
	if tex_technician_avatar:
		var av_img = TextureRect.new()
		av_img.texture = tex_technician_avatar
		av_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		av_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		av_circle.add_child(av_img)
	else:
		var av_lbl = Label.new()
		av_lbl.text = "👷"
		av_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		av_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		av_lbl.add_theme_font_size_override("font_size", 40)
		av_circle.add_child(av_lbl)
		
	# MULAI Button (Centered Bottom)
	var mulai_btn = Button.new()
	mulai_btn.text = "MULAI"
	mulai_btn.position = Vector2((660 - 200) / 2.0, 16)
	mulai_btn.size = Vector2(200, 48)
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color("#a7f3d0")
	sb_btn.border_color = Color("#1b4332")
	sb_btn.set_border_width_all(3)
	sb_btn.set_corner_radius_all(16)
	mulai_btn.add_theme_stylebox_override("normal", sb_btn)
	mulai_btn.add_theme_font_override("font", font_black)
	mulai_btn.add_theme_font_size_override("font_size", 16)
	mulai_btn.add_theme_color_override("font_color", Color("#1b4332"))
	mulai_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mulai_btn.pressed.connect(_on_mulai_pressed)
	bot_box.add_child(mulai_btn)

func _open_intro_modal() -> void:
	is_modal_open = true
	is_game_active = false
	intro_modal.visible = true
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(intro_modal, "modulate:a", 1.0, 0.25)
	_play_synth_sequence([440.0, 523.25, 659.25], 0.08)

func _on_mulai_pressed() -> void:
	_play_synth_sequence([523.25, 659.25, 783.99], 0.08)
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(intro_modal, "modulate:a", 0.0, 0.2)
	tw.finished.connect(func():
		intro_modal.visible = false
		is_modal_open = false
		if not is_completed and not is_game_over:
			_start_after_tutorial()
	)

# ==============================================================================
# TASK MODAL (POPUP KLASIFIKASI PAN, LAN, MAN & WAN)
# ==============================================================================
func _setup_task_modal() -> void:
	task_modal = Control.new()
	task_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	task_modal.visible = false
	task_modal.modulate.a = 0.0
	task_modal.z_index = 220
	add_child(task_modal)
	
	# Dark backdrop
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	task_modal.add_child(dim)
	
	# Modal Box (1060 x 590) - Using Panel so children keep exact positions
	var win_container = Panel.new()
	win_container.name = "WinContainer"
	win_container.custom_minimum_size = Vector2(1060, 590)
	win_container.size = Vector2(1060, 590)
	win_container.position = Vector2((1560 - 1060) / 2.0, (720 - 590) / 2.0)
	var sb_win = StyleBoxFlat.new()
	sb_win.bg_color = Color("#fdf8f0")
	sb_win.border_color = Color("#4a2e2b")
	sb_win.set_border_width_all(4)
	sb_win.set_corner_radius_all(22)
	sb_win.shadow_color = Color(0, 0, 0, 0.35)
	sb_win.shadow_size = 16
	sb_win.shadow_offset = Vector2(0, 8)
	win_container.add_theme_stylebox_override("panel", sb_win)
	task_modal.add_child(win_container)
	
	# Header Strip (Pastel Purple)
	var header_bar = Panel.new()
	header_bar.position = Vector2(0, 0)
	header_bar.size = Vector2(1060, 60)
	var sb_hdr = StyleBoxFlat.new()
	sb_hdr.bg_color = Color("#ebdfff")
	sb_hdr.border_color = Color("#4a2e2b")
	sb_hdr.set_border_width_all(3.5)
	sb_hdr.corner_radius_top_left = 20
	sb_hdr.corner_radius_top_right = 20
	header_bar.add_theme_stylebox_override("panel", sb_hdr)
	win_container.add_child(header_bar)
	
	var title_lbl = Label.new()
	title_lbl.text = "Level 4.1: Klasifikasi Wilayah PAN, LAN, MAN & WAN"
	title_lbl.position = Vector2(0, 14)
	title_lbl.size = Vector2(1060, 32)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", font_black)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	header_bar.add_child(title_lbl)
	
	# Standardized Universal Close Button (38x38)
	var close_btn = CloseButtonScene.instantiate()
	close_btn.name = "CloseButton"
	close_btn.position = Vector2(1060 - 48, 11)
	close_btn.custom_minimum_size = Vector2(38, 38)
	close_btn.size = Vector2(38, 38)
	if close_btn.has_signal("closed"):
		close_btn.closed.connect(_close_task_modal)
	close_btn.pressed.connect(_close_task_modal)
	win_container.add_child(close_btn)
	
	# Content Box (Dashed outer border)
	var content_panel = Panel.new()
	content_panel.position = Vector2(25, 75)
	content_panel.size = Vector2(1010, 495)
	var sb_cp = StyleBoxFlat.new()
	sb_cp.bg_color = Color("#ffffff")
	sb_cp.border_color = Color("#e5dcd3")
	sb_cp.set_border_width_all(2.5)
	sb_cp.set_corner_radius_all(16)
	content_panel.add_theme_stylebox_override("panel", sb_cp)
	win_container.add_child(content_panel)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.position = Vector2(15, 12)
	content_vbox.size = Vector2(980, 470)
	content_vbox.add_theme_constant_override("separation", 10)
	content_panel.add_child(content_vbox)
	
	# 4 Category Columns HBox
	var slots_hbox = HBoxContainer.new()
	slots_hbox.custom_minimum_size = Vector2(980, 240)
	slots_hbox.add_theme_constant_override("separation", 12)
	content_vbox.add_child(slots_hbox)
	
	modal_slot_nodes.clear()
	for cat_id in ["pan", "lan", "man", "wan"]:
		var slot_ctrl = _build_modal_category_slot(cat_id)
		slots_hbox.add_child(slot_ctrl["root"])
		modal_slot_nodes[cat_id] = slot_ctrl
		
	# Cards Tray (Cards yet to be placed)
	var tray_vbox = VBoxContainer.new()
	tray_vbox.custom_minimum_size = Vector2(980, 140)
	tray_vbox.add_theme_constant_override("separation", 4)
	content_vbox.add_child(tray_vbox)
	
	var tray_lbl = Label.new()
	tray_lbl.text = "KARTU SITUASI JARINGAN (SERET KARTU KE SLOT, ATAU KLIK KARTU LALU KLIK SLOT; KLIK SLOT TERISI UNTUK MENGEMBALIKAN):"
	tray_lbl.add_theme_font_override("font", font_extrabold)
	tray_lbl.add_theme_font_size_override("font_size", 10)
	tray_lbl.add_theme_color_override("font_color", Color("#7c5843"))
	tray_vbox.add_child(tray_lbl)
	
	var cards_hbox = HBoxContainer.new()
	cards_hbox.custom_minimum_size = Vector2(980, 115)
	cards_hbox.add_theme_constant_override("separation", 12)
	tray_vbox.add_child(cards_hbox)
	
	modal_card_nodes.clear()
	for c_id in tray_order:
		var c_widget = _build_modal_tray_card(c_id)
		cards_hbox.add_child(c_widget["root"])
		modal_card_nodes[c_id] = c_widget
		
	# Bottom Validation Button
	verify_button = Button.new()
	verify_button.text = "✓ KLIK UNTUK VALIDASI KLASIFIKASI WILAYAH (PAN, LAN, MAN, WAN)"
	verify_button.custom_minimum_size = Vector2(980, 48)
	verify_button.size = Vector2(980, 48)
	var sb_v = StyleBoxFlat.new()
	sb_v.bg_color = Color("#d1fae5")
	sb_v.border_color = Color("#064e3b")
	sb_v.set_border_width_all(3)
	sb_v.set_corner_radius_all(14)
	verify_button.add_theme_stylebox_override("normal", sb_v)
	
	var sb_vh = sb_v.duplicate() as StyleBoxFlat
	sb_vh.bg_color = Color("#a7f3d0")
	verify_button.add_theme_stylebox_override("hover", sb_vh)
	
	verify_button.add_theme_font_override("font", font_black)
	verify_button.add_theme_font_size_override("font_size", 14)
	verify_button.add_theme_color_override("font_color", Color("#064e3b"))
	verify_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	verify_button.pressed.connect(_on_verify_pressed)
	content_vbox.add_child(verify_button)

func _build_modal_category_slot(cat_id: String) -> Dictionary:
	var c_data = CATEGORIES[cat_id]
	var col = VBoxContainer.new()
	col.custom_minimum_size = Vector2(236, 235)
	col.size = Vector2(236, 235)
	col.add_theme_constant_override("separation", 6)
	
	# Header Pill (e.g. PAN (Pribadi))
	var hdr = PanelContainer.new()
	hdr.custom_minimum_size = Vector2(236, 36)
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = c_data["color_hdr"]
	sb_h.border_color = c_data["color_border"]
	sb_h.set_border_width_all(2.5)
	sb_h.set_corner_radius_all(12)
	hdr.add_theme_stylebox_override("panel", sb_h)
	col.add_child(hdr)
	
	var lbl_h = Label.new()
	lbl_h.text = c_data["name"]
	lbl_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_h.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_h.add_theme_font_override("font", font_black)
	lbl_h.add_theme_font_size_override("font_size", 13)
	lbl_h.add_theme_color_override("font_color", c_data["color_text"])
	hdr.add_child(lbl_h)
	
	# Slot Panel (Dashed box)
	var slot_panel = PanelContainer.new()
	slot_panel.custom_minimum_size = Vector2(236, 185)
	var sb_s = StyleBoxFlat.new()
	sb_s.bg_color = Color("#ffffff")
	sb_s.border_color = c_data["color_border"]
	sb_s.set_border_width_all(2.5)
	sb_s.set_corner_radius_all(14)
	slot_panel.add_theme_stylebox_override("panel", sb_s)
	col.add_child(slot_panel)
	
	slot_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	slot_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_on_slot_clicked(cat_id)
	)
	
	var slot_vbox = VBoxContainer.new()
	slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_vbox.add_theme_constant_override("separation", 4)
	slot_panel.add_child(slot_vbox)
	
	# Placeholder text
	var ph_lbl = Label.new()
	ph_lbl.text = "[ Taruh Kartu di Sini ]"
	ph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ph_lbl.add_theme_font_override("font", font_semibold)
	ph_lbl.add_theme_font_size_override("font_size", 12)
	ph_lbl.add_theme_color_override("font_color", Color("#94a3b8"))
	slot_vbox.add_child(ph_lbl)
	
	# Card Content Box (Visible when a card is placed)
	var card_placed_box = VBoxContainer.new()
	card_placed_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card_placed_box.visible = false
	slot_vbox.add_child(card_placed_box)
	
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(60, 60)
	icon_rect.size = Vector2(60, 60)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_placed_box.add_child(icon_rect)
	
	var desc_lbl = Label.new()
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_override("font", font_black)
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color("#1e293b"))
	card_placed_box.add_child(desc_lbl)
	
	var chk_lbl = Label.new()
	chk_lbl.text = "✓ Terpasang"
	chk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chk_lbl.add_theme_font_override("font", font_extrabold)
	chk_lbl.add_theme_font_size_override("font_size", 11)
	chk_lbl.add_theme_color_override("font_color", Color("#16a34a"))
	card_placed_box.add_child(chk_lbl)
	
	return {
		"root": col,
		"panel": slot_panel,
		"placeholder": ph_lbl,
		"card_placed_box": card_placed_box,
		"icon_rect": icon_rect,
		"desc_lbl": desc_lbl,
		"chk_lbl": chk_lbl
	}

func _build_modal_tray_card(c_id: String) -> Dictionary:
	var c_info = CARDS_DATA[c_id]
	var card_btn = PanelContainer.new()
	card_btn.custom_minimum_size = Vector2(236, 110)
	card_btn.size = Vector2(236, 110)
	card_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#f8fafc")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	card_btn.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	card_btn.add_child(vbox)
	
	var icon_rect = TextureRect.new()
	icon_rect.texture = c_info["texture"]
	icon_rect.custom_minimum_size = Vector2(46, 46)
	icon_rect.size = Vector2(46, 46)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon_rect)
	
	var title = Label.new()
	title.text = c_info["modal_text"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", font_black)
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("#1e293b"))
	vbox.add_child(title)
	
	card_btn.gui_input.connect(func(ev: InputEvent): _on_card_gui_input(ev, c_id))
	
	return {
		"root": card_btn,
		"stylebox": sb,
		"icon_rect": icon_rect,
		"title_lbl": title
	}

# ==============================================================================
# CARD PLACEMENT LOGIC & VALIDATION
# ==============================================================================
func _all_assigned() -> bool:
	for s_id in ["pan", "lan", "man", "wan"]:
		if modal_assignments[s_id] == "":
			return false
	return true

func _on_card_gui_input(ev: InputEvent, card_id: String) -> void:
	if is_completed or is_game_over:
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		_play_synth_sequence([440.0], 0.05)
		if selected_tray_card_id == card_id:
			selected_tray_card_id = ""
		else:
			selected_tray_card_id = card_id
		drag_pending_card = card_id
		drag_press_pos = get_global_mouse_position()
		_refresh_all()

var drag_from_slot: String = ""

func _on_slot_gui_input(ev: InputEvent, slot_id: String) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		# Slot terisi + tidak ada kartu terpilih: tekan = bersiap menyeret kartunya keluar,
		# ketukan biasa (tanpa geser) tetap mengembalikan kartu ke tray saat dilepas.
		if not is_completed and not is_game_over and not locked_slots.get(slot_id, false) 				and selected_tray_card_id == "" and modal_assignments[slot_id] != "":
			drag_pending_card = modal_assignments[slot_id]
			drag_from_slot = slot_id
			drag_press_pos = get_global_mouse_position()
			return
		_on_slot_clicked(slot_id)

func _on_slot_clicked(slot_id: String) -> void:
	if is_completed or is_game_over:
		return
	if locked_slots.get(slot_id, false):
		show_toast("✓ Slot ini sudah benar dan terkunci.")
		return
	if selected_tray_card_id != "":
		_assign_card(selected_tray_card_id, slot_id)
		return
	# Klik slot terisi -> kembalikan kartu ke tray
	if modal_assignments[slot_id] != "":
		modal_assignments[slot_id] = ""
		_play_synth_sequence([392.0, 330.0], 0.06)
		_refresh_all()

func _assign_card(card_id: String, slot_id: String) -> void:
	if locked_slots.get(slot_id, false):
		return
	for s_id in modal_assignments.keys():
		if modal_assignments[s_id] == card_id and not locked_slots.get(s_id, false):
			modal_assignments[s_id] = ""
	modal_assignments[slot_id] = card_id
	selected_tray_card_id = ""
	_play_synth_sequence([523.25, 659.25], 0.06)
	_refresh_all()

func _slot_at(pos: Vector2) -> String:
	for s_id in ["pan", "lan", "man", "wan"]:
		var panel: Control = null
		if is_modal_open and modal_slot_nodes.has(s_id):
			panel = modal_slot_nodes[s_id]["panel"]
		elif not is_modal_open and room_wb_slots.has(s_id):
			panel = room_wb_slots[s_id]["panel"]
		if panel and panel.is_visible_in_tree() and panel.get_global_rect().has_point(pos):
			return s_id
	return ""

func _begin_drag(card_id: String) -> void:
	drag_active = true
	var c_info = CARDS_DATA[card_id]
	drag_ghost = Panel.new()
	drag_ghost.size = Vector2(170, 64)
	drag_ghost.z_index = 400
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_g = StyleBoxFlat.new()
	sb_g.bg_color = Color("#ffffff")
	sb_g.border_color = Color("#2563eb")
	sb_g.set_border_width_all(3)
	sb_g.set_corner_radius_all(12)
	sb_g.shadow_color = Color(0, 0, 0, 0.25)
	sb_g.shadow_size = 6
	drag_ghost.add_theme_stylebox_override("panel", sb_g)
	var gl = Label.new()
	gl.text = c_info["icon_emoji"] + " " + c_info["title"]
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gl.set_anchors_preset(Control.PRESET_FULL_RECT)
	gl.add_theme_font_override("font", font_black)
	gl.add_theme_font_size_override("font_size", 12)
	gl.add_theme_color_override("font_color", Color("#1e293b"))
	gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_ghost.add_child(gl)
	add_child(drag_ghost)
	drag_ghost.position = get_global_mouse_position() - drag_ghost.size * 0.5

func _end_drag_cleanup() -> void:
	drag_pending_card = ""
	drag_from_slot = ""
	drag_active = false
	if drag_ghost:
		drag_ghost.queue_free()
		drag_ghost = null

func _refresh_all() -> void:
	_update_modal_ui()
	_update_room_ui()

func _update_room_ui() -> void:
	for c_id in tray_order:
		if not room_tray_cards.has(c_id):
			continue
		var w: Control = room_tray_cards[c_id]
		var is_placed = false
		for s_id in modal_assignments.keys():
			if modal_assignments[s_id] == c_id:
				is_placed = true
		w.modulate.a = 0.0 if is_placed else 1.0
		w.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_placed else Control.MOUSE_FILTER_STOP
		var sb = w.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			if c_id == selected_tray_card_id:
				sb.border_color = Color("#2563eb")
				sb.bg_color = Color("#eff6ff")
			else:
				sb.border_color = Color("#4a2e2b")
				sb.bg_color = Color("#ffffff")
	for s_id in room_wb_slots.keys():
		var sd = room_wb_slots[s_id]
		var cid = modal_assignments[s_id]
		var panel_sb = (sd["panel"] as Control).get_theme_stylebox("panel") as StyleBoxFlat
		if cid != "":
			sd["placeholder"].visible = false
			sd["placed_box"].visible = true
			sd["icon_lbl"].text = CARDS_DATA[cid]["icon_emoji"]
			sd["title_lbl"].text = CARDS_DATA[cid]["modal_text"]
			var ok = locked_slots.get(s_id, false)
			sd["chk_lbl"].text = "✓ Cocok" if ok else "Terpasang"
			sd["chk_lbl"].add_theme_color_override("font_color", Color("#16a34a") if ok else Color("#2563eb"))
			if panel_sb:
				panel_sb.bg_color = Color("#dcfce7") if ok else Color(1, 1, 1, 0.9)
		else:
			sd["placeholder"].visible = true
			sd["placed_box"].visible = false
			if panel_sb:
				panel_sb.bg_color = Color(1, 1, 1, 0.6)
	if room_validate_btn:
		room_validate_btn.visible = _all_assigned() and not is_completed and not is_game_over

func _update_modal_ui() -> void:
	# 1. Tray: sembunyikan kartu yang sudah terpasang + sorot kartu terpilih
	for c_id in CARDS_DATA.keys():
		var node_data = modal_card_nodes[c_id]
		var is_placed = false
		for s in modal_assignments.keys():
			if modal_assignments[s] == c_id:
				is_placed = true
				break
		node_data["root"].visible = not is_placed
		var sb: StyleBoxFlat = node_data["stylebox"]
		if c_id == selected_tray_card_id:
			sb.border_color = Color("#2563eb")
			sb.bg_color = Color("#eff6ff")
			sb.set_border_width_all(4)
		else:
			sb.border_color = Color("#4a2e2b")
			sb.bg_color = Color("#f8fafc")
			sb.set_border_width_all(3)

	# 2. Slot kategori
	for s_id in modal_slot_nodes.keys():
		var slot_data = modal_slot_nodes[s_id]
		var placed_card_id = modal_assignments[s_id]
		var slot_sb = (slot_data["panel"] as Control).get_theme_stylebox("panel") as StyleBoxFlat
		if placed_card_id != "":
			slot_data["placeholder"].visible = false
			slot_data["card_placed_box"].visible = true
			var c_info = CARDS_DATA[placed_card_id]
			slot_data["icon_rect"].texture = c_info["texture"]
			slot_data["desc_lbl"].text = c_info["modal_text"]
			var ok = locked_slots.get(s_id, false)
			slot_data["chk_lbl"].text = "✓ Benar" if ok else "Terpasang"
			slot_data["chk_lbl"].add_theme_color_override("font_color", Color("#16a34a") if ok else Color("#2563eb"))
			if slot_sb:
				slot_sb.bg_color = Color("#dcfce7") if ok else Color("#ffffff")
		else:
			slot_data["placeholder"].visible = true
			slot_data["card_placed_box"].visible = false
			if slot_sb:
				slot_sb.bg_color = Color("#ffffff")

func _on_verify_pressed() -> void:
	# Check if all 4 slots are filled
	for s_id in ["pan", "lan", "man", "wan"]:
		if modal_assignments[s_id] == "":
			_play_buzz_error()
			show_toast("⚠️ Tempatkan semua 4 kartu ke dalam kategori wilayah terlebih dahulu!")
			return
			
	# Check correctness
	var is_all_correct = true
	var wrong_count = 0
	for s_id in ["pan", "lan", "man", "wan"]:
		if modal_assignments[s_id] != s_id:
			is_all_correct = false
			wrong_count += 1
			
	if not is_all_correct:
		_on_validation_error()
	else:
		_on_validation_success()

func _flash_slot_red(s_id: String) -> void:
	for sd in [modal_slot_nodes.get(s_id, null), room_wb_slots.get(s_id, null)]:
		if sd == null:
			continue
		var sb = (sd["panel"] as Control).get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			sb.bg_color = Color("#fecaca")

func _on_validation_error() -> void:
	error_count += 1
	hearts = max(0, hearts - 1)
	_update_hearts_ui()
	_play_buzz_error()
	_shake_node(task_modal.get_node("WinContainer") if is_modal_open else whiteboard_container)

	var wrong_slots: Array = []
	for s_id in ["pan", "lan", "man", "wan"]:
		if modal_assignments[s_id] == s_id:
			locked_slots[s_id] = true
		else:
			wrong_slots.append(s_id)
			_flash_slot_red(s_id)
	show_toast("❌ %d kartu belum tepat! Kartu yang benar terkunci hijau — periksa lagi cakupan wilayah: PAN (Pribadi), LAN (Gedung), MAN (Kota), WAN (Dunia)." % wrong_slots.size(), 4.0)

	if hearts <= 0:
		_game_over()
		return
	await get_tree().create_timer(0.8).timeout
	for s_id in wrong_slots:
		modal_assignments[s_id] = ""
	selected_tray_card_id = ""
	_refresh_all()

func _on_validation_success() -> void:
	is_completed = true
	is_game_active = false
	for s_id in ["pan", "lan", "man", "wan"]:
		locked_slots[s_id] = true
	selected_tray_card_id = ""
	_refresh_all()
	if verify_button:
		verify_button.text = "✓ KLASIFIKASI WILAYAH BENAR!"
	_play_win_fanfare()
	if is_modal_open:
		await get_tree().create_timer(1.0).timeout
		_close_task_modal()

	# Hilangkan lencana peringatan
	if wb_alert_badge:
		wb_alert_badge.visible = false
	if tray_alert_badge:
		tray_alert_badge.visible = false

	# Simpan progres dan buka Level 4.2
	var pd = get_node_or_null("/root/PlayerData")
	if pd:
		pd.set_level_stars(4, 1, hearts)

	await get_tree().create_timer(1.2).timeout
	_show_victory_dialog()

func _shake_node(n: Control) -> void:
	var orig = n.position
	var tw = create_tween()
	tw.tween_property(n, "position", orig + Vector2(-12, 0), 0.05)
	tw.tween_property(n, "position", orig + Vector2(12, 0), 0.05)
	tw.tween_property(n, "position", orig + Vector2(-8, 0), 0.05)
	tw.tween_property(n, "position", orig + Vector2(8, 0), 0.05)
	tw.tween_property(n, "position", orig, 0.05)

func _open_task_modal() -> void:
	if is_modal_open:
		return
	is_modal_open = true
	is_game_active = false
	task_modal.visible = true
	task_modal.modulate.a = 0.0
	_play_synth_sequence([523.25, 659.25], 0.08)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(task_modal, "modulate:a", 1.0, 0.2)
	_refresh_all()

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

# ==============================================================================
# VICTORY & GAME OVER DIALOGS (UNIVERSAL GAMEDIALOG)
# ==============================================================================
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
	
	var time_str = "Skor: %d | Waktu Tersisa: %02d:%02d" % [max(10, 100 - error_count * 15), int(time_remaining) / 60, int(time_remaining) % 60]
	var desc = "Luar biasa! Kamu berhasil mengklasifikasikan situasi jaringan ke dalam jangkauan wilayah yang tepat:\n- PAN: Jarak pribadi (HP, Smartwatch)\n- LAN: Satu gedung/ruangan (Kantor, Rumah)\n- MAN: Jaringan antar cabang satu kota\n- WAN: Antarnegara dan antarbenua (Global)\n\nMisi Level 4.1 SELESAI!"
	
	if not game_dialog or not is_instance_valid(game_dialog):
		_setup_game_dialog()
	else:
		game_dialog.z_index = 350
		
	var act_next = func():
		_play_synth_sequence([523.25, 659.25, 783.99], 0.08)
		get_tree().change_scene_to_file("res://scenes/gameplay/level_4_2.tscn")
	var act_map = func():
		get_tree().change_scene_to_file("res://scenes/level_path.tscn")
		
	game_dialog.show_win(
		"MISI SELESAI!",
		desc,
		hearts,
		time_str,
		act_next,
		act_map,
		"LANJUT KE 4.2"
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
		reason = cause + " Periksa kembali jangkauan wilayah jaringan: PAN (Pribadi), LAN (Gedung), MAN (Kota), WAN (Dunia). Coba lagi!"
		
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

func _on_back_pressed() -> void:
	_play_synth_sequence([440.0, 392.0], 0.08)
	if not game_dialog or not is_instance_valid(game_dialog):
		_setup_game_dialog()
	else:
		game_dialog.z_index = 350
		
	game_dialog.show_confirmation(
		"KELUAR LEVEL?",
		"Apakah kamu yakin ingin kembali ke Peta Level? Progres saat ini belum tersimpan.",
		func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn")
	)

func _update_hearts_ui() -> void:
	HeartsStyle.refresh(hearts_rects, hearts)

# ==============================================================================
# PROCESS LOOP & CHARACTER MOVEMENT
# ==============================================================================
func _process(delta: float) -> void:
	anim_pulse_time += delta
	
	# Alert badges bobbing
	if wb_alert_badge and wb_alert_badge.visible:
		wb_alert_badge.position.y = -12.0 + sin(anim_pulse_time * 5.0) * 4.0
	if tray_alert_badge and tray_alert_badge.visible:
		tray_alert_badge.position.y = -10.0 + sin(anim_pulse_time * 5.0) * 4.0
		
	if is_game_over or is_completed:
		return
		
	# Timer countdown
	if is_game_active and not is_modal_open:
		time_remaining -= delta
		if time_remaining <= 0.0:
			time_remaining = 0.0
			_game_over("Waktu misi telah habis! Klasifikasi jangkauan wilayah PAN, LAN, MAN, WAN belum terselesaikan tepat waktu.")
			return
		var m = int(time_remaining) / 60
		var s = int(time_remaining) % 60
		timer_label.text = "%02d:%02d" % [m, s]
		if time_remaining < 30.0:
			timer_label.add_theme_color_override("font_color", Color("#ef4444"))
			
	# Movement
	if is_game_active and not is_modal_open:
		_process_movement(delta)
		_check_station_proximity()

# Kotak "kaki" karakter untuk tabrakan dengan perabot
func _feet_rect(node_pos: Vector2) -> Rect2:
	return Rect2(node_pos.x + 34.0, node_pos.y + 72.0, 52.0, 22.0)

func _collides_at(node_pos: Vector2) -> bool:
	var feet = _feet_rect(node_pos)
	for n in [rack_container, whiteboard_container, tray_container]:
		if n and feet.intersects(Rect2(n.position + Vector2(6, 6), n.size - Vector2(12, 12))):
			return true
	return false

func _process_movement(delta: float) -> void:
	var move_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_dir.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_dir.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_dir.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_dir.y += 1.0
		
	if joystick_vector.length() > 0.15:
		move_dir = joystick_vector
		
	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()
		is_moving = true
		var step = move_dir * MOVE_SPEED * delta
		# Gerak per sumbu agar bisa menyusur perabot (tabrakan dengan rak, papan, dan tray)
		var cand_x = character_node.position + Vector2(step.x, 0.0)
		cand_x.x = clamp(cand_x.x, 130.0, 1420.0)
		if not _collides_at(cand_x):
			character_node.position = cand_x
		var cand_y = character_node.position + Vector2(0.0, step.y)
		cand_y.y = clamp(cand_y.y, 300.0, 620.0)
		if not _collides_at(cand_y):
			character_node.position = cand_y
		
		if move_dir.x < -0.1:
			facing_left = true
		elif move_dir.x > 0.1:
			facing_left = false
		char_sprite.flip_h = facing_left
		
		# Walk animation
		walk_anim_timer += delta
		if walk_anim_timer >= 0.045:
			walk_anim_timer = 0.0
			walk_frame_index = (walk_frame_index + 1) % max(1, walk_frames.size())
			if walk_frames.size() > 0:
				char_sprite.texture = walk_frames[walk_frame_index]
				
		# Footstep sound
		footstep_timer += delta
		if footstep_timer >= 0.28:
			footstep_timer = 0.0
			_play_footstep()
	else:
		is_moving = false
		walk_frame_index = 0
		char_sprite.texture = (walk_frames[0] if walk_frames.size() > 0 else tex_char_idle)

func _check_station_proximity() -> void:
	var char_center = character_node.position + Vector2(45, 40)
	var wb_center = whiteboard_container.position + whiteboard_container.size / 2.0
	var tray_center = tray_container.position + tray_container.size / 2.0
	
	var dist_wb = char_center.distance_to(wb_center)
	var dist_tray = char_center.distance_to(tray_center)
	
	if dist_wb < 260.0 or dist_tray < 200.0:
		interaction_prompt.visible = true
	else:
		interaction_prompt.visible = false

# ==============================================================================
# INPUT HANDLING FOR TOUCH & MOUSE
# ==============================================================================
func _input(event: InputEvent) -> void:
	if drag_pending_card != "":
		if event is InputEventMouseMotion:
			var mp = get_global_mouse_position()
			if not drag_active and mp.distance_to(drag_press_pos) > 8.0:
				if drag_from_slot != "":
					# kartu ditarik keluar dari slot -> kosongkan slotnya
					modal_assignments[drag_from_slot] = ""
					_refresh_all()
				_begin_drag(drag_pending_card)
			if drag_active and drag_ghost:
				drag_ghost.position = mp - drag_ghost.size * 0.5
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var cid = drag_pending_card
			var was_drag = drag_active
			var from_slot = drag_from_slot
			var drop_pos = get_global_mouse_position()
			_end_drag_cleanup()
			if not was_drag and from_slot != "":
				_on_slot_clicked(from_slot)
			if was_drag:
				var target = _slot_at(drop_pos)
				if target != "":
					_assign_card(cid, target)
				else:
					selected_tray_card_id = ""
					_refresh_all()
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var is_pressed = event.is_pressed()
		var pos = event.position
		
		if is_pressed:
			if pos.distance_to(joystick_center) < 130.0 and joystick_touch_id == -1:
				joystick_touch_id = event.index if (event is InputEventScreenTouch) else 1
				_update_joystick(pos)
		else:
			var touch_id = event.index if (event is InputEventScreenTouch) else 1
			if touch_id == joystick_touch_id:
				joystick_touch_id = -1
				joystick_vector = Vector2.ZERO
				joystick_knob.position = joystick_center - Vector2(27.5, 27.5)
				
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		var touch_id = event.index if (event is InputEventScreenDrag) else 1
		if touch_id == joystick_touch_id:
			_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2) -> void:
	var offset = touch_pos - joystick_center
	if offset.length() > joystick_max_dist:
		offset = offset.normalized() * joystick_max_dist
	joystick_vector = offset / joystick_max_dist
	joystick_knob.position = joystick_center + offset - Vector2(27.5, 27.5)

# ==============================================================================
# AUDIO GENERATOR HELPERS
# ==============================================================================
func _play_footstep() -> void:
	if footstep_player:
		var freqs = [150.0, 165.0, 180.0]
		var f = freqs[randi() % freqs.size()]
		_play_tone_on_player(footstep_player, f, 0.04, 0.12)

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
		var t = float(i) / float(num_samples)
		var env = sin(t * PI)
		var val = sin(2.0 * PI * freq * (float(i) / float(sample_rate))) * env * vol
		var sample_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_val)
	stream.data = data
	player.stream = stream
	player.play()

func _play_synth_sequence(freqs: Array, step_time: float) -> void:
	var sample_rate = 22050
	var total_dur = step_time * freqs.size()
	var num_samples = int(sample_rate * total_dur)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	var samples_per_step = int(sample_rate * step_time)
	for s_idx in range(freqs.size()):
		var freq = freqs[s_idx]
		for i in range(samples_per_step):
			var global_i = s_idx * samples_per_step + i
			if global_i >= num_samples:
				break
			var t = float(i) / float(samples_per_step)
			var env = sin(t * PI)
			var val = sin(2.0 * PI * freq * (float(i) / float(sample_rate))) * env * 0.25
			var sample_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
			data.encode_s16(global_i * 2, sample_val)
	stream.data = data
	if audio_player:
		audio_player.stream = stream
		audio_player.play()


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
		{ "title": "Misi Level 4.1", "text": "Cocokkan setiap kartu situasi jaringan ke kategori yang benar: PAN, LAN, MAN, atau WAN." },
		TutorialOverlay.step_move(self),
		{ "title": "1. Kartu Situasi", "text": "Ini kartu-kartu yang harus dikelompokkan. Tekan lalu seret satu kartu ke kolom yang tepat di papan.", "target": tray_container, "pointer": "both" },
		{ "title": "2. Papan Klasifikasi", "text": "PAN = area pribadi (HP, smartwatch), LAN = satu gedung, MAN = satu kota, WAN = antarnegara. Lepaskan kartu di kolomnya.", "target": whiteboard_container, "pointer": "both" },
		TutorialOverlay.step_hearts(self),
		{ "title": "Siap?", "text": "Selesaikan misi sebelum waktu habis. Lupa caranya? Tekan tombol ? (kuning) di dekat pewaktu kapan saja untuk melihat panduan ini lagi." }
	]
