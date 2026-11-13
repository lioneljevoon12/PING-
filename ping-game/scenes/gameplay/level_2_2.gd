extends Control

# Level 2.2 - Konfigurasi Firewall Manual (IP Privat vs IP Publik)
# Sesuai Proposal & Desain Figma 100%:
# - RFC 1918 Private IP (10.x, 172.16-31.x, 192.168.x) -> ALLOW (LAN Aman)
# - Public IP (Eksternal WAN) -> BLOCK (Karantina / Tolak Akses)
# - Desain Ruang: Meja PC Satpam Jaringan, Maskot Perisai, Rak Trafik Masuk, Kabel Lantai
# - Lantai Kotak-Kotak (Grid Rounded Tiles) terlihat jelas di seluruh ruangan
# - Komponen reusable: PacketItem, FirewallBin, CloseButton, GameDialog, PauseModal

const IPClassifier = preload("res://scripts/ip_classifier.gd")
const PacketItemScene = preload("res://scenes/gameplay/packet_item.tscn")
const FirewallBinScene = preload("res://scenes/gameplay/firewall_bin.tscn")
const CloseButtonScene = preload("res://scenes/close_button.tscn")
const PauseModalScene = preload("res://scenes/pause_modal.tscn")
const GameDialogScene = preload("res://scenes/game_dialog.tscn")

const MOVE_SPEED = 240.0
const TOTAL_PACKETS = 6
const TIME_LIMIT = 165.0 # 02:45

# --- FONTS ---
var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_extrabold = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var font_semibold = preload("res://art/assets/PING! Assets/Fonts/Nunito-SemiBold.ttf")

# --- TEXTURES ---
var tex_char_idle = preload("res://art/assets/PING! Assets/Character/main-char-router.png")
var tex_frame_jam = preload("res://art/assets/PING! Assets/asset-gameplay/generals/frame-jam.png")
var tex_vector_heart = preload("res://art/assets/PING! Assets/asset-gameplay/generals/vector-hearts.png")
var tex_star_gold = preload("res://art/ui-ux/levelpath/star_gold.png")
var tex_star_gray = preload("res://art/ui-ux/levelpath/star_gray.png")

# Mobile Joystick (Style C)
var tex_dpad_base = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_pad_a.png")
var tex_dpad_knob = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_nub_a.png")

# Dynamic loaded textures
var tex_router_obj: Texture2D = null
var tex_cabinet: Texture2D = null
var tex_pc_operator: Texture2D = null
var tex_guardian: Texture2D = null
var tex_switch_icon: Texture2D = null
var tex_defense_icon: Texture2D = null

# Scene Node References
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer
@onready var background: TextureRect = %Background
@onready var door_arch: TextureRect = %DoorArch
@onready var potted_plant: TextureRect = %PottedPlant
@onready var left_rack_cabinet: TextureRect = %LeftRackCabinet
@onready var server_cabinet: TextureRect = %ServerCabinet
@onready var cables_container: Control = %CablesContainer
@onready var center_desk: Control = %CenterDesk
@onready var pc_node: TextureRect = %PCNode
@onready var center_mascot: TextureRect = %CenterMascot
@onready var filter_btn: Button = %FilterBtn
@onready var filter_alert_pill: PanelContainer = %FilterAlertPill
@onready var left_pad: Control = %LeftPad
@onready var right_pad: Control = %RightPad
@onready var whiteboard_node: Control = %WhiteboardNode
@onready var character_node: Control = %CharacterNode

# Character & Movement State
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
var filter_modal: Control
var filter_card: Control
var whiteboard_modal: Control
var pause_modal: Control
var game_dialog: Control

# Filter Modal Elements
var filter_queue_container: HBoxContainer
var bin_allow: Control
var bin_block: Control
var active_packets: Array[Control] = []
var selected_packet: Control = null

# Floor Pad Bins (Room view interactive bins)
var floor_pads_dict: Dictionary = {}

# Gameplay State
var is_game_active: bool = false
var is_modal_open: bool = false
var time_remaining: float = TIME_LIMIT
var hearts: int = 3
var packets_sorted_count: int = 0
var traffic_deck: Array[Dictionary] = []

func _ready() -> void:
	call_deferred("_setup_help_button")
	_load_dynamic_assets()
	_setup_character()
	_build_room_decorations()
	_build_mobile_controls()
	_build_header_ui()
	_build_intro_modal()
	_build_filter_modal()
	_build_toast_ui()
	
	# Responsif layout map ruangan
	_reposition_responsive()
	get_viewport().size_changed.connect(_reposition_responsive)
	
	# Siapkan deck trafik 6 paket seimbang
	traffic_deck = IPClassifier.generate_firewall_deck(TOTAL_PACKETS)
	
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
		_trigger_game_over("Waktu habis! Saring trafik jaringan lebih cepat agar server aman.")
		return
		
	# Movement & Animation
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
	if is_modal_open:
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
		
		# Uji independen X dan Y untuk sliding halus di pinggir rintangan (meja & rak)
		var test_x = char_pos.x + delta_mov.x
		if not _is_room_collision(Vector2(test_x, char_pos.y)):
			char_pos.x = test_x
			
		var test_y = char_pos.y + delta_mov.y
		if not _is_room_collision(Vector2(char_pos.x, test_y)):
			char_pos.y = test_y
			
		character_node.position = char_pos
		
		# Walk Sprite Flip & Frame Animation
		if char_sprite:
			if final_dir.x < -0.05:
				char_sprite.flip_h = true
			elif final_dir.x > 0.05:
				char_sprite.flip_h = false
				
			if walk_frames.size() > 0:
				walk_frame_index += delta * 14.0
				var frame_idx = int(walk_frame_index) % walk_frames.size()
				char_sprite.texture = walk_frames[frame_idx]
				
		# Footstep sound
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
		
	# 3. Rak Peralatan Kiri (Left Rack Cabinet)
	if left_rack_cabinet:
		var lr = left_rack_cabinet.get_global_rect()
		if feet_r > lr.position.x + 10.0 and feet_l < lr.position.x + lr.size.x - 10.0:
			if feet_b > lr.position.y + 80.0 and feet_t < lr.position.y + lr.size.y:
				return true
				
	# 4. Server Cabinet Kanan
	if server_cabinet:
		var sr = server_cabinet.get_global_rect()
		if feet_r > sr.position.x + 10.0 and feet_l < sr.position.x + sr.size.x - 10.0:
			if feet_b > sr.position.y + 80.0 and feet_t < sr.position.y + sr.size.y:
				return true
				
	# 5. Meja PC Satpam (Center Desk)
	if center_desk:
		var dr = center_desk.get_global_rect()
		if feet_r > dr.position.x + 20.0 and feet_l < dr.position.x + dr.size.x - 20.0:
			if feet_b > dr.position.y + 35.0 and feet_t < dr.position.y + dr.size.y - 10.0:
				return true
				
	return false

func _check_proximity() -> void:
	if not center_desk or not filter_alert_pill:
		return
		
	var desk_rect = center_desk.get_global_rect()
	var char_center = char_pos + Vector2(110.0, 60.0)
	var desk_center = desk_rect.position + desk_rect.size / 2.0
	var dist = char_center.distance_to(desk_center)
	
	var is_near = (dist < 250.0)
	if filter_alert_pill.visible != is_near:
		filter_alert_pill.visible = is_near
		if is_near:
			var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			filter_alert_pill.scale = Vector2(0.5, 0.5)
			tw.tween_property(filter_alert_pill, "scale", Vector2.ONE, 0.18)
			
	if filter_btn:
		filter_btn.modulate = Color(1.15, 1.15, 1.15, 1.0) if is_near else Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active or is_modal_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if filter_alert_pill and filter_alert_pill.visible:
				_open_filter_modal()

