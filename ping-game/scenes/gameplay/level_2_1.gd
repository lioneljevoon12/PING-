extends Control

# Level 2.1 - Sortir IPv4 ke Kelas A, B, atau C
# Sesuai Proposal & Desain Figma 100%:
# - Kontrol penuh Karakter (Joystick mobile & Keyboard WASD/Arrow)
# - Kelas A: Oktet pertama 1 - 126
# - Kelas B: Oktet pertama 128 - 191
# - Kelas C: Oktet pertama 192 - 223
# - Indikator pengurangan hati jelas (Heart break / cracked kawaii animation)
# - Layout rapi tanpa clipping/jumping pada antrean kartu

const IPClassifier = preload("res://scripts/ip_classifier.gd")
const LevelConfig = preload("res://scripts/level_config.gd")
const PacketItemScene = preload("res://scenes/gameplay/packet_item.tscn")
const ClassBinScene = preload("res://scenes/gameplay/class_bin.tscn")
const CloseButtonScene = preload("res://scenes/close_button.tscn")
const PauseModalScene = preload("res://scenes/pause_modal.tscn")

const MOVE_SPEED = 240.0

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

# Dynamic loaded textures (Safe against unimported files)
var tex_router_obj: Texture2D = null
var tex_cabinet: Texture2D = null
var tex_pc_operator: Texture2D = null

# Config Resource
var config: Resource = null

# Scene Node References
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer
@onready var wall_background: Control = %WallBackground
@onready var top_wall_band: Control = %TopWallBand
@onready var door_arch: TextureRect = %DoorArch
@onready var potted_plant: TextureRect = %PottedPlant
@onready var left_rack_cabinet: TextureRect = %LeftRackCabinet
@onready var server_cabinet: TextureRect = %ServerCabinet
@onready var floor_area: Panel = %FloorArea
@onready var cables_container: Control = %CablesContainer
@onready var center_desk: Control = %CenterDesk
@onready var desk_packets_row: HBoxContainer = %DeskPacketsRow
@onready var pc_node: TextureRect = %PCNode
@onready var sortir_btn: Button = %SortirBtn
@onready var sortir_alert_pill: PanelContainer = %SortirAlertPill
@onready var bin_a_pad: Control = %BinA_Pad
@onready var bin_b_pad: Control = %BinB_Pad
@onready var bin_c_pad: Control = %BinC_Pad
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
var sorting_modal: Control
var sorting_card: Control
var whiteboard_modal: Control
var pause_modal: Control
var win_modal: Control
var win_card: Control
var win_stars_row: HBoxContainer
var win_time_lbl: Label
var win_score_lbl: Label
var gameover_modal: Control
var gameover_card: Control
var gameover_reason_lbl: Label
var game_dialog: Control

# Sorting Modal Elements
var sorting_queue_container: HBoxContainer
var sorting_bins_dict: Dictionary = {}
var active_packets: Array[Control] = []
var selected_packet: Control = null

# Floor Pad Bins (Room view interactive bins)
var floor_bins_dict: Dictionary = {}

# Gameplay State
var is_game_active: bool = false
var has_won: bool = false
var time_remaining: float = 165.0
var hearts: int = 3
var packets_to_sort: int = 10
var packets_sorted_count: int = 0
var generated_packet_queue: Array[Dictionary] = []

func _ready() -> void:
	tex_router_obj = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/router objects 1.png")
	tex_cabinet = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/lab_pastel_server_cabinet.png")
	tex_pc_operator = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/operator_pc_2_1.png")
	
	if server_cabinet and tex_cabinet:
		server_cabinet.texture = tex_cabinet
	if pc_node and tex_pc_operator:
		pc_node.texture = tex_pc_operator
		
	config = LevelConfig.new()
	config.packet_count = 10
	config.time_limit = 165.0
	config.initial_hearts = 3
	
	time_remaining = config.time_limit
	hearts = config.initial_hearts
	packets_to_sort = config.packet_count
	
	_load_walk_frames()
	_generate_packet_data_list()
	
	_build_room_decorations()
	_build_character()
	_build_header_ui()
	_build_mobile_controls()
	
	_build_sorting_modal()
	_build_intro_modal()
	_build_whiteboard_modal()
	_build_pause_modal()
	_build_win_gameover_modals()
	_build_toast_ui()
	
	help_btn = TutorialOverlay.make_help_button(header_ui, Vector2(0, 20), _on_help_pressed)
	_reposition_responsive()
	get_viewport().size_changed.connect(_reposition_responsive)
	
	_open_intro_modal()

func _load_walk_frames() -> void:
	walk_frames.clear()
	for i in range(1, 33):
		var p = "res://art/assets/PING! Assets/Sprite animation/router walk/%d.png" % i
		if ResourceLoader.exists(p):
			var tex = load(p)
			if tex:
				walk_frames.append(tex)

func _generate_packet_data_list() -> void:
	generated_packet_queue.clear()
	var class_distribution = ["A", "B", "C", "A", "B", "C", "A", "B", "C", "C"]
	class_distribution.shuffle()
	
	for i in range(packets_to_sort):
		var target_c = class_distribution[i % class_distribution.size()]
		var pdata = IPClassifier.generate_packet_data(target_c)
		generated_packet_queue.append(pdata)

func _process(delta: float) -> void:
	if is_game_active and not has_won:
		time_remaining = max(0.0, time_remaining - delta)
		_update_timer_display()
		if time_remaining <= 0.0:
			is_game_active = false
			_trigger_game_over("Waktu habis! Sortir paket IPv4 belum selesai.")

	# Movement logic
	var move_vec = Vector2.ZERO
	var any_modal_open = (intro_modal and intro_modal.visible) or \
						 (sorting_modal and sorting_modal.visible) or \
						 (whiteboard_modal and whiteboard_modal.visible) or \
						 (pause_modal and pause_modal.visible) or \
						 (win_modal and win_modal.visible) or \
						 (gameover_modal and gameover_modal.visible)
						 
	if is_game_active and not any_modal_open:
		move_vec = input_dir
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
			move_vec.x += 1.0
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
			move_vec.x -= 1.0
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			move_vec.y += 1.0
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			move_vec.y -= 1.0
			
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER):
			_trigger_proximity_action()
			
	if move_vec.length() > 0.05:
		move_vec = move_vec.normalized()
		var delta_mov = move_vec * MOVE_SPEED * delta
		var vp_sz = get_viewport_rect().size
		
		var test_x = clamp(char_pos.x + delta_mov.x, 30.0, vp_sz.x - 140.0)
		if not _is_room_collision(Vector2(test_x, char_pos.y)):
			char_pos.x = test_x
			
		var test_y = clamp(char_pos.y + delta_mov.y, 220.0, vp_sz.y - 120.0)
		if not _is_room_collision(Vector2(char_pos.x, test_y)):
			char_pos.y = test_y
			
		character_node.position = char_pos
		
		# Walk frames animation
		walk_frame_index += delta * 18.0
		if walk_frames.size() > 0:
			var idx = int(walk_frame_index) % walk_frames.size()
			char_sprite.texture = walk_frames[idx]
			
		if move_vec.x > 0.05:
			char_sprite.flip_h = false
		elif move_vec.x < -0.05:
			char_sprite.flip_h = true
			
		footstep_timer += delta
		if footstep_timer > 0.28:
			footstep_timer = 0.0
			_play_footstep()
	else:
		if char_sprite:
			char_sprite.texture = (walk_frames[0] if walk_frames.size() > 0 else tex_char_idle)
			
	_update_proximity_prompts()

