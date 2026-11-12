extends Control

# Level 1.3 - Hub atau Switch? (Collision Domain & Unicast Routing)
# Core Gameplay: Memilih konsentrator yang tepat (Switch vs Hub), menghubungkan kabel straight ke 4 PC,
# dan melakukan pengujian transmisi data Unicast bebas Collision.

const MOVE_SPEED = 240.0
const COLLISION_SLIDE_FACTOR = 0.85

# --- ASSETS ---
var font_regular = preload("res://art/assets/PING! Assets/Fonts/Nunito-Regular.ttf")
var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_extrabold = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_semibold = preload("res://art/assets/PING! Assets/Fonts/Nunito-SemiBold.ttf")
var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")

var tex_char_idle = preload("res://art/assets/PING! Assets/Character/main-char-router.png")
var tex_frame_jam: Texture2D = load("res://art/assets/PING! Assets/asset-gameplay/generals/frame-jam.png")
var tex_vector_heart: Texture2D = load("res://art/assets/PING! Assets/asset-gameplay/generals/vector-hearts.png")

# Stage 1.3 Assets
var tex_rack = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/rak-kabel.png")
var tex_table = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.3/meja-panjang.png")
var tex_desk = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.3/meja-pc.png")
var tex_pc = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.3/pc-image.png")
var tex_hub = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.3/hub-happy.png")
var tex_switch = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.3/switch-happy.png")
var tex_switch_vertical = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.3/switch1-removebg-preview 2.png")

# Rack Cables Decoration
var tex_cable_green = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-hijau.png")
var tex_cable_yellow = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-kuning.png")
var tex_cable_blue = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-biru.png")
var tex_cable_red = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-merah.png")

var tex_star_gold = preload("res://art/ui-ux/levelpath/star_gold.png")
var tex_star_gray = preload("res://art/ui-ux/levelpath/star_gray.png")

# Mobile Controls (Style C)
var tex_dpad_base = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_pad_a.png")
var tex_dpad_knob = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_nub_a.png")
var tex_action_normal = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/button_circle.png")
var tex_action_pressed = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/button_circle.png")

# Audio Synthesizer
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer

# Scene References
@onready var background: TextureRect = %Background
@onready var top_dark_wall: ColorRect = %TopDarkWall
@onready var door_arch: TextureRect = %DoorArch
@onready var potted_plant: TextureRect = %PottedPlant
@onready var room_container: Control = %RoomContainer
@onready var left_rack_node: Control = %LeftRack
@onready var cable_table_node: Control = %CableTable
@onready var pc1_node: Control = %PC1Node
@onready var pc2_node: Control = %PC2Node
@onready var pc3_node: Control = %PC3Node
@onready var pc4_node: Control = %PC4Node
@onready var cables_container: Control = %CablesContainer
@onready var packets_container: Control = %PacketsContainer
@onready var character_mascot: Control = %CharacterMascot

# Animations
var walk_frames: Array[Texture2D] = []
var packet_frames: Array[Texture2D] = []
var walk_frame_index: float = 0.0
var char_sprite: TextureRect

# Gameplay State
var is_game_active: bool = false
var time_remaining: float = 180.0
var hearts: int = 3

var held_device: String = "" # "switch", "hub", or ""
var placed_device: String = "" # "switch", "hub", or ""
var cabling_connected: Dictionary = {1: false, 2: false, 3: false, 4: false}
var selected_cable_type: String = "straight"
var btn_cable_straight: Button
var btn_cable_cross: Button
var btn_finish_cabling: Button
var pc_rows_box: VBoxContainer
var cables_installed: bool = false
var is_simulating: bool = false
var has_won: bool = false

# Table & Rack Visual Elements
var table_device_rect: TextureRect
var table_mac_tag: PanelContainer
var table_prompt_pill: PanelContainer
var table_prompt_label: Label
var rack_prompt_pill: PanelContainer
var rack_prompt_label: Label
var rack_hub_preview: TextureRect
var rack_switch_preview: TextureRect
var rack_hub_distress: Label

# PC Nodes Visuals
var pc_sprites: Dictionary = {}
var pc_emotes: Dictionary = {}

# Modals
var intro_modal: Control
var intro_card: Control
var device_modal: Control
var device_card: Control
var cabling_modal: Control
var cabling_card: Control
var guidebook_modal: Control
var guidebook_card: Control
var pause_modal: Control
var pause_card: Control
var win_modal: Control
var win_card: Control
var win_stars_row: HBoxContainer
var win_time_lbl: Label
var gameover_modal: Control
var gameover_card: Control
var gameover_reason_lbl: Label
var settings_modal: Control

# UI Elements
var header_ui: Control
var timer_label: Label
var hearts_container: HBoxContainer
var hearts_rects: Array[TextureRect] = []
var broken_labels: Array[Label] = []
var game_dialog: Control
var toast_panel: PanelContainer
var toast_label: Label
var toast_tween: Tween

# Movement & Joystick State
var char_pos: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO
var footstep_timer: float = 0.0
var dpad_touch_id: int = -1
var dpad_center: Vector2 = Vector2.ZERO
var dpad_knob_sprite: TextureRect
var dpad_radius: float = 55.0

# Cable connection line coordinates
var cable_points: Dictionary = {}

func _ready() -> void:
	settings_modal = preload("res://scenes/settings_modal.tscn").instantiate()
	add_child(settings_modal)
	
	_load_walk_frames()
	_load_packet_frames()
	
	_build_room_visuals()
	_build_character()
	_build_header_ui()
	_build_mobile_controls()
	
	_build_device_modal()
	_build_cabling_modal()
	_build_guidebook_modal()
	_build_pause_modal()
	_build_win_gameover_modals()
	_build_intro_modal()
	_build_toast_ui()
	
	_reposition_responsive()
	get_viewport().size_changed.connect(_reposition_responsive)
	
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-level1-3-intro" in all_args:
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_3_intro_render.png")
		get_tree().quit()
		
	if "--screenshot-level1-3-gameplay" in all_args:
		await get_tree().create_timer(0.2).timeout
		_start_gameplay()
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_3_gameplay_render.png")
		get_tree().quit()

	if "--screenshot-level1-3-cabling" in all_args:
		await get_tree().create_timer(0.2).timeout
		_start_gameplay()
		placed_device = "switch"
		_refresh_table_visuals()
		_open_cabling_modal()
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_3_cabling_render.png")
		get_tree().quit()

	if "--screenshot-level1-3-transmission" in all_args:
		await get_tree().create_timer(0.2).timeout
		_start_gameplay()
		placed_device = "switch"
		cables_installed = true
		_refresh_table_visuals()
		cables_container.queue_redraw()
		_start_simulation()
		await get_tree().create_timer(0.6).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_3_transmission_render.png")
		get_tree().quit()

	if "--screenshot-level1-3-collision" in all_args:
		await get_tree().create_timer(0.2).timeout
		_start_gameplay()
		placed_device = "hub"
		cables_installed = true
		_refresh_table_visuals()
		cables_container.queue_redraw()
		_start_simulation()
		await get_tree().create_timer(0.9).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_3_collision_render.png")
		get_tree().quit()

func _load_walk_frames() -> void:
	walk_frames.clear()
	for i in range(1, 33):
		var p = "res://art/assets/PING! Assets/Sprite animation/router walk/%d.png" % i
		if ResourceLoader.exists(p):
			var tex = load(p)
			if tex:
				walk_frames.append(tex)

func _load_packet_frames() -> void:
	packet_frames.clear()
	for i in range(1, 61):
		var p = "res://art/assets/PING! Assets/Sprite animation/paket data/%d.png" % i
		if ResourceLoader.exists(p):
			var tex = load(p)
			if tex:
				packet_frames.append(tex)

func _process(delta: float) -> void:
	if is_game_active and not has_won:
		time_remaining = max(0.0, time_remaining - delta)
		_update_timer_display()
		if time_remaining <= 0.0:
			is_game_active = false
			_trigger_game_over("Waktu habis! Pengaturan jaringan kantor gagal diselesaikan tepat waktu.")
			
	var move_vec = Vector2.ZERO
	var any_modal_open = (intro_modal and intro_modal.visible) or \
						 (device_modal and device_modal.visible) or \
						 (cabling_modal and cabling_modal.visible) or \
						 (guidebook_modal and guidebook_modal.visible) or \
						 (pause_modal and pause_modal.visible) or \
						 (settings_modal and settings_modal.visible) or \
						 (win_modal and win_modal.visible) or \
						 (gameover_modal and gameover_modal.visible) or \
						 is_simulating
						 
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
			
		if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_ENTER):
			_trigger_context_action()
			
	if move_vec.length() > 0.05:
		move_vec = move_vec.normalized()
		var delta_mov = move_vec * MOVE_SPEED * delta
		var vp_sz = get_viewport_rect().size
		
		# Independent X movement & obstacle sliding
		var test_x = clamp(char_pos.x + delta_mov.x, 20.0, vp_sz.x - 260.0)
		if not _is_room_collision(Vector2(test_x, char_pos.y)):
			char_pos.x = test_x
			
		# Independent Y movement & obstacle sliding
		var test_y = clamp(char_pos.y + delta_mov.y, 220.0, vp_sz.y - 170.0)
		if not _is_room_collision(Vector2(char_pos.x, test_y)):
			char_pos.y = test_y
			
		character_mascot.position = char_pos
		
		# Update walk animation
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
			char_sprite.texture = tex_char_idle
			
	_update_proximity_prompts()