# --- LOAD ASSETS ---
func _load_dynamic_assets() -> void:
	tex_cabinet = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/lab_pastel_server_cabinet.png")
	tex_pc_operator = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/operator_pc_2_1.png")
	tex_guardian = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/guardian-icon.png")
	tex_switch_icon = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/switch-icons.png")
	tex_defense_icon = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/defense-icons.png")
	tex_router_obj = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/router objects 1.png")
	
	# Load Walk frames router jika ada
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

# --- ROOM DECORATIONS (FIGMA IMAGE 10) ---
func _build_room_decorations() -> void:
	# 1. Left Rack Cabinet Shelves & Label
	var rack_pill = _create_mini_pill("Rak Trafik Masuk / Filter & Log Koneksi", Color("#eff6ff"), Color("#1e40af"))
	rack_pill.position = Vector2(10, -28)
	left_rack_cabinet.add_child(rack_pill)
	
	var shelf_container = Control.new()
	shelf_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	left_rack_cabinet.add_child(shelf_container)
	
	var tex_panel = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/straight.png")
	var tex_cable = _safe_load_texture("res://art/assets/scattered/kabel_utp-removebg-preview.png")
	if tex_panel:
		_add_shelf_item(shelf_container, tex_panel, Vector2(55, 65))
	if tex_switch_icon:
		_add_shelf_item(shelf_container, tex_switch_icon, Vector2(55, 145))
	if tex_cable:
		_add_shelf_item(shelf_container, tex_cable, Vector2(55, 230))
		
	# 2. Server Cabinet on Right
	if tex_cabinet and server_cabinet:
		server_cabinet.texture = tex_cabinet
		
	# 3. Whiteboard on Wall (Aturan Firewall Flowchart)
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
	wb_title.text = "ATURAN FIREWALL MANUAL"
	wb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wb_title.add_theme_font_override("font", font_black)
	wb_title.add_theme_font_size_override("font_size", 11)
	wb_title.add_theme_color_override("font_color", Color("#1e3a8a"))
	wb_vbox.add_child(wb_title)
	
	var wb_content = Label.new()
	wb_content.text = "ALLOW: IP Privat (LAN)  |  BLOCK: IP Publik (WAN)"
	wb_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wb_content.add_theme_font_override("font", font_bold)
	wb_content.add_theme_font_size_override("font_size", 10)
	wb_content.add_theme_color_override("font_color", Color("#2563eb"))
	wb_vbox.add_child(wb_content)
	
	var wb_btn = Button.new()
	wb_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	wb_btn.flat = true
	wb_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	wb_btn.pressed.connect(_open_whiteboard_modal)
	wb_panel.add_child(wb_btn)
	_setup_hover_scale(wb_panel, 1.05)
	
	# 4. Center Desk Equipment
	if pc_node and tex_pc_operator:
		pc_node.texture = tex_pc_operator
		
	var pc_lbl = _create_mini_pill("MONITOR KEAMANAN", Color("#ffffff"), Color("#475569"))
	pc_lbl.position = Vector2(10, 68)
	center_desk.add_child(pc_lbl)
	
	# Preview Cards on Desk (Left: Green IP Privat, Right: Red IP Publik)
	var card_left = _create_desk_preview_card("IP PRIVAT (AMAN)", "192.168.1.25", "-> Izinkan (Allow)", Color("#a7f3d0"), Color("#059669"), Color("#065f46"))
	card_left.position = Vector2(130, 16)
	center_desk.add_child(card_left)
	
	if center_mascot and tex_guardian:
		center_mascot.texture = tex_guardian
		# Gentle bobbing animation
		var tw_mascot = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_mascot.tween_property(center_mascot, "position:y", 6.0, 1.2)
		tw_mascot.tween_property(center_mascot, "position:y", 12.0, 1.2)
		
	var card_right = _create_desk_preview_card("IP PUBLIK (ASING)", "203.0.113.5", "-> Blokir (Deny)", Color("#fecdd3"), Color("#dc2626"), Color("#991b1b"))
	card_right.position = Vector2(360, 16)
	center_desk.add_child(card_right)
	
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
	filter_alert_pill.add_theme_stylebox_override("panel", sb_alert)
	var alert_lbl = filter_alert_pill.get_node("FilterAlertLabel") as Label
	alert_lbl.add_theme_font_override("font", font_extrabold)
	alert_lbl.add_theme_color_override("font_color", Color("#dc2626"))
	
	# Filter Button on Desk
	var sb_filter = StyleBoxFlat.new()
	sb_filter.bg_color = Color("#fed7aa")
	sb_filter.border_color = Color("#ea580c")
	sb_filter.set_border_width_all(2)
	sb_filter.set_corner_radius_all(8)
	filter_btn.add_theme_stylebox_override("normal", sb_filter)
	filter_btn.add_theme_stylebox_override("hover", sb_filter)
	filter_btn.add_theme_stylebox_override("pressed", sb_filter)
	filter_btn.add_theme_font_override("font", font_black)
	filter_btn.add_theme_color_override("font_color", Color("#9a3412"))
	filter_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	filter_btn.pressed.connect(_open_filter_modal)
	_setup_hover_scale(filter_btn, 1.1)
	
	center_desk.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_open_filter_modal()
		elif event is InputEventScreenTouch and event.pressed:
			_open_filter_modal()
	)
	center_desk.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# 5. Floor Bins / Interactive Pads (Left: ALLOW, Right: BLOCK)
	_setup_floor_pad(left_pad, "ALLOW", Color("#a7f3d0"), Color("#059669"), "✓ IZINKAN MASUK: IP PRIVAT (10.x / 172.16-31.x / 192.168.x)", "LAN AMAN", tex_switch_icon, "✓")
	_setup_floor_pad(right_pad, "BLOCK", Color("#fecdd3"), Color("#dc2626"), "✕ BLOKIR KONEKSI: IP PUBLIK / EKSTERNAL (WAN)", "KARANTINA", tex_guardian if tex_guardian else tex_defense_icon, "✕")
	
	cables_container.draw.connect(_on_cables_draw)

func _create_desk_preview_card(title_txt: String, ip_txt: String, sub_txt: String, bg_col: Color, border_col: Color, text_col: Color) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(115, 68)
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(6)
	card.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)
	
	var l_title = Label.new()
	l_title.text = title_txt
	l_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_title.add_theme_font_override("font", font_black)
	l_title.add_theme_font_size_override("font_size", 9)
	l_title.add_theme_color_override("font_color", text_col)
	vbox.add_child(l_title)
	
	var l_ip = Label.new()
	l_ip.text = ip_txt
	l_ip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_ip.add_theme_font_override("font", font_extrabold)
	l_ip.add_theme_font_size_override("font_size", 11)
	l_ip.add_theme_color_override("font_color", text_col)
	vbox.add_child(l_ip)
	
	var l_sub = Label.new()
	l_sub.text = sub_txt
	l_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_sub.add_theme_font_override("font", font_semibold)
	l_sub.add_theme_font_size_override("font_size", 8)
	l_sub.add_theme_color_override("font_color", text_col)
	vbox.add_child(l_sub)
	
	return card