func _is_room_collision(pos: Vector2) -> bool:
	var feet_l = pos.x + 35.0
	var feet_r = pos.x + 185.0
	var feet_t = pos.y + 60.0
	var feet_b = pos.y + 115.0
	
	# 1. Top Wall boundary
	if feet_t < 240.0:
		return true
		
	# 2. Left Rack Cabinet
	if left_rack_cabinet:
		var lr = left_rack_cabinet.get_global_rect()
		if feet_r > lr.position.x + 10.0 and feet_l < lr.position.x + lr.size.x - 10.0:
			if feet_b > lr.position.y + 80.0 and feet_t < lr.position.y + lr.size.y:
				return true
			
	# 3. Center Desk
	if center_desk:
		var desk_rect = center_desk.get_global_rect()
		if feet_r > desk_rect.position.x + 20.0 and feet_l < desk_rect.position.x + desk_rect.size.x - 20.0:
			if feet_b > desk_rect.position.y + 35.0 and feet_t < desk_rect.position.y + desk_rect.size.y - 10.0:
				return true
			
	# 4. Right Server Cabinet
	if server_cabinet:
		var s_rect = server_cabinet.get_global_rect()
		if feet_r > s_rect.position.x + 10.0 and feet_l < s_rect.position.x + s_rect.size.x - 10.0:
			if feet_b > s_rect.position.y + 80.0 and feet_t < s_rect.position.y + s_rect.size.y:
				return true
			
	return false

func _update_proximity_prompts() -> void:
	if not sortir_alert_pill:
		return
	var char_center = char_pos + Vector2(110.0, 60.0)
	var desk_center = center_desk.position + center_desk.size / 2.0
	var near_desk = char_center.distance_to(desk_center) < 220.0
	
	sortir_alert_pill.visible = is_game_active and near_desk
	sortir_btn.modulate = Color(1.15, 1.15, 1.15, 1.0) if near_desk else Color.WHITE

func _trigger_proximity_action() -> void:
	var char_center = char_pos + Vector2(110.0, 60.0)
	var desk_center = center_desk.position + center_desk.size / 2.0
	var wb_center = whiteboard_node.position + whiteboard_node.size / 2.0
	
	if char_center.distance_to(desk_center) < 230.0:
		_open_sorting_modal()
	elif char_center.distance_to(wb_center) < 240.0:
		_open_whiteboard_modal()

func _update_timer_display() -> void:
	if not timer_label:
		return
	var mins = int(time_remaining) / 60
	var secs = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	
	if time_remaining < 20.0 and time_remaining > 0.0:
		timer_label.add_theme_color_override("font_color", Color("#dc2626"))
		if clock_icon:
			clock_icon.modulate = Color(1.0, 0.4, 0.4, 1.0)
	else:
		timer_label.add_theme_color_override("font_color", Color("#4a2e2b"))
		if clock_icon:
			clock_icon.modulate = Color.WHITE

# --- ROOM VISUALS BUILDER ---
func _build_room_decorations() -> void:
	var sb_floor = StyleBoxFlat.new()
	sb_floor.bg_color = Color(0.81, 0.89, 0.92, 0.35)
	sb_floor.border_color = Color("#7fa6b3")
	sb_floor.set_border_width_all(3)
	sb_floor.set_corner_radius_all(24)
	floor_area.add_theme_stylebox_override("panel", sb_floor)
	
	# Left Rack Cabinet Shelves
	var rack_pill = _create_mini_pill("Rak Peralatan Switch & Kabel LAN", Color("#eff6ff"), Color("#1e40af"))
	rack_pill.position = Vector2(20, -28)
	left_rack_cabinet.add_child(rack_pill)
	
	var shelf_container = Control.new()
	shelf_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	left_rack_cabinet.add_child(shelf_container)
	
	var tex_c_green = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-hijau.png")
	var tex_c_yellow = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-kuning.png")
	var tex_c_blue = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-biru.png")
	var tex_c_red = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-merah.png")
	var tex_switch = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage1/1.3/switch-happy.png")
	
	if tex_c_green: _add_shelf_item(shelf_container, tex_c_green, Vector2(30, 75))
	if tex_c_yellow: _add_shelf_item(shelf_container, tex_c_yellow, Vector2(80, 75))
	if tex_c_blue: _add_shelf_item(shelf_container, tex_c_blue, Vector2(130, 75))
	if tex_c_red: _add_shelf_item(shelf_container, tex_c_red, Vector2(180, 75))
	
	if tex_switch:
		var sw_rect = TextureRect.new()
		sw_rect.texture = tex_switch
		sw_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sw_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sw_rect.size = Vector2(90, 48)
		sw_rect.position = Vector2(75, 160)
		shelf_container.add_child(sw_rect)
		
	if tex_c_yellow: _add_shelf_item(shelf_container, tex_c_yellow, Vector2(40, 245))
	if tex_c_green: _add_shelf_item(shelf_container, tex_c_green, Vector2(100, 245))
	if tex_c_blue: _add_shelf_item(shelf_container, tex_c_blue, Vector2(160, 245))
	
	# Whiteboard on Wall
	var wb_panel = PanelContainer.new()
	wb_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb_wb = StyleBoxFlat.new()
	sb_wb.bg_color = Color("#ffffff")
	sb_wb.border_color = Color("#3b82f6")
	sb_wb.set_border_width_all(3)
	sb_wb.set_corner_radius_all(10)
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
	wb_title.add_theme_font_size_override("font_size", 11)
	wb_title.add_theme_color_override("font_color", Color("#1e3a8a"))
	wb_vbox.add_child(wb_title)
	
	var wb_content = Label.new()
	wb_content.text = "A: 1-126  |  B: 128-191  |  C: 192-223"
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
	
	# Alert Pill "! Sortir Kelas IPv4"
	var sb_alert = StyleBoxFlat.new()
	sb_alert.bg_color = Color("#ffffff")
	sb_alert.border_color = Color("#ef4444")
	sb_alert.set_border_width_all(2)
	sb_alert.set_corner_radius_all(12)
	sb_alert.content_margin_left = 10
	sb_alert.content_margin_right = 10
	sb_alert.content_margin_top = 2
	sb_alert.content_margin_bottom = 2
	sortir_alert_pill.add_theme_stylebox_override("panel", sb_alert)
	var alert_lbl = sortir_alert_pill.get_node("SortirAlertLabel") as Label
	alert_lbl.add_theme_font_override("font", font_extrabold)
	alert_lbl.add_theme_color_override("font_color", Color("#dc2626"))
	
	# Sortir Button on Desk
	var sb_sortir = StyleBoxFlat.new()
	sb_sortir.bg_color = Color("#fed7aa")
	sb_sortir.border_color = Color("#ea580c")
	sb_sortir.set_border_width_all(2)
	sb_sortir.set_corner_radius_all(8)
	sortir_btn.add_theme_stylebox_override("normal", sb_sortir)
	sortir_btn.add_theme_stylebox_override("hover", sb_sortir)
	sortir_btn.add_theme_stylebox_override("pressed", sb_sortir)
	sortir_btn.add_theme_font_override("font", font_black)
	sortir_btn.add_theme_color_override("font_color", Color("#9a3412"))
	sortir_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	sortir_btn.pressed.connect(_open_sorting_modal)
	_setup_hover_scale(sortir_btn, 1.1)
	
	# Mini router mascot in center of desk
	var desk_router = TextureRect.new()
	if tex_router_obj:
		desk_router.texture = tex_router_obj
	desk_router.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desk_router.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	desk_router.size = Vector2(56, 36)
	desk_router.position = Vector2(125, 20)
	center_desk.add_child(desk_router)
	
	# 3 Floor Router Pads (A, B, C)
	_setup_floor_pad(bin_a_pad, "A", Color("#a7f3d0"), Color("#0d9488"), "KELAS A (1-126)")
	_setup_floor_pad(bin_b_pad, "B", Color("#bae6fd"), Color("#0284c7"), "KELAS B (128-191)")
	_setup_floor_pad(bin_c_pad, "C", Color("#ddd6fe"), Color("#7c3aed"), "KELAS C (192-223)")
	
	cables_container.draw.connect(_on_cables_draw)