func _is_room_collision(pos: Vector2) -> bool:
	var feet_l = pos.x + 85.0
	var feet_r = pos.x + 170.0
	var feet_t = pos.y + 75.0
	var feet_b = pos.y + 138.0
	
	# 1. Top Wall
	if feet_t < 240.0:
		return true
		
	# 2. Left Rack Cabinet (x: 80 to 350, y: 220 to 570)
	if feet_r > 75.0 and feet_l < 350.0:
		if feet_b > 240.0 and feet_t < 570.0:
			return true
			
	# 3. Center Table (x: 620 to 940, y: 410 to 535)
	if feet_r > 620.0 and feet_l < 940.0:
		if feet_b > 410.0 and feet_t < 535.0:
			return true
			
	# 4. PC 1 Station (x: 400 to 565, y: 360 to 495)
	if feet_r > 400.0 and feet_l < 565.0:
		if feet_b > 360.0 and feet_t < 495.0:
			return true
			
	# 5. PC 2 Station (x: 400 to 565, y: 560 to 690)
	if feet_r > 400.0 and feet_l < 565.0:
		if feet_b > 560.0 and feet_t < 690.0:
			return true
			
	# 6. PC 3 Station (x: 1000 to 1165, y: 560 to 690)
	if feet_r > 1000.0 and feet_l < 1165.0:
		if feet_b > 560.0 and feet_t < 690.0:
			return true
			
	# 7. PC 4 Station (x: 1000 to 1165, y: 360 to 495)
	if feet_r > 1000.0 and feet_l < 1165.0:
		if feet_b > 360.0 and feet_t < 495.0:
			return true
			
	return false

func _trigger_context_action() -> void:
	var char_center = char_pos + Vector2(128.0, 72.0)
	var rack_center = left_rack_node.position + left_rack_node.size / 2.0
	var table_center = cable_table_node.position + cable_table_node.size / 2.0
	
	if char_center.distance_to(rack_center) < 220.0:
		_open_device_modal()
	elif char_center.distance_to(table_center) < 220.0:
		_handle_table_interaction()

func _update_proximity_prompts() -> void:
	if not rack_prompt_pill or not table_prompt_pill:
		return
	if is_simulating or (cabling_modal and cabling_modal.visible) or (device_modal and device_modal.visible):
		rack_prompt_pill.visible = false
		table_prompt_pill.visible = false
		return
		
	var char_center = char_pos + Vector2(128.0, 72.0)
	var rack_center = left_rack_node.position + left_rack_node.size / 2.0
	var table_center = cable_table_node.position + cable_table_node.size / 2.0
	
	var near_rack = char_center.distance_to(rack_center) < 260.0
	var near_table = char_center.distance_to(table_center) < 230.0
	
	rack_prompt_pill.visible = is_game_active and near_rack and (placed_device == "")
	table_prompt_pill.visible = is_game_active and near_table and (held_device != "" or placed_device != "")
	
	if placed_device == "":
		if held_device != "":
			table_prompt_label.text = "! Letakkan %s" % held_device.to_upper()
		else:
			table_prompt_label.text = "Ambil Perangkat di Rak"
	else:
		if not cables_installed:
			table_prompt_label.text = "! Hubungkan Kabel ke 4 PC"
		else:
			table_prompt_label.text = "🚀 Uji Transmisi Data"

# --- ROOM VISUALS BUILDER ---
func _build_room_visuals() -> void:
	# 1. Left Rack Cabinet
	var rack_bg = TextureRect.new()
	rack_bg.name = "RackCabinet"
	rack_bg.texture = tex_rack
	rack_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rack_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rack_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	left_rack_node.add_child(rack_bg)
	
	# Shelf Visual Items
	var shelf_container = Control.new()
	shelf_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	left_rack_node.add_child(shelf_container)
	
	# Top shelf cables
	var c_top1 = _create_mini_cable(tex_cable_green, Vector2(30, 75))
	var c_top2 = _create_mini_cable(tex_cable_yellow, Vector2(75, 75))
	var c_top3 = _create_mini_cable(tex_cable_blue, Vector2(120, 75))
	var c_top4 = _create_mini_cable(tex_cable_red, Vector2(165, 75))
	shelf_container.add_child(c_top1)
	shelf_container.add_child(c_top2)
	shelf_container.add_child(c_top3)
	shelf_container.add_child(c_top4)
	
	# Middle shelf devices: HUB and SWITCH side by side with pill labels
	rack_hub_preview = TextureRect.new()
	rack_hub_preview.texture = tex_hub
	rack_hub_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rack_hub_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rack_hub_preview.size = Vector2(90, 48)
	rack_hub_preview.position = Vector2(32, 160)
	shelf_container.add_child(rack_hub_preview)
	
	var hub_tag = _create_mini_pill("HUB", Color("#fef3c7"), Color("#b45309"))
	hub_tag.position = Vector2(50, 140)
	shelf_container.add_child(hub_tag)
	
	rack_switch_preview = TextureRect.new()
	rack_switch_preview.texture = tex_switch
	rack_switch_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rack_switch_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rack_switch_preview.size = Vector2(85, 48)
	rack_switch_preview.position = Vector2(145, 160)
	shelf_container.add_child(rack_switch_preview)
	
	var switch_tag = _create_mini_pill("SWITCH", Color("#e0e7ff"), Color("#3730a3"))
	switch_tag.position = Vector2(155, 140)
	shelf_container.add_child(switch_tag)
	
	# Hub distress indicator (( HUB )) when collision occurs
	rack_hub_distress = Label.new()
	rack_hub_distress.text = "(( HUB ))\n>.<"
	rack_hub_distress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rack_hub_distress.add_theme_font_override("font", font_black)
	rack_hub_distress.add_theme_font_size_override("font_size", 12)
	rack_hub_distress.add_theme_color_override("font_color", Color("#dc2626"))
	rack_hub_distress.position = Vector2(30, 155)
	rack_hub_distress.visible = false
	shelf_container.add_child(rack_hub_distress)
	
	# Bottom shelf cables
	var c_bot1 = _create_mini_cable(tex_cable_yellow, Vector2(30, 245))
	var c_bot2 = _create_mini_cable(tex_cable_green, Vector2(75, 245))
	var c_bot3 = _create_mini_cable(tex_cable_red, Vector2(120, 245))
	var c_bot4 = _create_mini_cable(tex_cable_blue, Vector2(165, 245))
	shelf_container.add_child(c_bot1)
	shelf_container.add_child(c_bot2)
	shelf_container.add_child(c_bot3)
	shelf_container.add_child(c_bot4)
	
	# Rack prompt pill
	rack_prompt_pill = _create_interaction_pill("🔍 Pilih Perangkat")
	rack_prompt_pill.position = Vector2(45, 12)
	var pill_b = Button.new()
	pill_b.set_anchors_preset(Control.PRESET_FULL_RECT)
	pill_b.flat = true
	pill_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pill_b.pressed.connect(_open_device_modal)
	rack_prompt_pill.add_child(pill_b)
	left_rack_node.add_child(rack_prompt_pill)
	rack_prompt_label = rack_prompt_pill.get_node("Label") as Label
	var rack_btn = Button.new()
	rack_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	rack_btn.flat = true
	rack_btn.mouse_filter = Control.MOUSE_FILTER_PASS
	rack_btn.pressed.connect(func():
		var char_center = char_pos + Vector2(128.0, 72.0)
		var rack_center = left_rack_node.position + left_rack_node.size / 2.0
		if char_center.distance_to(rack_center) < 260.0:
			_open_device_modal()
		else:
			show_toast("Dekati rak di sebelah kiri untuk memilih perangkat!", 2.5)
	)
	left_rack_node.add_child(rack_btn)
	
	# 2. Center Table (Meja Panjang)
	var table_tex = TextureRect.new()
	table_tex.texture = tex_table
	table_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	table_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	table_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	cable_table_node.add_child(table_tex)
	
	# Device placed on table
	table_device_rect = TextureRect.new()
	table_device_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	table_device_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	table_device_rect.size = Vector2(180, 105)
	table_device_rect.position = Vector2(70, -25)
	table_device_rect.visible = false
	cable_table_node.add_child(table_device_rect)
	
	# MAC Address yellow tag on Switch top-right (as in Figma Image 4)
	table_mac_tag = PanelContainer.new()
	var sb_mac = StyleBoxFlat.new()
	sb_mac.bg_color = Color("#fef08a")
	sb_mac.border_color = Color("#ca8a04")
	sb_mac.set_border_width_all(1.5)
	sb_mac.set_corner_radius_all(5)
	sb_mac.content_margin_left = 6
	sb_mac.content_margin_right = 6
	sb_mac.content_margin_top = 2
	sb_mac.content_margin_bottom = 2
	table_mac_tag.add_theme_stylebox_override("panel", sb_mac)
	var mac_lbl = Label.new()
	mac_lbl.text = "MAC"
	mac_lbl.add_theme_font_override("font", font_black)
	mac_lbl.add_theme_font_size_override("font_size", 10)
	mac_lbl.add_theme_color_override("font_color", Color("#713f12"))
	table_mac_tag.add_child(mac_lbl)
	table_mac_tag.position = Vector2(210, -32)
	table_mac_tag.visible = false
	cable_table_node.add_child(table_mac_tag)
	
	# Table prompt pill
	table_prompt_pill = _create_interaction_pill("Ambil Perangkat di Rak")
	table_prompt_pill.position = Vector2(50, -68)
	cable_table_node.add_child(table_prompt_pill)
	table_prompt_label = table_prompt_pill.get_node("Label") as Label
	var table_btn = Button.new()
	table_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	table_btn.flat = true
	table_btn.mouse_filter = Control.MOUSE_FILTER_PASS
	table_btn.pressed.connect(_handle_table_interaction)
	cable_table_node.add_child(table_btn)
	
	# 3. 4 PC Desks & Monitors
	_setup_pc_node(pc1_node, "PC 1", Vector2(400, 360))
	_setup_pc_node(pc2_node, "PC 2", Vector2(400, 560))
	_setup_pc_node(pc3_node, "PC 3", Vector2(1000, 560))
	_setup_pc_node(pc4_node, "PC 4", Vector2(1000, 360))
	
	# 4. Custom Draw for smooth connecting cables
	cables_container.draw.connect(_on_cables_draw)

func _create_mini_cable(tex: Texture2D, pos: Vector2) -> TextureRect:
	var tr = TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = Vector2(36, 36)
	tr.position = pos
	return tr