func _setup_floor_pad(pad_node: Control, rule_type: String, bg_col: Color, border_col: Color, caption_text: String, tag_text: String, icon_tex: Texture2D, badge_symbol: String) -> void:
	var pad_panel = PanelContainer.new()
	pad_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#e5d0b1")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(8)
	pad_panel.add_theme_stylebox_override("panel", sb)
	pad_node.add_child(pad_panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	pad_panel.add_child(vbox)
	
	# Top Inner Box with Icon, Badge, and Pill
	var top_box = PanelContainer.new()
	var sb_tb = StyleBoxFlat.new()
	sb_tb.bg_color = bg_col
	sb_tb.border_color = border_col
	sb_tb.set_border_width_all(2)
	sb_tb.set_corner_radius_all(12)
	sb_tb.set_content_margin_all(6)
	top_box.add_theme_stylebox_override("panel", sb_tb)
	top_box.custom_minimum_size = Vector2(0, 64)
	vbox.add_child(top_box)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	top_box.add_child(hbox)
	
	var tr_icon = TextureRect.new()
	if icon_tex:
		tr_icon.texture = icon_tex
	tr_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr_icon.custom_minimum_size = Vector2(65, 45)
	hbox.add_child(tr_icon)
	
	# Circle Badge
	var b_pan = PanelContainer.new()
	b_pan.custom_minimum_size = Vector2(28, 28)
	var sb_b = StyleBoxFlat.new()
	sb_b.bg_color = border_col
	sb_b.set_corner_radius_all(14)
	b_pan.add_theme_stylebox_override("panel", sb_b)
	hbox.add_child(b_pan)
	
	var b_lbl = Label.new()
	b_lbl.text = badge_symbol
	b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b_lbl.add_theme_font_override("font", font_black)
	b_lbl.add_theme_font_size_override("font_size", 14)
	b_lbl.add_theme_color_override("font_color", Color.WHITE)
	b_pan.add_child(b_lbl)
	
	# Tag Pill
	var tag_pill = _create_mini_pill(tag_text, Color.WHITE, border_col)
	hbox.add_child(tag_pill)
	
	# Bottom Caption Pill
	var lbl_panel = PanelContainer.new()
	var sb_lbl = StyleBoxFlat.new()
	sb_lbl.bg_color = Color("#ffffff")
	sb_lbl.border_color = border_col
	sb_lbl.set_border_width_all(1.5)
	sb_lbl.set_corner_radius_all(8)
	sb_lbl.content_margin_left = 10
	sb_lbl.content_margin_right = 10
	sb_lbl.content_margin_top = 3
	sb_lbl.content_margin_bottom = 3
	lbl_panel.add_theme_stylebox_override("panel", sb_lbl)
	vbox.add_child(lbl_panel)
	
	var lbl = Label.new()
	lbl.text = caption_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", border_col.darkened(0.2))
	lbl_panel.add_child(lbl)
	
	var pad_btn = Button.new()
	pad_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad_btn.flat = true
	pad_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pad_btn.pressed.connect(func(): _on_gate_selected(rule_type))
	pad_node.add_child(pad_btn)
	_setup_hover_scale(pad_node, 1.04)
	
	floor_pads_dict[rule_type] = pad_node

func _on_cables_draw() -> void:
	# 1. Cyan dashed cable from Left Rack to Center Desk
	var rack_rect = left_rack_cabinet.get_global_rect()
	var rack_exit = Vector2(rack_rect.position.x + rack_rect.size.x, rack_rect.position.y + rack_rect.size.y * 0.65)
	
	var desk_rect = center_desk.get_global_rect()
	var desk_left_entry = Vector2(desk_rect.position.x, desk_rect.position.y + desk_rect.size.y * 0.55)
	
	var rack_mid = Vector2((rack_exit.x + desk_left_entry.x) * 0.5, desk_left_entry.y)
	cables_container.draw_dashed_line(rack_exit, Vector2(rack_mid.x, rack_exit.y), Color("#38bdf8"), 4.0, 8.0)
	cables_container.draw_dashed_line(Vector2(rack_mid.x, rack_exit.y), rack_mid, Color("#38bdf8"), 4.0, 8.0)
	cables_container.draw_dashed_line(rack_mid, desk_left_entry, Color("#38bdf8"), 4.0, 8.0)
	
	# 2. Mint cable from Center Desk to Left Pad (ALLOW)
	var desk_bottom_allow = Vector2(desk_rect.position.x + desk_rect.size.x * 0.25, desk_rect.position.y + desk_rect.size.y - 10.0)
	var left_pad_rect = left_pad.get_global_rect()
	var left_pad_entry = Vector2(left_pad_rect.position.x + left_pad_rect.size.x * 0.5, left_pad_rect.position.y)
	
	var mid_y_allow = (desk_bottom_allow.y + left_pad_entry.y) * 0.5
	cables_container.draw_line(desk_bottom_allow, Vector2(desk_bottom_allow.x, mid_y_allow), Color("#10b981"), 4.0)
	cables_container.draw_line(Vector2(desk_bottom_allow.x, mid_y_allow), Vector2(left_pad_entry.x, mid_y_allow), Color("#10b981"), 4.0)
	cables_container.draw_line(Vector2(left_pad_entry.x, mid_y_allow), left_pad_entry, Color("#10b981"), 4.0)
	
	# 3. Coral cable from Center Desk to Right Pad (BLOCK)
	var desk_bottom_block = Vector2(desk_rect.position.x + desk_rect.size.x * 0.75, desk_rect.position.y + desk_rect.size.y - 10.0)
	var right_pad_rect = right_pad.get_global_rect()
	var right_pad_entry = Vector2(right_pad_rect.position.x + right_pad_rect.size.x * 0.5, right_pad_rect.position.y)
	
	var mid_y_block = (desk_bottom_block.y + right_pad_entry.y) * 0.5
	cables_container.draw_line(desk_bottom_block, Vector2(desk_bottom_block.x, mid_y_block), Color("#ef4444"), 4.0)
	cables_container.draw_line(Vector2(desk_bottom_block.x, mid_y_block), Vector2(right_pad_entry.x, mid_y_block), Color("#ef4444"), 4.0)
	cables_container.draw_line(Vector2(right_pad_entry.x, mid_y_block), right_pad_entry, Color("#ef4444"), 4.0)

func _add_shelf_item(parent: Control, tex: Texture2D, pos: Vector2) -> void:
	var tr = TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = Vector2(40, 30)
	tr.position = pos
	parent.add_child(tr)

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

# --- MOBILE VIRTUAL JOYSTICK ---
func _build_mobile_controls() -> void:
	mobile_controls_root = Control.new()
	mobile_controls_root.name = "MobileControls"
	mobile_controls_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	mobile_controls_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mobile_controls_root)
	
	var pad_rect = TextureRect.new()
	pad_rect.name = "DpadBase"
	pad_rect.texture = tex_dpad_base
	pad_rect.custom_minimum_size = Vector2(120, 120)
	pad_rect.size = Vector2(120, 120)
	pad_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pad_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pad_rect.position = Vector2(50, 540)
	pad_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	mobile_controls_root.add_child(pad_rect)
	
	dpad_knob_sprite = TextureRect.new()
	dpad_knob_sprite.name = "DpadKnob"
	dpad_knob_sprite.texture = tex_dpad_knob
	dpad_knob_sprite.custom_minimum_size = Vector2(52, 52)
	dpad_knob_sprite.size = Vector2(52, 52)
	dpad_knob_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dpad_knob_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dpad_knob_sprite.position = Vector2(34, 34)
	dpad_knob_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad_rect.add_child(dpad_knob_sprite)
	
	pad_rect.gui_input.connect(_handle_dpad_input)

