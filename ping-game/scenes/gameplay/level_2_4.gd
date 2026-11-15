extends Control

# Level 2.4 - Balasan MAC Address (ARP-Reply) & Tabel ARP
# Sesuai Proposal & Desain Figma 100%:
# - Alur 3 Tahap: 1. Pilih ARP-Reply -> 2. Simpan ke Tabel ARP -> 3. Balik & Uji Unicast
# - Animasi Amplop Bersayap (Personifikasi Data) ARP-Reply dari PC 3 -> Switch -> PC 1 (Unicast)
# - PC 1 menyimpan pasangan IP-MAC PC 3 di Tabel ARP, jalur berubah hijau (UP)
# - Komponen reusable: CloseButton, PauseModal, GameDialog

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

# Dynamic Loaded Textures
var tex_switch_icon: Texture2D = null
var tex_pc_operator: Texture2D = null
var tex_router_obj: Texture2D = null
var tex_envelope: Texture2D = null
var tex_panel: Texture2D = null
var tex_cable: Texture2D = null

# Scene Node References
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer
@onready var background: TextureRect = %Background
@onready var door_arch: TextureRect = %DoorArch
@onready var potted_plant: TextureRect = %PottedPlant
@onready var wall_clock: TextureRect = %WallClock
@onready var left_rack_cabinet: TextureRect = %LeftRackCabinet
@onready var whiteboard_node: Control = %WhiteboardNode
@onready var cables_container: Control = %CablesContainer

@onready var pc1_desk: Control = %PC1Desk
@onready var pc1_monitor: TextureRect = %PC1Monitor
@onready var pc1_pill: PanelContainer = %PC1Pill
@onready var pc1_bubble: PanelContainer = %PC1Bubble

@onready var center_desk: Control = %CenterDesk
@onready var center_switch: TextureRect = %CenterSwitch
@onready var center_router: TextureRect = %CenterRouter
@onready var kawal_btn: Button = %KawalBtn
@onready var kawal_alert_pill: PanelContainer = %KawalAlertPill

@onready var pc2_desk: Control = %PC2Desk
@onready var pc2_monitor: TextureRect = %PC2Monitor
@onready var pc2_pill: PanelContainer = %PC2Pill

@onready var pc3_desk: Control = %PC3Desk
@onready var pc3_monitor: TextureRect = %PC3Monitor
@onready var pc3_pill: PanelContainer = %PC3Pill
@onready var pc3_star_badge: TextureRect = %PC3StarBadge

@onready var pc4_desk: Control = %PC4Desk
@onready var pc4_monitor: TextureRect = %PC4Monitor
@onready var pc4_pill: PanelContainer = %PC4Pill

@onready var character_node: Control = %CharacterNode

# Character & Movement
var walk_frames: Array[Texture2D] = []
var walk_frame_index: float = 0.0
var char_sprite: TextureRect
var char_pos: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO
var footstep_timer: float = 0.0

# Mobile Controls (Joystick)
var mobile_controls_root: Control
var dpad_touch_id: int = -1
var dpad_center: Vector2 = Vector2.ZERO
var dpad_knob_sprite: TextureRect
var dpad_radius: float = 55.0

# UI Elements
var header_ui: Control
var timer_label: Label
var clock_icon: TextureRect
var hearts_panel: PanelContainer
var hearts_container: HBoxContainer
var hearts_rects: Array[TextureRect] = []
var broken_labels: Array[Label] = []
var toast_panel: PanelContainer
var toast_label: Label
var toast_tween: Tween

# Modals
var intro_modal: Control
var popup_modal: Control
var popup_card: Control
var whiteboard_modal: Control
var pause_modal: Control
var game_dialog: Control

# Pop up 2.3 Interactive State
var current_tahap: int = 1 # 1: Cari PC, 2: Isi Amplop, 3: Broadcast
var tab_buttons: Array[Button] = []
var tahap_status_label: Label
var tahap_status_panel: PanelContainer
var tahap_container: Control

# Tahap 1 State
var selected_target_pc: int = 0 # 1, 2, 3, 4 (Correct: 3)
var pc_selection_cards: Dictionary = {}

# Tahap 2 State
var selected_target_ip: String = "" # Correct: "192.168.1.50"
var selected_dest_mac: String = "" # Correct: "FF:FF:FF:FF:FF:FF"
var selected_delivery_type: String = "" # Correct: "Broadcast"
var tahap2_option_buttons: Dictionary = {}

# Tahap 3 State
var selected_ports: Dictionary = {
	1: false, # Port 1 (PC 1 Asal - Locked)
	2: false, # Port 2 (PC 2)
	3: false, # Port 3 (PC 3 Target)
	4: false, # Port 4 (PC 4)
	5: false  # Port 5 (Router)
}
var port_cards: Dictionary = {}

# Gameplay State
var is_game_active: bool = false
var is_modal_open: bool = false
var is_completed: bool = false
var time_remaining: float = TIME_LIMIT
var hearts: int = 3
var error_count: int = 0
var is_animating_broadcast: bool = false

# Topo Diagram References (For Success State - Figma Screenshot)
var topo_p3_box: PanelContainer = null
var topo_p3_label: Label = null
var topo_envelope_icon: TextureRect = null

# Flying Envelope Mascots for Animation
var flying_envelopes: Array[TextureRect] = []

func _ready() -> void:
	call_deferred("_setup_help_button")
	_load_dynamic_assets()
	_setup_character()
	_build_room_decorations()
	_build_mobile_controls()
	_build_header_ui()
	_build_pause_modal()
	_build_intro_modal()
	_build_popup_2_3()
	_build_toast_ui()
	
	_reposition_responsive()
	get_viewport().size_changed.connect(_reposition_responsive)
	
	# Buka Intro Modal di awal level
	get_tree().create_timer(0.1).timeout.connect(_open_intro_modal)

func _process(delta: float) -> void:
	if not is_game_active:
		return
		
	# Countdown Timer
	time_remaining = max(0.0, time_remaining - delta)
	_update_timer_display()
	if time_remaining <= 0.0:
		is_game_active = false
		_trigger_game_over("Waktu habis! Selesaikan ARP-Reply & Tabel ARP tepat waktu agar jalur menjadi hijau (UP).")
		return
		
	# Movement & Proximity
	_handle_movement(delta)
	_check_proximity()

func _update_timer_display() -> void:
	if not timer_label:
		return
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	if time_remaining <= 30.0:
		timer_label.add_theme_color_override("font_color", Color("#ef4444"))
		if clock_icon:
			clock_icon.modulate = Color(1.0, 0.4, 0.4, 1.0)
	else:
		timer_label.add_theme_color_override("font_color", Color("#4a2e2b"))
		if clock_icon:
			clock_icon.modulate = Color.WHITE

func _handle_movement(delta: float) -> void:
	if is_modal_open or is_animating_broadcast:
		input_dir = Vector2.ZERO
		return
		
	# Keyboard WASD / Arrow
	var k_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		k_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		k_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		k_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		k_dir.x += 1.0
		
	var final_dir = input_dir if input_dir.length() > 0.1 else k_dir.normalized()
	
	if final_dir.length() > 0.05:
		var delta_mov = final_dir * MOVE_SPEED * delta
		
		var test_x = char_pos.x + delta_mov.x
		if not _is_room_collision(Vector2(test_x, char_pos.y)):
			char_pos.x = test_x
			
		var test_y = char_pos.y + delta_mov.y
		if not _is_room_collision(Vector2(char_pos.x, test_y)):
			char_pos.y = test_y
			
		character_node.position = char_pos
		
		# Sprite Flip & Walk Animation
		if char_sprite:
			if final_dir.x < -0.05:
				char_sprite.flip_h = true
			elif final_dir.x > 0.05:
				char_sprite.flip_h = false
				
			if walk_frames.size() > 0:
				walk_frame_index += delta * 14.0
				var frame_idx = int(walk_frame_index) % walk_frames.size()
				char_sprite.texture = walk_frames[frame_idx]
				
		footstep_timer += delta
		if footstep_timer >= 0.28:
			footstep_timer = 0.0
			_play_footstep()
	else:
		if char_sprite:
			char_sprite.texture = (walk_frames[0] if walk_frames.size() > 0 else tex_char_idle)
		walk_frame_index = 0.0

func _is_room_collision(pos: Vector2) -> bool:
	var feet_l = pos.x + 40.0
	var feet_r = pos.x + 180.0
	var feet_t = pos.y + 70.0
	var feet_b = pos.y + 115.0
	
	var vp_sz = get_viewport_rect().size
	
	# 1. Batas layar
	if feet_l < 15.0 or feet_r > vp_sz.x - 15.0 or feet_b > vp_sz.y - 15.0:
		return true
		
	# 2. Dinding atas (Y < 235)
	if feet_t < 235.0:
		return true
		
	# 3. Rak Peralatan Kiri
	if left_rack_cabinet:
		var lr = left_rack_cabinet.get_global_rect()
		if feet_r > lr.position.x + 10.0 and feet_l < lr.position.x + lr.size.x - 10.0:
			if feet_b > lr.position.y + 80.0 and feet_t < lr.position.y + lr.size.y:
				return true
				
	# 4. PC 1 Desk (Kiri)
	if pc1_desk:
		var r1 = pc1_desk.get_global_rect()
		if feet_r > r1.position.x + 10.0 and feet_l < r1.position.x + r1.size.x - 10.0:
			if feet_b > r1.position.y + 20.0 and feet_t < r1.position.y + r1.size.y:
				return true
				
	# 5. Meja Switch Tengah
	if center_desk:
		var dr = center_desk.get_global_rect()
		if feet_r > dr.position.x + 15.0 and feet_l < dr.position.x + dr.size.x - 15.0:
			if feet_b > dr.position.y + 25.0 and feet_t < dr.position.y + dr.size.y - 10.0:
				return true
				
	# 6. Desks Kanan (PC 2, PC 3, PC 4)
	for d in [pc2_desk, pc3_desk, pc4_desk]:
		if d:
			var dr = d.get_global_rect()
			if feet_r > dr.position.x + 10.0 and feet_l < dr.position.x + dr.size.x - 10.0:
				if feet_b > dr.position.y + 20.0 and feet_t < dr.position.y + dr.size.y:
					return true
					
	return false