func _create_mini_pill(text: String, bg: Color, fg: Color) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(1.5)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", fg)
	p.add_child(lbl)
	return p

func _create_interaction_pill(text: String) -> PanelContainer:
	var pill = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	pill.add_theme_stylebox_override("panel", sb)
	
	var lbl = Label.new()
	lbl.name = "Label"
	lbl.text = text
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color("#1e293b"))
	pill.add_child(lbl)
	return pill

func _setup_pc_node(parent: Control, pc_name: String, pos: Vector2) -> void:
	parent.position = pos
	parent.size = Vector2(170, 140)
	
	# PC Desk
	var desk_rect = TextureRect.new()
	desk_rect.texture = tex_desk
	desk_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desk_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	desk_rect.size = Vector2(170, 95)
	desk_rect.position = Vector2(0, 45)
	parent.add_child(desk_rect)
	
	# Label PC under desk
	var lbl = Label.new()
	lbl.text = pc_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color("#5c3d2e"))
	lbl.position = Vector2(0, 102)
	lbl.size = Vector2(170, 24)
	parent.add_child(lbl)
	
	# PC Monitor with cute face
	var monitor_rect = TextureRect.new()
	monitor_rect.texture = tex_pc
	monitor_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monitor_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monitor_rect.size = Vector2(110, 95)
	monitor_rect.position = Vector2(30, -5)
	parent.add_child(monitor_rect)
	pc_sprites[pc_name] = monitor_rect
	
	# Sparkle/Heart emote container
	var emote_lbl = Label.new()
	emote_lbl.text = "✨"
	emote_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emote_lbl.add_theme_font_size_override("font_size", 22)
	emote_lbl.position = Vector2(65, -35)
	emote_lbl.visible = false
	parent.add_child(emote_lbl)
	pc_emotes[pc_name] = emote_lbl

# Draw smooth green cables between central table and the 4 PCs
func _on_cables_draw() -> void:
	if not cables_installed or placed_device == "":
		return
		
	var center = cable_table_node.position + Vector2(cable_table_node.size.x / 2.0, 32.0)
	var p1 = pc1_node.position + Vector2(155.0, 72.0)
	var p2 = pc2_node.position + Vector2(155.0, 72.0)
	var p3 = pc3_node.position + Vector2(15.0, 72.0)
	var p4 = pc4_node.position + Vector2(15.0, 72.0)
	
	var cable_border_col = Color("#15803d")
	var cable_body_col = Color("#86efac")
	
	# Cables emerging directly from ports 1, 2, 3, 4 of Switch / Hub
	_draw_bezier_cable(center + Vector2(-55, 36), p1, Vector2(-35, 35), cable_border_col, 9.0)
	_draw_bezier_cable(center + Vector2(-55, 36), p1, Vector2(-35, 35), cable_body_col, 5.0)
	
	_draw_bezier_cable(center + Vector2(-20, 42), p2, Vector2(-30, 60), cable_border_col, 9.0)
	_draw_bezier_cable(center + Vector2(-20, 42), p2, Vector2(-30, 60), cable_body_col, 5.0)
	
	_draw_bezier_cable(center + Vector2(20, 42), p3, Vector2(30, 60), cable_border_col, 9.0)
	_draw_bezier_cable(center + Vector2(20, 42), p3, Vector2(30, 60), cable_body_col, 5.0)
	
	_draw_bezier_cable(center + Vector2(55, 36), p4, Vector2(35, 35), cable_border_col, 9.0)
	_draw_bezier_cable(center + Vector2(55, 36), p4, Vector2(35, 35), cable_body_col, 5.0)

func _draw_bezier_cable(start: Vector2, finish: Vector2, ctrl_offset: Vector2, col: Color, width: float) -> void:
	var mid = (start + finish) / 2.0 + ctrl_offset
	var pts: PackedVector2Array = []
	for step in range(25):
		var t = float(step) / 24.0
		var pt = (1.0 - t) * (1.0 - t) * start + 2.0 * (1.0 - t) * t * mid + t * t * finish
		pts.append(pt)
	cables_container.draw_polyline(pts, col, width, true)

func _get_bezier_point(start: Vector2, finish: Vector2, ctrl_offset: Vector2, t: float) -> Vector2:
	var mid = (start + finish) / 2.0 + ctrl_offset
	return (1.0 - t) * (1.0 - t) * start + 2.0 * (1.0 - t) * t * mid + t * t * finish

# --- CHARACTER SETUP ---
func _build_character() -> void:
	char_sprite = TextureRect.new()
	char_sprite.texture = tex_char_idle
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.size = Vector2(256, 144)
	character_mascot.add_child(char_sprite)
	
	var screen_w = get_viewport_rect().size.x
	char_pos = Vector2(screen_w / 2.0 - 128.0, 270.0)
	character_mascot.position = char_pos

# --- MOBILE JOYSTICK CONTROLS (STYLE C) ---
func _build_mobile_controls() -> void:
	var dpad_layer = Control.new()
	dpad_layer.name = "MobileControls"
	dpad_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dpad_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dpad_layer)
	
	# Joystick Base
	var joystick_base = TextureRect.new()
	joystick_base.texture = tex_dpad_base
	joystick_base.size = Vector2(170, 170)
	joystick_base.position = Vector2(60, get_viewport_rect().size.y - 210)
	joystick_base.modulate = Color(1, 1, 1, 0.75)
	joystick_base.mouse_filter = Control.MOUSE_FILTER_PASS
	joystick_base.gui_input.connect(_handle_joystick_input)
	dpad_layer.add_child(joystick_base)
	
	# Joystick Knob
	dpad_knob_sprite = TextureRect.new()
	dpad_knob_sprite.texture = tex_dpad_knob
	dpad_knob_sprite.size = Vector2(60, 60)
	dpad_knob_sprite.position = Vector2(55, 55)
	dpad_knob_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(dpad_knob_sprite)
	
	dpad_center = Vector2(85, 85)
	
	# Mobile Action Button
	var action_btn = TextureButton.new()
	action_btn.texture_normal = tex_action_normal
	action_btn.texture_pressed = tex_action_pressed
	action_btn.ignore_texture_size = true
	action_btn.stretch_mode = TextureButton.STRETCH_SCALE
	action_btn.size = Vector2(90, 90)
	action_btn.position = Vector2(get_viewport_rect().size.x - 140, get_viewport_rect().size.y - 150)
	action_btn.modulate = Color(1, 1, 1, 0.85)
	action_btn.pressed.connect(_trigger_context_action)
	_setup_hover_scale(action_btn, 1.1)
	dpad_layer.add_child(action_btn)
	
	var act_lbl = Label.new()
	act_lbl.text = "AKSI"
	act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	act_lbl.add_theme_font_override("font", font_black)
	act_lbl.add_theme_font_size_override("font_size", 14)
	act_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	act_lbl.position = Vector2(0, 32)
	act_lbl.size = Vector2(90, 26)
	action_btn.add_child(act_lbl)

func _handle_joystick_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		var st = ev as InputEventScreenTouch
		if st.pressed:
			if dpad_touch_id == -1:
				dpad_touch_id = st.index
				_process_knob(st.position)
		else:
			if st.index == dpad_touch_id:
				_reset_joystick()
	elif ev is InputEventScreenDrag:
		var sd = ev as InputEventScreenDrag
		if sd.index == dpad_touch_id:
			_process_knob(sd.position)
	elif ev is InputEventMouseButton:
		var mb = ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				dpad_touch_id = 999
				_process_knob(mb.position)
			else:
				_reset_joystick()
	elif ev is InputEventMouseMotion:
		if dpad_touch_id == 999:
			_process_knob((ev as InputEventMouseMotion).position)

func _process_knob(touch_local_pos: Vector2) -> void:
	var delta_pos = touch_local_pos - dpad_center
	var dist = delta_pos.length()
	if dist > dpad_radius:
		delta_pos = delta_pos.normalized() * dpad_radius
	input_dir = delta_pos / dpad_radius
	dpad_knob_sprite.position = dpad_center + delta_pos - Vector2(30, 30)

func _reset_joystick() -> void:
	dpad_touch_id = -1
	input_dir = Vector2.ZERO
	dpad_knob_sprite.position = dpad_center - Vector2(30, 30)