func _handle_dpad_input(event: InputEvent) -> void:
	var pad_rect = mobile_controls_root.get_node("DpadBase") as TextureRect
	dpad_center = pad_rect.global_position + pad_rect.size / 2.0
	
	if event is InputEventScreenTouch:
		if event.pressed:
			dpad_touch_id = event.index
			_update_dpad_vector(event.position)
		elif event.index == dpad_touch_id:
			_reset_dpad()
	elif event is InputEventScreenDrag and event.index == dpad_touch_id:
		_update_dpad_vector(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dpad_touch_id = 99
				_update_dpad_vector(event.position)
			else:
				_reset_dpad()
	elif event is InputEventMouseMotion and dpad_touch_id == 99:
		_update_dpad_vector(event.position)

func _update_dpad_vector(local_touch_pos: Vector2) -> void:
	var pad_rect = mobile_controls_root.get_node("DpadBase") as TextureRect
	var center = pad_rect.size / 2.0
	var offset = local_touch_pos - center
	var dist = offset.length()
	
	if dist > dpad_radius:
		offset = offset.normalized() * dpad_radius
		
	input_dir = offset / dpad_radius
	dpad_knob_sprite.position = center + offset - dpad_knob_sprite.size / 2.0

func _reset_dpad() -> void:
	dpad_touch_id = -1
	input_dir = Vector2.ZERO
	var pad_rect = mobile_controls_root.get_node("DpadBase") as TextureRect
	var center = pad_rect.size / 2.0
	dpad_knob_sprite.position = center - dpad_knob_sprite.size / 2.0

# --- HEADER UI (HEARTS WITH BREAK INDICATOR + TIMER + PAUSE) ---
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
	back_btn.pressed.connect(_open_pause_modal)
	_setup_hover_scale(back_btn, 1.1)
	header_ui.add_child(back_btn)
	
	# Hearts Panel (Kawaii 3 Hati)
	hearts_panel = PanelContainer.new()
	hearts_panel.name = "HeartsPanel"
	var sb_hearts = StyleBoxFlat.new()
	sb_hearts.bg_color = Color("#fffdf7")
	sb_hearts.border_color = Color("#4a2e2b")
	sb_hearts.set_border_width_all(2.5)
	sb_hearts.set_corner_radius_all(14)
	sb_hearts.shadow_color = Color(0, 0, 0, 0.15)
	sb_hearts.shadow_size = 4
	sb_hearts.shadow_offset = Vector2(0, 2)
	sb_hearts.set_content_margin_all(8)
	sb_hearts.content_margin_left = 14
	sb_hearts.content_margin_right = 14
	hearts_panel.add_theme_stylebox_override("panel", sb_hearts)
	header_ui.add_child(hearts_panel)
	
	hearts_container = HBoxContainer.new()
	hearts_container.add_theme_constant_override("separation", 10)
	hearts_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hearts_panel.add_child(hearts_container)
	
	for i in range(3):
		var h_box = Control.new()
		h_box.custom_minimum_size = Vector2(32, 28)
		hearts_container.add_child(h_box)
		
		var hr = TextureRect.new()
		hr.texture = tex_vector_heart
		hr.custom_minimum_size = Vector2(30, 26)
		hr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hr.modulate = Color(1.0, 0.28, 0.4, 1.0)
		hr.pivot_offset = Vector2(15, 13)
		h_box.add_child(hr)
		hearts_rects.append(hr)
		HeartsStyle.schedule_normalize(hearts_rects)
		
		var bl = Label.new()
		bl.text = "✕"
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bl.add_theme_font_override("font", font_black)
		bl.add_theme_font_size_override("font_size", 20)
		bl.add_theme_color_override("font_color", Color("#dc2626"))
		bl.set_anchors_preset(Control.PRESET_FULL_RECT)
		bl.visible = false
		h_box.add_child(bl)
		broken_labels.append(bl)
		
	# Level 2.2 Badge
	var level_badge = PanelContainer.new()
	level_badge.name = "LevelBadge"
	var sb_badge = StyleBoxFlat.new()
	sb_badge.bg_color = Color("#fffdf7")
	sb_badge.border_color = Color("#4a2e2b")
	sb_badge.set_border_width_all(2.5)
	sb_badge.set_corner_radius_all(14)
	sb_badge.shadow_color = Color(0, 0, 0, 0.15)
	sb_badge.shadow_size = 4
	sb_badge.shadow_offset = Vector2(0, 2)
	sb_badge.set_content_margin_all(4)
	sb_badge.content_margin_left = 12
	sb_badge.content_margin_right = 12
	level_badge.add_theme_stylebox_override("panel", sb_badge)
	header_ui.add_child(level_badge)
	
	var vb_badge = VBoxContainer.new()
	vb_badge.alignment = BoxContainer.ALIGNMENT_CENTER
	level_badge.add_child(vb_badge)
	
	var sub_lvl = Label.new()
	sub_lvl.text = "Level"
	sub_lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lvl.add_theme_font_override("font", font_bold)
	sub_lvl.add_theme_font_size_override("font_size", 10)
	sub_lvl.add_theme_color_override("font_color", Color("#64748b"))
	vb_badge.add_child(sub_lvl)
	
	var num_lvl = Label.new()
	num_lvl.text = "2.2"
	num_lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lvl.add_theme_font_override("font", font_black)
	num_lvl.add_theme_font_size_override("font_size", 16)
	num_lvl.add_theme_color_override("font_color", Color("#1e293b"))
	vb_badge.add_child(num_lvl)
	
	# Timer Panel (Jam + 02:45)
	var timer_panel = PanelContainer.new()
	timer_panel.name = "TimerPanel"
	var sb_timer = StyleBoxFlat.new()
	sb_timer.bg_color = Color("#fffdf7")
	sb_timer.border_color = Color("#4a2e2b")
	sb_timer.set_border_width_all(2.5)
	sb_timer.set_corner_radius_all(14)
	sb_timer.shadow_color = Color(0, 0, 0, 0.15)
	sb_timer.shadow_size = 4
	sb_timer.shadow_offset = Vector2(0, 2)
	sb_timer.set_content_margin_all(6)
	sb_timer.content_margin_left = 12
	sb_timer.content_margin_right = 16
	timer_panel.add_theme_stylebox_override("panel", sb_timer)
	header_ui.add_child(timer_panel)
	
	var hb_timer = HBoxContainer.new()
	hb_timer.add_theme_constant_override("separation", 8)
	hb_timer.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_panel.add_child(hb_timer)
	
	clock_icon = TextureRect.new()
	clock_icon.texture = tex_frame_jam
	clock_icon.custom_minimum_size = Vector2(30, 30)
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
		back_btn.position = Vector2(25.0, top_y)
		back_btn.size = Vector2(52.0, 52.0)
		
	if hearts_panel:
		hearts_panel.position = Vector2(90.0, top_y)
		
	var level_badge = header_ui.get_node_or_null("LevelBadge") as Control
	if level_badge:
		level_badge.position = Vector2(235.0, top_y)
		
	var pause_btn = header_ui.get_node_or_null("PauseBtn") as Control
	if pause_btn:
		pause_btn.position = Vector2(vp_sz.x - 75.0, top_y)
		pause_btn.size = Vector2(52.0, 52.0)
		
	var timer_panel = header_ui.get_node_or_null("TimerPanel") as Control
	if timer_panel:
		timer_panel.position = Vector2(vp_sz.x - 230.0, top_y)

# --- INTRO MODAL (FIGMA IMAGE 9) ---
func _build_intro_modal() -> void:
	intro_modal = Control.new()
	intro_modal.name = "IntroModal"
	intro_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_modal.z_index = 150
	intro_modal.visible = false
	add_child(intro_modal)
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	intro_modal.add_child(dim)
	
	var intro_card = Control.new()
	intro_card.size = Vector2(840, 530)
	intro_card.pivot_offset = Vector2(420, 265)
	intro_modal.add_child(intro_card)
	
	var bg_panel = PanelContainer.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fefce8")
	sb.border_color = Color("#38bdf8")
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(22)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 6)
	sb.set_content_margin_all(22)
	bg_panel.add_theme_stylebox_override("panel", sb)
	intro_card.add_child(bg_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	bg_panel.add_child(vbox)
	
	# Notebook Hole top
	var hole = Control.new()
	hole.custom_minimum_size = Vector2(20, 16)
	hole.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var hole_tr = Panel.new()
	hole_tr.custom_minimum_size = Vector2(16, 16)
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color("#fffef7")
	sb_h.border_color = Color("#4a2e2b")
	sb_h.set_border_width_all(2.5)
	sb_h.set_corner_radius_all(8)
	hole_tr.add_theme_stylebox_override("panel", sb_h)
	hole.add_child(hole_tr)
	vbox.add_child(hole)
	
	# Title
	var title = Label.new()
	title.text = "🛡️ Level 2.2 – Aturan Firewall: IP Privat vs IP Publik"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font_black)
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color("#2d1810"))
	vbox.add_child(title)
	
	# Skenario Misi Card
	var mission_card = PanelContainer.new()
	var sb_m = StyleBoxFlat.new()
	sb_m.bg_color = Color("#ffffff")
	sb_m.border_color = Color("#fed7aa")
	sb_m.set_border_width_all(2)
	sb_m.set_corner_radius_all(14)
	sb_m.set_content_margin_all(10)
	mission_card.add_theme_stylebox_override("panel", sb_m)
	vbox.add_child(mission_card)
	
	var m_vbox = VBoxContainer.new()
	m_vbox.add_theme_constant_override("separation", 3)
	mission_card.add_child(m_vbox)
	
	var m_head = HBoxContainer.new()
	m_head.add_theme_constant_override("separation", 10)
	m_vbox.add_child(m_head)
	
	var pill_tag = _create_mini_pill("SKENARIO MISI", Color("#fed7aa"), Color("#ea580c"))
	m_head.add_child(pill_tag)
	
	var m_t = Label.new()
	m_t.text = "Saring trafik yang meminta akses langsung ke Server Internal (LAN)!"
	m_t.add_theme_font_override("font", font_bold)
	m_t.add_theme_font_size_override("font_size", 12)
	m_t.add_theme_color_override("font_color", Color("#1e293b"))
	m_head.add_child(m_t)
	
	var m_desc = Label.new()
	m_desc.text = "• Aturan Skenario: ALLOW (Izinkan) alamat IP Privat internal, dan BLOCK (Tolak) akses langsung dari IP Publik.\nℹ️ Catatan: Alamat IP Publik TIDAK selalu berbahaya (misal DNS 8.8.8.8/8.8.4.4), namun diblokir karena aturan server khusus lokal."
	m_desc.add_theme_font_override("font", font_semibold)
	m_desc.add_theme_font_size_override("font_size", 11)
	m_desc.add_theme_color_override("font_color", Color("#475569"))
	m_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	m_vbox.add_child(m_desc)
	
	# Reference Boxes (ALLOW vs BLOCK)
	var ref_row = HBoxContainer.new()
	ref_row.add_theme_constant_override("separation", 12)
	vbox.add_child(ref_row)
	
	var box_allow = _create_intro_ref_box(
		"✓ ALLOW (IZINKAN – IP PRIVAT LAN)",
		"• 10.0.0.0 – 10.255.255.255 (10.x.x.x)\n• 172.16.0.0 – 172.31.255.255\n• 192.168.0.0 – 192.168.255.255",
		Color("#a7f3d0"),
		Color("#059669"),
		Color("#065f46")
	)
	box_allow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ref_row.add_child(box_allow)
	
	var box_block = _create_intro_ref_box(
		"✕ BLOCK (TOLAK – IP PUBLIK WAN)",
		"Alamat publik yang digunakan di jaringan internet luar (di luar 3 rentang IP Privat di samping).\nContoh: 203.0.113.45 • 8.8.4.4 • 185.199.108.15",
		Color("#fecdd3"),
		Color("#dc2626"),
		Color("#991b1b")
	)
	box_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ref_row.add_child(box_block)
	
	# Instructions & Conditions row
	var inst_row = HBoxContainer.new()
	inst_row.add_theme_constant_override("separation", 12)
	vbox.add_child(inst_row)
	
	var inst_left = _create_intro_note_box(
		"🕹️ LANGKAH BERMAIN & KONTROL",
		"1. Klik \"Filter\" atau dekati meja PC Satpam.\n2. Pilih kartu trafik IP yang mengantre di atas.\n3. Drag / arahkan ke gerbang ALLOW atau gerbang BLOCK.",
		Color("#ffffff"),
		Color("#64748b")
	)
	inst_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inst_row.add_child(inst_left)
	
	var inst_right = _create_intro_note_box(
		"🏆 KONDISI MENYELESAIKAN MISI",
		"• Seluruh paket trafik (6/6) berhasil dipisahkan sesuai aturan firewall skenario permainan.\n✓ IP Privat -> ALLOW | IP Publik -> BLOCK\n✓ Membuka akses ke misi Level 2.3 (ARP-Request).",
		Color("#f0fdf4"),
		Color("#10b981")
	)
	inst_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inst_row.add_child(inst_right)
	
	# Bottom Row: Avatar Mascot + MULAI Button
	var bot_row = HBoxContainer.new()
	bot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_row.add_theme_constant_override("separation", 16)
	vbox.add_child(bot_row)
	
	var avatar_box = PanelContainer.new()
	avatar_box.custom_minimum_size = Vector2(44, 44)
	var sb_av = StyleBoxFlat.new()
	sb_av.bg_color = Color("#ffffff")
	sb_av.border_color = Color("#4a2e2b")
	sb_av.set_border_width_all(2.5)
	sb_av.set_corner_radius_all(22)
	avatar_box.add_theme_stylebox_override("panel", sb_av)
	bot_row.add_child(avatar_box)
	
	var av_tr = TextureRect.new()
	av_tr.texture = tex_char_idle
	av_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_box.add_child(av_tr)
	
	var mulai_btn = Button.new()
	mulai_btn.text = "MULAI"
	mulai_btn.custom_minimum_size = Vector2(220, 46)
	mulai_btn.add_theme_font_override("font", font_black)
	mulai_btn.add_theme_font_size_override("font_size", 17)
	mulai_btn.add_theme_color_override("font_color", Color("#065f46"))
	var sb_mulai = StyleBoxFlat.new()
	sb_mulai.bg_color = Color("#6ee7b7")
	sb_mulai.border_color = Color("#059669")
	sb_mulai.set_border_width_all(2.5)
	sb_mulai.set_corner_radius_all(14)
	sb_mulai.shadow_color = Color(0.02, 0.59, 0.41, 0.3)
	sb_mulai.shadow_size = 6
	sb_mulai.shadow_offset = Vector2(0, 3)
	mulai_btn.add_theme_stylebox_override("normal", sb_mulai)
	mulai_btn.add_theme_stylebox_override("hover", sb_mulai)
	mulai_btn.add_theme_stylebox_override("pressed", sb_mulai)
	mulai_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mulai_btn.pressed.connect(_close_intro_modal)
	_setup_hover_scale(mulai_btn, 1.05)
	bot_row.add_child(mulai_btn)