func _check_proximity() -> void:
	if not center_desk or not kawal_alert_pill:
		return
		
	var desk_rect = center_desk.get_global_rect()
	var char_center = char_pos + Vector2(110.0, 60.0)
	var desk_center = desk_rect.position + desk_rect.size / 2.0
	var dist = char_center.distance_to(desk_center)
	
	var is_near = (dist < 260.0)
	if kawal_alert_pill.visible != is_near:
		kawal_alert_pill.visible = is_near
		if is_near:
			var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			kawal_alert_pill.scale = Vector2(0.5, 0.5)
			tw.tween_property(kawal_alert_pill, "scale", Vector2.ONE, 0.18)
			
	if kawal_btn:
		kawal_btn.modulate = Color(1.15, 1.15, 1.15, 1.0) if is_near else Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active or is_modal_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if kawal_alert_pill and kawal_alert_pill.visible:
				_open_popup_2_3()

# --- LOAD ASSETS ---
func _load_dynamic_assets() -> void:
	tex_pc_operator = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/operator_pc_2_1.png")
	tex_switch_icon = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/switch-icons.png")
	tex_router_obj = _safe_load_texture("res://art/assets/PING! Assets/Character/main-char-router.png")
	tex_envelope = _safe_load_texture("res://art/assets/PING! Assets/Sprite animation/paket data/1.png")
	tex_panel = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/straight.png")
	tex_cable = _safe_load_texture("res://art/assets/scattered/kabel_utp-removebg-preview.png")
	
	for i in range(1, 33):
		var p = "res://art/assets/PING! Assets/Sprite animation/router walk/%d.png" % i
		var tex = _safe_load_texture(p)
		if tex:
			walk_frames.append(tex)
	if walk_frames.is_empty():
		walk_frames.append(tex_char_idle)

func _setup_character() -> void:
	character_node.custom_minimum_size = Vector2(220, 120)
	character_node.size = Vector2(220, 120)
	character_node.pivot_offset = Vector2(110, 60)
	
	char_sprite = TextureRect.new()
	char_sprite.name = "CharSprite"
	char_sprite.texture = (walk_frames[0] if walk_frames.size() > 0 else tex_char_idle)
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.custom_minimum_size = Vector2(320, 176)
	char_sprite.size = Vector2(320, 176)
	char_sprite.position = Vector2(-50, -28)
	character_node.add_child(char_sprite)
	var _pd = get_node_or_null("/root/PlayerData")
	if _pd and _pd.has_method("apply_to_character"):
		_pd.apply_to_character(char_sprite)
	
	char_pos = character_node.position

# --- ROOM DECORATIONS (FIGMA IMAGE 2) ---
func _build_room_decorations() -> void:
	# 1. Left Rack Cabinet
	var rack_pill = _create_mini_pill("Rak Tabel ARP & MAC / Status LINK UP (Hijau)", Color("#eff6ff"), Color("#1e40af"))
	rack_pill.position = Vector2(10, -28)
	left_rack_cabinet.add_child(rack_pill)
	
	var shelf_container = Control.new()
	shelf_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	left_rack_cabinet.add_child(shelf_container)
	if tex_panel:
		_add_shelf_item(shelf_container, tex_panel, Vector2(55, 65))
	if tex_switch_icon:
		_add_shelf_item(shelf_container, tex_switch_icon, Vector2(55, 145))
	if tex_cable:
		_add_shelf_item(shelf_container, tex_cable, Vector2(55, 230))
		
	# 2. Whiteboard on Wall
	var wb_panel = PanelContainer.new()
	wb_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb_wb = StyleBoxFlat.new()
	sb_wb.bg_color = Color("#ffffff")
	sb_wb.border_color = Color("#3b82f6")
	sb_wb.set_border_width_all(3)
	sb_wb.set_corner_radius_all(12)
	sb_wb.shadow_color = Color(0, 0, 0, 0.15)
	sb_wb.shadow_size = 6
	sb_wb.shadow_offset = Vector2(0, 3)
	sb_wb.set_content_margin_all(8)
	wb_panel.add_theme_stylebox_override("panel", sb_wb)
	whiteboard_node.add_child(wb_panel)
	
	var wb_vbox = VBoxContainer.new()
	wb_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	wb_panel.add_child(wb_vbox)
	
	var wb_title = Label.new()
	wb_title.text = "KELAS ALAMAT IPv4"
	wb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wb_title.add_theme_font_override("font", font_black)
	wb_title.add_theme_font_size_override("font_size", 10)
	wb_title.add_theme_color_override("font_color", Color("#1e3a8a"))
	wb_vbox.add_child(wb_title)
	
	var wb_content = Label.new()
	wb_content.text = "A: 1-126  |  B: 128-191  |  C: 192-223\nARP-Reply: Kembalikan MAC Tujuan"
	wb_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wb_content.add_theme_font_override("font", font_bold)
	wb_content.add_theme_font_size_override("font_size", 8)
	wb_content.add_theme_color_override("font_color", Color("#2563eb"))
	wb_vbox.add_child(wb_content)
	
	# 3. PC 1 Desk (Pengirim: 192.168.1.10)
	if pc1_monitor and tex_pc_operator:
		pc1_monitor.texture = tex_pc_operator
		pc1_monitor.modulate = Color(0.72, 0.88, 1.0) # Soft blue
		
	_style_pill(pc1_pill, Color("#ffffff"), Color("#475569"))
	
	# Speech Bubble di atas PC 1
	var sb_bubble = StyleBoxFlat.new()
	sb_bubble.bg_color = Color("#ffffff")
	sb_bubble.border_color = Color("#38bdf8")
	sb_bubble.set_border_width_all(2)
	sb_bubble.set_corner_radius_all(10)
	sb_bubble.content_margin_left = 10
	sb_bubble.content_margin_right = 10
	sb_bubble.content_margin_top = 4
	sb_bubble.content_margin_bottom = 4
	pc1_bubble.add_theme_stylebox_override("panel", sb_bubble)
	var bubble_lbl = pc1_bubble.get_node("PC1BubbleLabel") as Label
	bubble_lbl.add_theme_font_override("font", font_extrabold)
	bubble_lbl.add_theme_font_size_override("font_size", 9)
	bubble_lbl.add_theme_color_override("font_color", Color("#0369a1"))
	
	# 4. Center Desk (Switch + Router + Tombol Kawal)
	if center_switch and tex_switch_icon:
		center_switch.texture = tex_switch_icon
	if center_router and tex_router_obj:
		center_router.texture = tex_router_obj
		
	var sb_kawal = StyleBoxFlat.new()
	sb_kawal.bg_color = Color("#fed7aa")
	sb_kawal.border_color = Color("#ea580c")
	sb_kawal.set_border_width_all(2)
	sb_kawal.set_corner_radius_all(10)
	sb_kawal.shadow_color = Color(0.92, 0.35, 0.05, 0.25)
	sb_kawal.shadow_size = 4
	sb_kawal.shadow_offset = Vector2(0, 2)
	kawal_btn.add_theme_stylebox_override("normal", sb_kawal)
	kawal_btn.add_theme_stylebox_override("hover", sb_kawal)
	kawal_btn.add_theme_stylebox_override("pressed", sb_kawal)
	kawal_btn.add_theme_font_override("font", font_black)
	kawal_btn.add_theme_color_override("font_color", Color("#9a3412"))
	kawal_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	kawal_btn.pressed.connect(_open_popup_2_3)
	_setup_hover_scale(kawal_btn, 1.1)
	
	# Proximity Alert Pill
	var sb_alert = StyleBoxFlat.new()
	sb_alert.bg_color = Color("#ffffff")
	sb_alert.border_color = Color("#ef4444")
	sb_alert.set_border_width_all(2)
	sb_alert.set_corner_radius_all(12)
	sb_alert.content_margin_left = 12
	sb_alert.content_margin_right = 12
	sb_alert.content_margin_top = 2
	sb_alert.content_margin_bottom = 2
	kawal_alert_pill.add_theme_stylebox_override("panel", sb_alert)
	var alert_lbl = kawal_alert_pill.get_node("KawalAlertLabel") as Label
	alert_lbl.add_theme_font_override("font", font_extrabold)
	alert_lbl.add_theme_color_override("font_color", Color("#dc2626"))
	kawal_alert_pill.visible = false

	# Kartu MAC Address di atas Switch (dibawa oleh ARP-Reply)
	var mac_card = _create_mini_pill("KARTU MAC ADDRESS: 00:1A:2B:3C:4D:5E", Color("#fef9c3"), Color("#854d0e"))
	mac_card.position = Vector2(20, -42)
	center_desk.add_child(mac_card)
	
	center_desk.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_open_popup_2_3()
	)
	
	# 5. Right Desks (PC 2: .12, PC 3: .50 Target, PC 4: .88)
	if pc2_monitor and tex_pc_operator:
		pc2_monitor.texture = tex_pc_operator
		pc2_monitor.modulate = Color(0.92, 0.85, 1.0) # Lavender
	_style_pill(pc2_pill, Color("#ffffff"), Color("#475569"))
	
	if pc3_monitor and tex_pc_operator:
		pc3_monitor.texture = tex_pc_operator
		pc3_monitor.modulate = Color(0.75, 1.0, 0.88) # Mint green (Target)
	_style_pill(pc3_pill, Color("#dcfce7"), Color("#15803d"))
	
	if pc4_monitor and tex_pc_operator:
		pc4_monitor.texture = tex_pc_operator
		pc4_monitor.modulate = Color(0.82, 0.92, 1.0) # Light blue
	_style_pill(pc4_pill, Color("#ffffff"), Color("#475569"))
	
	cables_container.draw.connect(_on_cables_draw)

func _style_pill(pill: PanelContainer, bg: Color, border: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1.5)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", sb)
	var lbl = pill.get_child(0) as Label
	if lbl:
		lbl.add_theme_font_override("font", font_bold)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", border)