# --- HEADER UI ---
func _build_header_ui() -> void:
	header_ui = Control.new()
	header_ui.name = "HeaderUI"
	header_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_ui)
	
	# Back Button
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
	sb_back.shadow_color = Color(0, 0, 0, 0.25)
	sb_back.shadow_size = 5
	sb_back.shadow_offset = Vector2(0, 3)
	back_btn.add_theme_stylebox_override("normal", sb_back)
	back_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
	_setup_hover_scale(back_btn, 1.1)
	header_ui.add_child(back_btn)
	
	# Hearts Container
	var hearts_panel = PanelContainer.new()
	hearts_panel.name = "HeartsPanel"
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color("#ffffff")
	sb_h.border_color = Color("#4a2e2b")
	sb_h.set_border_width_all(2.5)
	sb_h.set_corner_radius_all(16)
	sb_h.shadow_color = Color(0, 0, 0, 0.25)
	sb_h.shadow_size = 5
	sb_h.shadow_offset = Vector2(0, 3)
	sb_h.content_margin_left = 14
	sb_h.content_margin_right = 14
	sb_h.content_margin_top = 6
	sb_h.content_margin_bottom = 6
	hearts_panel.add_theme_stylebox_override("panel", sb_h)
	
	hearts_container = HBoxContainer.new()
	hearts_container.add_theme_constant_override("separation", 10)
	hearts_panel.add_child(hearts_container)
	
	hearts_rects.clear()
	broken_labels.clear()
	for i in range(3):
		var slot = Control.new()
		slot.custom_minimum_size = Vector2(40, 36)
		slot.size = Vector2(40, 36)
		hearts_container.add_child(slot)
		
		var h = TextureRect.new()
		h.texture = tex_vector_heart
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.pivot_offset = Vector2(20, 18)
		h.modulate = Color(1.0, 0.28, 0.4, 1.0)
		slot.add_child(h)
		hearts_rects.append(h)
		
		var b_lbl = Label.new()
		b_lbl.text = "✕"
		b_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b_lbl.add_theme_font_override("font", font_black)
		b_lbl.add_theme_font_size_override("font_size", 22)
		b_lbl.add_theme_color_override("font_color", Color("#dc2626"))
		b_lbl.visible = false
		slot.add_child(b_lbl)
		broken_labels.append(b_lbl)
		
	_update_hearts_display()
	header_ui.add_child(hearts_panel)
	
	# Level 3 Badge
	var lvl_panel = PanelContainer.new()
	lvl_panel.name = "LevelBadge"
	var sb_lvl = StyleBoxFlat.new()
	sb_lvl.bg_color = Color("#ffffff")
	sb_lvl.border_color = Color("#4a2e2b")
	sb_lvl.set_border_width_all(2.5)
	sb_lvl.set_corner_radius_all(14)
	sb_lvl.shadow_color = Color(0, 0, 0, 0.25)
	sb_lvl.shadow_size = 5
	sb_lvl.shadow_offset = Vector2(0, 3)
	sb_lvl.content_margin_left = 14
	sb_lvl.content_margin_right = 14
	sb_lvl.content_margin_top = 4
	sb_lvl.content_margin_bottom = 4
	lvl_panel.add_theme_stylebox_override("panel", sb_lvl)
	
	var vb_lvl = VBoxContainer.new()
	vb_lvl.alignment = BoxContainer.ALIGNMENT_CENTER
	vb_lvl.add_theme_constant_override("separation", 0)
	var t_sub = Label.new()
	t_sub.text = "Level"
	t_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_sub.add_theme_font_override("font", font_bold)
	t_sub.add_theme_font_size_override("font_size", 11)
	t_sub.add_theme_color_override("font_color", Color("#64748b"))
	vb_lvl.add_child(t_sub)
	var t_num = Label.new()
	t_num.text = "3"
	t_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_num.add_theme_font_override("font", font_black)
	t_num.add_theme_font_size_override("font_size", 16)
	t_num.add_theme_color_override("font_color", Color("#1e293b"))
	vb_lvl.add_child(t_num)
	lvl_panel.add_child(vb_lvl)
	header_ui.add_child(lvl_panel)
	
	# Timer Panel
	var timer_panel = PanelContainer.new()
	timer_panel.name = "TimerPanel"
	var sb_timer = StyleBoxFlat.new()
	sb_timer.bg_color = Color("#ffffff")
	sb_timer.border_color = Color("#4a2e2b")
	sb_timer.set_border_width_all(2.5)
	sb_timer.set_corner_radius_all(16)
	sb_timer.shadow_color = Color(0, 0, 0, 0.25)
	sb_timer.shadow_size = 5
	sb_timer.shadow_offset = Vector2(0, 3)
	sb_timer.content_margin_left = 14
	sb_timer.content_margin_right = 16
	sb_timer.content_margin_top = 6
	sb_timer.content_margin_bottom = 6
	timer_panel.add_theme_stylebox_override("panel", sb_timer)
	
	var hb_timer = HBoxContainer.new()
	hb_timer.add_theme_constant_override("separation", 10)
	hb_timer.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_panel.add_child(hb_timer)
	
	var clock_icon = TextureRect.new()
	clock_icon.texture = tex_frame_jam
	clock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	clock_icon.custom_minimum_size = Vector2(30, 30)
	hb_timer.add_child(clock_icon)
	
	timer_label = Label.new()
	timer_label.text = "03:00"
	timer_label.add_theme_font_override("font", font_black)
	timer_label.add_theme_font_size_override("font_size", 20)
	timer_label.add_theme_color_override("font_color", Color("#1e293b"))
	hb_timer.add_child(timer_label)
	header_ui.add_child(timer_panel)
	
	# Hamburger / Pause Button
	var pause_btn = Button.new()
	pause_btn.name = "PauseBtn"
	pause_btn.text = "≡"
	pause_btn.custom_minimum_size = Vector2(52, 52)
	pause_btn.add_theme_font_override("font", font_black)
	pause_btn.add_theme_font_size_override("font_size", 26)
	var sb_pause = StyleBoxFlat.new()
	sb_pause.bg_color = Color("#ffffff")
	sb_pause.border_color = Color("#4a2e2b")
	sb_pause.set_border_width_all(2.5)
	sb_pause.set_corner_radius_all(14)
	sb_pause.shadow_color = Color(0, 0, 0, 0.25)
	sb_pause.shadow_size = 5
	sb_pause.shadow_offset = Vector2(0, 3)
	pause_btn.add_theme_stylebox_override("normal", sb_pause)
	pause_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	pause_btn.pressed.connect(_open_pause_modal)
	_setup_hover_scale(pause_btn, 1.1)
	header_ui.add_child(pause_btn)

func _update_timer_display() -> void:
	if not timer_label:
		return
	var mins = int(time_remaining) / 60
	var secs = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	if time_remaining <= 30.0:
		timer_label.add_theme_color_override("font_color", Color("#ef4444"))
	else:
		timer_label.add_theme_color_override("font_color", Color("#1e293b"))

func _update_hearts_display(is_damage_event: bool = false) -> void:
	for idx in range(hearts_rects.size()):
		var hr = hearts_rects[idx]
		var bl = broken_labels[idx] if idx < broken_labels.size() else null
		if hr:
			if idx < hearts:
				hr.modulate = Color(1.0, 0.28, 0.4, 1.0)
				hr.scale = Vector2.ONE
				if bl: bl.visible = false
			else:
				if is_damage_event and idx == hearts:
					hr.modulate = Color(1.0, 0.1, 0.1, 1.0)
					var tw = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
					tw.tween_property(hr, "scale", Vector2(1.25, 1.25), 0.1)
					tw.tween_property(hr, "scale", Vector2(0.85, 0.85), 0.15)
					tw.tween_property(hr, "modulate", Color(0.25, 0.2, 0.22, 0.35), 0.2)
					if bl:
						bl.visible = true
						bl.modulate.a = 0.0
						var tw_b = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
						tw_b.tween_property(bl, "modulate:a", 1.0, 0.15)
				else:
					hr.modulate = Color(0.25, 0.2, 0.22, 0.35)
					hr.scale = Vector2(0.85, 0.85)
					if bl:
						bl.visible = true
						bl.modulate.a = 1.0

func _deduct_heart() -> void:
	if hearts > 0:
		hearts -= 1
		_play_tone(180.0, 0.35, 0.3)
		_update_hearts_display(true)
		
		# Gentle screen bounce
		var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(room_container, "position:y", 12.0, 0.08)
		tw.tween_property(room_container, "position:y", -10.0, 0.08)
		tw.tween_property(room_container, "position:y", 0.0, 0.08)
		
		if hearts <= 0:
			is_game_active = false
			_trigger_game_over("Nyawa teknisi habis! Hub terus memicu tabrakan paket data.")

# --- INTRO MODAL (FIGMA IMAGE 1) ---
func _build_intro_modal() -> void:
	intro_modal = Control.new()
	intro_modal.name = "IntroModal"
	intro_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	intro_modal.visible = true
	add_child(intro_modal)
	
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.65)
	intro_modal.add_child(backdrop)
	
	intro_card = Control.new()
	intro_card.name = "IntroCard"
	intro_card.size = Vector2(580, 360)
	intro_card.pivot_offset = Vector2(290, 180)
	intro_modal.add_child(intro_card)
	
	var bg_panel = PanelContainer.new()
	bg_panel.size = Vector2(580, 360)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fffbeb")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(26)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 6)
	bg_panel.add_theme_stylebox_override("panel", sb)
	intro_card.add_child(bg_panel)
	
	var vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	bg_panel.add_child(vb)
	
	var top_pin = Label.new()
	top_pin.text = "⭕"
	top_pin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_pin.add_theme_font_size_override("font_size", 16)
	vb.add_child(top_pin)
	
	var title = Label.new()
	title.text = "Level 1.3 Hub atau Switch?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font_black)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb.add_child(title)
	
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(300, 2)
	div.color = Color("#d97706")
	div.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(div)
	
	var desc = Label.new()
	desc.text = "Kantor baru ini punya 4 komputer yang harus terhubung. Pasang perangkat yang tepat, lalu kirim amplop data. Salah pilih? Amplopnya akan saling tabrakan!"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_override("font", font_bold)
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color("#78350f"))
	vb.add_child(desc)
	
	var btn_start = Button.new()
	btn_start.text = "MULAI"
	btn_start.custom_minimum_size = Vector2(160, 44)
	btn_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_start.add_theme_font_override("font", font_black)
	btn_start.add_theme_font_size_override("font_size", 16)
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color("#a7f3d0")
	sb_btn.border_color = Color("#4a2e2b")
	sb_btn.set_border_width_all(2.5)
	sb_btn.set_corner_radius_all(14)
	btn_start.add_theme_stylebox_override("normal", sb_btn)
	btn_start.add_theme_color_override("font_color", Color("#14532d"))
	btn_start.pressed.connect(_start_gameplay)
	_setup_hover_scale(btn_start, 1.1)
	vb.add_child(btn_start)
	
	# Mascot Circle Avatar on bottom left
	var avatar_badge = PanelContainer.new()
	avatar_badge.size = Vector2(76, 76)
	avatar_badge.position = Vector2(-24, 290)
	var sb_av = StyleBoxFlat.new()
	sb_av.bg_color = Color("#fef3c7")
	sb_av.border_color = Color("#4a2e2b")
	sb_av.set_border_width_all(3.5)
	sb_av.set_corner_radius_all(38)
	sb_av.set_content_margin_all(6)
	avatar_badge.add_theme_stylebox_override("panel", sb_av)
	var av_img = TextureRect.new()
	av_img.texture = preload("res://art/ui-ux/icons/figma_avatar_karakter.png")
	av_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_badge.add_child(av_img)
	intro_card.add_child(avatar_badge)