func _create_intro_ref_box(title: String, body: String, bg_col: Color, border_col: Color, text_col: Color) -> PanelContainer:
	var pan = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(8)
	pan.add_theme_stylebox_override("panel", sb)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	pan.add_child(vb)
	
	var tl = Label.new()
	tl.text = title
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.add_theme_font_override("font", font_black)
	tl.add_theme_font_size_override("font_size", 12)
	tl.add_theme_color_override("font_color", text_col)
	vb.add_child(tl)
	
	var bl = Label.new()
	bl.text = body
	bl.add_theme_font_override("font", font_bold)
	bl.add_theme_font_size_override("font_size", 10)
	bl.add_theme_color_override("font_color", text_col.darkened(0.1))
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(bl)
	return pan

func _create_intro_note_box(title: String, body: String, bg_col: Color, border_col: Color) -> PanelContainer:
	var pan = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(1.5)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(8)
	pan.add_theme_stylebox_override("panel", sb)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	pan.add_child(vb)
	
	var tl = Label.new()
	tl.text = title
	tl.add_theme_font_override("font", font_bold)
	tl.add_theme_font_size_override("font_size", 11)
	tl.add_theme_color_override("font_color", Color("#1e293b"))
	vb.add_child(tl)
	
	var bl = Label.new()
	bl.text = body
	bl.add_theme_font_override("font", font_semibold)
	bl.add_theme_font_size_override("font_size", 10)
	bl.add_theme_color_override("font_color", Color("#475569"))
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(bl)
	return pan