# --- CABLING & CIRCLE NODES (FIGMA IMAGE 2) ---
func _on_cables_draw() -> void:
	# 1. Cable from PC 1 to Center Desk (Switch)
	var r1 = pc1_desk.get_global_rect()
	var rd = center_desk.get_global_rect()
	var p1_exit = Vector2(r1.position.x + r1.size.x, r1.position.y + r1.size.y * 0.55)
	var cd_entry = Vector2(rd.position.x, rd.position.y + rd.size.y * 0.55)
	
	cables_container.draw_line(p1_exit, cd_entry, Color("#38bdf8"), 5.0)
	
	# 2. Branch Cables from Center Desk (Switch) to PC 2, PC 3, PC 4
	var cd_exit = Vector2(rd.position.x + rd.size.x, rd.position.y + rd.size.y * 0.55)
	
	var r2 = pc2_desk.get_global_rect()
	var r3 = pc3_desk.get_global_rect()
	var r4 = pc4_desk.get_global_rect()
	
	var p2_entry = Vector2(r2.position.x, r2.position.y + r2.size.y * 0.55)
	var p3_entry = Vector2(r3.position.x, r3.position.y + r3.size.y * 0.55)
	var p4_entry = Vector2(r4.position.x, r4.position.y + r4.size.y * 0.55)
	
	# Junction X
	var junction_x = cd_exit.x + 50.0
	cables_container.draw_line(cd_exit, Vector2(junction_x, cd_exit.y), Color("#38bdf8"), 5.0)
	
	# Top branch to PC 2 (with node circle)
	var node_pos_2 = Vector2(junction_x, p2_entry.y)
	cables_container.draw_dashed_line(Vector2(junction_x, cd_exit.y), node_pos_2, Color("#38bdf8"), 4.0, 6.0)
	cables_container.draw_line(node_pos_2, p2_entry, Color("#38bdf8"), 5.0)
	_draw_circle_node(node_pos_2, 14.0, Color("#38bdf8"))
	
	# Middle branch to PC 3 (Target - solid thick cable with larger node)
	var node_pos_3 = Vector2(junction_x + 55.0, p3_entry.y)
	cables_container.draw_line(Vector2(junction_x, cd_exit.y), node_pos_3, Color("#0284c7"), 6.0)
	cables_container.draw_line(node_pos_3, p3_entry, Color("#0284c7"), 6.0)
	_draw_circle_node(node_pos_3, 16.0, Color("#059669"))
	
	# Bottom branch to PC 4 (with node circle)
	var node_pos_4 = Vector2(junction_x, p4_entry.y)
	cables_container.draw_dashed_line(Vector2(junction_x, cd_exit.y), node_pos_4, Color("#38bdf8"), 4.0, 6.0)
	cables_container.draw_line(node_pos_4, p4_entry, Color("#38bdf8"), 5.0)
	_draw_circle_node(node_pos_4, 14.0, Color("#38bdf8"))

func _draw_circle_node(center: Vector2, radius: float, accent_col: Color) -> void:
	cables_container.draw_circle(center, radius, Color.WHITE)
	cables_container.draw_arc(center, radius, 0, TAU, 32, Color("#4a2e2b"), 2.5)
	# Draw small play arrow ▶ inside circle
	var tri = PackedVector2Array([
		center + Vector2(-radius * 0.35, -radius * 0.45),
		center + Vector2(radius * 0.45, 0.0),
		center + Vector2(-radius * 0.35, radius * 0.45)
	])
	cables_container.draw_colored_polygon(tri, accent_col)

# --- HEADER UI & PAUSE MODAL ---
func _build_header_ui() -> void:
	header_ui = Control.new()
	header_ui.name = "HeaderUI"
	header_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_ui)
	
	var back_btn = Button.new()
	back_btn.name = "BackBtn"
	back_btn.text = "<"
	back_btn.custom_minimum_size = Vector2(52, 52)
	back_btn.size = Vector2(52, 52)
	back_btn.add_theme_font_override("font", font_black)
	back_btn.add_theme_font_size_override("font_size", 24)
	var sb_back = StyleBoxFlat.new()
	sb_back.bg_color = Color("#fed0cf")
	sb_back.border_color = Color("#4a2e2b")
	sb_back.set_border_width_all(2.5)
	sb_back.set_corner_radius_all(26)
	sb_back.shadow_color = Color(0, 0, 0, 0.2)
	sb_back.shadow_size = 4
	sb_back.shadow_offset = Vector2(0, 2)
	back_btn.add_theme_stylebox_override("normal", sb_back)
	back_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UiKit.style_back_button(back_btn)
	back_btn.pressed.connect(_open_pause_modal)
	_setup_hover_scale(back_btn, 1.1)
	header_ui.add_child(back_btn)
	
	# Hearts Panel
	hearts_panel = PanelContainer.new()
	hearts_panel.name = "HeartsPanel"
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color("#fed0cf")
	sb_h.border_color = Color("#4a2e2b")
	sb_h.set_border_width_all(2.5)
	sb_h.set_corner_radius_all(18)
	sb_h.content_margin_left = 12
	sb_h.content_margin_right = 12
	sb_h.content_margin_top = 8
	sb_h.content_margin_bottom = 8
	hearts_panel.add_theme_stylebox_override("panel", sb_h)
	header_ui.add_child(hearts_panel)
	
	hearts_container = HBoxContainer.new()
	hearts_container.add_theme_constant_override("separation", 6)
	hearts_panel.add_child(hearts_container)
	
	for i in range(3):
		var h_box = Control.new()
		h_box.custom_minimum_size = Vector2(28, 26)
		hearts_container.add_child(h_box)
		
		var hr = TextureRect.new()
		hr.texture = tex_vector_heart
		hr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hr.set_anchors_preset(Control.PRESET_FULL_RECT)
		hr.modulate = Color(1.0, 0.28, 0.4, 1.0)
		h_box.add_child(hr)
		hearts_rects.append(hr)
		HeartsStyle.schedule_normalize(hearts_rects)
		
		var bl = Label.new()
		bl.text = "✕"
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bl.set_anchors_preset(Control.PRESET_FULL_RECT)
		bl.add_theme_font_override("font", font_black)
		bl.add_theme_font_size_override("font_size", 16)
		bl.add_theme_color_override("font_color", Color("#4a2e2b"))
		bl.visible = false
		h_box.add_child(bl)
		broken_labels.append(bl)
		
	# Level Badge "Level 2.3"
	var level_badge = PanelContainer.new()
	level_badge.name = "LevelBadge"
	var sb_lb = StyleBoxFlat.new()
	sb_lb.bg_color = Color("#fffdf7")
	sb_lb.border_color = Color("#4a2e2b")
	sb_lb.set_border_width_all(2.5)
	sb_lb.set_corner_radius_all(12)
	sb_lb.content_margin_left = 14
	sb_lb.content_margin_right = 14
	sb_lb.content_margin_top = 4
	sb_lb.content_margin_bottom = 4
	level_badge.add_theme_stylebox_override("panel", sb_lb)
	header_ui.add_child(level_badge)
	
	var lb_vbox = VBoxContainer.new()
	lb_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lb_vbox.add_theme_constant_override("separation", -2)
	level_badge.add_child(lb_vbox)
	
	var t_sub = Label.new()
	t_sub.text = "Level"
	t_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_sub.add_theme_font_override("font", font_bold)
	t_sub.add_theme_font_size_override("font_size", 9)
	t_sub.add_theme_color_override("font_color", Color("#78716c"))
	lb_vbox.add_child(t_sub)
	
	var t_num = Label.new()
	t_num.text = "2.4"
	t_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_num.add_theme_font_override("font", font_black)
	t_num.add_theme_font_size_override("font_size", 14)
	t_num.add_theme_color_override("font_color", Color("#1c1917"))
	lb_vbox.add_child(t_num)
	
	# Timer Panel
	var timer_panel = PanelContainer.new()
	timer_panel.name = "TimerPanel"
	var sb_timer = StyleBoxFlat.new()
	sb_timer.bg_color = Color("#fffdf7")
	sb_timer.border_color = Color("#4a2e2b")
	sb_timer.set_border_width_all(2.5)
	sb_timer.set_corner_radius_all(18)
	sb_timer.content_margin_left = 14
	sb_timer.content_margin_right = 14
	sb_timer.content_margin_top = 8
	sb_timer.content_margin_bottom = 8
	timer_panel.add_theme_stylebox_override("panel", sb_timer)
	header_ui.add_child(timer_panel)
	
	var hb_timer = HBoxContainer.new()
	hb_timer.add_theme_constant_override("separation", 8)
	hb_timer.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_panel.add_child(hb_timer)
	
	clock_icon = TextureRect.new()
	clock_icon.texture = preload("res://art/assets/PING! Assets/asset-gameplay/generals/frame-jam.png")
	clock_icon.custom_minimum_size = Vector2(24, 24)
	clock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb_timer.add_child(clock_icon)
	
	timer_label = Label.new()
	timer_label.text = "02:45"
	timer_label.add_theme_font_override("font", font_black)
	timer_label.add_theme_font_size_override("font_size", 18)
	timer_label.add_theme_color_override("font_color", Color("#4a2e2b"))
	hb_timer.add_child(timer_label)
	
	# Pause Button "≡"
	var pause_btn = Button.new()
	pause_btn.name = "PauseBtn"
	pause_btn.text = "≡"
	pause_btn.custom_minimum_size = Vector2(52, 52)
	pause_btn.size = Vector2(52, 52)
	pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pause_btn.add_theme_font_override("font", font_black)
	pause_btn.add_theme_font_size_override("font_size", 24)
	var sb_pause = StyleBoxFlat.new()
	sb_pause.bg_color = Color("#fffdf7")
	sb_pause.border_color = Color("#4a2e2b")
	sb_pause.set_border_width_all(2.5)
	sb_pause.set_corner_radius_all(14)
	sb_pause.shadow_color = Color(0, 0, 0, 0.2)
	sb_pause.shadow_size = 4
	sb_pause.shadow_offset = Vector2(0, 2)
	pause_btn.add_theme_stylebox_override("normal", sb_pause)
	pause_btn.add_theme_stylebox_override("hover", sb_pause)
	pause_btn.add_theme_stylebox_override("pressed", sb_pause)
	pause_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	pause_btn.pressed.connect(_open_pause_modal)
	_setup_hover_scale(pause_btn, 1.1)
	header_ui.add_child(pause_btn)
	
	_position_header_elements()

func _position_header_elements() -> void:
	if not header_ui:
		return
	var vp_sz = get_viewport_rect().size
	var top_y = 20.0
	
	var back_btn = header_ui.get_node_or_null("BackBtn") as Control
	if back_btn:
		back_btn.position = Vector2(30.0, top_y)
		back_btn.size = Vector2(52.0, 52.0)
		
	if hearts_panel:
		hearts_panel.position = Vector2(106.0, top_y)
		
	var level_badge = header_ui.get_node_or_null("LevelBadge") as Control
	if level_badge:
		level_badge.position = Vector2(260.0, top_y)
		
	var pause_btn = header_ui.get_node_or_null("PauseBtn") as Control
	if pause_btn:
		pause_btn.position = Vector2(vp_sz.x - 75.0, top_y)
		pause_btn.size = Vector2(52.0, 52.0)
		
	var timer_panel = header_ui.get_node_or_null("TimerPanel") as Control
	if timer_panel:
		timer_panel.position = Vector2(vp_sz.x - 230.0, top_y)