func _add_shelf_item(parent: Control, tex: Texture2D, pos: Vector2) -> void:
	var tr = TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = Vector2(40, 30)
	tr.position = pos
	parent.add_child(tr)

func _setup_floor_pad(pad_node: Control, cls: String, bg_col: Color, border_col: Color, label_text: String) -> void:
	var pad_panel = PanelContainer.new()
	pad_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#e5d0b1")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(8)
	pad_panel.add_theme_stylebox_override("panel", sb)
	pad_node.add_child(pad_panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	pad_panel.add_child(vbox)
	
	var router_box = PanelContainer.new()
	var sb_r = StyleBoxFlat.new()
	sb_r.bg_color = bg_col
	sb_r.border_color = border_col
	sb_r.set_border_width_all(2)
	sb_r.set_corner_radius_all(10)
	router_box.add_theme_stylebox_override("panel", sb_r)
	router_box.custom_minimum_size = Vector2(0, 68)
	vbox.add_child(router_box)
	
	var r_tr = TextureRect.new()
	if tex_router_obj:
		r_tr.texture = tex_router_obj
	r_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r_tr.custom_minimum_size = Vector2(90, 52)
	router_box.add_child(r_tr)
	
	var lbl_panel = PanelContainer.new()
	var sb_lbl = StyleBoxFlat.new()
	sb_lbl.bg_color = Color("#ffffff")
	sb_lbl.border_color = border_col
	sb_lbl.set_border_width_all(1.5)
	sb_lbl.set_corner_radius_all(8)
	sb_lbl.content_margin_left = 8
	sb_lbl.content_margin_right = 8
	sb_lbl.content_margin_top = 2
	sb_lbl.content_margin_bottom = 2
	lbl_panel.add_theme_stylebox_override("panel", sb_lbl)
	vbox.add_child(lbl_panel)
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", border_col.darkened(0.2))
	lbl_panel.add_child(lbl)
	
	var pad_btn = Button.new()
	pad_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad_btn.flat = true
	pad_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pad_btn.pressed.connect(func(): _on_class_bin_selected(cls))
	pad_node.add_child(pad_btn)
	_setup_hover_scale(pad_node, 1.04)
	
	floor_bins_dict[cls] = pad_node

func _on_cables_draw() -> void:
	var desk_rect = center_desk.get_global_rect()
	var desk_bottom_center = Vector2(desk_rect.position.x + desk_rect.size.x * 0.5, desk_rect.position.y + desk_rect.size.y - 10.0)
	
	var colors = [Color("#10b981"), Color("#38bdf8"), Color("#c084fc")]
	var pads = [bin_a_pad, bin_b_pad, bin_c_pad]
	
	for i in range(3):
		var p_rect = pads[i].get_global_rect()
		var p_top = Vector2(p_rect.position.x + p_rect.size.x * 0.5, p_rect.position.y)
		var start_pt = desk_bottom_center + Vector2((i - 1) * 36.0, 0)
		var mid_y = lerp(start_pt.y, p_top.y, 0.5)
		
		var pts = PackedVector2Array([
			start_pt,
			Vector2(start_pt.x, mid_y),
			Vector2(p_top.x, mid_y),
			p_top
		])
		cables_container.draw_polyline(pts, colors[i], 4.0, true)

# --- CHARACTER & CONTROLS BUILDER ---
func _build_character() -> void:
	character_node.custom_minimum_size = Vector2(220, 120)
	character_node.size = Vector2(220, 120)
	character_node.pivot_offset = Vector2(110, 60)
	char_sprite = TextureRect.new()
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

func _build_mobile_controls() -> void:
	mobile_controls_root = Control.new()
	mobile_controls_root.name = "MobileControls"
	mobile_controls_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	mobile_controls_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mobile_controls_root)
	
	# Virtual Joystick Pad (Bottom-Left)
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