func _start_gameplay() -> void:
	_play_sweep(440.0, 880.0, 0.15, 0.25)
	intro_modal.visible = false
	is_game_active = true
	show_toast("Misi Dimulai: Dekati Rak di sebelah kiri untuk mengambil perangkat!", 3.5)

# --- TABLE INTERACTION & STATE HANDLING ---
func _handle_table_interaction() -> void:
	if placed_device == "":
		if held_device != "":
			placed_device = held_device
			held_device = ""
			_play_sweep(350.0, 700.0, 0.15, 0.2)
			_refresh_table_visuals()
			show_toast("%s berhasil dipasang di meja! Sekarang sambungkan kabel ke 4 PC." % placed_device.to_upper(), 3.0)
		else:
			_open_device_modal()
	else:
		if not cables_installed:
			_open_cabling_modal()
		else:
			_start_simulation()

func _refresh_table_visuals() -> void:
	if placed_device == "switch":
		table_device_rect.texture = tex_switch
		table_device_rect.visible = true
		table_mac_tag.visible = true
		# On rack, switch is moved to table, hub stays on rack with soundwaves (( HUB )) as in Figma Image 4
		if rack_switch_preview:
			rack_switch_preview.visible = false
		if rack_hub_preview:
			rack_hub_preview.visible = true
		if rack_hub_distress:
			rack_hub_distress.visible = true
	elif placed_device == "hub":
		table_device_rect.texture = tex_hub
		table_device_rect.visible = true
		table_mac_tag.visible = false
		if rack_hub_preview:
			rack_hub_preview.visible = false
		if rack_switch_preview:
			rack_switch_preview.visible = true
		if rack_hub_distress:
			rack_hub_distress.visible = false
	else:
		table_device_rect.visible = false
		table_mac_tag.visible = false
		if rack_switch_preview:
			rack_switch_preview.visible = true
		if rack_hub_preview:
			rack_hub_preview.visible = true
		if rack_hub_distress:
			rack_hub_distress.visible = false

# --- DEVICE SELECTION MODAL (RACK) ---
func _build_device_modal() -> void:
	device_modal = Control.new()
	device_modal.name = "DeviceModal"
	device_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	device_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	device_modal.visible = false
	device_modal.z_index = 240
	add_child(device_modal)
	
	var bd = ColorRect.new()
	bd.set_anchors_preset(Control.PRESET_FULL_RECT)
	bd.color = Color(0, 0, 0, 0.65)
	device_modal.add_child(bd)
	
	device_card = Control.new()
	device_card.size = Vector2(720, 420)
	device_card.pivot_offset = Vector2(360, 210)
	device_modal.add_child(device_card)
	
	var panel = PanelContainer.new()
	panel.size = Vector2(720, 420)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fffbeb")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	device_card.add_child(panel)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)
	
	# Top bar with Close button
	var hb_top = HBoxContainer.new()
	var d_title = Label.new()
	d_title.text = "PILIH KONSENTRATOR JARINGAN"
	d_title.add_theme_font_override("font", font_black)
	d_title.add_theme_font_size_override("font_size", 20)
	d_title.add_theme_color_override("font_color", Color("#4a2e2b"))
	d_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb_top.add_child(d_title)
	
	var close_b = preload("res://scenes/close_button.tscn").instantiate()
	close_b.closed.connect(func(): device_modal.visible = false)
	hb_top.add_child(close_b)
	vb.add_child(hb_top)
	
	var d_sub = Label.new()
	d_sub.text = "Pilih perangkat jaringan yang tepat untuk menghubungkan 4 PC agar transmisi data tidak mengalami collision!"
	d_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_sub.add_theme_font_override("font", font_bold)
	d_sub.add_theme_font_size_override("font_size", 14)
	d_sub.add_theme_color_override("font_color", Color("#78350f"))
	vb.add_child(d_sub)
	
	# 2 Option Cards: HUB vs SWITCH
	var hb_cards = HBoxContainer.new()
	hb_cards.add_theme_constant_override("separation", 20)
	hb_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb_cards)
	
	# HUB CARD
	var card_hub = _create_device_choice_card(
		"HUB (Multiport Repeater)",
		"Layer 1 (Physical)",
		"Meneruskan sinyal listrik ke SEMUA port (Broadcast).\n1 Collision Domain bersama.\nRawan tabrakan data jika 2 PC kirim sekaligus!",
		tex_hub,
		Color("#fef3c7"),
		Color("#b45309"),
		func(): _choose_device_and_close("hub")
	)
	hb_cards.add_child(card_hub)
	
	# SWITCH CARD
	var card_switch = _create_device_choice_card(
		"SWITCH (Bridge Cerdas)",
		"Layer 2 (Data Link)",
		"Membaca MAC Address tujuan & merutekan Unicast.\nMemisahkan Collision Domain per port.\nBebas collision, data mengalir simultan!",
		tex_switch,
		Color("#e0e7ff"),
		Color("#3730a3"),
		func(): _choose_device_and_close("switch")
	)
	hb_cards.add_child(card_switch)

func _create_device_choice_card(title: String, layer_txt: String, desc: String, tex: Texture2D, bg: Color, border_c: Color, on_select: Callable) -> Control:
	var c = PanelContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border_c
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(14)
	c.add_theme_stylebox_override("panel", sb)
	
	var vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 8)
	c.add_child(vb)
	
	var img = TextureRect.new()
	img.texture = tex
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.custom_minimum_size = Vector2(110, 60)
	vb.add_child(img)
	
	var t = Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_override("font", font_black)
	t.add_theme_font_size_override("font_size", 14)
	t.add_theme_color_override("font_color", Color("#1e293b"))
	vb.add_child(t)
	
	var l = Label.new()
	l.text = layer_txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font_bold)
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", border_c)
	vb.add_child(l)
	
	var d = Label.new()
	d.text = desc
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_override("font", font_regular)
	d.add_theme_font_size_override("font_size", 12)
	d.add_theme_color_override("font_color", Color("#334155"))
	vb.add_child(d)
	
	var b = Button.new()
	b.text = "Pilih Perangkat Ini"
	b.custom_minimum_size = Vector2(160, 38)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_override("font", font_black)
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(on_select)
	_setup_hover_scale(b, 1.08)
	vb.add_child(b)
	
	return c

func _open_device_modal() -> void:
	_play_sweep(400.0, 600.0, 0.1, 0.2)
	device_modal.visible = true
	var vp_sz = get_viewport_rect().size
	device_card.position = Vector2((vp_sz.x - device_card.size.x) / 2.0, (vp_sz.y - device_card.size.y) / 2.0)

func _choose_device_and_close(dev: String) -> void:
	held_device = dev
	placed_device = dev
	device_modal.visible = false
	_refresh_table_visuals()
	_play_sweep(500.0, 750.0, 0.12, 0.25)
	show_toast("Kamu memilih %s! Perangkat telah diletakkan di meja tengah." % dev.to_upper(), 3.0)