func _build_pause_modal() -> void:
	pause_modal = PauseModalScene.instantiate()
	pause_modal.z_index = 200
	add_child(pause_modal)
	pause_modal.resume_requested.connect(func(): is_game_active = true)
	pause_modal.restart_requested.connect(func(): get_tree().reload_current_scene())
	pause_modal.exit_requested.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))

func _open_pause_modal() -> void:
	is_game_active = false
	if pause_modal.has_method("open"):
		pause_modal.open()
	else:
		pause_modal.visible = true

# --- INTRO MODAL (FIGMA IMAGE 1) ---
func _build_intro_modal() -> void:
	intro_modal = IntroCard.build(self, "Level 2.4 – Balasan MAC Address (ARP-Reply) & Tabel ARP", "Pemilik IP 192.168.1.50 membalas dengan MAC Address-nya! ARP-Reply memberi tahu MAC yang sesuai, lalu disimpan ke Tabel ARP (ARP Cache).", _close_intro_modal, 150, false)

func _create_diagram_pc_box(title_txt: String, ip_txt: String, desc_txt: String, bg_col: Color, border_col: Color, text_col: Color) -> PanelContainer:
	var pan = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	pan.add_theme_stylebox_override("panel", sb)
	pan.custom_minimum_size = Vector2(170, 60)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	pan.add_child(vb)
	
	var tl = Label.new()
	tl.text = title_txt
	tl.add_theme_font_override("font", font_black)
	tl.add_theme_font_size_override("font_size", 10)
	tl.add_theme_color_override("font_color", text_col)
	vb.add_child(tl)
	
	var il = Label.new()
	il.text = ip_txt
	il.add_theme_font_override("font", font_extrabold)
	il.add_theme_font_size_override("font_size", 10)
	il.add_theme_color_override("font_color", text_col)
	vb.add_child(il)
	
	var dl = Label.new()
	dl.text = desc_txt
	dl.add_theme_font_override("font", font_semibold)
	dl.add_theme_font_size_override("font_size", 8)
	dl.add_theme_color_override("font_color", text_col.lightened(0.2))
	vb.add_child(dl)
	return pan

func _create_intro_col_box(title_txt: String, body_txt: String, bg_col: Color, border_col: Color) -> PanelContainer:
	var pan = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(1.5)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	pan.add_theme_stylebox_override("panel", sb)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	pan.add_child(vb)
	
	var tl = Label.new()
	tl.text = title_txt
	tl.add_theme_font_override("font", font_black)
	tl.add_theme_font_size_override("font_size", 10)
	tl.add_theme_color_override("font_color", Color("#1e293b"))
	vb.add_child(tl)
	
	var bl = Label.new()
	bl.text = body_txt
	bl.add_theme_font_override("font", font_semibold)
	bl.add_theme_font_size_override("font_size", 9)
	bl.add_theme_color_override("font_color", Color("#475569"))
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(bl)
	return pan

func _open_intro_modal() -> void:
	is_modal_open = true
	intro_modal.visible = true
	var card = IntroCard.card_of(intro_modal)
	card.position = (get_viewport_rect().size - card.size) / 2.0
	card.scale = Vector2(0.8, 0.8)
	card.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2.ONE, 0.25)
	tw.tween_property(card, "modulate:a", 1.0, 0.22)
	_play_chime_sound()

func _close_intro_modal() -> void:
	var card = IntroCard.card_of(intro_modal)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(card, "scale", Vector2(0.8, 0.8), 0.18)
	tw.tween_property(card, "modulate:a", 0.0, 0.16)
	await tw.finished
	intro_modal.visible = false
	is_modal_open = false
	_start_after_tutorial()
	_play_chime_sound()