# --- HEADER UI BUILDER (KAWAII HEARTS WITH BREAK INDICATOR) ---
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
	back_btn.pressed.connect(_open_pause_modal)
	_setup_hover_scale(back_btn, 1.1)
	header_ui.add_child(back_btn)
	
	# Hearts Container with clear depleted / break indicators
	hearts_panel = PanelContainer.new()
	hearts_panel.name = "HeartsPanel"
	var sb_hearts = StyleBoxFlat.new()
	sb_hearts.bg_color = Color("#e6f7f5")
	sb_hearts.border_color = Color("#4a2e2b")
	sb_hearts.set_border_width_all(2.5)
	sb_hearts.set_corner_radius_all(14)
	sb_hearts.shadow_color = Color(0, 0, 0, 0.15)
	sb_hearts.shadow_size = 4
	sb_hearts.shadow_offset = Vector2(0, 2)
	sb_hearts.set_content_margin_all(6)
	sb_hearts.content_margin_left = 14
	sb_hearts.content_margin_right = 14
	hearts_panel.add_theme_stylebox_override("panel", sb_hearts)
	header_ui.add_child(hearts_panel)
	
	hearts_container = HBoxContainer.new()
	hearts_container.add_theme_constant_override("separation", 10)
	hearts_panel.add_child(hearts_container)
	
	hearts_rects.clear()
	broken_labels.clear()
	
	for i in range(3):
		var slot = Control.new()
		slot.custom_minimum_size = Vector2(34, 30)
		slot.size = Vector2(34, 30)
		hearts_container.add_child(slot)
		
		var h_rect = TextureRect.new()
		h_rect.texture = tex_vector_heart
		h_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		h_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h_rect.pivot_offset = Vector2(17, 15)
		slot.add_child(h_rect)
		hearts_rects.append(h_rect)
		HeartsStyle.schedule_normalize(hearts_rects)
		
		var b_lbl = Label.new()
		b_lbl.text = "✕"
		b_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b_lbl.add_theme_font_override("font", font_black)
		b_lbl.add_theme_font_size_override("font_size", 18)
		b_lbl.add_theme_color_override("font_color", Color("#dc2626"))
		b_lbl.visible = false
		slot.add_child(b_lbl)
		broken_labels.append(b_lbl)
		
	# Level 2.1 Badge
	var level_badge = PanelContainer.new()
	level_badge.name = "LevelBadge"
	var sb_badge = StyleBoxFlat.new()
	sb_badge.bg_color = Color("#ffffff")
	sb_badge.border_color = Color("#4a2e2b")
	sb_badge.set_border_width_all(2.5)
	sb_badge.set_corner_radius_all(12)
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
	num_lvl.text = "2.1"
	num_lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lvl.add_theme_font_override("font", font_black)
	num_lvl.add_theme_font_size_override("font_size", 16)
	num_lvl.add_theme_color_override("font_color", Color("#1e293b"))
	vb_badge.add_child(num_lvl)
	
	# Timer Panel (Jam Beker + 02:45)
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

# --- SORTING MODAL BUILDER (Figma Image 3) ---
func _build_sorting_modal() -> void:
	sorting_modal = Control.new()
	sorting_modal.name = "SortingModal"
	sorting_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	sorting_modal.visible = false
	add_child(sorting_modal)
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	sorting_modal.add_child(dim)
	
	sorting_card = Control.new()
	sorting_card.size = Vector2(960, 560)
	sorting_card.pivot_offset = Vector2(480, 280)
	sorting_modal.add_child(sorting_card)
	
	var bg_panel = PanelContainer.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb_outer = StyleBoxFlat.new()
	sb_outer.bg_color = Color("#fffef7")
	sb_outer.border_color = Color("#7c3aed")
	sb_outer.set_border_width_all(3.5)
	sb_outer.set_corner_radius_all(24)
	sb_outer.shadow_color = Color(0, 0, 0, 0.3)
	sb_outer.shadow_size = 14
	sb_outer.shadow_offset = Vector2(0, 6)
	sb_outer.set_content_margin_all(20)
	bg_panel.add_theme_stylebox_override("panel", sb_outer)
	sorting_card.add_child(bg_panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	bg_panel.add_child(main_vbox)
	
	var header_row = HBoxContainer.new()
	main_vbox.add_child(header_row)
	
	var title_lbl = Label.new()
	title_lbl.text = "Level 2.1: Klasifikasi Alamat IPv4 (Kelas A, B, dan C)"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_override("font", font_black)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color("#581c87"))
	header_row.add_child(title_lbl)
	
	var close_btn = CloseButtonScene.instantiate()
	if close_btn.has_signal("closed"):
		close_btn.closed.connect(_close_sorting_modal)
	else:
		close_btn.pressed.connect(_close_sorting_modal)
	header_row.add_child(close_btn)
	
	var dashed_panel = PanelContainer.new()
	dashed_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb_inner = StyleBoxFlat.new()
	sb_inner.bg_color = Color("#fcfcf9")
	sb_inner.border_color = Color("#d8b4fe")
	sb_inner.set_border_width_all(2)
	sb_inner.set_corner_radius_all(16)
	sb_inner.set_content_margin_all(14)
	dashed_panel.add_theme_stylebox_override("panel", sb_inner)
	main_vbox.add_child(dashed_panel)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 12)
	dashed_panel.add_child(content_vbox)
	
	var sub_lbl = Label.new()
	sub_lbl.text = "PILIH PAKET IPv4 LALU MASUKKAN KE KELAS YANG SESUAI DENGAN OKTET PERTAMA:"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_override("font", font_black)
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color("#475569"))
	content_vbox.add_child(sub_lbl)
	
	# ScrollContainer with invisible scrollbar to prevent line clipping
	var scroll_q = ScrollContainer.new()
	scroll_q.custom_minimum_size = Vector2(0, 96)
	scroll_q.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_q.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	content_vbox.add_child(scroll_q)
	
	sorting_queue_container = HBoxContainer.new()
	sorting_queue_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sorting_queue_container.alignment = BoxContainer.ALIGNMENT_CENTER
	sorting_queue_container.add_theme_constant_override("separation", 14)
	scroll_q.add_child(sorting_queue_container)
	
	var sep = HSeparator.new()
	content_vbox.add_child(sep)
	
	# 3 Class Bins (A, B, C)
	var bins_row = HBoxContainer.new()
	bins_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bins_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bins_row.add_theme_constant_override("separation", 24)
	content_vbox.add_child(bins_row)
	
	sorting_bins_dict.clear()
	for cls in ["A", "B", "C"]:
		var bin_inst = ClassBinScene.instantiate()
		bin_inst.target_class = cls
		bin_inst.bin_selected.connect(_on_class_bin_selected)
		bins_row.add_child(bin_inst)
		sorting_bins_dict[cls] = bin_inst

func _populate_packet_cards() -> void:
	for child in sorting_queue_container.get_children():
		child.queue_free()
	active_packets.clear()
	selected_packet = null
	
	for i in range(generated_packet_queue.size()):
		var pdata = generated_packet_queue[i]
		var item = PacketItemScene.instantiate()
		sorting_queue_container.add_child(item)
		item.set_packet_info(i + 1, pdata)
		item.selected.connect(_on_packet_selected)
		item.drag_started.connect(_on_packet_drag_started)
		item.drag_ended.connect(_on_packet_drag_ended)
		active_packets.append(item)
		
	_refresh_desk_preview()

func _refresh_desk_preview() -> void:
	for child in desk_packets_row.get_children():
		child.queue_free()
		
	var show_count = min(3, generated_packet_queue.size() - packets_sorted_count)
	for i in range(show_count):
		var idx = packets_sorted_count + i
		if idx < generated_packet_queue.size():
			var pdata = generated_packet_queue[idx]
			var mini_card = PanelContainer.new()
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color("#ffffff")
			sb.border_color = Color("#3b82f6")
			sb.set_border_width_all(1.5)
			sb.set_corner_radius_all(8)
			sb.set_content_margin_all(4)
			mini_card.add_theme_stylebox_override("panel", sb)
			
			var vb = VBoxContainer.new()
			vb.alignment = BoxContainer.ALIGNMENT_CENTER
			mini_card.add_child(vb)
			
			var l_top = Label.new()
			l_top.text = "PAKET IP #%d" % (idx + 1)
			l_top.add_theme_font_override("font", font_bold)
			l_top.add_theme_font_size_override("font_size", 9)
			l_top.add_theme_color_override("font_color", Color("#2563eb"))
			vb.add_child(l_top)
			
			var l_ip = Label.new()
			l_ip.text = "[%d] %s" % [pdata["first_octet"], pdata["rest"]]
			l_ip.add_theme_font_override("font", font_extrabold)
			l_ip.add_theme_font_size_override("font_size", 10)
			l_ip.add_theme_color_override("font_color", Color("#1e293b"))
			vb.add_child(l_ip)
			
			desk_packets_row.add_child(mini_card)