func _open_intro_modal() -> void:
	is_modal_open = true
	intro_modal.visible = true
	var card = intro_modal.get_child(1) as Control
	card.position = (get_viewport_rect().size - card.size) / 2.0
	card.scale = Vector2(0.8, 0.8)
	card.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2.ONE, 0.25)
	tw.tween_property(card, "modulate:a", 1.0, 0.22)
	_play_chime_sound()

func _close_intro_modal() -> void:
	var card = intro_modal.get_child(1) as Control
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(card, "scale", Vector2(0.8, 0.8), 0.18)
	tw.tween_property(card, "modulate:a", 0.0, 0.16)
	await tw.finished
	intro_modal.visible = false
	is_modal_open = false
	_start_after_tutorial()
	_play_chime_sound()

# --- FILTER MODAL (FIGMA IMAGE 3) ---
func _build_filter_modal() -> void:
	filter_modal = Control.new()
	filter_modal.name = "FilterModal"
	filter_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	filter_modal.z_index = 100
	filter_modal.visible = false
	add_child(filter_modal)
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	filter_modal.add_child(dim)
	
	filter_card = Control.new()
	filter_card.size = Vector2(980, 560)
	filter_card.pivot_offset = Vector2(490, 280)
	filter_modal.add_child(filter_card)
	
	var bg_panel = PanelContainer.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fffdfa")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(22)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 6)
	sb.set_content_margin_all(14)
	bg_panel.add_theme_stylebox_override("panel", sb)
	filter_card.add_child(bg_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	bg_panel.add_child(vbox)
	
	# Top Lavender Header Bar (Figma Image 7)
	var header_bar = PanelContainer.new()
	var sb_hbar = StyleBoxFlat.new()
	sb_hbar.bg_color = Color("#e9d5ff")
	sb_hbar.border_color = Color("#c084fc")
	sb_hbar.set_border_width_all(1.5)
	sb_hbar.set_corner_radius_all(14)
	sb_hbar.content_margin_left = 16
	sb_hbar.content_margin_right = 10
	sb_hbar.content_margin_top = 8
	sb_hbar.content_margin_bottom = 8
	header_bar.add_theme_stylebox_override("panel", sb_hbar)
	vbox.add_child(header_bar)
	
	var header_row = HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_bar.add_child(header_row)
	
	var m_title = Label.new()
	m_title.text = "Level 2.2: Konfigurasi Firewall Manual (IP Privat vs IP Publik)"
	m_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_title.add_theme_font_override("font", font_black)
	m_title.add_theme_font_size_override("font_size", 16)
	m_title.add_theme_color_override("font_color", Color("#4c1d95"))
	header_row.add_child(m_title)
	
	var close_btn = CloseButtonScene.instantiate()
	close_btn.closed.connect(_close_filter_modal)
	header_row.add_child(close_btn)
	
	# Subtitle
	var m_sub = Label.new()
	m_sub.text = "PERIKSA ALAMAT IP PENGIRIM DAN ARAHKAN KE GERBANG FIREWALL YANG TEPAT!"
	m_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_sub.add_theme_font_override("font", font_extrabold)
	m_sub.add_theme_font_size_override("font_size", 12)
	m_sub.add_theme_color_override("font_color", Color("#334155"))
	vbox.add_child(m_sub)
	
	# Queue Area for Packets
	var queue_scroll = ScrollContainer.new()
	queue_scroll.custom_minimum_size = Vector2(0, 100)
	queue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	queue_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(queue_scroll)
	
	filter_queue_container = HBoxContainer.new()
	filter_queue_container.add_theme_constant_override("separation", 14)
	filter_queue_container.alignment = BoxContainer.ALIGNMENT_CENTER
	filter_queue_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	queue_scroll.add_child(filter_queue_container)
	
	# Two Firewall Bins Side-by-Side (ALLOW on Left, BLOCK on Right)
	var bins_row = HBoxContainer.new()
	bins_row.add_theme_constant_override("separation", 20)
	bins_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(bins_row)
	
	bin_allow = FirewallBinScene.instantiate()
	bin_allow.rule = "ALLOW"
	bin_allow.gate_selected.connect(_on_gate_selected)
	bins_row.add_child(bin_allow)
	
	bin_block = FirewallBinScene.instantiate()
	bin_block.rule = "BLOCK"
	bin_block.gate_selected.connect(_on_gate_selected)
	bins_row.add_child(bin_block)

func _open_filter_modal() -> void:
	if is_modal_open:
		return
	is_modal_open = true
	filter_modal.visible = true
	
	var vp_sz = get_viewport_rect().size
	filter_card.position = (vp_sz - filter_card.size) / 2.0
	filter_card.scale = Vector2(0.85, 0.85)
	filter_card.modulate.a = 0.0
	
	_populate_queue_packets()
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(filter_card, "scale", Vector2.ONE, 0.22)
	tw.tween_property(filter_card, "modulate:a", 1.0, 0.20)
	_play_chime_sound()

func _close_filter_modal() -> void:
	if not filter_modal.visible:
		return
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(filter_card, "scale", Vector2(0.85, 0.85), 0.18)
	tw.tween_property(filter_card, "modulate:a", 0.0, 0.16)
	await tw.finished
	filter_modal.visible = false
	is_modal_open = false
	selected_packet = null

func _populate_queue_packets() -> void:
	for child in filter_queue_container.get_children():
		child.queue_free()
	active_packets.clear()
	selected_packet = null
	
	var start_idx = packets_sorted_count
	var end_idx = min(start_idx + 4, traffic_deck.size())
	
	for i in range(start_idx, end_idx):
		var p_item = PacketItemScene.instantiate()
		filter_queue_container.add_child(p_item)
		if p_item.has_method("set_firewall_info"):
			p_item.set_firewall_info(i + 1, traffic_deck[i])
		else:
			p_item.set_packet_info(i + 1, traffic_deck[i])
		p_item.drag_ended.connect(_on_packet_drag_ended)
		p_item.selected.connect(_on_packet_selected)
		active_packets.append(p_item)

func _on_packet_selected(item: Control) -> void:
	if selected_packet == item:
		selected_packet = null
		return
		
	for p in active_packets:
		if is_instance_valid(p) and p != item:
			p.set_selected(false)
			
	selected_packet = item

func _on_packet_drag_ended(item: Control, release_pos: Vector2) -> void:
	var target_gate: String = ""
	var chosen_bin: Control = null
	
	if bin_allow.contains_global_point(release_pos):
		target_gate = "ALLOW"
		chosen_bin = bin_allow
	elif bin_block.contains_global_point(release_pos):
		target_gate = "BLOCK"
		chosen_bin = bin_block
		
	if target_gate != "":
		_process_classification(item, target_gate, chosen_bin)
	else:
		item.animate_return_home()

func _on_gate_selected(rule_type: String) -> void:
	var target_bin = bin_allow if rule_type == "ALLOW" else bin_block
	
	if selected_packet and is_instance_valid(selected_packet):
		_process_classification(selected_packet, rule_type, target_bin)
	elif active_packets.size() > 0:
		var first_packet = active_packets[0]
		if is_instance_valid(first_packet):
			_process_classification(first_packet, rule_type, target_bin)
	else:
		if not is_modal_open:
			_open_filter_modal()

func _process_classification(item: Control, chosen_rule: String, bin_inst: Control) -> void:
	var data = item.packet_data
	var actual_action = data.get("action", "ALLOW")
	var ip_str = data.get("ip", "")
	var is_correct = (chosen_rule == actual_action)
	
	if is_correct:
		_handle_correct_classification(item, chosen_rule, ip_str, bin_inst)
	else:
		_handle_wrong_classification(item, chosen_rule, actual_action, ip_str, bin_inst)

func _handle_correct_classification(item: Control, chosen_rule: String, ip_str: String, bin_inst: Control) -> void:
	_play_chime_sound()
	
	if bin_inst:
		bin_inst.animate_success()
		
	# Feedback animasi pada kartu pad lantai
	if floor_pads_dict.has(chosen_rule):
		var floor_pad = floor_pads_dict[chosen_rule] as Control
		var tw_pad = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_pad.tween_property(floor_pad, "scale", Vector2(1.08, 1.08), 0.15)
		tw_pad.tween_property(floor_pad, "scale", Vector2.ONE, 0.15)
		
	var target_center = bin_inst.global_position + bin_inst.size / 2.0 if bin_inst else global_position
	
	var is_priv = (chosen_rule == "ALLOW")
	var success_msg = "✓ TEPAT! %s adalah IP %s. Akses %s!" % [
		ip_str,
		"Privat (LAN)" if is_priv else "Publik (WAN)",
		"diizinkan ke server lokal" if is_priv else "diblokir ke karantina"
	]
	show_toast(success_msg, 2.5)
	
	active_packets.erase(item)
	if selected_packet == item:
		selected_packet = null
		
	item.animate_success_absorb(target_center, func():
		packets_sorted_count += 1
		if active_packets.size() < 3 and packets_sorted_count + active_packets.size() < traffic_deck.size():
			_populate_queue_packets()
			
		if packets_sorted_count >= TOTAL_PACKETS:
			_trigger_win()
	)

func _handle_wrong_classification(item: Control, chosen_rule: String, actual_rule: String, ip_str: String, bin_inst: Control) -> void:
	_play_buzz_error()
	
	if bin_inst:
		bin_inst.animate_error()
		
	_shake_screen()
	
	# Penalti HP & indikator hati komikal
	hearts = max(0, hearts - 1)
	_update_hearts_display(true)
	
	var err_msg = ""
	if actual_rule == "ALLOW":
		err_msg = "❌ SALAH! %s adalah IP Privat (RFC 1918). Trafik internal sah harus DIIZINKAN (ALLOW)!" % ip_str
	else:
		err_msg = "❌ SALAH! %s adalah IP Publik (WAN). Akses langsung dari internet luar harus DIBLOKIR (BLOCK)!" % ip_str
		
	show_toast(err_msg, 3.8)
	item.animate_return_home()
	
	if hearts <= 0:
		is_game_active = false
		_trigger_game_over("Nyawa teknisi habis! Pelajari kembali rentang IP Privat RFC 1918 (10.x, 172.16-31.x, 192.168.x).")

func _shake_screen() -> void:
	var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in range(4):
		tw.tween_property(self, "position", Vector2(randf_range(-7.0, 7.0), randf_range(-5.0, 5.0)), 0.04)
	tw.tween_property(self, "position", Vector2.ZERO, 0.05)

func _update_hearts_display(is_damage_event: bool = false) -> void:
	HeartsStyle.refresh(hearts_rects, hearts)

# --- WHITEBOARD MODAL (EDUKASI FIREWALL) ---
func _open_whiteboard_modal() -> void:
	if not whiteboard_modal:
		whiteboard_modal = Control.new()
		whiteboard_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(whiteboard_modal)
		
		var dim = ColorRect.new()
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.color = Color(0, 0, 0, 0.6)
		whiteboard_modal.add_child(dim)
		
		var wb_c = PanelContainer.new()
		wb_c.custom_minimum_size = Vector2(620, 360)
		var sb_wb = StyleBoxFlat.new()
		sb_wb.bg_color = Color("#ffffff")
		sb_wb.border_color = Color("#3b82f6")
		sb_wb.set_border_width_all(3.5)
		sb_wb.set_corner_radius_all(18)
		sb_wb.set_content_margin_all(20)
		wb_c.add_theme_stylebox_override("panel", sb_wb)
		whiteboard_modal.add_child(wb_c)
		
		var vb = VBoxContainer.new()
		vb.add_theme_constant_override("separation", 10)
		wb_c.add_child(vb)
		
		var head = HBoxContainer.new()
		vb.add_child(head)
		
		var t = Label.new()
		t.text = "📋 Panduan Firewall: RFC 1918 vs Public IP"
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.add_theme_font_override("font", font_black)
		t.add_theme_font_size_override("font_size", 16)
		t.add_theme_color_override("font_color", Color("#1e3a8a"))
		head.add_child(t)
		
		var c_btn = CloseButtonScene.instantiate()
		c_btn.closed.connect(func(): whiteboard_modal.visible = false)
		head.add_child(c_btn)
		
		var info_txt = Label.new()
		info_txt.text = "1. IP PRIVAT (RFC 1918) -> ALLOW\n   • 10.0.0.0/8 (10.0.0.0 - 10.255.255.255)\n   • 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)\n   • 192.168.0.0/16 (192.168.0.0 - 192.168.255.255)\n   -> Digunakan di jaringan lokal (LAN) internal, aman untuk diizinkan.\n\n2. IP PUBLIK (WAN) -> BLOCK\n   • Seluruh IP di luar rentang privat di atas (contoh: 203.0.113.45, 8.8.4.4, dll).\n   -> Akses langsung dari internet publik ditolak/dikarantina demi keamanan server lokal."
		info_txt.add_theme_font_override("font", font_semibold)
		info_txt.add_theme_font_size_override("font_size", 12)
		info_txt.add_theme_color_override("font_color", Color("#334155"))
		info_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(info_txt)
		
	whiteboard_modal.visible = true
	var c = whiteboard_modal.get_child(1) as Control
	c.position = (get_viewport_rect().size - c.size) / 2.0

# --- PAUSE MODAL ---
func _open_pause_modal() -> void:
	if not pause_modal:
		pause_modal = PauseModalScene.instantiate()
		pause_modal.z_index = 200
		add_child(pause_modal)
		pause_modal.resume_requested.connect(func(): is_game_active = true)
		pause_modal.restart_requested.connect(func(): get_tree().reload_current_scene())
		pause_modal.exit_requested.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
		
	is_game_active = false
	if pause_modal.has_method("open"):
		pause_modal.open()
	else:
		pause_modal.visible = true

# --- WIN & GAME OVER (MENGGUNAKAN GAMEDIALOG) ---
func _trigger_win() -> void:
	is_game_active = false
	if filter_modal and filter_modal.visible:
		filter_modal.visible = false
	is_modal_open = true
	
	_play_win_fanfare()
	
	var stars = 1
	if hearts == 3 and time_remaining >= 60.0:
		stars = 3
	elif hearts >= 2:
		stars = 2
		
	# Simpan ke PlayerData
	if Engine.has_singleton("PlayerData") or ResourceLoader.exists("res://scripts/player_data.gd"):
		if PlayerData:
			PlayerData.set_level_stars(2, 2, stars)
			
	if not game_dialog:
		game_dialog = GameDialogScene.instantiate()
		add_child(game_dialog)
		
	var time_used = int(TIME_LIMIT - time_remaining)
	var win_msg = "Luar biasa! Seluruh paket berhasil disaring dengan tepat sesuai aturan firewall!\n\n★ Rating: %d/3 Bintang\n⏱️ Waktu Selesai: %02d:%02d\n❤️ Sisa Nyawa: %d/3" % [
		stars,
		time_used / 60,
		time_used % 60,
		hearts
	]
	
	var act_next = func():
		get_tree().change_scene_to_file("res://scenes/gameplay/level_2_3.tscn")
	var act_map = func():
		get_tree().change_scene_to_file("res://scenes/level_path.tscn")
		
	var btn_list: Array[Dictionary] = [
		{ "text": "Lanjut ke Level 2.3", "action": act_next, "color": "green" },
		{ "text": "Kembali ke Map", "action": act_map, "color": "blue" }
	]
	
	game_dialog.setup_dialog("MISI BERHASIL!", win_msg, btn_list, "sukses")
	game_dialog.open()

func _trigger_game_over(reason: String) -> void:
	is_game_active = false
	if filter_modal and filter_modal.visible:
		filter_modal.visible = false
	is_modal_open = true
	
	_play_buzz_error()
	
	if not game_dialog:
		game_dialog = GameDialogScene.instantiate()
		add_child(game_dialog)
		
	var act_retry = func():
		get_tree().reload_current_scene()
	var act_map = func():
		get_tree().change_scene_to_file("res://scenes/level_path.tscn")
		
	var btn_list: Array[Dictionary] = [
		{ "text": "Coba Lagi", "action": act_retry, "color": "orange" },
		{ "text": "Kembali ke Map", "action": act_map, "color": "blue" }
	]
	
	game_dialog.setup_dialog("MISI GAGAL", reason, btn_list, "gagal")
	game_dialog.open()

# --- TOAST NOTIFICATION ---
func _build_toast_ui() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.name = "ToastPanel"
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#1e293b")
	sb.border_color = Color("#475569")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(10)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	toast_panel.add_theme_stylebox_override("panel", sb)
	toast_panel.visible = false
	toast_panel.z_index = 120
	add_child(toast_panel)
	
	toast_label = Label.new()
	toast_label.add_theme_font_override("font", font_bold)
	toast_label.add_theme_font_size_override("font_size", 13)
	toast_label.add_theme_color_override("font_color", Color("#ffffff"))
	toast_panel.add_child(toast_label)

func show_toast(text: String, duration: float = 3.0) -> void:
	if not toast_panel or not toast_label:
		return
	toast_label.text = text
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	
	var vp_sz = get_viewport_rect().size
	toast_panel.reset_size()
	toast_panel.position = Vector2((vp_sz.x - toast_panel.size.x) / 2.0, vp_sz.y - 110.0)
	
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_tween = create_tween()
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	toast_tween.tween_interval(duration)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	toast_tween.tween_callback(func(): toast_panel.visible = false)

# --- AUDIO SYNTHESIS HELPER (0 File Dependency) ---
func _play_chime_sound() -> void:
	if not audio_player:
		return
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.4
	audio_player.stream = gen
	audio_player.play()
	var pb = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb:
		_fill_tone_buffer(pb, [523.25, 659.25, 783.99], 0.25)

func _play_buzz_error() -> void:
	if not audio_player:
		return
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.35
	audio_player.stream = gen
	audio_player.play()
	var pb = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb:
		_fill_tone_buffer(pb, [180.0, 150.0], 0.3)

func _play_win_fanfare() -> void:
	if not audio_player:
		return
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.8
	audio_player.stream = gen
	audio_player.play()
	var pb = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb:
		_fill_tone_buffer(pb, [523.25, 659.25, 783.99, 1046.5], 0.7)

func _play_footstep() -> void:
	if not footstep_player:
		return
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.08
	footstep_player.stream = gen
	footstep_player.play()
	var pb = footstep_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb:
		var sample_rate = 22050.0
		var frames = int(sample_rate * 0.05)
		for i in range(frames):
			var sample = (randf() * 2.0 - 1.0) * 0.15 * (1.0 - float(i) / frames)
			pb.push_frame(Vector2(sample, sample))

func _fill_tone_buffer(playback: AudioStreamGeneratorPlayback, freqs: Array, dur: float) -> void:
	var sample_rate = 22050.0
	var frames_per_freq = int((sample_rate * dur) / freqs.size())
	for freq in freqs:
		var phase = 0.0
		var phase_inc = (float(freq) * 2.0 * PI) / sample_rate
		for i in range(frames_per_freq):
			var sample = sin(phase) * 0.25 * (1.0 - float(i) / frames_per_freq)
			playback.push_frame(Vector2(sample, sample))
			phase += phase_inc

# --- RESPONSIVE ROOM GENERATION ---
func _reposition_responsive() -> void:
	var vp_sz = get_viewport_rect().size
	var center_x = vp_sz.x / 2.0
	
	if door_arch:
		door_arch.position = Vector2(center_x - 160.0, 45.0)
		door_arch.size = Vector2(320.0, 200.0)
		
	if potted_plant:
		potted_plant.position = Vector2(center_x + 180.0, 75.0)
		potted_plant.size = Vector2(100.0, 170.0)
		
	if whiteboard_node:
		whiteboard_node.position = Vector2(center_x - 390.0, 95.0)
		whiteboard_node.size = Vector2(200.0, 110.0)
		
	if left_rack_cabinet:
		left_rack_cabinet.position = Vector2(clamp(center_x - 590.0, 20.0, 70.0), 200.0)
		left_rack_cabinet.size = Vector2(260.0, 360.0)
		
	if server_cabinet:
		server_cabinet.position = Vector2(clamp(center_x + 380.0, vp_sz.x - 260.0, vp_sz.x - 200.0), 200.0)
		server_cabinet.size = Vector2(220.0, 380.0)
		
	if center_desk:
		var desk_w = 560.0
		var desk_h = 135.0
		center_desk.size = Vector2(desk_w, desk_h)
		center_desk.position = Vector2(center_x - desk_w / 2.0, clamp(vp_sz.y * 0.49, 365.0, 415.0))
		
	var pad_y = clamp(vp_sz.y * 0.75, 540.0, vp_sz.y - 160.0)
	var pad_w = 360.0
	var pad_h = 140.0
	if left_pad:
		left_pad.size = Vector2(pad_w, pad_h)
		left_pad.position = Vector2(center_x - pad_w - 40.0, pad_y)
	if right_pad:
		right_pad.size = Vector2(pad_w, pad_h)
		right_pad.position = Vector2(center_x + 40.0, pad_y)
		
	if char_pos == Vector2.ZERO:
		char_pos = Vector2(center_x - 110.0, 260.0)
		character_node.position = char_pos
		
	if mobile_controls_root:
		var pad_base = mobile_controls_root.get_node_or_null("DpadBase") as Control
		if pad_base:
			pad_base.position = Vector2(40.0, vp_sz.y - 160.0)
			
	_position_header_elements()
	
	if cables_container:
		cables_container.queue_redraw()

# --- HOVER SCALE UTILITY ---
func _setup_hover_scale(node: Control, scale_mult: float) -> void:
	node.mouse_entered.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector2(scale_mult, scale_mult), 0.12)
	)
	node.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector2.ONE, 0.12)
	)

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
		{ "title": "Misi Level 2.2", "text": "Saring trafik yang meminta akses ke server internal: izinkan IP Privat, blokir IP Publik." },
		{ "title": "1. Aturan Firewall", "text": "Baca aturannya dulu. ALLOW untuk IP Privat (10.x, 172.16 - 172.31, 192.168.x) dan BLOCK untuk IP Publik.", "target": whiteboard_node, "pointer": "hand" },
		{ "title": "2. Konsol Filter", "text": "Dekati meja tengah ini lalu klik tombol Filter (atau tekan Spasi) untuk membuka konsol penyaring.", "target": center_desk, "pointer": "both" },
		{ "title": "3. Zona Hasil", "text": "Di konsol, tempatkan tiap alamat IP ke zona yang benar: IP Privat ke LAN Aman (kiri), IP Publik ke Karantina (kanan).", "target": (func(): return TutorialOverlay.union_of([left_pad, right_pad])), "pointer": "arrow" },
		{ "title": "Siap?", "text": "Selesaikan misi sebelum waktu habis. Lupa caranya? Tekan tombol ? (kuning) di dekat pewaktu kapan saja untuk melihat panduan ini lagi." }
	]