# --- CABLING MODAL (FIGMA IMAGE 3) ---
func _build_cabling_modal() -> void:
	cabling_modal = Control.new()
	cabling_modal.name = "CablingModal"
	cabling_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	cabling_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	cabling_modal.visible = false
	cabling_modal.z_index = 245
	add_child(cabling_modal)
	
	var bd = ColorRect.new()
	bd.set_anchors_preset(Control.PRESET_FULL_RECT)
	bd.color = Color(0, 0, 0, 0.65)
	cabling_modal.add_child(bd)
	
	cabling_card = Control.new()
	cabling_card.size = Vector2(760, 480)
	cabling_card.pivot_offset = Vector2(380, 240)
	cabling_modal.add_child(cabling_card)
	
	# Main Outer Container with Lavender Header
	var vb_wrap = VBoxContainer.new()
	vb_wrap.size = Vector2(760, 480)
	vb_wrap.add_theme_constant_override("separation", 0)
	cabling_card.add_child(vb_wrap)
	
	# Lavender Header Bar
	var header_bar = PanelContainer.new()
	header_bar.custom_minimum_size = Vector2(760, 48)
	var sb_top = StyleBoxFlat.new()
	sb_top.bg_color = Color("#e9d5ff")
	sb_top.border_color = Color("#4a2e2b")
	sb_top.set_border_width_all(3.5)
	sb_top.corner_radius_top_left = 22
	sb_top.corner_radius_top_right = 22
	sb_top.content_margin_left = 18
	sb_top.content_margin_right = 14
	header_bar.add_theme_stylebox_override("panel", sb_top)
	
	var hb_hb = HBoxContainer.new()
	var h_title = Label.new()
	h_title.text = "PENGKABELAN PORT KONSENTRATOR"
	h_title.add_theme_font_override("font", font_black)
	h_title.add_theme_font_size_override("font_size", 16)
	h_title.add_theme_color_override("font_color", Color("#581c87"))
	h_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb_hb.add_child(h_title)
	
	var btn_x = preload("res://scenes/close_button.tscn").instantiate()
	btn_x.closed.connect(func(): cabling_modal.visible = false)
	hb_hb.add_child(btn_x)
	header_bar.add_child(hb_hb)
	vb_wrap.add_child(header_bar)
	
	# Dashed Card Area
	var body_panel = PanelContainer.new()
	body_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb_body = StyleBoxFlat.new()
	sb_body.bg_color = Color("#fffdf7")
	sb_body.border_color = Color("#4a2e2b")
	sb_body.set_border_width_all(3.5)
	sb_body.corner_radius_bottom_left = 22
	sb_body.corner_radius_bottom_right = 22
	sb_body.set_content_margin_all(16)
	body_panel.add_theme_stylebox_override("panel", sb_body)
	vb_wrap.add_child(body_panel)
	
	# Dashed inner box
	var dashed_box = Control.new()
	dashed_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	dashed_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dashed_box.draw.connect(func():
		var col = Color("#ca8a04")
		var lw = 2.5
		var dash = 7.0
		var sz = dashed_box.size
		dashed_box.draw_dashed_line(Vector2(4, 4), Vector2(sz.x - 4, 4), col, lw, dash)
		dashed_box.draw_dashed_line(Vector2(sz.x - 4, 4), Vector2(sz.x - 4, sz.y - 4), col, lw, dash)
		dashed_box.draw_dashed_line(Vector2(sz.x - 4, sz.y - 4), Vector2(4, sz.y - 4), col, lw, dash)
		dashed_box.draw_dashed_line(Vector2(4, sz.y - 4), Vector2(4, 4), col, lw, dash)
	)
	body_panel.add_child(dashed_box)
	
	var hb_content = HBoxContainer.new()
	hb_content.add_theme_constant_override("separation", 24)
	body_panel.add_child(hb_content)
	
	# Left: Vertical View of Switch / Hub with 8 ports
	var left_box = VBoxContainer.new()
	left_box.alignment = BoxContainer.ALIGNMENT_CENTER
	left_box.custom_minimum_size = Vector2(160, 360)
	hb_content.add_child(left_box)
	
	var dev_vertical = TextureRect.new()
	dev_vertical.texture = tex_switch_vertical
	dev_vertical.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dev_vertical.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dev_vertical.custom_minimum_size = Vector2(140, 340)
	left_box.add_child(dev_vertical)
	
	# Right: Challenge Panel
	var right_box = VBoxContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.add_theme_constant_override("separation", 8)
	hb_content.add_child(right_box)
	
	# Challenge Instruction
	var chal_lbl = Label.new()
	chal_lbl.text = "TANTANGAN: HUBUNGKAN 4 PC KE KONSENTRATOR"
	chal_lbl.add_theme_font_override("font", font_black)
	chal_lbl.add_theme_font_size_override("font_size", 13)
	chal_lbl.add_theme_color_override("font_color", Color("#581c87"))
	right_box.add_child(chal_lbl)
	
	# Cable Selector Buttons
	var cable_sel_box = HBoxContainer.new()
	cable_sel_box.add_theme_constant_override("separation", 8)
	right_box.add_child(cable_sel_box)
	
	btn_cable_straight = Button.new()
	btn_cable_straight.text = "🟢 Kabel Straight (T568B)"
	btn_cable_straight.custom_minimum_size = Vector2(240, 36)
	btn_cable_straight.add_theme_font_override("font", font_black)
	btn_cable_straight.add_theme_font_size_override("font_size", 12)
	btn_cable_straight.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_cable_straight.pressed.connect(func(): _select_cable_type("straight"))
	cable_sel_box.add_child(btn_cable_straight)
	
	btn_cable_cross = Button.new()
	btn_cable_cross.text = "🟠 Kabel Cross (T568A/B)"
	btn_cable_cross.custom_minimum_size = Vector2(240, 36)
	btn_cable_cross.add_theme_font_override("font", font_black)
	btn_cable_cross.add_theme_font_size_override("font_size", 12)
	btn_cable_cross.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_cable_cross.pressed.connect(func(): _select_cable_type("cross"))
	cable_sel_box.add_child(btn_cable_cross)
	
	# 4 PC Rows Container
	pc_rows_box = VBoxContainer.new()
	pc_rows_box.add_theme_constant_override("separation", 6)
	right_box.add_child(pc_rows_box)
	
	# Bottom Finish Button
	btn_finish_cabling = Button.new()
	btn_finish_cabling.text = "Colokkan Semua PC Terlebih Dahulu (0/4)"
	btn_finish_cabling.custom_minimum_size = Vector2(380, 42)
	btn_finish_cabling.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_finish_cabling.add_theme_font_override("font", font_black)
	btn_finish_cabling.add_theme_font_size_override("font_size", 14)
	btn_finish_cabling.disabled = true
	btn_finish_cabling.pressed.connect(_on_cables_connected_done)
	_setup_hover_scale(btn_finish_cabling, 1.05)
	right_box.add_child(btn_finish_cabling)
	
	_update_cable_selector_buttons()
	_refresh_pc_rows()

func _select_cable_type(type: String) -> void:
	selected_cable_type = type
	_play_sweep(440.0, 580.0, 0.08, 0.12)
	_update_cable_selector_buttons()

func _update_cable_selector_buttons() -> void:
	if not btn_cable_straight or not btn_cable_cross:
		return
		
	var sb_st = StyleBoxFlat.new()
	sb_st.set_corner_radius_all(10)
	sb_st.set_border_width_all(2.5)
	sb_st.content_margin_left = 12
	sb_st.content_margin_right = 12
	sb_st.content_margin_top = 6
	sb_st.content_margin_bottom = 6
	
	var sb_cr = sb_st.duplicate()
	
	if selected_cable_type == "straight":
		sb_st.bg_color = Color("#bbf7d0")
		sb_st.border_color = Color("#15803d")
		btn_cable_straight.add_theme_color_override("font_color", Color("#14532d"))
		
		sb_cr.bg_color = Color("#f1f5f9")
		sb_cr.border_color = Color("#cbd5e1")
		btn_cable_cross.add_theme_color_override("font_color", Color("#64748b"))
	else:
		sb_st.bg_color = Color("#f1f5f9")
		sb_st.border_color = Color("#cbd5e1")
		btn_cable_straight.add_theme_color_override("font_color", Color("#64748b"))
		
		sb_cr.bg_color = Color("#fed7aa")
		sb_cr.border_color = Color("#c2410c")
		btn_cable_cross.add_theme_color_override("font_color", Color("#9a3412"))
		
	btn_cable_straight.add_theme_stylebox_override("normal", sb_st)
	btn_cable_straight.add_theme_stylebox_override("hover", sb_st)
	btn_cable_straight.add_theme_stylebox_override("pressed", sb_st)
	
	btn_cable_cross.add_theme_stylebox_override("normal", sb_cr)
	btn_cable_cross.add_theme_stylebox_override("hover", sb_cr)
	btn_cable_cross.add_theme_stylebox_override("pressed", sb_cr)

func _refresh_pc_rows() -> void:
	if not pc_rows_box:
		return
	for ch in pc_rows_box.get_children():
		ch.queue_free()
		
	var count = 0
	for i in range(1, 5):
		var is_conn = cabling_connected.get(i, false)
		if is_conn:
			count += 1
		var row = _create_cabling_pc_row("PC %d" % i, "Port %d" % i, is_conn, i)
		pc_rows_box.add_child(row)
		
	var sb_fin = StyleBoxFlat.new()
	sb_fin.set_corner_radius_all(12)
	sb_fin.set_border_width_all(2.5)
	sb_fin.content_margin_left = 16
	sb_fin.content_margin_right = 16
	sb_fin.content_margin_top = 8
	sb_fin.content_margin_bottom = 8
	
	if count >= 4:
		btn_finish_cabling.disabled = false
		btn_finish_cabling.text = "▶ Semua PC Terhubung! Lanjut Uji Transmisi"
		btn_finish_cabling.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		sb_fin.bg_color = Color("#bbf7d0")
		sb_fin.border_color = Color("#4a2e2b")
		btn_finish_cabling.add_theme_color_override("font_color", Color("#14532d"))
		btn_finish_cabling.add_theme_color_override("font_disabled_color", Color("#14532d"))
	else:
		btn_finish_cabling.disabled = true
		btn_finish_cabling.text = "Colokkan Semua PC Terlebih Dahulu (%d/4)" % count
		btn_finish_cabling.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		sb_fin.bg_color = Color("#e2e8f0")
		sb_fin.border_color = Color("#94a3b8")
		btn_finish_cabling.add_theme_color_override("font_color", Color("#94a3b8"))
		btn_finish_cabling.add_theme_color_override("font_disabled_color", Color("#94a3b8"))
		
	btn_finish_cabling.add_theme_stylebox_override("normal", sb_fin)
	btn_finish_cabling.add_theme_stylebox_override("hover", sb_fin)
	btn_finish_cabling.add_theme_stylebox_override("pressed", sb_fin)
	btn_finish_cabling.add_theme_stylebox_override("disabled", sb_fin)

func _create_cabling_pc_row(pc_name: String, port_name: String, is_conn: bool, pc_idx: int) -> Control:
	var row = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#f0fdf4") if is_conn else Color("#f8fafc")
	sb.border_color = Color("#16a34a") if is_conn else Color("#cbd5e1")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	row.add_theme_stylebox_override("panel", sb)
	
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	
	var pc_icon = TextureRect.new()
	pc_icon.texture = tex_pc
	pc_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pc_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pc_icon.custom_minimum_size = Vector2(36, 32)
	hb.add_child(pc_icon)
	
	var vb_info = VBoxContainer.new()
	vb_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb_info.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var lbl_pc = Label.new()
	lbl_pc.text = pc_name
	lbl_pc.add_theme_font_override("font", font_black)
	lbl_pc.add_theme_font_size_override("font_size", 13)
	lbl_pc.add_theme_color_override("font_color", Color("#1e293b"))
	vb_info.add_child(lbl_pc)
	
	var lbl_p = Label.new()
	lbl_p.text = "Target: %s" % port_name
	lbl_p.add_theme_font_override("font", font_regular)
	lbl_p.add_theme_font_size_override("font_size", 11)
	lbl_p.add_theme_color_override("font_color", Color("#64748b"))
	vb_info.add_child(lbl_p)
	hb.add_child(vb_info)
	
	if is_conn:
		var status_lbl = Label.new()
		status_lbl.text = "✓ Terhubung (Straight)"
		status_lbl.add_theme_font_override("font", font_bold)
		status_lbl.add_theme_font_size_override("font_size", 12)
		status_lbl.add_theme_color_override("font_color", Color("#16a34a"))
		status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(status_lbl)
	else:
		var btn_plug = Button.new()
		btn_plug.text = "🔌 Pasang Kabel"
		btn_plug.custom_minimum_size = Vector2(130, 32)
		btn_plug.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_plug.add_theme_font_override("font", font_black)
		btn_plug.add_theme_font_size_override("font_size", 11)
		var sb_p = StyleBoxFlat.new()
		sb_p.bg_color = Color("#e0e7ff")
		sb_p.border_color = Color("#4a2e2b")
		sb_p.set_border_width_all(2)
		sb_p.set_corner_radius_all(8)
		sb_p.content_margin_left = 8
		sb_p.content_margin_right = 8
		btn_plug.add_theme_stylebox_override("normal", sb_p)
		btn_plug.add_theme_stylebox_override("hover", sb_p)
		btn_plug.add_theme_stylebox_override("pressed", sb_p)
		btn_plug.add_theme_color_override("font_color", Color("#3730a3"))
		btn_plug.pressed.connect(func(): _try_connect_pc(pc_idx))
		_setup_hover_scale(btn_plug, 1.05)
		hb.add_child(btn_plug)
		
	return row