# --- DRAG & DROP AND TAP LOGIC ---
func _on_packet_selected(item: Control) -> void:
	if selected_packet == item:
		if not item.is_selected:
			selected_packet = null
	else:
		if selected_packet and is_instance_valid(selected_packet):
			selected_packet.set_selected(false)
		selected_packet = item
		_play_tone(587.33, 0.08, 0.15)

func _on_packet_drag_started(item: Control) -> void:
	if selected_packet and selected_packet != item and is_instance_valid(selected_packet):
		selected_packet.set_selected(false)
	selected_packet = item
	item.set_selected(true)
	_play_tone(659.25, 0.08, 0.15)

func _on_packet_drag_ended(item: Control, global_drop_pos: Vector2) -> void:
	# Seret selesai: pilihan "ketuk" dibersihkan agar tidak menempel pada kartu
	item.set_selected(false)
	if selected_packet == item:
		selected_packet = null
	var item_center = item.global_position + item.size / 2.0
	
	var candidate_bins: Array[Control] = []
	for bin_inst in sorting_bins_dict.values():
		if bin_inst.contains_point(item_center):
			candidate_bins.append(bin_inst)
			
	if candidate_bins.is_empty():
		item.animate_return_home()
		return
		
	var best_bin: Control = candidate_bins[0]
	var best_dist = item_center.distance_to(best_bin.global_position + best_bin.size / 2.0)
	for i in range(1, candidate_bins.size()):
		var b = candidate_bins[i]
		var d = item_center.distance_to(b.global_position + b.size / 2.0)
		if d < best_dist:
			best_dist = d
			best_bin = b
			
	_evaluate_packet_classification(item, best_bin.target_class, best_bin)

func _on_class_bin_selected(target_class: String) -> void:
	if selected_packet and is_instance_valid(selected_packet):
		var target_bin: Control = sorting_bins_dict.get(target_class, null)
		_evaluate_packet_classification(selected_packet, target_class, target_bin)
	else:
		show_toast("Pilih atau seret salah satu kartu paket data di atas terlebih dahulu!", 2.0)
		_play_tone(440.0, 0.08, 0.15)

func _evaluate_packet_classification(item: Control, chosen_class: String, bin_inst: Control) -> void:
	if not is_game_active or has_won:
		return
		
	var actual_class = item.packet_data.get("class", "")
	var first_octet = item.packet_data.get("first_octet", 1)
	var educational_hint = item.packet_data.get("hint", "")
	
	if chosen_class == actual_class:
		_handle_correct_classification(item, chosen_class, bin_inst)
	else:
		_handle_wrong_classification(item, chosen_class, actual_class, first_octet, educational_hint, bin_inst)

func _handle_correct_classification(item: Control, chosen_class: String, bin_inst: Control) -> void:
	_play_chime_success()
	
	if bin_inst:
		bin_inst.flash_success()
		
	if floor_bins_dict.has(chosen_class):
		var floor_pad = floor_bins_dict[chosen_class] as Control
		var tw_pad = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_pad.tween_property(floor_pad, "scale", Vector2(1.08, 1.08), 0.15)
		tw_pad.tween_property(floor_pad, "scale", Vector2.ONE, 0.15)
		
	packets_sorted_count += 1
	var target_center = bin_inst.global_position + bin_inst.size / 2.0 if bin_inst else item.global_position
	
	active_packets.erase(item)
	selected_packet = null
	
	item.animate_success_absorb(target_center, func():
		_refresh_desk_preview()
		if packets_sorted_count >= packets_to_sort:
			_trigger_win()
	)

func _handle_wrong_classification(item: Control, chosen_class: String, actual_class: String, first_octet: int, educational_hint: String, bin_inst: Control) -> void:
	_play_buzz_error()
	
	if bin_inst:
		bin_inst.flash_error()
		
	_shake_screen()
	
	# Kurangi HP & beri tanda visual jelas pada HUD Hati
	hearts = max(0, hearts - 1)
	_update_hearts_display(true)
	
	var hint_msg = "❌ SALAH! %d itu rentang %s, jadi KELAS %s!" % [
		first_octet,
		IPClassifier.get_range_text(actual_class),
		actual_class
	]
	show_toast(hint_msg, 3.5)
	
	item.animate_return_home()
	
	if hearts <= 0:
		is_game_active = false
		_trigger_game_over("Nyawa teknisi habis! Pelajari kembali rentang oktet Kelas A, B, dan C.")

func _shake_screen() -> void:
	var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in range(4):
		tw.tween_property(self, "position", Vector2(randf_range(-7.0, 7.0), randf_range(-5.0, 5.0)), 0.04)
	tw.tween_property(self, "position", Vector2.ZERO, 0.05)

func _update_hearts_display(is_damage_event: bool = false) -> void:
	HeartsStyle.refresh(hearts_rects, hearts)