# --- POP UP 2.3 (3-TAHAP INTERACTIVE MODAL) ---
func _build_popup_2_3() -> void:
	popup_modal = Control.new()
	popup_modal.name = "Popup2_3Modal"
	popup_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_modal.z_index = 120
	popup_modal.visible = false
	add_child(popup_modal)
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	popup_modal.add_child(dim)
	
	popup_card = Control.new()
	popup_card.size = Vector2(980, 650)
	popup_card.pivot_offset = Vector2(490, 325)
	popup_modal.add_child(popup_card)
	
	var bg_panel = PanelContainer.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(22)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 6)
	sb.set_content_margin_all(14)
	bg_panel.add_theme_stylebox_override("panel", sb)
	popup_card.add_child(bg_panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	bg_panel.add_child(main_vbox)
	
	# 1. Top Tab Row with CloseButton
	var tab_row = HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	tab_row.add_theme_constant_override("separation", 10)
	main_vbox.add_child(tab_row)
	
	var tab_names = ["1. Pilih Balasan", "2. Tabel ARP", "3. Balik & Unicast"]
	tab_buttons.clear()
	for i in range(tab_names.size()):
		var tb = Button.new()
		tb.text = tab_names[i]
		tb.custom_minimum_size = Vector2(130, 36)
		tb.add_theme_font_override("font", font_black)
		tb.add_theme_font_size_override("font_size", 12)
		tb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_style_tab_btn(tb, false, false)
		var t_idx = i + 1
		tb.pressed.connect(func(): _switch_tahap(t_idx))
		tab_row.add_child(tb)
		tab_buttons.append(tb)
		
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_row.add_child(spacer)
	
	var close_btn = CloseButtonScene.instantiate()
	close_btn.closed.connect(_close_popup_2_3)
	tab_row.add_child(close_btn)
	
	# 2. Fixed Topology Diagram Card (Figma Images 3, 4, 5)
	var topo_card = PanelContainer.new()
	var sb_topo = StyleBoxFlat.new()
	sb_topo.bg_color = Color("#ffffff")
	sb_topo.border_color = Color("#4a2e2b")
	sb_topo.set_border_width_all(2.5)
	sb_topo.set_corner_radius_all(14)
	sb_topo.set_content_margin_all(10)
	topo_card.add_theme_stylebox_override("panel", sb_topo)
	main_vbox.add_child(topo_card)
	
	var topo_hbox = HBoxContainer.new()
	topo_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	topo_hbox.add_theme_constant_override("separation", 16)
	topo_card.add_child(topo_hbox)
	
	# Left: PC 1 (Pengirim)
	var pc1_card = _create_topo_card("PC 1 (Pengirim)\n192.168.1.10", Color("#fed0cf"), Color("#4a2e2b"))
	topo_hbox.add_child(pc1_card)
	
	var p1_cable = Control.new()
	p1_cable.custom_minimum_size = Vector2(70, 90)
	p1_cable.draw.connect(func():
		var y = p1_cable.size.y * 0.35
		_draw_cable_double_line(p1_cable, Vector2(0, y), Vector2(p1_cable.size.x, y))
	)
	topo_hbox.add_child(p1_cable)
	
	# Center: Switch & Router Box
	var sw_outer = PanelContainer.new()
	var sb_swo = StyleBoxFlat.new()
	sb_swo.bg_color = Color("#fed7aa")
	sb_swo.border_color = Color("#4a2e2b")
	sb_swo.set_border_width_all(2)
	sb_swo.set_corner_radius_all(14)
	sb_swo.set_content_margin_all(8)
	sw_outer.add_theme_stylebox_override("panel", sb_swo)
	topo_hbox.add_child(sw_outer)
	
	var sw_vb = VBoxContainer.new()
	sw_vb.add_theme_constant_override("separation", 6)
	sw_outer.add_child(sw_vb)
	
	var sw_inner = _create_topo_card("SWITCH", Color("#dbeafe"), Color("#1e40af"))
	sw_inner.custom_minimum_size = Vector2(110, 36)
	sw_vb.add_child(sw_inner)
	
	var rt_inner = _create_topo_card("ROUTER\nPort 5 • WAN", Color("#99f6e4"), Color("#0f766e"))
	rt_inner.custom_minimum_size = Vector2(110, 36)
	sw_vb.add_child(rt_inner)
	
	# Branch Cables from Switch to Right Ports
	var branch_cables = Control.new()
	branch_cables.custom_minimum_size = Vector2(150, 110)
	branch_cables.draw.connect(func():
		var sz = branch_cables.size
		var origin = Vector2(0, sz.y * 0.35)
		var p2_end = Vector2(sz.x, sz.y * 0.16)
		var p3_end = Vector2(sz.x, sz.y * 0.50)
		var p4_end = Vector2(sz.x, sz.y * 0.84)
		_draw_cable_double_line(branch_cables, origin, p2_end)
		_draw_cable_double_line(branch_cables, origin, p3_end)
		_draw_cable_double_line(branch_cables, origin, p4_end)
	)
	topo_hbox.add_child(branch_cables)
	
	topo_envelope_icon = TextureRect.new()
	topo_envelope_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	topo_envelope_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	topo_envelope_icon.texture = tex_envelope
	topo_envelope_icon.custom_minimum_size = Vector2(36, 26)
	topo_envelope_icon.size = Vector2(36, 26)
	topo_envelope_icon.position = Vector2(100, 42)
	topo_envelope_icon.visible = false
	branch_cables.add_child(topo_envelope_icon)
	
	# Right: Ports & Target PCs
	var right_ports_vb = VBoxContainer.new()
	right_ports_vb.add_theme_constant_override("separation", 4)
	topo_hbox.add_child(right_ports_vb)
	
	var p2_box = _create_topo_card("Port 2 • PC 2\n192.168.1.12", Color("#ffffff"), Color("#4a2e2b"))
	right_ports_vb.add_child(p2_box)
	
	var p3_box = _create_topo_card("Port 3 • PC 3\n192.168.1.50", Color("#ffffff"), Color("#4a2e2b"))
	right_ports_vb.add_child(p3_box)
	topo_p3_box = p3_box
	topo_p3_label = p3_box.get_child(0) as Label
	var nic_pill = _create_mini_pill("NIC: 00:1A:2B:3C:4D:5E", Color("#fef9c3"), Color("#854d0e"))
	right_ports_vb.add_child(nic_pill)
	
	var p4_box = _create_topo_card("Port 4 • PC 4\n192.168.1.88", Color("#ffffff"), Color("#4a2e2b"))
	right_ports_vb.add_child(p4_box)
	
	# 3. Dynamic Status Pill
	tahap_status_panel = PanelContainer.new()
	var sb_stat = StyleBoxFlat.new()
	sb_stat.bg_color = Color("#eff6ff")
	sb_stat.border_color = Color("#4a2e2b")
	sb_stat.set_border_width_all(1.5)
	sb_stat.set_corner_radius_all(10)
	sb_stat.content_margin_left = 14
	sb_stat.content_margin_right = 14
	sb_stat.content_margin_top = 4
	sb_stat.content_margin_bottom = 4
	tahap_status_panel.add_theme_stylebox_override("panel", sb_stat)
	main_vbox.add_child(tahap_status_panel)
	
	tahap_status_label = Label.new()
	tahap_status_label.text = "Tahap 1/3 — Pilih ARP-Reply yang Benar\nPC 3 (192.168.1.50) membalas ARP-Request. Pilih balasan yang benar-benar berasal dari PC 3. Cocokkan dengan label NIC di samping PC 3!"
	tahap_status_label.add_theme_font_override("font", font_bold)
	tahap_status_label.add_theme_font_size_override("font_size", 10)
	tahap_status_label.add_theme_color_override("font_color", Color("#1e40af"))
	tahap_status_panel.add_child(tahap_status_label)
	
	# 4. Action Area (Switches content per Tahap)
	tahap_container = Control.new()
	tahap_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(tahap_container)
	
	_switch_tahap(1)

func _create_topo_card(text_content: String, bg_col: Color, border_col: Color) -> PanelContainer:
	var pan = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	pan.add_theme_stylebox_override("panel", sb)
	
	var lbl = Label.new()
	lbl.text = text_content
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", border_col)
	pan.add_child(lbl)
	return pan

func _style_tab_btn(btn: Button, is_active: bool, is_done: bool) -> void:
	var sb = StyleBoxFlat.new()
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(6)
	
	if is_active:
		sb.bg_color = Color("#fef08a") # Active yellow
	elif is_done:
		sb.bg_color = Color("#a7f3d0") # Done mint
	else:
		sb.bg_color = Color("#ffffff") # Unfinished white
		
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", Color("#1e293b"))

func _draw_cable_double_line(canvas: Control, from_pt: Vector2, to_pt: Vector2) -> void:
	canvas.draw_line(from_pt, to_pt, Color("#4a2e2b"), 6.0)
	canvas.draw_line(from_pt, to_pt, Color("#38bdf8"), 3.0)

func _switch_tahap(target_tahap: int) -> void:
	current_tahap = target_tahap
	
	# Update Tab Bar Visuals
	for i in range(tab_buttons.size()):
		var idx = i + 1
		var is_act = (idx == current_tahap)
		var is_don = (idx < current_tahap) or is_completed
		_style_tab_btn(tab_buttons[i], is_act, is_don)
		
	# Clear & Render Tahap Content
	for child in tahap_container.get_children():
		child.queue_free()
		
	if current_tahap == 1:
		if tahap_status_panel:
			tahap_status_panel.visible = true
		_render_tahap_1()
	elif current_tahap == 2:
		if tahap_status_panel:
			tahap_status_panel.visible = true
		_render_tahap_2()
	elif current_tahap == 3:
		if tahap_status_panel:
			tahap_status_panel.visible = true
		_render_tahap_3()
	elif current_tahap == 4:
		_render_success_view()

# --- DATA LEVEL 2.4 (ARP-REPLY & TABEL ARP) ---
const MAC_PC3 := "00:1A:2B:3C:4D:5E"
const MAC_PC2 := "00:1A:2B:AA:BB:12"
const MAC_FAKE := "00:1A:2B:99:88:77"
const MAC_BCAST := "FF:FF:FF:FF:FF:FF"
const REPLY_OPTIONS: Array = [
	{ "title": "Dari PC 3 • 192.168.1.50", "sub": "MAC: 00:1A:2B:3C:4D:5E • Balasan dari PC 3" },
	{ "title": "Dari PC 2 • 192.168.1.12", "sub": "MAC: 00:1A:2B:AA:BB:12 • Milik PC lain" },
	{ "title": "Dari PC 3 • 192.168.1.50", "sub": "MAC: 00:1A:2B:99:88:77 • MAC berbeda dari label NIC" },
	{ "title": "Dari 192.168.1.50", "sub": "MAC: FF:FF:FF:FF:FF:FF • Alamat Broadcast" },
]
const REPLY_WRONG_MSG: Array = [
	"",
	"❌ SALAH! Balasan itu berasal dari PC 2 (192.168.1.12), bukan dari pemilik IP 192.168.1.50.",
	"❌ SALAH! MAC pada balasan itu tidak cocok dengan label NIC PC 3 (00:1A:2B:3C:4D:5E).",
	"❌ SALAH! FF:FF:FF:FF:FF:FF adalah alamat Broadcast, bukan MAC milik PC 3. ARP-Reply dikirim Unicast!",
]
const IP_OPTIONS: Array = ["192.168.1.12", "192.168.1.50", "192.168.1.88"]
const MAC_OPTIONS: Array = ["00:1A:2B:3C:4D:5E", "00:1A:2B:AA:BB:12", "00:1A:2B:99:88:77", "FF:FF:FF:FF:FF:FF"]
const ROUTE_OPTIONS: Array = [
	{ "title": "PC 3 → Switch (Port 3) → PC 1 (Port 1)", "sub": "Balasan Unicast langsung ke pengirim" },
	{ "title": "PC 3 → Switch → PC 2 (Port 2)", "sub": "Ke komputer lain" },
	{ "title": "PC 3 → Switch → Router (Port 5)", "sub": "Keluar jaringan lokal" },
]
const TEST_MAC_OPTIONS: Array = [
	{ "title": "00:1A:2B:3C:4D:5E", "sub": "MAC PC 3 (dari Tabel ARP)" },
	{ "title": "FF:FF:FF:FF:FF:FF", "sub": "Broadcast" },
	{ "title": "00:1A:2B:AA:BB:12", "sub": "MAC PC 2" },
]

var sel_reply: int = -1
var sel_ip: String = ""
var sel_mac: String = ""
var sel_route: int = -1
var sel_test_mac: int = -1
var arp_saved: bool = false
var choice_btns: Dictionary = {}
var arp_val_ip: Label
var arp_val_mac: Label

# --- HELPER UI POPUP 2.4 ---
func _new_tahap_card() -> VBoxContainer:
	var card_panel = PanelContainer.new()
	card_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(12)
	card_panel.add_theme_stylebox_override("panel", sb)
	tahap_container.add_child(card_panel)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card_panel.add_child(vb)
	return vb

func _set_status(msg: String, ok: bool) -> void:
	tahap_status_label.text = msg
	var sb_stat = tahap_status_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if ok:
		sb_stat.bg_color = Color("#a7f3d0")
		sb_stat.border_color = Color("#4a2e2b")
		tahap_status_label.add_theme_color_override("font_color", Color("#1e293b"))
	else:
		sb_stat.bg_color = Color("#eff6ff")
		sb_stat.border_color = Color("#3b82f6")
		tahap_status_label.add_theme_color_override("font_color", Color("#1e40af"))

func _heading(txt: String) -> Label:
	var l = Label.new()
	l.text = txt
	l.add_theme_font_override("font", font_black)
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color("#1e293b"))
	return l

# Tombol pilihan dengan judul + sub (sub boleh kosong)
func _choice_btn(title: String, sub: String, h: float) -> Button:
	var b = Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(120, h)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 10
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 0)
	b.add_child(vb)
	var t = Label.new()
	t.text = title
	t.add_theme_font_override("font", font_black)
	t.add_theme_font_size_override("font_size", 11)
	t.add_theme_color_override("font_color", Color("#1e293b"))
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(t)
	if sub != "":
		var s = Label.new()
		s.text = sub
		s.add_theme_font_override("font", font_semibold)
		s.add_theme_font_size_override("font_size", 9)
		s.add_theme_color_override("font_color", Color("#64748b"))
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(s)
	_style_choice_btn(b, false)
	return b