func _try_connect_pc(pc_num: int) -> void:
	if cabling_connected.get(pc_num, false):
		return
		
	if selected_cable_type == "cross":
		_play_sweep(220.0, 140.0, 0.2, 0.25)
		hearts = max(0, hearts - 1)
		_update_hearts_display()
		show_toast("❌ SALAH KABEL! Kabel Cross hanya untuk PC ke PC. Menghubungkan PC ke Switch/Hub harus pakai Kabel Straight (T568B)!", 4.0)
		if hearts <= 0:
			cabling_modal.visible = false
			_trigger_game_over("Nyawa habis karena salah memilih jenis kabel jaringan!")
		return
		
	_play_sweep(523.25, 784.0, 0.1, 0.18)
	cabling_connected[pc_num] = true
	show_toast("✓ PC %d berhasil terhubung ke Port %d dengan Kabel Straight!" % [pc_num, pc_num], 2.0)
	_refresh_pc_rows()
	
	var count = 0
	for v in cabling_connected.values():
		if v: count += 1
		
	if count >= 4:
		_play_sweep(659.25, 1046.5, 0.2, 0.3)
		show_toast("🎉 Semua 4 PC berhasil terhubung! Tekan tombol di bawah untuk menguji transmisi data.", 3.5)

func _open_cabling_modal() -> void:
	if toast_panel:
		toast_panel.visible = false
	_play_sweep(400.0, 650.0, 0.1, 0.2)
	cabling_modal.visible = true
	var vp_sz = get_viewport_rect().size
	cabling_card.position = Vector2((vp_sz.x - cabling_card.size.x) / 2.0, (vp_sz.y - cabling_card.size.y) / 2.0)
	_refresh_pc_rows()
	_update_cable_selector_buttons()

func _on_cables_connected_done() -> void:
	cables_installed = true
	cabling_modal.visible = false
	cables_container.queue_redraw()
	_play_sweep(520.0, 880.0, 0.15, 0.25)
	show_toast("Semua kabel terpasang! Tekan 'Uji Transmisi Data' di meja tengah.", 3.5)

# --- DATA TRANSMISSION SIMULATION & WINGED DATA PACKETS (FIGMA IMAGE 4) ---
func _start_simulation() -> void:
	if is_simulating:
		return
	is_simulating = true
	
	# Center point of table device
	var center = cable_table_node.position + Vector2(cable_table_node.size.x / 2.0, 30.0)
	var p1 = pc1_node.position + Vector2(150.0, 70.0)
	var p2 = pc2_node.position + Vector2(150.0, 70.0)
	var p3 = pc3_node.position + Vector2(20.0, 70.0)
	var p4 = pc4_node.position + Vector2(20.0, 70.0)
	
	# Packet A: PC 2 -> PC 4
	var packet_a = _create_winged_packet("PC2 → PC4")
	packets_container.add_child(packet_a)
	
	# Packet B: PC 1 -> PC 3
	var packet_b = _create_winged_packet("PC1 → PC3")
	packets_container.add_child(packet_b)
	
	_play_sweep(440.0, 880.0, 0.2, 0.25)
	show_toast("Mengirim amplop data secara bersamaan...", 2.0)
	
	var tw = create_tween().set_parallel(true)
	
	# Phase 1: Travel from sources to Central Device (duration: 1.2s)
	tw.tween_method(func(t: float):
		_update_packet_anim(packet_a)
		_update_packet_anim(packet_b)
		packet_a.position = _get_bezier_point(p2, center + Vector2(-20, 42), Vector2(-30, 60), t) - Vector2(35, 30)
		packet_b.position = _get_bezier_point(p1, center + Vector2(-55, 36), Vector2(-35, 35), t) - Vector2(35, 30)
	, 0.0, 1.0, 1.2)
	
	await tw.finished
	
	if placed_device == "switch":
		# SUCCESS BRANCH: SWITCH UNICAST ROUTING
		_play_tone(659.25, 0.15, 0.25)
		if table_mac_tag:
			var tw_mac = create_tween().set_parallel(true)
			tw_mac.tween_property(table_mac_tag, "scale", Vector2(1.3, 1.3), 0.15)
			tw_mac.chain().tween_property(table_mac_tag, "scale", Vector2.ONE, 0.15)
			
		show_toast("Switch membaca MAC Address: Meneruskan paket ke port tujuan masing-masing!", 2.0)
		
		# Phase 2: Travel from Switch to destination PCs (PC4 & PC3)
		var tw2 = create_tween().set_parallel(true)
		tw2.tween_method(func(t: float):
			_update_packet_anim(packet_a)
			_update_packet_anim(packet_b)
			packet_a.position = _get_bezier_point(center + Vector2(55, 36), p4, Vector2(35, 35), t) - Vector2(35, 30)
			packet_b.position = _get_bezier_point(center + Vector2(20, 42), p3, Vector2(30, 60), t) - Vector2(35, 30)
		, 0.0, 1.0, 1.2)
		
		await tw2.finished
		
		# Arrival Celebration
		_play_sweep(523.25, 1046.5, 0.35, 0.3)
		if "PC 4" in pc_emotes:
			pc_emotes["PC 4"].visible = true
		if "PC 3" in pc_emotes:
			pc_emotes["PC 3"].visible = true
			
		show_toast("🎉 Sukses! Switch memisahkan collision domain: Bebas Tabrakan!", 3.0)
		await get_tree().create_timer(1.2).timeout
		
		packet_a.queue_free()
		packet_b.queue_free()
		is_simulating = false
		_trigger_win()
		
	else:
		# COLLISION BRANCH: HUB REPEATER CONFLICT
		_play_tone(150.0, 0.45, 0.35)
		
		# Collision Burst Animation at Center
		var col_burst = Label.new()
		col_burst.text = "💥 COLLISION!\nTABRAKAN DATA"
		col_burst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col_burst.add_theme_font_override("font", font_black)
		col_burst.add_theme_font_size_override("font_size", 18)
		col_burst.add_theme_color_override("font_color", Color("#dc2626"))
		col_burst.position = center - Vector2(80, 50)
		packets_container.add_child(col_burst)
		
		# Hub gets dizzy with soundwaves (( HUB )) (as in Figma Image 4)
		if rack_hub_distress:
			rack_hub_distress.visible = true
			
		_deduct_heart()
		show_toast("⚠️ TABRAKAN DATA (COLLISION)! Hub meneruskan sinyal ke semua port (1 Collision Domain). Ganti dengan Switch di rak!", 4.0)
		
		await get_tree().create_timer(1.8).timeout
		col_burst.queue_free()
		packet_a.queue_free()
		packet_b.queue_free()
		is_simulating = false

func _create_winged_packet(route_text: String) -> Control:
	var packet_node = Control.new()
	packet_node.size = Vector2(80, 60)
	
	# Winged Envelope Sprite
	var sp = TextureRect.new()
	sp.name = "Sprite"
	if packet_frames.size() > 0:
		sp.texture = packet_frames[0]
	sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sp.size = Vector2(70, 42)
	sp.position = Vector2(5, 0)
	packet_node.add_child(sp)
	
	# Route Pill Badge (Image 4: "PC2 -> PC4", "PC1 -> PC3")
	var pill = PanelContainer.new()
	pill.name = "RoutePill"
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(1.5)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", sb)
	
	var lbl = Label.new()
	lbl.text = route_text
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#1e293b"))
	pill.add_child(lbl)
	pill.position = Vector2(2, 38)
	packet_node.add_child(pill)
	
	return packet_node

func _update_packet_anim(packet_node: Control) -> void:
	if not packet_node or packet_frames.size() == 0:
		return
	var sp = packet_node.get_node_or_null("Sprite") as TextureRect
	if sp:
		var frame = (Time.get_ticks_msec() / 30) % packet_frames.size()
		sp.texture = packet_frames[frame]