# --- INTRO MODAL BUILDER (Figma Image 1) ---
func _build_intro_modal() -> void:
	intro_modal = Control.new()
	intro_modal.name = "IntroModal"
	intro_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_modal.visible = false
	add_child(intro_modal)
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	intro_modal.add_child(dim)
	
	var intro_card = Control.new()
	intro_card.size = Vector2(820, 520)
	intro_card.pivot_offset = Vector2(410, 260)
	intro_modal.add_child(intro_card)
	
	var bg_panel = PanelContainer.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fffef7")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(22)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 6)
	sb.set_content_margin_all(24)
	bg_panel.add_theme_stylebox_override("panel", sb)
	intro_card.add_child(bg_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	bg_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "📦 Level 2.1 – Pengelompokan Kelas Alamat IPv4"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font_black)
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("#4a2e2b"))
	vbox.add_child(title)
	
	var tujuan_panel = PanelContainer.new()
	var sb_tujuan = StyleBoxFlat.new()
	sb_tujuan.bg_color = Color("#ffffff")
	sb_tujuan.border_color = Color("#cbd5e1")
	sb_tujuan.set_border_width_all(1.5)
	sb_tujuan.set_corner_radius_all(10)
	sb_tujuan.set_content_margin_all(8)
	tujuan_panel.add_theme_stylebox_override("panel", sb_tujuan)
	vbox.add_child(tujuan_panel)
	
	var vb_tujuan = VBoxContainer.new()
	vb_tujuan.add_theme_constant_override("separation", 4)
	tujuan_panel.add_child(vb_tujuan)
	
	var hb_tujuan = HBoxContainer.new()
	hb_tujuan.add_theme_constant_override("separation", 8)
	vb_tujuan.add_child(hb_tujuan)
	
	var pill_tujuan = _create_mini_pill("TUJUAN", Color("#fecaca"), Color("#991b1b"))
	hb_tujuan.add_child(pill_tujuan)
	
	var lbl_tujuan = Label.new()
	lbl_tujuan.text = "Kelompokkan paket IPv4 yang masuk ke Kelas A, B, atau C!"
	lbl_tujuan.add_theme_font_override("font", font_bold)
	lbl_tujuan.add_theme_font_size_override("font_size", 13)
	lbl_tujuan.add_theme_color_override("font_color", Color("#1e293b"))
	hb_tujuan.add_child(lbl_tujuan)
	
	var lbl_subtujuan = Label.new()
	lbl_subtujuan.text = "• Cara menentukan kelas: Cukup perhatikan ANGKA PERTAMA (oktet ke-1) sebelum tanda titik.\n📖 Catatan: Pembagian Kelas A, B, C adalah konsep classful IPv4 historis sebagai dasar pengalamatan."
	lbl_subtujuan.add_theme_font_override("font", font_semibold)
	lbl_subtujuan.add_theme_font_size_override("font_size", 11)
	lbl_subtujuan.add_theme_color_override("font_color", Color("#64748b"))
	vb_tujuan.add_child(lbl_subtujuan)
	
	var cards_row = HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 12)
	vbox.add_child(cards_row)
	
	cards_row.add_child(_create_intro_class_card("KELAS A", "Oktet 1: 1 - 126", "Contoh: 10.24.1.5", Color("#e6fffa"), Color("#319795")))
	cards_row.add_child(_create_intro_class_card("KELAS B", "Oktet 1: 128 - 191", "Contoh: 172.16.0.4", Color("#ebf8ff"), Color("#3182ce")))
	cards_row.add_child(_create_intro_class_card("KELAS C", "Oktet 1: 192 - 223", "Contoh: 192.168.1.10", Color("#f3e8ff"), Color("#805ad5")))
	
	var bottom_row = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 12)
	vbox.add_child(bottom_row)
	
	var c_ctrl = _create_info_box("🎮 LANGKAH BERMAIN & KONTROL", "1. Gunakan Joystick atau Tombol WASD/Panah untuk bergerak mendekati Meja Sortir.\n2. Klik 'Sortir' untuk membuka antrean paket.\n3. Drag kartu paket IPv4 ke keranjang kelas, ATAU klik kartu lalu klik keranjang.")
	c_ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(c_ctrl)
	
	var c_cond = _create_info_box("⭐ KONDISI MENYELESAIKAN MISI", "• Seluruh 10 kartu paket IPv4 berhasil disortir.\n• Bintang 3: Nyawa penuh (3 HP) & sisa waktu banyak.\n• Bintang 2: Minimal 2 HP tersisa.")
	c_cond.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(c_cond)
	
	var btn_start = Button.new()
	btn_start.text = "MULAI"
	btn_start.custom_minimum_size = Vector2(220, 48)
	btn_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_start.add_theme_font_override("font", font_black)
	btn_start.add_theme_font_size_override("font_size", 17)
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color("#99f6e4")
	sb_btn.border_color = Color("#0d9488")
	sb_btn.set_border_width_all(2.5)
	sb_btn.set_corner_radius_all(14)
	btn_start.add_theme_stylebox_override("normal", sb_btn)
	btn_start.add_theme_stylebox_override("hover", sb_btn)
	btn_start.add_theme_stylebox_override("pressed", sb_btn)
	btn_start.add_theme_color_override("font_color", Color("#0f766e"))
	btn_start.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_start.pressed.connect(_on_intro_start_pressed)
	_setup_hover_scale(btn_start, 1.08)
	vbox.add_child(btn_start)

func _create_intro_class_card(cls_title: String, octet_str: String, example_str: String, bg_col: Color, border_col: Color) -> Control:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	
	var vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	
	var pill = _create_mini_pill(cls_title, border_col.lightened(0.8), border_col)
	vb.add_child(pill)
	
	var l_oct = Label.new()
	l_oct.text = octet_str
	l_oct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_oct.add_theme_font_override("font", font_black)
	l_oct.add_theme_font_size_override("font_size", 12)
	l_oct.add_theme_color_override("font_color", border_col.darkened(0.2))
	vb.add_child(l_oct)
	
	var l_ex = Label.new()
	l_ex.text = example_str
	l_ex.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_ex.add_theme_font_override("font", font_semibold)
	l_ex.add_theme_font_size_override("font_size", 10)
	l_ex.add_theme_color_override("font_color", Color("#64748b"))
	vb.add_child(l_ex)
	
	return panel

func _create_info_box(title: String, text: String) -> Control:
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#cbd5e1")
	sb.set_border_width_all(1.5)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	
	var vb = VBoxContainer.new()
	panel.add_child(vb)
	
	var l_t = Label.new()
	l_t.text = title
	l_t.add_theme_font_override("font", font_black)
	l_t.add_theme_font_size_override("font_size", 11)
	l_t.add_theme_color_override("font_color", Color("#334155"))
	vb.add_child(l_t)
	
	var l_c = Label.new()
	l_c.text = text
	l_c.add_theme_font_override("font", font_semibold)
	l_c.add_theme_font_size_override("font_size", 10)
	l_c.add_theme_color_override("font_color", Color("#64748b"))
	vb.add_child(l_c)
	
	return panel

func _create_mini_pill(text: String, bg_col: Color, text_col: Color) -> PanelContainer:
	var pc = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = text_col
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	pc.add_theme_stylebox_override("panel", sb)
	
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font_black)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", text_col)
	pc.add_child(l)
	return pc

func _open_intro_modal() -> void:
	intro_modal.visible = true
	var card = intro_modal.get_child(1) as Control
	_animate_modal_open(intro_modal, card)

func _on_intro_start_pressed() -> void:
	_play_tone(523.25, 0.1, 0.2)
	intro_modal.visible = false
	_populate_packet_cards()
	# Panduan bermain: bagian ruangan -> buka mesin sortir -> bagian mesin sortir -> mulai
	TutorialOverlay.start(self, _tutorial_room_steps(), func():
		_open_sorting_modal()
		TutorialOverlay.start(self, _tutorial_sort_steps(), func():
			is_game_active = true
		)
	)

# --- PANDUAN BERMAIN (hint pop up dengan tangan/panah) ---
func _union_rect(nodes: Array) -> Rect2:
	var r = Rect2()
	var first = true
	for n in nodes:
		if n is Control and (n as Control).is_visible_in_tree():
			var gr = (n as Control).get_global_rect()
			r = gr if first else r.merge(gr)
			first = false
	return r