func _style_choice_btn(btn: Button, is_sel: bool) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#eff6ff") if is_sel else Color("#ffffff")
	sb.border_color = Color("#2563eb") if is_sel else Color("#4a2e2b")
	sb.set_border_width_all(3 if is_sel else 2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

# Registrasi grup tombol pilihan: group = nama grup, pilihan satu per grup
func _register_choice(group: String, idx: int, btn: Button) -> void:
	if not choice_btns.has(group):
		choice_btns[group] = {}
	choice_btns[group][idx] = btn

func _refresh_choice_group(group: String, selected: int) -> void:
	if not choice_btns.has(group):
		return
	for k in choice_btns[group].keys():
		var b = choice_btns[group][k]
		if is_instance_valid(b):
			_style_choice_btn(b, k == selected)

func _build_arp_table(parent: Control, ip_txt: String, mac_txt: String, filled: bool) -> void:
	var tbl = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(0)
	tbl.add_theme_stylebox_override("panel", sb)
	parent.add_child(tbl)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	tbl.add_child(vb)
	var rows = [["TABEL ARP PC 1", "#93c5fd", ""], ["IP ADDRESS|MAC ADDRESS", "#dbeafe", ""], ["data", "#a7f3d0" if filled else "#fef9c3", ""]]
	for r in rows:
		var pan = PanelContainer.new()
		var sbr = StyleBoxFlat.new()
		sbr.bg_color = Color(r[1])
		sbr.content_margin_left = 12
		sbr.content_margin_right = 12
		sbr.content_margin_top = 3
		sbr.content_margin_bottom = 3
		pan.add_theme_stylebox_override("panel", sbr)
		vb.add_child(pan)
		if r[0] == "data":
			var hb = HBoxContainer.new()
			pan.add_child(hb)
			arp_val_ip = Label.new()
			arp_val_ip.text = ip_txt
			arp_val_ip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			arp_val_ip.add_theme_font_override("font", font_extrabold)
			arp_val_ip.add_theme_font_size_override("font_size", 11)
			arp_val_ip.add_theme_color_override("font_color", Color("#1e293b"))
			hb.add_child(arp_val_ip)
			arp_val_mac = Label.new()
			arp_val_mac.text = mac_txt
			arp_val_mac.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			arp_val_mac.add_theme_font_override("font", font_extrabold)
			arp_val_mac.add_theme_font_size_override("font_size", 11)
			arp_val_mac.add_theme_color_override("font_color", Color("#1e293b"))
			hb.add_child(arp_val_mac)
		elif "|" in r[0]:
			var hb2 = HBoxContainer.new()
			pan.add_child(hb2)
			for part in r[0].split("|"):
				var lbl = Label.new()
				lbl.text = part
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.add_theme_font_override("font", font_black)
				lbl.add_theme_font_size_override("font_size", 9)
				lbl.add_theme_color_override("font_color", Color("#1e3a8a"))
				hb2.add_child(lbl)
		else:
			var lbl2 = Label.new()
			lbl2.text = r[0]
			lbl2.add_theme_font_override("font", font_black)
			lbl2.add_theme_font_size_override("font_size", 9)
			lbl2.add_theme_color_override("font_color", Color("#1e3a8a"))
			pan.add_child(lbl2)

func _column_box(title_txt: String) -> VBoxContainer:
	var pan = PanelContainer.new()
	pan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#faf7f0")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	pan.add_theme_stylebox_override("panel", sb)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	pan.add_child(vb)
	var t = Label.new()
	t.text = title_txt
	t.add_theme_font_override("font", font_black)
	t.add_theme_font_size_override("font_size", 10)
	t.add_theme_color_override("font_color", Color("#1e293b"))
	vb.add_child(t)
	vb.set_meta("panel", pan)
	return vb

# --- TAHAP 4: LEVEL 2.4 SELESAI / SUCCESS VIEW (FIGMA) ---
func _render_success_view() -> void:
	current_tahap = 4
	is_completed = true
	for tb in tab_buttons:
		_style_tab_btn(tb, false, true)
	if topo_p3_box:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color("#a8e6cf")
		sb.border_color = Color("#4a2e2b")
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		topo_p3_box.add_theme_stylebox_override("panel", sb)
	if topo_p3_label:
		topo_p3_label.add_theme_color_override("font_color", Color("#1e293b"))
	if tahap_status_panel:
		tahap_status_panel.visible = false

	var success_vb = VBoxContainer.new()
	success_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	success_vb.add_theme_constant_override("separation", 8)
	tahap_container.add_child(success_vb)

	var ban1 = PanelContainer.new()
	var sb1 = StyleBoxFlat.new()
	sb1.bg_color = Color("#a8e6cf")
	sb1.border_color = Color("#4a2e2b")
	sb1.set_border_width_all(2.0)
	sb1.set_corner_radius_all(14)
	sb1.content_margin_left = 16
	sb1.content_margin_right = 16
	sb1.content_margin_top = 8
	sb1.content_margin_bottom = 8
	ban1.add_theme_stylebox_override("panel", sb1)
	success_vb.add_child(ban1)
	var vb1 = VBoxContainer.new()
	vb1.add_theme_constant_override("separation", 3)
	ban1.add_child(vb1)
	var t1 = Label.new()
	t1.text = "Level 2.4 Selesai! Jalur berubah hijau (UP)"
	t1.add_theme_font_override("font", font_black)
	t1.add_theme_font_size_override("font_size", 12)
	t1.add_theme_color_override("font_color", Color("#1e293b"))
	vb1.add_child(t1)
	var d1 = Label.new()
	d1.text = "ARP-Reply kembali ke PC 1, MAC PC 3 tersimpan di Tabel ARP, dan frame Unicast ke 00:1A:2B:3C:4D:5E berhasil — koneksi aktif!"
	d1.add_theme_font_override("font", font_semibold)
	d1.add_theme_font_size_override("font_size", 10)
	d1.add_theme_color_override("font_color", Color("#334155"))
	d1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb1.add_child(d1)

	var ban2 = PanelContainer.new()
	var sb2 = StyleBoxFlat.new()
	sb2.bg_color = Color("#a8e6cf")
	sb2.border_color = Color("#4a2e2b")
	sb2.set_border_width_all(2.0)
	sb2.set_corner_radius_all(14)
	sb2.content_margin_left = 16
	sb2.content_margin_right = 16
	sb2.content_margin_top = 8
	sb2.content_margin_bottom = 8
	ban2.add_theme_stylebox_override("panel", sb2)
	success_vb.add_child(ban2)
	var vb2 = VBoxContainer.new()
	vb2.add_theme_constant_override("separation", 5)
	ban2.add_child(vb2)
	var t2 = Label.new()
	t2.text = "Level 2.4 Selesai! Jalur PC 1 ↔ PC 3 kini hijau (UP)."
	t2.add_theme_font_override("font", font_black)
	t2.add_theme_font_size_override("font_size", 13)
	t2.add_theme_color_override("font_color", Color("#1e293b"))
	vb2.add_child(t2)
	_build_arp_table(vb2, "192.168.1.50", MAC_PC3, true)
	var d2 = Label.new()
	var score_val = max(0, 100 - error_count * 10)
	d2.text = "ARP-Reply membawa MAC Address PC 3, disimpan di Tabel ARP, lalu dipakai untuk mengirim frame Unicast. Skor: %d/100 • Kesalahan: %dx" % [score_val, error_count]
	d2.add_theme_font_override("font", font_semibold)
	d2.add_theme_font_size_override("font_size", 10)
	d2.add_theme_color_override("font_color", Color("#334155"))
	d2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb2.add_child(d2)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	success_vb.add_child(btn_row)
	var next_btn = Button.new()
	next_btn.text = "Lanjut ke Stage 3"
	next_btn.custom_minimum_size = Vector2(180, 36)
	_style_action_btn(next_btn, Color("#a7f3d0"), Color("#059669"), Color("#065f46"))
	next_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/gameplay/level_3_1.tscn")
	)
	btn_row.add_child(next_btn)
	var map_btn = Button.new()
	map_btn.text = "Kembali ke Map"
	map_btn.custom_minimum_size = Vector2(140, 36)
	_style_action_btn(map_btn, Color("#e0f2fe"), Color("#0284c7"), Color("#0369a1"))
	map_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/level_path.tscn")
	)
	btn_row.add_child(map_btn)

# --- TAHAP 1: PILIH ARP-REPLY YANG BENAR (FIGMA) ---
func _render_tahap_1() -> void:
	_set_status("Tahap 1/3 — Pilih ARP-Reply yang Benar\nPC 3 (192.168.1.50) membalas ARP-Request. Pilih balasan yang benar-benar berasal dari PC 3. Cocokkan dengan label NIC di samping PC 3!", false)
	choice_btns.clear()
	var vb = _new_tahap_card()
	vb.add_child(_heading("1. Pilih ARP-Reply yang Benar-benar dari PC 3"))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(grid)
	for i in range(REPLY_OPTIONS.size()):
		var idx = i
		var b = _choice_btn(REPLY_OPTIONS[i]["title"], REPLY_OPTIONS[i]["sub"], 54)
		b.pressed.connect(func():
			sel_reply = idx
			_refresh_choice_group("reply", sel_reply)
		)
		grid.add_child(b)
		_register_choice("reply", i, b)
	_refresh_choice_group("reply", sel_reply)
	var bot_h = HBoxContainer.new()
	bot_h.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(bot_h)
	var check_btn = Button.new()
	check_btn.text = "Periksa Balasan"
	check_btn.custom_minimum_size = Vector2(160, 38)
	_style_action_btn(check_btn, Color("#a7f3d0"), Color("#059669"), Color("#065f46"))
	check_btn.pressed.connect(_validate_tahap_1)
	bot_h.add_child(check_btn)

func _validate_tahap_1() -> void:
	if sel_reply < 0:
		show_toast("Pilihlah salah satu ARP-Reply terlebih dahulu!", 2.0)
		return
	if sel_reply == 0:
		_play_chime_sound()
		show_toast("✓ TEPAT! Balasan sah dari PC 3 — MAC cocok dengan label NIC.", 2.2)
		_switch_tahap(2)
	else:
		_handle_penalty(REPLY_WRONG_MSG[sel_reply])

# --- TAHAP 2: SIMPAN KE TABEL ARP (FIGMA) ---
func _render_tahap_2() -> void:
	_set_status("Tahap 1 benar — balasan sah dari PC 3\nBalasan datang dari 192.168.1.50 dan MAC-nya cocok dengan NIC PC 3. Sekarang simpan pasangannya di Tabel ARP PC 1.", true)
	choice_btns.clear()
	var vb = _new_tahap_card()
	vb.add_theme_constant_override("separation", 6)
	vb.add_child(_heading("2. Simpan Pasangan IP ↔ MAC ke Tabel ARP PC 1"))
	_build_arp_table(vb, sel_ip if sel_ip != "" else "–", sel_mac if sel_mac != "" else "–", false)

	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(cols)
	var ca = _column_box("A. IP Address")
	cols.add_child(ca.get_meta("panel"))
	for i in range(IP_OPTIONS.size()):
		var val = IP_OPTIONS[i]
		var idx = i
		var b = _choice_btn(val, "", 28)
		b.pressed.connect(func():
			sel_ip = val
			arp_val_ip.text = val
			_refresh_choice_group("ip", idx)
		)
		ca.add_child(b)
		_register_choice("ip", i, b)
	var cb = _column_box("B. MAC Address")
	cols.add_child(cb.get_meta("panel"))
	for j in range(MAC_OPTIONS.size()):
		var val2 = MAC_OPTIONS[j]
		var idx2 = j
		var b2 = _choice_btn(val2, "", 28)
		b2.pressed.connect(func():
			sel_mac = val2
			arp_val_mac.text = val2
			_refresh_choice_group("mac", idx2)
		)
		cb.add_child(b2)
		_register_choice("mac", j, b2)
	_refresh_choice_group("ip", IP_OPTIONS.find(sel_ip))
	_refresh_choice_group("mac", MAC_OPTIONS.find(sel_mac))

	var bot_h = HBoxContainer.new()
	vb.add_child(bot_h)
	var back_btn = Button.new()
	back_btn.text = "Tahap 1"
	back_btn.custom_minimum_size = Vector2(100, 34)
	_style_action_btn(back_btn, Color("#ffffff"), Color("#4a2e2b"), Color("#1e293b"))
	back_btn.pressed.connect(func(): _switch_tahap(1))
	bot_h.add_child(back_btn)
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_h.add_child(sp)
	var save_btn = Button.new()
	save_btn.text = "Simpan ke Tabel ARP"
	save_btn.custom_minimum_size = Vector2(190, 34)
	_style_action_btn(save_btn, Color("#a7f3d0"), Color("#059669"), Color("#065f46"))
	save_btn.pressed.connect(_validate_tahap_2)
	bot_h.add_child(save_btn)