# --- GUIDEBOOK MODAL ---
func _build_guidebook_modal() -> void:
	guidebook_modal = Control.new()
	guidebook_modal.name = "GuidebookModal"
	guidebook_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	guidebook_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	guidebook_modal.visible = false
	guidebook_modal.z_as_relative = false
	guidebook_modal.z_index = 250
	add_child(guidebook_modal)
	
	var bd = ColorRect.new()
	bd.set_anchors_preset(Control.PRESET_FULL_RECT)
	bd.color = Color(0, 0, 0, 0.7)
	guidebook_modal.add_child(bd)
	
	guidebook_card = Control.new()
	guidebook_card.size = Vector2(680, 440)
	guidebook_card.pivot_offset = Vector2(340, 220)
	guidebook_modal.add_child(guidebook_card)
	
	var panel = PanelContainer.new()
	panel.size = Vector2(680, 440)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fffdf7")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sb)
	guidebook_card.add_child(panel)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	
	var hb_top = HBoxContainer.new()
	var g_title = Label.new()
	g_title.text = "PANDUAN JARINGAN: HUB VS SWITCH"
	g_title.add_theme_font_override("font", font_black)
	g_title.add_theme_font_size_override("font_size", 20)
	g_title.add_theme_color_override("font_color", Color("#4a2e2b"))
	g_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb_top.add_child(g_title)
	
	var btn_close_g = preload("res://scenes/close_button.tscn").instantiate()
	btn_close_g.closed.connect(func(): guidebook_modal.visible = false)
	hb_top.add_child(btn_close_g)
	vb.add_child(hb_top)
	
	var txt = Label.new()
	txt.text = """1. HUB (Multiport Repeater - Layer 1 Physical):
• Meneruskan sinyal listrik secara membabi buta ke SELURUH port aktif (Broadcast).
• Seluruh perangkat berada dalam SATU Collision Domain. Jika dua PC mengirim data bersamaan, sinyal akan bertabrakan (Collision) dan paket data rusak.

2. SWITCH (Bridge Cerdas - Layer 2 Data Link):
• Memiliki MAC Address Table untuk mencatat port mana yang terhubung ke PC mana.
• Meneruskan frame data hanya ke port tujuan secara spesifik (Unicast).
• Memisahkan Collision Domain per port (Microsegmentation), sehingga komunikasi antar PC dapat berlangsung serentak tanpa tabrakan!"""
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.add_theme_font_override("font", font_bold)
	txt.add_theme_font_size_override("font_size", 14)
	txt.add_theme_color_override("font_color", Color("#334155"))
	vb.add_child(txt)
	
	var btn_ok = Button.new()
	btn_ok.text = "Paham & Tutup"
	btn_ok.custom_minimum_size = Vector2(200, 42)
	btn_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_ok.add_theme_font_override("font", font_black)
	btn_ok.add_theme_font_size_override("font_size", 15)
	btn_ok.pressed.connect(func(): guidebook_modal.visible = false)
	vb.add_child(btn_ok)

func _open_guidebook_modal() -> void:
	_play_sweep(400.0, 700.0, 0.1, 0.2)
	guidebook_modal.visible = true
	var vp_sz = get_viewport_rect().size
	guidebook_card.position = Vector2((vp_sz.x - guidebook_card.size.x) / 2.0, (vp_sz.y - guidebook_card.size.y) / 2.0)

# --- PAUSE, WIN, & GAME OVER MODALS ---
func _build_pause_modal() -> void:
	pause_modal = preload("res://scenes/pause_modal.tscn").instantiate()
	pause_modal.z_index = 240
	pause_modal.settings_modal = settings_modal
	add_child(pause_modal)

func _open_pause_modal() -> void:
	if pause_modal and pause_modal.has_method("open"):
		pause_modal.open()

func _close_pause_modal() -> void:
	if pause_modal and pause_modal.has_method("close"):
		pause_modal.close()

func _build_win_gameover_modals() -> void:
	game_dialog = preload("res://scenes/game_dialog.tscn").instantiate()
	game_dialog.name = "GameDialog"
	add_child(game_dialog)
	win_modal = game_dialog
	gameover_modal = game_dialog

func _create_modal_btn(text: String, bg_col: Color, font_col: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 48)
	btn.add_theme_font_override("font", font_black)
	btn.add_theme_font_size_override("font_size", 16)
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_color_override("font_color", font_col)
	_setup_hover_scale(btn, 1.08)
	return btn

func _trigger_win() -> void:
	has_won = true
	is_game_active = false
	if PlayerData:
		PlayerData.set_level_stars(1, 3, hearts)
		
	var mins = int(time_remaining) / 60
	var secs = int(time_remaining) % 60
	var time_str = "Sisa Waktu: %02d:%02d" % [mins, secs]
	var desc = "Luar biasa! Konsentrator Switch berhasil dipasang dan kabel Straight terhubung ke semua PC tanpa collision!"
	game_dialog.show_win(
		"LEVEL 1.3 SELESAI!",
		desc,
		hearts,
		time_str,
		func(): get_tree().change_scene_to_file("res://scenes/gameplay/level_2_1.tscn"),
		func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"),
		"STAGE 2 LEVEL 2.1"
	)

func _trigger_game_over(reason: String) -> void:
	is_game_active = false
	_update_hearts_display(true)
	game_dialog.show_game_over(
		reason,
		func(): get_tree().reload_current_scene(),
		func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn")
	)

# --- TOAST NOTIFICATIONS ---
func _build_toast_ui() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.name = "ToastPanel"
	toast_panel.visible = false
	toast_panel.z_as_relative = false
	toast_panel.z_index = 300
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#1e293b")
	sb.border_color = Color("#fed0cf")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 28.0
	sb.content_margin_right = 28.0
	sb.content_margin_top = 14.0
	sb.content_margin_bottom = 14.0
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	toast_panel.add_theme_stylebox_override("panel", sb)
	add_child(toast_panel)
	
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_override("font", font_extrabold)
	toast_label.add_theme_font_size_override("font_size", 18)
	toast_label.add_theme_color_override("font_color", Color.WHITE)
	toast_panel.add_child(toast_label)

func show_toast(text: String, duration: float = 3.0) -> void:
	if not toast_panel or not toast_label:
		return
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_panel.move_to_front()
	toast_label.text = text
	toast_panel.reset_size()
	var screen_w = get_viewport_rect().size.x
	toast_panel.position = Vector2((screen_w - toast_panel.size.x) / 2.0, 105.0)
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	toast_panel.scale = Vector2(0.92, 0.92)
	
	toast_tween = create_tween().set_parallel(true)
	toast_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.18)
	toast_tween.tween_property(toast_panel, "scale", Vector2.ONE, 0.18)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(duration)
	fade_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.25)
	fade_tween.chain().tween_callback(func(): toast_panel.visible = false)

# --- REPOSITION RESPONSIVE ---
func _reposition_responsive() -> void:
	var screen_w = get_viewport_rect().size.x
	var center_x = screen_w / 2.0
	
	if door_arch:
		door_arch.position = Vector2(center_x - 164.0, 46.0)
		door_arch.size = Vector2(328.0, 200.0)
	if potted_plant:
		potted_plant.position = Vector2(center_x + 180.0, 70.0)
		potted_plant.size = Vector2(120.0, 180.0)
	if left_rack_node:
		left_rack_node.position = Vector2(80.0, 220.0)
		left_rack_node.size = Vector2(270.0, 360.0)
	if cable_table_node:
		cable_table_node.position = Vector2(center_x - 160.0, 420.0)
		cable_table_node.size = Vector2(320.0, 110.0)
	if pc1_node:
		pc1_node.position = Vector2(center_x - 380.0, 370.0)
	if pc2_node:
		pc2_node.position = Vector2(center_x - 380.0, 560.0)
	if pc3_node:
		pc3_node.position = Vector2(center_x + 210.0, 560.0)
	if pc4_node:
		pc4_node.position = Vector2(center_x + 210.0, 370.0)
		
	if char_pos == Vector2.ZERO:
		char_pos = Vector2(center_x - 128.0, 270.0)
		character_mascot.position = char_pos
		
	if header_ui:
		var back_b = header_ui.get_node_or_null("BackBtn")
		var hearts_p = header_ui.get_node_or_null("HeartsPanel")
		var lvl_p = header_ui.get_node_or_null("LevelBadge")
		var timer_p = header_ui.get_node_or_null("TimerPanel")
		var pause_b = header_ui.get_node_or_null("PauseBtn")
		
		if back_b:
			back_b.position = Vector2(40, 26)
		if hearts_p:
			hearts_p.position = Vector2(110, 26)
		if lvl_p:
			lvl_p.position = Vector2(270, 26)
		if timer_p:
			timer_p.position = Vector2(screen_w - 240, 26)
		if pause_b:
			pause_b.position = Vector2(screen_w - 74, 26)
			
	if intro_card:
		var vp_sz = get_viewport_rect().size
		intro_card.position = Vector2((vp_sz.x - intro_card.size.x) / 2.0, (vp_sz.y - intro_card.size.y) / 2.0)
	if device_card:
		var vp_sz = get_viewport_rect().size
		device_card.position = Vector2((vp_sz.x - device_card.size.x) / 2.0, (vp_sz.y - device_card.size.y) / 2.0)
	if cabling_card:
		var vp_sz = get_viewport_rect().size
		cabling_card.position = Vector2((vp_sz.x - cabling_card.size.x) / 2.0, (vp_sz.y - cabling_card.size.y) / 2.0)
	if guidebook_card:
		var vp_sz = get_viewport_rect().size
		guidebook_card.position = Vector2((vp_sz.x - guidebook_card.size.x) / 2.0, (vp_sz.y - guidebook_card.size.y) / 2.0)
	if pause_card:
		var vp_sz = get_viewport_rect().size
		pause_card.position = Vector2((vp_sz.x - pause_card.size.x) / 2.0, (vp_sz.y - pause_card.size.y) / 2.0)

	cables_container.queue_redraw()

# --- HELPER UTILITIES ---
func _setup_hover_scale(node: Control, scale_factor: float = 1.08) -> void:
	node.mouse_entered.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector2(scale_factor, scale_factor), 0.1)
	)
	node.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector2.ONE, 0.1)
	)

# --- SYNTHESIZED RETRO AUDIO ---
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
			var envelope = 1.0 - (float(i) / float(num_samples))
			var wave = sin(2.0 * PI * freq * t) * envelope * vol
			pb.push_frame(Vector2(wave, wave))

func _play_sweep(freq_start: float, freq_end: float, duration: float, vol: float = 0.2) -> void:
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
			var progress = float(i) / float(num_samples)
			var freq = lerp(freq_start, freq_end, progress)
			var t = float(i) / sample_rate
			var envelope = sin(progress * PI)
			var wave = sin(2.0 * PI * freq * t) * envelope * vol
			pb.push_frame(Vector2(wave, wave))

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
			var noise = (randf() * 2.0 - 1.0) * env * 0.08
			pb.push_frame(Vector2(noise, noise))