func _tutorial_room_steps() -> Array:
	var dpad = mobile_controls_root.get_node_or_null("DpadBase") if mobile_controls_root else null
	return [
		{ "title": "Selamat datang, Teknisi!", "text": "Tugasmu: sortir paket alamat IPv4 ke Kelas A, B, atau C sebelum waktu habis. Yuk lihat caranya!" },
		{ "title": "1. Meja Sortir", "text": "Dekati meja ini, lalu klik tombol Sortir (atau tekan Spasi) untuk membuka mesin sortir paket.", "target": center_desk, "pointer": "both" },
		{ "title": "2. Papan Contekan", "text": "Papan di atas berisi rentang oktet pertama tiap kelas. Dekati dan klik papan kapan saja kamu lupa.", "target": whiteboard_node, "pointer": "hand" },
		{ "title": "3. Pad Kelas", "text": "Tiga pad di lantai ini mewakili Kelas A, B, dan C. Paket yang benar akan menyala hijau di sini.", "target": func(): return _union_rect([bin_a_pad, bin_b_pad, bin_c_pad]), "pointer": "arrow" },
	]

func _tutorial_sort_steps() -> Array:
	var hearts_panel = header_ui.get_node_or_null("HeartsPanel") if header_ui else null
	return [
		{ "title": "4. Antrean Paket", "text": "Ini paket IPv4 yang harus disortir. Lihat angka PERTAMA pada alamatnya (oktet pertama), lalu klik paketnya.", "target": sorting_queue_container.get_parent(), "pointer": "hand" },
		{ "title": "5. Masukkan ke Kelas", "text": "Seret paket ke kelas yang tepat, atau klik paket lalu klik kelasnya.\nKelas A: 1–126  |  Kelas B: 128–191  |  Kelas C: 192–223.", "target": func(): return _union_rect(sorting_bins_dict.values()), "pointer": "both" },
		{ "title": "Siap?", "text": "Sortir semua paket sebelum waktu habis. Butuh bantuan lagi? Tekan tombol ? di pojok kanan atas." },
	]

var help_btn: Button

func _on_help_pressed() -> void:
	if get_tree().paused:
		return
	if sorting_modal.visible:
		TutorialOverlay.start(self, _tutorial_sort_steps(), Callable(), true)
	else:
		TutorialOverlay.start(self, _tutorial_room_steps(), Callable(), true)

# --- WHITEBOARD / CHEAT SHEET MODAL ---
func _build_whiteboard_modal() -> void:
	whiteboard_modal = Control.new()
	whiteboard_modal.name = "WhiteboardModal"
	whiteboard_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	whiteboard_modal.visible = false
	add_child(whiteboard_modal)
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			_close_whiteboard_modal()
	)
	whiteboard_modal.add_child(dim)
	
	var card = Control.new()
	card.size = Vector2(640, 420)
	card.pivot_offset = Vector2(320, 210)
	whiteboard_modal.add_child(card)
	
	var bg = PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#2563eb")
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(20)
	sb.set_content_margin_all(20)
	bg.add_theme_stylebox_override("panel", sb)
	card.add_child(bg)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	bg.add_child(vb)
	
	var h_top = HBoxContainer.new()
	vb.add_child(h_top)
	
	var title = Label.new()
	title.text = "📋 Contekan Belajar: Rentang Kelas IPv4"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", font_black)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("#1e3a8a"))
	h_top.add_child(title)
	
	var close_btn = CloseButtonScene.instantiate()
	if close_btn.has_signal("closed"):
		close_btn.closed.connect(_close_whiteboard_modal)
	else:
		close_btn.pressed.connect(_close_whiteboard_modal)
	h_top.add_child(close_btn)
	
	var info_text = Label.new()
	info_text.text = "Gunakan tabel di bawah ini sebagai panduan cepat menyortir paket:\n\n" + \
		"• KELAS A : 1 s/d 126\n   (Untuk jaringan berskala sangat besar. Default Subnet Mask: /8 atau 255.0.0.0)\n\n" + \
		"• KELAS B : 128 s/d 191\n   (Untuk jaringan skala menengah ke besar. Default Subnet Mask: /16 atau 255.255.0.0)\n\n" + \
		"• KELAS C : 192 s/d 223\n   (Untuk jaringan lokal/kantor kecil. Default Subnet Mask: /24 atau 255.255.255.0)\n\n" + \
		"⚠️ Catatan Khusus:\n" + \
		"  - Oktet 0 = Alamat Jaringan Default\n" + \
		"  - Oktet 127 = Loopback / Localhost (bukan Kelas A/B/C biasa)\n" + \
		"  - Oktet 224-239 = Kelas D (Multicast)\n" + \
		"  - Oktet 240-255 = Kelas E (Eksperimental/Riset)"
	info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_text.add_theme_font_override("font", font_semibold)
	info_text.add_theme_font_size_override("font_size", 12)
	info_text.add_theme_color_override("font_color", Color("#1e293b"))
	vb.add_child(info_text)

func _open_whiteboard_modal() -> void:
	whiteboard_modal.visible = true
	var card = whiteboard_modal.get_child(1) as Control
	_animate_modal_open(whiteboard_modal, card)

func _close_whiteboard_modal() -> void:
	whiteboard_modal.visible = false

# --- MODAL CONTROLS ---
func _open_sorting_modal() -> void:
	sorting_modal.visible = true
	_animate_modal_open(sorting_modal, sorting_card)

func _close_sorting_modal() -> void:
	sorting_modal.visible = false

func _build_pause_modal() -> void:
	pause_modal = PauseModalScene.instantiate()
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

# --- WIN & GAMEOVER MODALS ---
func _build_win_gameover_modals() -> void:
	game_dialog = preload("res://scenes/game_dialog.tscn").instantiate()
	game_dialog.name = "GameDialog"
	add_child(game_dialog)
	win_modal = game_dialog
	gameover_modal = game_dialog

func _create_modal_btn(text: String, bg_col: Color, font_col: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 46)
	btn.add_theme_font_override("font", font_black)
	btn.add_theme_font_size_override("font_size", 15)
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", font_col)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_setup_hover_scale(btn, 1.08)
	return btn

func _trigger_win() -> void:
	has_won = true
	is_game_active = false
	if sorting_modal:
		sorting_modal.visible = false
	
	var earned_stars = config.calculate_stars(hearts, time_remaining) if config else hearts
	PlayerData.set_level_stars(2, 1, earned_stars)
	
	var mins = int(time_remaining) / 60
	var secs = int(time_remaining) % 60
	var time_str = "Sisa Waktu: %02d:%02d • Paket: %d / %d" % [mins, secs, packets_sorted_count, packets_to_sort]
	var desc = "Selamat! Seluruh paket IPv4 berhasil disortir ke kelas yang tepat (Kelas A, B, atau C)."
	
	_play_chime_victory()
	game_dialog.show_win(
		"LEVEL 2.1 SELESAI!",
		desc,
		earned_stars,
		time_str,
		func(): get_tree().change_scene_to_file("res://scenes/gameplay/level_2_2.tscn"),
		func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"),
		"LANJUT KE 2.2"
	)