func _validate_tahap_2() -> void:
	if sel_ip == "" or sel_mac == "":
		show_toast("Pilih IP Address (A) dan MAC Address (B) terlebih dahulu!", 2.0)
		return
	if sel_ip == "192.168.1.50" and sel_mac == MAC_PC3:
		arp_saved = true
		_play_chime_sound()
		show_toast("✓ Tabel ARP PC 1 tersimpan: 192.168.1.50 = 00:1A:2B:3C:4D:5E", 2.4)
		_switch_tahap(3)
	elif sel_ip != "192.168.1.50":
		_handle_penalty("❌ SALAH! Yang dicari adalah IP 192.168.1.50 (milik PC 3), bukan %s." % sel_ip)
	else:
		_handle_penalty("❌ SALAH! MAC pasangan IP 192.168.1.50 harus sama dengan label NIC PC 3 (00:1A:2B:3C:4D:5E).")

# --- TAHAP 3: KAWAL BALASAN & UJI UNICAST (FIGMA) ---
func _render_tahap_3() -> void:
	_set_status("Tahap 2 benar — Tabel ARP PC 1 tersimpan\nSekarang PC 1 ingat: 192.168.1.50 = 00:1A:2B:3C:4D:5E, jadi tidak perlu bertanya lagi.", true)
	choice_btns.clear()
	var vb = _new_tahap_card()
	vb.add_theme_constant_override("separation", 6)
	vb.add_child(_heading("3. Kawal Balasan ke PC 1 & Uji Kirim Unicast"))
	_build_arp_table(vb, "192.168.1.50", MAC_PC3, true)

	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(cols)
	var ca = _column_box("A. Jalur Balik ARP-Reply")
	cols.add_child(ca.get_meta("panel"))
	for i in range(ROUTE_OPTIONS.size()):
		var idx = i
		var b = _choice_btn(ROUTE_OPTIONS[i]["title"], ROUTE_OPTIONS[i]["sub"], 40)
		b.pressed.connect(func():
			sel_route = idx
			_refresh_choice_group("route", idx)
		)
		ca.add_child(b)
		_register_choice("route", i, b)
	var cb = _column_box("B. MAC Tujuan Frame Uji (PC 1 → PC 3)")
	cols.add_child(cb.get_meta("panel"))
	for j in range(TEST_MAC_OPTIONS.size()):
		var idx2 = j
		var b2 = _choice_btn(TEST_MAC_OPTIONS[j]["title"], TEST_MAC_OPTIONS[j]["sub"], 40)
		b2.pressed.connect(func():
			sel_test_mac = idx2
			_refresh_choice_group("testmac", idx2)
		)
		cb.add_child(b2)
		_register_choice("testmac", j, b2)
	_refresh_choice_group("route", sel_route)
	_refresh_choice_group("testmac", sel_test_mac)

	var bot_h = HBoxContainer.new()
	vb.add_child(bot_h)
	var back_btn = Button.new()
	back_btn.text = "Tahap 2"
	back_btn.custom_minimum_size = Vector2(100, 34)
	_style_action_btn(back_btn, Color("#ffffff"), Color("#4a2e2b"), Color("#1e293b"))
	back_btn.pressed.connect(func(): _switch_tahap(2))
	bot_h.add_child(back_btn)
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_h.add_child(sp)
	var send_btn = Button.new()
	send_btn.text = "Kirim & Uji Frame Unicast"
	send_btn.custom_minimum_size = Vector2(220, 34)
	_style_action_btn(send_btn, Color("#a7f3d0"), Color("#059669"), Color("#065f46"))
	send_btn.pressed.connect(_validate_tahap_3)
	bot_h.add_child(send_btn)

func _validate_tahap_3() -> void:
	if sel_route < 0 or sel_test_mac < 0:
		show_toast("Pilih Jalur Balik (A) dan MAC Tujuan Frame Uji (B) terlebih dahulu!", 2.0)
		return
	if sel_route != 0:
		_handle_penalty("❌ SALAH! ARP-Reply dikirim Unicast langsung ke pengirim (PC 1 di Port 1), bukan ke PC lain atau Router.")
		return
	if sel_test_mac != 0:
		_handle_penalty("❌ SALAH! Frame uji ke PC 3 harus memakai MAC dari Tabel ARP (00:1A:2B:3C:4D:5E), bukan Broadcast atau MAC PC lain.")
		return
	_play_chime_sound()
	_close_popup_2_3()
	_start_in_room_reply_animation()

func _style_action_btn(btn: Button, bg_col: Color, border_col: Color, text_col: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_font_override("font", font_black)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", text_col)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_setup_hover_scale(btn, 1.05)

func _open_popup_2_3() -> void:
	if is_animating_broadcast:
		return
	if is_completed:
		_switch_tahap(4)
	is_modal_open = true
	popup_modal.visible = true
	
	var vp_sz = get_viewport_rect().size
	popup_card.position = (vp_sz - popup_card.size) / 2.0
	popup_card.scale = Vector2(0.85, 0.85)
	popup_card.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(popup_card, "scale", Vector2.ONE, 0.22)
	tw.tween_property(popup_card, "modulate:a", 1.0, 0.20)
	_play_chime_sound()

func _close_popup_2_3() -> void:
	if not popup_modal or not popup_modal.visible:
		return
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(popup_card, "scale", Vector2(0.85, 0.85), 0.18)
	tw.tween_property(popup_card, "modulate:a", 0.0, 0.16)
	await tw.finished
	popup_modal.visible = false
	is_modal_open = false
	if is_completed:
		get_tree().change_scene_to_file("res://scenes/level_path.tscn")

# --- ANIMASI ARP-REPLY (UNICAST) DI DALAM RUANGAN ---
func _start_in_room_reply_animation() -> void:
	is_animating_broadcast = true
	show_toast("PC 3 membalas ARP-Request dengan ARP-Reply (Unicast) berisi MAC-nya...", 2.2)

	_show_pc_response(pc3_desk, "BALASAN ARP-REPLY (UNICAST)\nMAC: 00:1A:2B:3C:4D:5E", Color("#10b981"))
	var r3 = pc3_desk.get_global_rect()
	var cd_rect = center_desk.get_global_rect()
	var r1 = pc1_desk.get_global_rect()
	var p3_pos = Vector2(r3.position.x, r3.position.y + 20.0)
	var sw_pos = Vector2(cd_rect.position.x + cd_rect.size.x * 0.65, cd_rect.position.y + 30.0)
	var p1_pos = Vector2(r1.position.x + r1.size.x * 0.5, r1.position.y)

	# 1. Amplop ARP-Reply terbang PC 3 -> Switch
	var env = _create_flying_envelope(p3_pos)
	var tw1 = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw1.tween_property(env, "global_position", sw_pos, 1.3)
	await tw1.finished
	_play_chime_sound()

	var tw_sw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_sw.tween_property(center_switch, "scale", Vector2(1.2, 1.2), 0.15)
	tw_sw.tween_property(center_switch, "scale", Vector2.ONE, 0.15)
	show_toast("Switch meneruskan ARP-Reply hanya ke Port 1 (PC 1) — Unicast!", 2.2)

	# 2. Switch -> PC 1 (hanya satu tujuan: Unicast)
	var tw2 = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw2.tween_property(env, "global_position", p1_pos, 1.3)
	await tw2.finished
	env.queue_free()

	# 3. PC 1 menyimpan ke Tabel ARP
	_play_chime_sound()
	_show_pc_response(pc1_desk, "✓ ARP-Reply diterima\nTabel ARP: .50 = 00:1A:..:5E", Color("#10b981"))
	_set_pc1_bubble("🟢 JALUR UP (LINK UP)\nTabel ARP PC 1 tersimpan", Color("#16a34a"))
	if pc3_star_badge:
		var tw_star = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_star.tween_property(pc3_star_badge, "scale", Vector2(1.8, 1.8), 0.3)
		tw_star.tween_property(pc3_star_badge, "scale", Vector2.ONE, 0.2)
	await get_tree().create_timer(1.8).timeout
	is_animating_broadcast = false
	_trigger_win()

func _set_pc1_bubble(txt: String, col: Color) -> void:
	if not pc1_bubble:
		return
	var lbl = pc1_bubble.get_node_or_null("PC1BubbleLabel") as Label
	if lbl:
		lbl.text = txt
		lbl.add_theme_color_override("font_color", col)
	var sb = pc1_bubble.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		sb.border_color = col

func _create_flying_envelope(start_pos: Vector2) -> TextureRect:
	var tr = TextureRect.new()
	# expand_mode HARUS diset sebelum texture & size, kalau tidak ukuran tertahan ukuran asli gambar (kebesaran)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture = tex_envelope
	tr.custom_minimum_size = Vector2(60, 42)
	tr.size = Vector2(60, 42)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.global_position = start_pos
	tr.z_index = 80
	add_child(tr)
	return tr

func _show_pc_response(desk: Control, msg: String, border_col: Color) -> void:
	var pill = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(6)
	pill.add_theme_stylebox_override("panel", sb)
	
	var lbl = Label.new()
	lbl.text = msg
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_extrabold)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", border_col)
	pill.add_child(lbl)
	
	pill.position = Vector2(10, -55)
	desk.add_child(pill)
	
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pill.scale = Vector2(0.3, 0.3)
	tw.tween_property(pill, "scale", Vector2.ONE, 0.2)

# --- PENALTY & GAME DIALOGS ---
func _handle_penalty(err_msg: String) -> void:
	error_count += 1
	_play_buzz_error()
	_shake_screen()
	hearts = max(0, hearts - 1)
	_update_hearts_display(true)
	show_toast(err_msg, 3.5)
	
	if hearts <= 0:
		is_game_active = false
		_close_popup_2_3()
		_trigger_game_over("Nyawa teknisi habis! Pelajari kembali mekanisme ARP-Reply (Unicast) & Tabel ARP.")

func _update_hearts_display(is_damage: bool = false) -> void:
	HeartsStyle.refresh(hearts_rects, hearts)