func _trigger_game_over(reason: String) -> void:
	is_game_active = false
	if sorting_modal:
		sorting_modal.visible = false
	_play_buzz_error()
	_update_hearts_display(true)
	game_dialog.show_game_over(
		reason if reason != "" else "Nyawa teknisi habis atau waktu telah habis!",
		func(): get_tree().reload_current_scene(),
		func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn")
	)

func _animate_modal_open(modal_root: Control, card: Control) -> void:
	var vp_sz = get_viewport_rect().size
	card.position = Vector2((vp_sz.x - card.size.x) / 2.0, (vp_sz.y - card.size.y) / 2.0)
	card.scale = Vector2(0.85, 0.85)
	modal_root.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(modal_root, "modulate:a", 1.0, 0.16)
	tw.tween_property(card, "scale", Vector2.ONE, 0.2)

# --- TOAST NOTIFICATIONS ---
func _build_toast_ui() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.name = "ToastPanel"
	toast_panel.visible = false
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.15, 0.22, 0.94)
	sb.border_color = Color("#f59e0b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	toast_panel.add_theme_stylebox_override("panel", sb)
	add_child(toast_panel)
	
	toast_label = Label.new()
	toast_label.add_theme_font_override("font", font_bold)
	toast_label.add_theme_font_size_override("font_size", 14)
	toast_label.add_theme_color_override("font_color", Color("#ffffff"))
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
	toast_panel.position = Vector2((vp_sz.x - t_sz.x) / 2.0, vp_sz.y - 120.0)
	
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
	if help_btn:
		help_btn.position = Vector2(vp_sz.x - 300.0, 20.0)
	
	door_arch.position = Vector2(center_x - 160.0, 45.0)
	potted_plant.position = Vector2(center_x + 180.0, 75.0)
	whiteboard_node.position = Vector2(center_x - 380.0, 110.0)
	
	left_rack_cabinet.position = Vector2(clamp(center_x - 620.0, 20.0, 80.0), 200.0)
	server_cabinet.position = Vector2(clamp(center_x + 390.0, vp_sz.x - 220.0, vp_sz.x - 180.0), 200.0)
	
	floor_area.position = Vector2(clamp(center_x - 540.0, 40.0, 100.0), 360.0)
	floor_area.size = Vector2(clamp(vp_sz.x - 160.0, 800.0, 1100.0), vp_sz.y - 380.0)
	
	center_desk.position = Vector2(center_x - 240.0, clamp(vp_sz.y * 0.52, 380.0, 440.0))
	
	var pad_y = clamp(vp_sz.y * 0.76, 560.0, vp_sz.y - 170.0)
	bin_a_pad.position = Vector2(center_x - 390.0, pad_y)
	bin_b_pad.position = Vector2(center_x - 120.0, pad_y)
	bin_c_pad.position = Vector2(center_x + 150.0, pad_y)
	
	# Mobile joystick placement
	if mobile_controls_root:
		var pad_base = mobile_controls_root.get_node_or_null("DpadBase") as Control
		if pad_base:
			pad_base.position = Vector2(40.0, vp_sz.y - 160.0)
			
	if header_ui:
		var back_b = header_ui.get_node_or_null("BackBtn") as Control
		var h_panel = header_ui.get_node_or_null("HeartsPanel") as Control
		var l_badge = header_ui.get_node_or_null("LevelBadge") as Control
		var t_panel = header_ui.get_node_or_null("TimerPanel") as Control
		var p_btn = header_ui.get_node_or_null("PauseBtn") as Control
		
		if back_b:
			back_b.position = Vector2(24.0, 24.0)
			back_b.size = Vector2(52.0, 52.0)
		if h_panel: h_panel.position = Vector2(90.0, 24.0)
		if l_badge: l_badge.position = Vector2(240.0, 24.0)
		if p_btn:
			p_btn.position = Vector2(vp_sz.x - 76.0, 24.0)
			p_btn.size = Vector2(52.0, 52.0)
		if t_panel: t_panel.position = Vector2(vp_sz.x - 224.0, 24.0)
			
	cables_container.queue_redraw()

# --- AUDIO SYNTHESIS HELPER ---
func _play_tone(freq: float, duration: float, vol: float = 0.2) -> void:
	if not audio_player:
		return
	var sample_rate = 22050.0
	var num_samples = int(sample_rate * duration)
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = duration + 0.05
	audio_player.stream = gen
	audio_player.play()
	var pb = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb:
		for i in range(num_samples):
			var t = float(i) / sample_rate
			var env = 1.0 - (float(i) / float(num_samples))
			var wave = sin(2.0 * PI * freq * t) * env * vol
			pb.push_frame(Vector2(wave, wave))

func _play_chime_success() -> void:
	if not audio_player:
		return
	var notes = [523.25, 659.25, 783.99]
	var duration = 0.08
	var sample_rate = 22050.0
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = duration * notes.size() + 0.05
	audio_player.stream = gen
	audio_player.play()
	var pb = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb:
		for note in notes:
			var n_samples = int(sample_rate * duration)
			for i in range(n_samples):
				var t = float(i) / sample_rate
				var env = 1.0 - (float(i) / float(n_samples))
				var wave = sin(2.0 * PI * note * t) * env * 0.18
				pb.push_frame(Vector2(wave, wave))

func _play_chime_victory() -> void:
	if not audio_player:
		return
	var notes = [523.25, 659.25, 783.99, 1046.5]
	var duration = 0.14
	var sample_rate = 22050.0
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = duration * notes.size() + 0.05
	audio_player.stream = gen
	audio_player.play()
	var pb = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb:
		for note in notes:
			var n_samples = int(sample_rate * duration)
			for i in range(n_samples):
				var t = float(i) / sample_rate
				var env = 1.0 - (float(i) / float(n_samples))
				var wave = sin(2.0 * PI * note * t) * env * 0.22
				pb.push_frame(Vector2(wave, wave))

func _play_buzz_error() -> void:
	_play_tone(160.0, 0.22, 0.25)

func _play_footstep() -> void:
	if not footstep_player:
		return
	var sample_rate = 22050.0
	var duration = 0.04
	var num_samples = int(sample_rate * duration)
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = duration + 0.02
	footstep_player.stream = gen
	footstep_player.play()
	var pb = footstep_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb:
		for i in range(num_samples):
			var env = 1.0 - (float(i) / float(num_samples))
			var noise = (randf() * 2.0 - 1.0) * env * 0.06
			pb.push_frame(Vector2(noise, noise))

func _setup_hover_scale(btn: Control, hover_scale: float = 1.08) -> void:
	btn.mouse_entered.connect(func():
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2.ONE * hover_scale, 0.1)
	)
	btn.mouse_exited.connect(func():
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2.ONE, 0.1)
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