func _shake_screen() -> void:
	var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in range(4):
		tw.tween_property(self, "position", Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0)), 0.04)
	tw.tween_property(self, "position", Vector2.ZERO, 0.05)

func _trigger_win() -> void:
	is_game_active = false
	is_completed = true
	_play_win_fanfare()
	
	var stars = 1
	if error_count == 0 and time_remaining >= 45.0:
		stars = 3
	elif error_count <= 1:
		stars = 2
		
	if Engine.has_singleton("PlayerData") or ResourceLoader.exists("res://scripts/player_data.gd"):
		if PlayerData:
			PlayerData.set_level_stars(2, 4, stars)
			
	# Tampilkan Pop up 2.3 dalam Tampilan Selesai (Sesuai Desain Figma Screenshot)
	_switch_tahap(4)
	_open_popup_2_3()

func _trigger_game_over(reason: String) -> void:
	is_game_active = false
	is_modal_open = true
	_play_buzz_error()
	
	if not game_dialog:
		game_dialog = GameDialogScene.instantiate()
		add_child(game_dialog)
		
	var act_retry = func():
		get_tree().reload_current_scene()
	var act_map = func():
		get_tree().change_scene_to_file("res://scenes/level_path.tscn")
		
	game_dialog.show_game_over(reason, act_retry, act_map)

# --- TOAST UI ---
func _build_toast_ui() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.name = "ToastPanel"
	toast_panel.z_index = 300
	toast_panel.visible = false
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.16, 0.23, 0.92)
	sb.border_color = Color("#38bdf8")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(10)
	toast_panel.add_theme_stylebox_override("panel", sb)
	add_child(toast_panel)
	
	toast_label = Label.new()
	toast_label.add_theme_font_override("font", font_bold)
	toast_label.add_theme_font_size_override("font_size", 12)
	toast_label.add_theme_color_override("font_color", Color.WHITE)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_panel.add_child(toast_label)

func show_toast(msg: String, duration: float = 2.5) -> void:
	if not toast_panel or not toast_label:
		return
	toast_label.text = msg
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	
	var vp_sz = get_viewport_rect().size
	var t_sz = toast_panel.get_minimum_size()
	toast_panel.size = t_sz
	toast_panel.position = Vector2((vp_sz.x - t_sz.x) / 2.0, vp_sz.y - 100.0)
	
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.15)
	toast_tween.tween_interval(duration)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.25)
	toast_tween.tween_callback(func(): toast_panel.visible = false)

# --- RESPONSIVE REPOSITIONING ---
func _reposition_responsive() -> void:
	var vp_sz = get_viewport_rect().size
	var center_x = vp_sz.x / 2.0
	
	if door_arch:
		door_arch.position = Vector2(center_x - 160.0, 45.0)
		door_arch.size = Vector2(320.0, 200.0)
		
	if potted_plant:
		potted_plant.position = Vector2(center_x + 180.0, 75.0)
		potted_plant.size = Vector2(100.0, 170.0)
		
	if wall_clock:
		wall_clock.position = Vector2(center_x + 295.0, 105.0)
		wall_clock.size = Vector2(50.0, 50.0)
		
	if whiteboard_node:
		whiteboard_node.position = Vector2(center_x - 390.0, 95.0)
		whiteboard_node.size = Vector2(200.0, 110.0)
		
	if left_rack_cabinet:
		left_rack_cabinet.position = Vector2(clamp(center_x - 590.0, 20.0, 70.0), 200.0)
		left_rack_cabinet.size = Vector2(260.0, 360.0)
		
	if pc1_desk:
		pc1_desk.position = Vector2(clamp(center_x - 350.0, 345.0, 400.0), clamp(vp_sz.y * 0.58, 430.0, 480.0))
		
	if center_desk:
		var desk_w = 260.0
		var desk_h = 135.0
		center_desk.size = Vector2(desk_w, desk_h)
		center_desk.position = Vector2(center_x - desk_w / 2.0 + 30.0, clamp(vp_sz.y * 0.56, 420.0, 470.0))
		
	var right_x = clamp(center_x + 280.0, vp_sz.x - 340.0, vp_sz.x - 220.0)
	if pc2_desk:
		pc2_desk.position = Vector2(right_x, clamp(vp_sz.y * 0.38, 290.0, 340.0))
	if pc3_desk:
		pc3_desk.position = Vector2(right_x, clamp(vp_sz.y * 0.56, 430.0, 480.0))
	if pc4_desk:
		pc4_desk.position = Vector2(right_x, clamp(vp_sz.y * 0.74, 570.0, 620.0))
		
	if char_pos == Vector2.ZERO:
		char_pos = Vector2(center_x - 80.0, 300.0)
		character_node.position = char_pos
		
	if mobile_controls_root:
		var pad_base = mobile_controls_root.get_node_or_null("DpadBase") as Control
		if pad_base:
			pad_base.position = Vector2(40.0, vp_sz.y - 160.0)
			
	_position_header_elements()
	
	if cables_container:
		cables_container.queue_redraw()

# --- MOBILE CONTROLS ---
func _build_mobile_controls() -> void:
	mobile_controls_root = Control.new()
	mobile_controls_root.name = "MobileControls"
	mobile_controls_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	mobile_controls_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_controls_root.z_index = 50
	add_child(mobile_controls_root)
	
	var vp_sz = get_viewport_rect().size
	var pad_base = Control.new()
	pad_base.name = "DpadBase"
	pad_base.size = Vector2(130, 130)
	pad_base.position = Vector2(40.0, vp_sz.y - 160.0)
	pad_base.mouse_filter = Control.MOUSE_FILTER_STOP
	mobile_controls_root.add_child(pad_base)
	
	var base_tex = TextureRect.new()
	base_tex.texture = tex_dpad_base
	base_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	base_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad_base.add_child(base_tex)
	
	dpad_knob_sprite = TextureRect.new()
	dpad_knob_sprite.texture = tex_dpad_knob
	dpad_knob_sprite.size = Vector2(50, 50)
	dpad_knob_sprite.position = Vector2(40, 40)
	dpad_knob_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dpad_knob_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pad_base.add_child(dpad_knob_sprite)
	
	dpad_center = Vector2(65, 65)
	
	pad_base.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					dpad_touch_id = 99
					_update_dpad_knob(event.position)
				else:
					_reset_dpad()
		elif event is InputEventMouseMotion and dpad_touch_id == 99:
			_update_dpad_knob(event.position)
		elif event is InputEventScreenTouch:
			if event.pressed:
				dpad_touch_id = event.index
				_update_dpad_knob(event.position)
			elif event.index == dpad_touch_id:
				_reset_dpad()
		elif event is InputEventScreenDrag and event.index == dpad_touch_id:
			_update_dpad_knob(event.position)
	)

func _update_dpad_knob(touch_pos: Vector2) -> void:
	var delta = touch_pos - dpad_center
	var dist = delta.length()
	if dist > dpad_radius:
		delta = delta.normalized() * dpad_radius
	dpad_knob_sprite.position = dpad_center + delta - dpad_knob_sprite.size / 2.0
	input_dir = delta / dpad_radius

func _reset_dpad() -> void:
	dpad_touch_id = -1
	input_dir = Vector2.ZERO
	if dpad_knob_sprite:
		dpad_knob_sprite.position = dpad_center - dpad_knob_sprite.size / 2.0

# --- AUDIO & UTILITIES ---
func _play_footstep() -> void:
	if footstep_player:
		_play_tone_on_player(footstep_player, randf_range(160.0, 190.0), 0.05, 0.12)

func _play_chime_sound() -> void:
	if audio_player:
		_play_synth_sequence([523.25, 659.25, 783.99], 0.09)

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
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = step_time * freqs.size() + 0.1
	audio_player.stream = gen
	audio_player.play()
	
	var playback: AudioStreamGeneratorPlayback = audio_player.get_stream_playback()
	if not playback:
		return
		
	var frames_per_freq = int(sample_rate * step_time)
	for freq in freqs:
		var phase = 0.0
		var phase_inc = (float(freq) * 2.0 * PI) / sample_rate
		for i in range(frames_per_freq):
			var sample = sin(phase) * 0.25 * (1.0 - float(i) / frames_per_freq)
			playback.push_frame(Vector2(sample, sample))
			phase += phase_inc

func _setup_hover_scale(node: Control, scale_mult: float) -> void:
	node.mouse_entered.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector2(scale_mult, scale_mult), 0.12)
	)
	node.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector2.ONE, 0.12)
	)

func _create_mini_pill(text: String, bg_col: Color, text_col: Color) -> PanelContainer:
	var pan = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = text_col
	sb.set_border_width_all(1.5)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pan.add_theme_stylebox_override("panel", sb)
	
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_bold)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", text_col)
	pan.add_child(lbl)
	return pan

func _add_shelf_item(parent: Control, tex: Texture2D, pos: Vector2) -> void:
	var tr = TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = Vector2(40, 30)
	tr.position = pos
	parent.add_child(tr)

static func _safe_load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var global_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_path):
		var img = Image.load_from_file(global_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


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
		{ "title": "Misi Level 2.4", "text": "Pemilik IP 192.168.1.50 harus membalas dengan MAC Address-nya (ARP-Reply), lalu disimpan ke Tabel ARP." },
		{ "title": "1. Pemilik IP", "text": "PC 3 memegang IP yang dicari. Ia membalas dengan ARP-Reply berisi MAC Address-nya.", "target": pc3_desk, "pointer": "hand" },
		{ "title": "2. Kawal ARP-Reply", "text": "Dekati perangkat di tengah lalu klik tombol Kawal agar balasan ARP-Reply sampai ke PC pengirim.", "target": center_desk, "pointer": "both" },
		{ "title": "3. PC Pengirim", "text": "PC 1 menerima balasan lalu menyimpan MAC Address ke Tabel ARP (ARP Cache) supaya tidak perlu bertanya lagi.", "target": pc1_desk, "pointer": "arrow" },
		{ "title": "4. Papan Referensi", "text": "Papan ini membedakan ARP-Request (bertanya) dan ARP-Reply (menjawab).", "target": whiteboard_node, "pointer": "hand" },
		{ "title": "Siap?", "text": "Selesaikan misi sebelum waktu habis. Lupa caranya? Tekan tombol ? (kuning) di dekat pewaktu kapan saja untuk melihat panduan ini lagi." }
	]
