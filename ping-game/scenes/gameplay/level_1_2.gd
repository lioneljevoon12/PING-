extends Control

# Level 1.2 - Menyusun Pin Warna TIA/EIA 568A/B
# Core Gameplay: Merakit Urutan Pin Warna Kabel Straight (T568B)

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
var tex_table = preload("res://art/ui-ux/levelpath/desk_station_new.png")
var tex_rack = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/rak-kabel.png")
var tex_crimping = preload("res://art/assets/PING! Assets/Objects/crimping_cropped.png")
var tex_cable_roll = preload("res://art/assets/PING! Assets/Objects/kabel_utp_cropped.png")

var tex_cable_green = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-hijau.png")
var tex_cable_yellow = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-kuning.png")
var tex_cable_blue = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-biru.png")
var tex_cable_red = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-merah.png")

var tex_diagram_cross = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/cross_opt.png")
var tex_diagram_straight = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/straight_opt.png")
var tex_rj45_housing = preload("res://art/rj45_housing_empty.png")
var tex_wire_po = preload("res://art/rj45_wires/wire_po.png")
var tex_wire_o = preload("res://art/rj45_wires/wire_o.png")
var tex_wire_ph = preload("res://art/rj45_wires/wire_ph.png")
var tex_wire_b = preload("res://art/rj45_wires/wire_b.png")
var tex_wire_pb = preload("res://art/rj45_wires/wire_pb.png")
var tex_wire_h = preload("res://art/rj45_wires/wire_h.png")
var tex_wire_pc = preload("res://art/rj45_wires/wire_pc.png")
var tex_wire_c = preload("res://art/rj45_wires/wire_c.png")

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
@onready var right_rack_node: Control = %RightRack
@onready var cable_table_node: Control = %CableTable
@onready var character_mascot: Control = %CharacterMascot

# UI Elements
var header_ui: Control
var action_btn_node: TextureButton
var joystick_zone: Control
var table_prompt_bubble: Control

# Modals
var intro_modal: Control
var intro_card: Control

var guidebook_modal: Control
var guidebook_card: Control

var crimping_modal: Control
var crimping_card: Control
var grid_wires_container: GridContainer

var pause_modal: Control
var settings_modal: Control
var pause_card: Control

var win_modal: Control
var win_card: Control
var win_stars_row: HBoxContainer

var gameover_modal: Control
var gameover_card: Control
var gameover_reason_lbl: Label

var toast_panel: PanelContainer
var toast_label: Label
var toast_tween: Tween
var timer_label: Label
var hearts_label: Label

# Character Mascot Visuals
var char_sprite: TextureRect
var walk_frames: Array[Texture2D] = []
var walk_anim_time: float = 0.0
var walk_anim_fps: float = 24.0
var char_facing_right: bool = true

# Gameplay State
var is_game_active: bool = false
var time_remaining: float = 165.0 # 02:45
var hearts: int = 3
var hearts_rects: Array[TextureRect] = []
var char_pos: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO
var footstep_timer: float = 0.0

# D-Pad Virtual Joystick State
var dpad_touch_id: int = -1
var dpad_center: Vector2 = Vector2.ZERO
var dpad_knob_sprite: TextureRect
var dpad_radius: float = 55.0

# --- MINIGAME WIRE ORDERING DATA ---
var all_wires_def: Array[Dictionary] = [
	{ "id": "white_orange", "name": "P-Oranye", "full_name": "Putih-Oranye", "base": Color("#ffffff"), "stripe": Color("#ea580c"), "is_striped": true, "tex": tex_wire_po },
	{ "id": "orange",       "name": "Oranye",   "full_name": "Oranye",       "base": Color("#ea580c"), "stripe": Color("#ea580c"), "is_striped": false, "tex": tex_wire_o },
	{ "id": "white_green",  "name": "P-Hijau",  "full_name": "Putih-Hijau",  "base": Color("#ffffff"), "stripe": Color("#16a34a"), "is_striped": true, "tex": tex_wire_ph },
	{ "id": "blue",         "name": "Biru",     "full_name": "Biru",         "base": Color("#0284c7"), "stripe": Color("#0284c7"), "is_striped": false, "tex": tex_wire_b },
	{ "id": "white_blue",   "name": "P-Biru",   "full_name": "Putih-Biru",   "base": Color("#ffffff"), "stripe": Color("#0284c7"), "is_striped": true, "tex": tex_wire_pb },
	{ "id": "green",        "name": "Hijau",    "full_name": "Hijau",        "base": Color("#16a34a"), "stripe": Color("#16a34a"), "is_striped": false, "tex": tex_wire_h },
	{ "id": "white_brown",  "name": "P-Cokelat","full_name": "Putih-Cokelat","base": Color("#ffffff"), "stripe": Color("#78350f"), "is_striped": true, "tex": tex_wire_pc },
	{ "id": "brown",        "name": "Cokelat",  "full_name": "Cokelat",      "base": Color("#78350f"), "stripe": Color("#78350f"), "is_striped": false, "tex": tex_wire_c }
]

const TARGET_SEQUENCE: Array[String] = [
	"white_orange", "orange", "white_green", "blue", "white_blue", "green", "white_brown", "brown"
]

var pin_slots: Array = [null, null, null, null, null, null, null, null]
var tray_wires: Array[Dictionary] = []

var dragging_wire_data: Dictionary = {}
var drag_ghost: Control = null
var slot_containers: Array[PanelContainer] = []
var tray_container: HBoxContainer = null
var rj45_channel_controls: Array[Control] = []
var rj45_wire_sprites: Array[TextureRect] = []
var rj45_pin_badges: Array[PanelContainer] = []
var tray_card_nodes: Array[PanelContainer] = []

func _ready() -> void:
	settings_modal = preload("res://scenes/settings_modal.tscn").instantiate()
	add_child(settings_modal)
	_load_walk_frames()
	_init_tray_wires()
	
	_build_room_visuals()
	_build_character()
	_build_header_ui()
	_build_mobile_controls()
	
	_build_guidebook_modal()
	_build_crimping_modal()
	_build_pause_modal()
	_build_win_gameover_modals()
	_build_intro_modal()
	_build_toast_ui()
	
	_reposition_responsive()
	get_viewport().size_changed.connect(_reposition_responsive)
	
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-gameplay" in all_args:
		await get_tree().create_timer(0.2).timeout
		_start_gameplay()
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_2_gameplay_render.png")
		get_tree().quit()
		
	if "--screenshot-crimping" in all_args:
		await get_tree().create_timer(0.2).timeout
		_start_gameplay()
		await get_tree().create_timer(0.2).timeout
		_open_crimping_modal()
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_2_minigame_render.png")
		get_tree().quit()

func _load_walk_frames() -> void:
	walk_frames.clear()
	for i in range(1, 33):
		var p = "res://art/assets/PING! Assets/Sprite animation/router walk/%d.png" % i
		if ResourceLoader.exists(p):
			var tex = load(p)
			if tex:
				walk_frames.append(tex)

func _init_tray_wires() -> void:
	tray_wires = all_wires_def.duplicate()
	tray_wires.shuffle()
	pin_slots = [null, null, null, null, null, null, null, null]

func _process(delta: float) -> void:
	if is_game_active:
		time_remaining = max(0.0, time_remaining - delta)
		_update_timer_display()
		if time_remaining <= 0.0:
			is_game_active = false
			_trigger_game_over("Waktu habis! Perakitan urutan pin kabel gagal diselesaikan tepat waktu.")
			
	_handle_character_movement(delta)
	_update_table_proximity()

func _update_timer_display() -> void:
	if not timer_label:
		return
	var m = int(time_remaining) / 60
	var s = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [m, s]
	if time_remaining <= 30.0:
		timer_label.add_theme_color_override("font_color", Color("#ef4444"))
	else:
		timer_label.add_theme_color_override("font_color", Color("#1e293b"))

func _handle_character_movement(delta: float) -> void:
	var move_vec = Vector2.ZERO
	if is_game_active and not crimping_modal.visible and not guidebook_modal.visible and not pause_modal.visible and not settings_modal.visible:
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
			var table_center = cable_table_node.position + Vector2(230.0, 65.0)
			var char_center = char_pos + Vector2(128.0, 72.0)
			if table_center.distance_to(char_center) < 230.0:
				_open_crimping_modal()
			
	if move_vec.length() > 0.0:
		move_vec = move_vec.normalized()
		var new_pos = char_pos + move_vec * MOVE_SPEED * delta
		var screen_w = get_viewport_rect().size.x
		var center_x = screen_w / 2.0
		
		if not _is_room_collision(new_pos, center_x):
			char_pos = new_pos
		else:
			var try_x = Vector2(new_pos.x, char_pos.y)
			if not _is_room_collision(try_x, center_x):
				char_pos = try_x
			else:
				var try_y = Vector2(char_pos.x, new_pos.y)
				if not _is_room_collision(try_y, center_x):
					char_pos = try_y
					
		if move_vec.x > 0.05:
			char_facing_right = true
		elif move_vec.x < -0.05:
			char_facing_right = false
			
		walk_anim_time += delta * walk_anim_fps
		var frame_idx = int(walk_anim_time) % max(1, walk_frames.size())
		if walk_frames.size() > 0:
			char_sprite.texture = walk_frames[frame_idx]
			
		char_sprite.flip_h = not char_facing_right
		character_mascot.position = char_pos
		
		footstep_timer += delta
		if footstep_timer >= 0.28:
			footstep_timer = 0.0
			_play_footstep()
	else:
		walk_anim_time = 0.0
		char_sprite.texture = tex_char_idle
		char_sprite.flip_h = not char_facing_right

func _is_room_collision(pos: Vector2, center_x: float) -> bool:
	var screen_w = get_viewport_rect().size.x
	var char_feet = Rect2(pos.x + 50.0, pos.y + 90.0, 156.0, 50.0)
	
	if pos.x < 30.0 or pos.x > screen_w - 280.0 or pos.y < 210.0 or pos.y > 560.0:
		return true
		
	var table_rect = Rect2(center_x - 220.0, 480.0, 440.0, 140.0)
	if table_rect.intersects(char_feet):
		return true
		
	var left_rack = Rect2(center_x - 560.0, 210.0, 270.0, 320.0)
	if left_rack.intersects(char_feet):
		return true
		
	var right_rack = Rect2(center_x + 290.0, 210.0, 270.0, 320.0)
	if right_rack.intersects(char_feet):
		return true
		
	return false

func _update_table_proximity() -> void:
	if not cable_table_node or not table_prompt_bubble:
		return
	var table_center = cable_table_node.position + Vector2(230.0, 65.0)
	var char_center = char_pos + Vector2(128.0, 72.0)
	var dist = table_center.distance_to(char_center)
	var is_near = dist < 230.0
	table_prompt_bubble.visible = is_near

func _build_room_visuals() -> void:
	_setup_decorative_rack(left_rack_node, "Rak Kabel Cross", "#c2410c")
	_setup_decorative_rack(right_rack_node, "Rak Kabel Straight", "#0284c7")
	_setup_cable_workbench()

func _setup_decorative_rack(rack_root: Control, title_text: String, badge_color_hex: String) -> void:
	rack_root.clip_contents = false
	rack_root.size = Vector2(270, 340)
	
	var rack_tex = TextureRect.new()
	rack_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rack_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rack_tex.custom_minimum_size = Vector2(270, 340)
	rack_tex.size = Vector2(270, 340)
	rack_tex.texture = tex_rack
	rack_root.add_child(rack_tex)
	
	var badge = PanelContainer.new()
	badge.name = "RackBadge"
	badge.custom_minimum_size = Vector2(174, 52)
	badge.size = Vector2(174, 52)
	badge.position = Vector2((270 - 174) / 2.0, -26)
	var sb_b = StyleBoxFlat.new()
	sb_b.bg_color = Color("#ffffff")
	sb_b.border_color = Color("#4a2e2b")
	sb_b.set_border_width_all(3.5)
	sb_b.set_corner_radius_all(14)
	sb_b.set_content_margin_all(2)
	sb_b.shadow_color = Color(0, 0, 0, 0.22)
	sb_b.shadow_size = 6
	sb_b.shadow_offset = Vector2(0, 3)
	badge.add_theme_stylebox_override("panel", sb_b)
	rack_root.add_child(badge)
	
	var vb_badge = VBoxContainer.new()
	vb_badge.alignment = BoxContainer.ALIGNMENT_CENTER
	vb_badge.add_theme_constant_override("separation", -2)
	badge.add_child(vb_badge)
	
	var lbl_top = Label.new()
	lbl_top.text = "Rak Kabel"
	lbl_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_top.add_theme_font_override("font", font_bold)
	lbl_top.add_theme_font_size_override("font_size", 13)
	lbl_top.add_theme_color_override("font_color", Color("#78716c"))
	vb_badge.add_child(lbl_top)
	
	var lbl_bot = Label.new()
	lbl_bot.text = "Cross" if "Cross" in title_text else "Straight"
	lbl_bot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_bot.add_theme_font_override("font", font_black)
	lbl_bot.add_theme_font_size_override("font_size", 16)
	lbl_bot.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb_badge.add_child(lbl_bot)
	
	var shelf_container = Control.new()
	shelf_container.name = "ShelfCablesContainer"
	shelf_container.clip_contents = true
	shelf_container.position = Vector2(16, 26)
	shelf_container.size = Vector2(238, 280)
	rack_root.add_child(shelf_container)
	
	var sample_cables = [tex_cable_green, tex_cable_yellow, tex_cable_blue, tex_cable_red]
	for row in range(2):
		for col in range(4):
			var c_img = TextureRect.new()
			c_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			c_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			c_img.custom_minimum_size = Vector2(50, 50)
			c_img.size = Vector2(50, 50)
			c_img.position = Vector2(12 + col * 56, 26 + row * 92)
			c_img.texture = sample_cables[(row * 4 + col) % sample_cables.size()]
			shelf_container.add_child(c_img)

func _setup_cable_workbench() -> void:
	cable_table_node.size = Vector2(460, 130)
	
	var t_panel = PanelContainer.new()
	t_panel.size = Vector2(460, 130)
	var sb_table = StyleBoxFlat.new()
	sb_table.bg_color = Color("#dfcaa9")
	sb_table.border_color = Color("#593717")
	sb_table.set_border_width_all(3)
	sb_table.set_corner_radius_all(12)
	t_panel.add_theme_stylebox_override("panel", sb_table)
	cable_table_node.add_child(t_panel)
	
	var items_row = HBoxContainer.new()
	items_row.position = Vector2(25, 18)
	items_row.size = Vector2(410, 95)
	items_row.alignment = BoxContainer.ALIGNMENT_CENTER
	items_row.add_theme_constant_override("separation", 40)
	cable_table_node.add_child(items_row)
	
	var crimp_rect = TextureRect.new()
	crimp_rect.texture = tex_crimping
	crimp_rect.custom_minimum_size = Vector2(110, 85)
	crimp_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crimp_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	items_row.add_child(crimp_rect)
	
	var roll_rect = TextureRect.new()
	roll_rect.texture = tex_cable_roll
	roll_rect.custom_minimum_size = Vector2(150, 88)
	roll_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	roll_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	items_row.add_child(roll_rect)
	
	table_prompt_bubble = Control.new()
	table_prompt_bubble.name = "TablePromptBubble"
	table_prompt_bubble.position = Vector2(270, -42)
	
	var bubble_p = PanelContainer.new()
	var sb_bubble = StyleBoxFlat.new()
	sb_bubble.bg_color = Color("#ffffff")
	sb_bubble.border_color = Color("#dc2626")
	sb_bubble.set_border_width_all(2)
	sb_bubble.set_corner_radius_all(14)
	sb_bubble.set_content_margin_all(6)
	sb_bubble.shadow_color = Color(0, 0, 0, 0.2)
	sb_bubble.shadow_size = 6
	bubble_p.add_theme_stylebox_override("panel", sb_bubble)
	table_prompt_bubble.add_child(bubble_p)
	
	var hb_b = HBoxContainer.new()
	hb_b.add_theme_constant_override("separation", 6)
	bubble_p.add_child(hb_b)
	
	var exc_lbl = Label.new()
	exc_lbl.text = "!"
	exc_lbl.add_theme_font_size_override("font_size", 16)
	hb_b.add_child(exc_lbl)
	
	var text_lbl = Label.new()
	text_lbl.text = "Urutkan Kabel"
	text_lbl.add_theme_font_override("font", font_black)
	text_lbl.add_theme_font_size_override("font_size", 15)
	text_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	hb_b.add_child(text_lbl)
	
	bubble_p.gui_input.connect(func(ev: InputEvent):
		if not is_game_active or crimping_modal.visible or guidebook_modal.visible:
			return
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			var table_center = cable_table_node.position + Vector2(230.0, 65.0)
			var char_center = char_pos + Vector2(128.0, 72.0)
			if table_center.distance_to(char_center) < 230.0:
				_open_crimping_modal()
	)
	_setup_hover_scale(bubble_p, 1.1)
	cable_table_node.add_child(table_prompt_bubble)

func _build_character() -> void:
	character_mascot.size = Vector2(256, 144)
	character_mascot.pivot_offset = Vector2(128, 72)
	char_sprite = TextureRect.new()
	char_sprite.name = "CharSprite"
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.custom_minimum_size = Vector2(256, 144)
	char_sprite.size = Vector2(256, 144)
	char_sprite.texture = tex_char_idle
	character_mascot.add_child(char_sprite)

func _build_header_ui() -> void:
	header_ui = Control.new()
	header_ui.name = "HeaderUI"
	header_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_ui)
	
	var back_btn = Button.new()
	back_btn.name = "BackBtn"
	back_btn.size = Vector2(64, 64)
	back_btn.custom_minimum_size = Vector2(64, 64)
	back_btn.pivot_offset = Vector2(32, 32)
	var sb_back = StyleBoxFlat.new()
	sb_back.bg_color = Color("#fed0cf")
	sb_back.border_color = Color("#4a2e2b")
	sb_back.set_border_width_all(3.5)
	sb_back.set_corner_radius_all(32)
	back_btn.add_theme_stylebox_override("normal", sb_back)
	var lbl_back = Label.new()
	lbl_back.text = "<"
	lbl_back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_back.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_back.add_theme_font_override("font", font_black)
	lbl_back.add_theme_font_size_override("font_size", 28)
	lbl_back.add_theme_color_override("font_color", Color("#4a2e2b"))
	lbl_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back_btn.add_child(lbl_back)
	back_btn.pressed.connect(_open_pause_modal)
	_setup_hover_scale(back_btn, 1.08)
	header_ui.add_child(back_btn)
	
	var hearts_panel = PanelContainer.new()
	hearts_panel.name = "HeartsPanel"
	hearts_panel.size = Vector2(196, 64)
	hearts_panel.custom_minimum_size = Vector2(196, 64)
	var sb_hp = StyleBoxFlat.new()
	sb_hp.bg_color = Color("#d3f4ee")
	sb_hp.border_color = Color("#4a2e2b")
	sb_hp.set_border_width_all(3.5)
	sb_hp.set_corner_radius_all(32)
	sb_hp.set_content_margin_all(8)
	hearts_panel.add_theme_stylebox_override("panel", sb_hp)
	header_ui.add_child(hearts_panel)
	
	var hb_h = HBoxContainer.new()
	hb_h.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_h.add_theme_constant_override("separation", 14)
	hearts_panel.add_child(hb_h)
	hearts_rects.clear()
	for i in range(3):
		var h_rect = TextureRect.new()
		h_rect.texture = tex_vector_heart
		h_rect.custom_minimum_size = Vector2(40, 36)
		h_rect.size = Vector2(40, 36)
		h_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb_h.add_child(h_rect)
		hearts_rects.append(h_rect)
		
	var lvl_panel = PanelContainer.new()
	lvl_panel.name = "LevelBadge"
	lvl_panel.size = Vector2(80, 64)
	lvl_panel.custom_minimum_size = Vector2(80, 64)
	var sb_lvl = StyleBoxFlat.new()
	sb_lvl.bg_color = Color("#ffffff")
	sb_lvl.border_color = Color("#4a2e2b")
	sb_lvl.set_border_width_all(3.5)
	sb_lvl.set_corner_radius_all(16)
	sb_lvl.set_content_margin_all(2)
	lvl_panel.add_theme_stylebox_override("panel", sb_lvl)
	header_ui.add_child(lvl_panel)
	
	var vb_lvl = VBoxContainer.new()
	vb_lvl.alignment = BoxContainer.ALIGNMENT_CENTER
	vb_lvl.add_theme_constant_override("separation", -4)
	lvl_panel.add_child(vb_lvl)
	
	var lbl_lvl_title = Label.new()
	lbl_lvl_title.text = "Level"
	lbl_lvl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_lvl_title.add_theme_font_override("font", font_bold)
	lbl_lvl_title.add_theme_font_size_override("font_size", 12)
	lbl_lvl_title.add_theme_color_override("font_color", Color("#78716c"))
	vb_lvl.add_child(lbl_lvl_title)
	
	var lbl_lvl_num = Label.new()
	lbl_lvl_num.text = "2"
	lbl_lvl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_lvl_num.add_theme_font_override("font", font_black)
	lbl_lvl_num.add_theme_font_size_override("font_size", 22)
	lbl_lvl_num.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb_lvl.add_child(lbl_lvl_num)
	
	var guide_top_btn = Button.new()
	guide_top_btn.name = "GuidebookTopBtn"
	guide_top_btn.size = Vector2(170, 64)
	guide_top_btn.custom_minimum_size = Vector2(170, 64)
	guide_top_btn.pivot_offset = Vector2(85, 32)
	var sb_gt = StyleBoxFlat.new()
	sb_gt.bg_color = Color("#ffffff")
	sb_gt.border_color = Color("#4a2e2b")
	sb_gt.set_border_width_all(3.5)
	sb_gt.set_corner_radius_all(32)
	guide_top_btn.add_theme_stylebox_override("normal", sb_gt)
	var text_g = Label.new()
	text_g.text = "Panduan Pin"
	text_g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_g.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_g.add_theme_font_override("font", font_black)
	text_g.add_theme_font_size_override("font_size", 15)
	text_g.add_theme_color_override("font_color", Color("#4a2e2b"))
	text_g.set_anchors_preset(Control.PRESET_FULL_RECT)
	guide_top_btn.add_child(text_g)
	guide_top_btn.pressed.connect(_open_guidebook_modal)
	_setup_hover_scale(guide_top_btn, 1.08)
	header_ui.add_child(guide_top_btn)
	
	var timer_panel = PanelContainer.new()
	timer_panel.name = "TimerPanel"
	timer_panel.size = Vector2(215, 64)
	timer_panel.custom_minimum_size = Vector2(215, 64)
	var sb_timer = StyleBoxFlat.new()
	sb_timer.bg_color = Color("#ffffff")
	sb_timer.border_color = Color("#4a2e2b")
	sb_timer.set_border_width_all(3.5)
	sb_timer.set_corner_radius_all(32)
	sb_timer.set_content_margin_all(8)
	timer_panel.add_theme_stylebox_override("panel", sb_timer)
	header_ui.add_child(timer_panel)
	
	var hb_timer = HBoxContainer.new()
	hb_timer.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_timer.add_theme_constant_override("separation", 10)
	timer_panel.add_child(hb_timer)
	
	var jam_icon = TextureRect.new()
	jam_icon.texture = tex_frame_jam
	jam_icon.custom_minimum_size = Vector2(36, 36)
	jam_icon.size = Vector2(36, 36)
	jam_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	jam_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb_timer.add_child(jam_icon)
	
	timer_label = Label.new()
	timer_label.text = "02:45"
	timer_label.add_theme_font_override("font", font_black)
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_label.add_theme_color_override("font_color", Color("#1e293b"))
	hb_timer.add_child(timer_label)
	
	var pause_btn = Button.new()
	pause_btn.name = "PauseBtn"
	pause_btn.size = Vector2(64, 64)
	pause_btn.custom_minimum_size = Vector2(64, 64)
	pause_btn.pivot_offset = Vector2(32, 32)
	var sb_pause = StyleBoxFlat.new()
	sb_pause.bg_color = Color("#ffffff")
	sb_pause.border_color = Color("#4a2e2b")
	sb_pause.set_border_width_all(3.5)
	sb_pause.set_corner_radius_all(16)
	pause_btn.add_theme_stylebox_override("normal", sb_pause)
	var lbl_menu = Label.new()
	lbl_menu.text = "\u2630"
	lbl_menu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_menu.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_menu.add_theme_font_override("font", font_black)
	lbl_menu.add_theme_font_size_override("font_size", 28)
	lbl_menu.add_theme_color_override("font_color", Color("#4a2e2b"))
	lbl_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_btn.add_child(lbl_menu)
	pause_btn.pressed.connect(_open_pause_modal)
	_setup_hover_scale(pause_btn, 1.08)
	header_ui.add_child(pause_btn)

func _update_hearts_display() -> void:
	for i in range(3):
		if i < hearts_rects.size():
			hearts_rects[i].visible = (i < hearts)

func _build_mobile_controls() -> void:
	joystick_zone = Control.new()
	joystick_zone.name = "JoystickZone"
	joystick_zone.position = Vector2(40, 480)
	joystick_zone.size = Vector2(180, 180)
	
	var dpad_base = TextureRect.new()
	dpad_base.texture = tex_dpad_base
	dpad_base.size = Vector2(140, 140)
	dpad_base.position = Vector2(20, 20)
	dpad_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dpad_base.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dpad_base.modulate = Color(1, 1, 1, 0.75)
	joystick_zone.add_child(dpad_base)
	
	dpad_knob_sprite = TextureRect.new()
	dpad_knob_sprite.texture = tex_dpad_knob
	dpad_knob_sprite.size = Vector2(60, 60)
	dpad_knob_sprite.position = Vector2(60, 60)
	dpad_knob_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dpad_knob_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	joystick_zone.add_child(dpad_knob_sprite)
	
	dpad_center = Vector2(90, 90)
	joystick_zone.gui_input.connect(_handle_joystick_input)
	add_child(joystick_zone)
	
	action_btn_node = TextureButton.new()
	action_btn_node.name = "ActionBtn"
	action_btn_node.texture_normal = tex_action_normal
	action_btn_node.texture_pressed = tex_action_pressed
	action_btn_node.custom_minimum_size = Vector2(110, 110)
	action_btn_node.size = Vector2(110, 110)
	action_btn_node.ignore_texture_size = true
	action_btn_node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	action_btn_node.pivot_offset = Vector2(55, 55)
	action_btn_node.pressed.connect(func():
		if not is_game_active or crimping_modal.visible or guidebook_modal.visible or pause_modal.visible or (settings_modal and settings_modal.visible):
			return
		var table_center = cable_table_node.position + Vector2(230.0, 65.0)
		var char_center = char_pos + Vector2(128.0, 72.0)
		var dist = table_center.distance_to(char_center)
		if dist < 230.0:
			_open_crimping_modal()
		else:
			show_toast("Dekati Meja Kerja untuk merakit urutan kabel!")
	)
	_setup_hover_scale(action_btn_node, 1.1)
	add_child(action_btn_node)

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

func _build_intro_modal() -> void:
	intro_modal = Control.new()
	intro_modal.name = "IntroModal"
	intro_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	intro_modal.visible = true
	add_child(intro_modal)
	
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.7)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	intro_modal.add_child(backdrop)
	
	intro_card = Control.new()
	intro_card.name = "IntroCard"
	intro_card.size = Vector2(580, 360)
	intro_card.pivot_offset = Vector2(290, 180)
	intro_modal.add_child(intro_card)
	
	var card = intro_card
	var bg_panel = PanelContainer.new()
	bg_panel.size = Vector2(580, 360)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fffbeb")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(26)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 6)
	bg_panel.add_theme_stylebox_override("panel", sb)
	card.add_child(bg_panel)
	
	var vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	bg_panel.add_child(vb)
	
	var top_pin_icon = Label.new()
	top_pin_icon.text = "\u2b55"
	top_pin_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_pin_icon.add_theme_font_size_override("font_size", 16)
	vb.add_child(top_pin_icon)
	
	var title = Label.new()
	title.text = "Level 1.2 Menyusun Pin Warna"
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
	desc.text = "Perakitan kabel sedang berlangsung dan waktu terus berjalan! Selesaikan tantangan ini dengan merakit urutan pin warna standar TIA/EIA 568A/B secara tepat sebelum batas waktu habis."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_override("font", font_bold)
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color("#78350f"))
	vb.add_child(desc)
	
	var btn_start = Button.new()
	btn_start.text = "MULAI"
	btn_start.custom_minimum_size = Vector2(160, 44)
	btn_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_start.add_theme_font_override("font", font_black)
	btn_start.add_theme_font_size_override("font_size", 15)
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color("#bbf7d0")
	sb_btn.border_color = Color("#4a2e2b")
	sb_btn.set_border_width_all(2.5)
	sb_btn.set_corner_radius_all(14)
	btn_start.add_theme_stylebox_override("normal", sb_btn)
	btn_start.add_theme_color_override("font_color", Color("#14532d"))
	btn_start.pressed.connect(_start_gameplay)
	_setup_hover_scale(btn_start, 1.1)
	vb.add_child(btn_start)
	
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
	av_img.texture = tex_char_idle
	av_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_badge.add_child(av_img)
	card.add_child(avatar_badge)

func _start_gameplay() -> void:
	intro_modal.visible = false
	is_game_active = true
	_play_sweep(523.25, 783.99, 0.1, 0.2)
	show_toast("Dekati Meja Kerja dan tekan 'Urutkan Kabel' untuk merakit kabel!")

# --- GUIDEBOOK MODAL (100% PERSIS FIGMA SCREEN 3) ---
func _build_guidebook_modal() -> void:
	guidebook_modal = Control.new()
	guidebook_modal.name = "GuidebookModal"
	guidebook_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	guidebook_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	guidebook_modal.visible = false
	guidebook_modal.z_as_relative = false
	guidebook_modal.z_index = 250
	add_child(guidebook_modal)
	
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.72)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			_close_guidebook_modal()
	)
	guidebook_modal.add_child(backdrop)
	
	guidebook_card = PanelContainer.new()
	guidebook_card.name = "GuidebookCard"
	guidebook_card.size = Vector2(820, 450)
	guidebook_card.pivot_offset = Vector2(410, 225)
	var sb_card = StyleBoxFlat.new()
	sb_card.bg_color = Color("#fffdf7")
	sb_card.border_color = Color("#4a2e2b")
	sb_card.set_border_width_all(3.5)
	sb_card.set_corner_radius_all(20)
	sb_card.shadow_color = Color(0, 0, 0, 0.35)
	sb_card.shadow_size = 14
	sb_card.shadow_offset = Vector2(0, 6)
	guidebook_card.add_theme_stylebox_override("panel", sb_card)
	guidebook_modal.add_child(guidebook_card)
	
	var vb_main = VBoxContainer.new()
	vb_main.add_theme_constant_override("separation", 0)
	guidebook_card.add_child(vb_main)
	
	# Header
	var header_panel = PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(813, 52)
	var sb_hdr = StyleBoxFlat.new()
	sb_hdr.bg_color = Color("#e8daf8")
	sb_hdr.border_color = Color("#4a2e2b")
	sb_hdr.border_width_bottom = 3
	sb_hdr.corner_radius_top_left = 17
	sb_hdr.corner_radius_top_right = 17
	header_panel.add_theme_stylebox_override("panel", sb_hdr)
	vb_main.add_child(header_panel)
	
	var h_box_hdr = Control.new()
	h_box_hdr.custom_minimum_size = Vector2(813, 52)
	header_panel.add_child(h_box_hdr)
	
	var title_lbl = Label.new()
	title_lbl.text = "PANDUAN SUSUNAN PIN RJ45 (TIA/EIA 568A/B)"
	title_lbl.size = Vector2(813, 52)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", font_black)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	h_box_hdr.add_child(title_lbl)
	
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.position = Vector2(813 - 48, 7)
	close_btn.size = Vector2(38, 38)
	close_btn.custom_minimum_size = Vector2(38, 38)
	close_btn.pivot_offset = Vector2(19, 19)
	var sb_close = StyleBoxFlat.new()
	sb_close.bg_color = Color("#fddede")
	sb_close.border_color = Color("#4a2e2b")
	sb_close.set_border_width_all(2.5)
	sb_close.set_corner_radius_all(19)
	close_btn.add_theme_stylebox_override("normal", sb_close)
	close_btn.add_theme_font_override("font", font_black)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	close_btn.pressed.connect(_close_guidebook_modal)
	_setup_hover_scale(close_btn, 1.15)
	h_box_hdr.add_child(close_btn)
	
	# Tabs Row (Straight vs Cross)
	var tab_margin = MarginContainer.new()
	tab_margin.add_theme_constant_override("margin_left", 20)
	tab_margin.add_theme_constant_override("margin_top", 10)
	tab_margin.add_theme_constant_override("margin_right", 20)
	tab_margin.add_theme_constant_override("margin_bottom", 6)
	vb_main.add_child(tab_margin)
	
	var tab_hb = HBoxContainer.new()
	tab_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hb.add_theme_constant_override("separation", 16)
	tab_margin.add_child(tab_hb)
	
	var btn_tab_straight = Button.new()
	btn_tab_straight.text = "KABEL STRAIGHT (T568B) - LEVEL INI"
	btn_tab_straight.custom_minimum_size = Vector2(340, 38)
	btn_tab_straight.add_theme_font_override("font", font_black)
	btn_tab_straight.add_theme_font_size_override("font_size", 14)
	
	var btn_tab_cross = Button.new()
	btn_tab_cross.text = "KABEL CROSS (T568A / T568B)"
	btn_tab_cross.custom_minimum_size = Vector2(300, 38)
	btn_tab_cross.add_theme_font_override("font", font_black)
	btn_tab_cross.add_theme_font_size_override("font_size", 14)
	
	var sb_tab_act = StyleBoxFlat.new()
	sb_tab_act.bg_color = Color("#dcfce7")
	sb_tab_act.border_color = Color("#16a34a")
	sb_tab_act.set_border_width_all(2.5)
	sb_tab_act.set_corner_radius_all(10)
	
	var sb_tab_inact = StyleBoxFlat.new()
	sb_tab_inact.bg_color = Color("#f1f5f9")
	sb_tab_inact.border_color = Color("#cbd5e1")
	sb_tab_inact.set_border_width_all(2)
	sb_tab_inact.set_corner_radius_all(10)
	
	btn_tab_straight.add_theme_stylebox_override("normal", sb_tab_act)
	btn_tab_straight.add_theme_color_override("font_color", Color("#15803d"))
	btn_tab_cross.add_theme_stylebox_override("normal", sb_tab_inact)
	btn_tab_cross.add_theme_color_override("font_color", Color("#64748b"))
	
	tab_hb.add_child(btn_tab_straight)
	tab_hb.add_child(btn_tab_cross)
	
	# Content Area
	var content_margin = MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_top", 6)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_bottom", 16)
	vb_main.add_child(content_margin)
	
	var dashed_box = Control.new()
	dashed_box.custom_minimum_size = Vector2(768, 280)
	dashed_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashed_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dashed_box.draw.connect(func():
		var w = dashed_box.size.x
		var h = dashed_box.size.y
		var col = Color("#baa89d")
		var lw = 3.0
		var dash = 10.0
		var pad = 4.0
		dashed_box.draw_dashed_line(Vector2(pad + 12, pad), Vector2(w - pad - 12, pad), col, lw, dash)
		dashed_box.draw_dashed_line(Vector2(w - pad, pad + 12), Vector2(w - pad, h - pad - 12), col, lw, dash)
		dashed_box.draw_dashed_line(Vector2(w - pad - 12, h - pad), Vector2(pad + 12, h - pad), col, lw, dash)
		dashed_box.draw_dashed_line(Vector2(pad, h - pad - 12), Vector2(pad, pad + 12), col, lw, dash)
	)
	content_margin.add_child(dashed_box)
	
	var hb_content = HBoxContainer.new()
	hb_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb_content.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_content.add_theme_constant_override("separation", 24)
	dashed_box.add_child(hb_content)
	
	var lbl_a = Label.new()
	lbl_a.text = "568B"
	lbl_a.custom_minimum_size = Vector2(90, 0)
	lbl_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_a.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_a.add_theme_font_override("font", font_black)
	lbl_a.add_theme_font_size_override("font_size", 22)
	lbl_a.add_theme_color_override("font_color", Color("#15803d"))
	hb_content.add_child(lbl_a)
	
	var diagram_rect = TextureRect.new()
	diagram_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	diagram_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	diagram_rect.custom_minimum_size = Vector2(500, 250)
	diagram_rect.texture = tex_diagram_straight
	hb_content.add_child(diagram_rect)
	
	var lbl_b = Label.new()
	lbl_b.text = "568B"
	lbl_b.custom_minimum_size = Vector2(90, 0)
	lbl_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_b.add_theme_font_override("font", font_black)
	lbl_b.add_theme_font_size_override("font_size", 22)
	lbl_b.add_theme_color_override("font_color", Color("#15803d"))
	hb_content.add_child(lbl_b)
	
	btn_tab_straight.pressed.connect(func():
		diagram_rect.texture = tex_diagram_straight
		lbl_a.text = "568B"
		lbl_b.text = "568B"
		lbl_a.add_theme_color_override("font_color", Color("#15803d"))
		lbl_b.add_theme_color_override("font_color", Color("#15803d"))
		btn_tab_straight.add_theme_stylebox_override("normal", sb_tab_act)
		btn_tab_straight.add_theme_color_override("font_color", Color("#15803d"))
		btn_tab_cross.add_theme_stylebox_override("normal", sb_tab_inact)
		btn_tab_cross.add_theme_color_override("font_color", Color("#64748b"))
	)
	
	btn_tab_cross.pressed.connect(func():
		diagram_rect.texture = tex_diagram_cross
		lbl_a.text = "568A"
		lbl_b.text = "568B"
		lbl_a.add_theme_color_override("font_color", Color("#4a2e2b"))
		lbl_b.add_theme_color_override("font_color", Color("#4a2e2b"))
		btn_tab_cross.add_theme_stylebox_override("normal", sb_tab_act)
		btn_tab_cross.add_theme_color_override("font_color", Color("#15803d"))
		btn_tab_straight.add_theme_stylebox_override("normal", sb_tab_inact)
		btn_tab_straight.add_theme_color_override("font_color", Color("#64748b"))
	)

func _open_guidebook_modal() -> void:
	_play_sweep(523.25, 783.99, 0.1, 0.15)
	guidebook_modal.move_to_front()
	guidebook_modal.visible = true
	if guidebook_card:
		var vp_sz = get_viewport_rect().size
		guidebook_card.position = Vector2((vp_sz.x - guidebook_card.size.x) / 2.0, (vp_sz.y - guidebook_card.size.y) / 2.0)
		guidebook_card.scale = Vector2(0.85, 0.85)
		guidebook_card.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(guidebook_card, "scale", Vector2.ONE, 0.22)
		tw.tween_property(guidebook_card, "modulate:a", 1.0, 0.18)

func _close_guidebook_modal() -> void:
	_play_sweep(659.25, 440.0, 0.1, 0.15)
	if guidebook_card:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(guidebook_card, "scale", Vector2(0.85, 0.85), 0.12)
		tw.tween_property(guidebook_card, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func(): guidebook_modal.visible = false)
	else:
		guidebook_modal.visible = false

# --- MINIGAME SUSUN PIN RJ45 (KABEL STRAIGHT T568B) ---
func _build_crimping_modal() -> void:
	crimping_modal = Control.new()
	crimping_modal.name = "CrimpingModal"
	crimping_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	crimping_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	crimping_modal.visible = false
	add_child(crimping_modal)
	
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.72)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	crimping_modal.add_child(backdrop)
	
	crimping_card = Control.new()
	crimping_card.name = "CrimpingCard"
	crimping_card.size = Vector2(920, 520)
	crimping_card.pivot_offset = Vector2(460, 260)
	crimping_modal.add_child(crimping_card)
	
	var bg_panel = PanelContainer.new()
	bg_panel.name = "CardBg"
	bg_panel.size = Vector2(920, 520)
	var sb_c = StyleBoxFlat.new()
	sb_c.bg_color = Color("#fffdf7")
	sb_c.border_color = Color("#4a2e2b")
	sb_c.set_border_width_all(3.5)
	sb_c.set_corner_radius_all(20)
	sb_c.shadow_color = Color(0, 0, 0, 0.35)
	sb_c.shadow_size = 14
	sb_c.shadow_offset = Vector2(0, 6)
	bg_panel.add_theme_stylebox_override("panel", sb_c)
	crimping_card.add_child(bg_panel)
	
	var vb_all = VBoxContainer.new()
	vb_all.add_theme_constant_override("separation", 0)
	bg_panel.add_child(vb_all)
	
	var hdr = PanelContainer.new()
	hdr.custom_minimum_size = Vector2(914, 46)
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color("#e8daf8")
	sb_h.border_color = Color("#4a2e2b")
	sb_h.border_width_bottom = 3
	sb_h.corner_radius_top_left = 17
	sb_h.corner_radius_top_right = 17
	hdr.add_theme_stylebox_override("panel", sb_h)
	vb_all.add_child(hdr)
	
	var c_hdr = Control.new()
	c_hdr.custom_minimum_size = Vector2(914, 46)
	hdr.add_child(c_hdr)
	
	var t_lbl = Label.new()
	t_lbl.text = "MERAKIT PIN KABEL STRAIGHT (STANDAR T568B)"
	t_lbl.size = Vector2(914, 46)
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t_lbl.add_theme_font_override("font", font_black)
	t_lbl.add_theme_font_size_override("font_size", 18)
	t_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	c_hdr.add_child(t_lbl)
	
	var c_btn = Button.new()
	c_btn.text = "✕"
	c_btn.position = Vector2(914 - 48, 4)
	c_btn.size = Vector2(38, 38)
	c_btn.custom_minimum_size = Vector2(38, 38)
	c_btn.pivot_offset = Vector2(19, 19)
	var sb_cls = StyleBoxFlat.new()
	sb_cls.bg_color = Color("#fddede")
	sb_cls.border_color = Color("#4a2e2b")
	sb_cls.set_border_width_all(2.5)
	sb_cls.set_corner_radius_all(19)
	c_btn.add_theme_stylebox_override("normal", sb_cls)
	c_btn.add_theme_font_override("font", font_black)
	c_btn.add_theme_font_size_override("font_size", 16)
	c_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	c_btn.pressed.connect(_close_crimping_modal)
	_setup_hover_scale(c_btn, 1.15)
	c_hdr.add_child(c_btn)
	
	var body_margin = MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 20)
	body_margin.add_theme_constant_override("margin_top", 12)
	body_margin.add_theme_constant_override("margin_right", 20)
	body_margin.add_theme_constant_override("margin_bottom", 12)
	vb_all.add_child(body_margin)
	
	var hb_body = HBoxContainer.new()
	hb_body.add_theme_constant_override("separation", 22)
	body_margin.add_child(hb_body)
	
	# LEFT COLUMN: RJ45 CONNECTOR
	var left_col = VBoxContainer.new()
	left_col.alignment = BoxContainer.ALIGNMENT_CENTER
	left_col.add_theme_constant_override("separation", 6)
	hb_body.add_child(left_col)
	
	var rj_label = Label.new()
	rj_label.text = "KONEKTOR RJ45"
	rj_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rj_label.add_theme_font_override("font", font_black)
	rj_label.add_theme_font_size_override("font_size", 16)
	rj_label.add_theme_color_override("font_color", Color("#334155"))
	left_col.add_child(rj_label)
	
	var rj_widget = Control.new()
	rj_widget.custom_minimum_size = Vector2(280, 390)
	rj_widget.size = Vector2(280, 390)
	left_col.add_child(rj_widget)
	
	var NATIVE_X = [47.0, 102.0, 157.0, 211.0, 264.0, 320.0, 374.0, 428.0]
	var scale_f = 280.0 / 502.0
	
	rj45_channel_controls.clear()
	rj45_wire_sprites.clear()
	rj45_pin_badges.clear()
	
	var channels_layer = Control.new()
	channels_layer.size = Vector2(280, 390)
	rj_widget.add_child(channels_layer)
	
	for i in range(8):
		var ch_x = NATIVE_X[i] * scale_f
		var ch_w = 15.0
		var ch_y = 108.0
		var ch_h = 224.0
		
		var ch_ctrl = Control.new()
		ch_ctrl.name = "RJChannel_%d" % i
		ch_ctrl.position = Vector2(ch_x, ch_y)
		ch_ctrl.size = Vector2(ch_w, ch_h)
		channels_layer.add_child(ch_ctrl)
		rj45_channel_controls.append(ch_ctrl)
		
		var empty_bg = Panel.new()
		empty_bg.size = Vector2(ch_w, ch_h)
		var sb_empty = StyleBoxFlat.new()
		sb_empty.bg_color = Color(0.9, 0.92, 0.95, 0.5)
		sb_empty.border_color = Color(0.75, 0.8, 0.88, 0.8)
		sb_empty.set_border_width_all(1)
		empty_bg.add_theme_stylebox_override("panel", sb_empty)
		ch_ctrl.add_child(empty_bg)
		
		var wire_tex_rect = TextureRect.new()
		wire_tex_rect.name = "WireTex"
		wire_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wire_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		wire_tex_rect.size = Vector2(ch_w, ch_h)
		wire_tex_rect.visible = false
		ch_ctrl.add_child(wire_tex_rect)
		rj45_wire_sprites.append(wire_tex_rect)
		
		var slot_idx = i
		ch_ctrl.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton:
				var mb = ev as InputEventMouseButton
				if mb.button_index == MOUSE_BUTTON_LEFT:
					if mb.pressed and pin_slots[slot_idx] != null:
						_start_wire_drag(pin_slots[slot_idx], slot_idx, mb.global_position)
					elif not mb.pressed:
						_end_wire_drag(mb.global_position)
			elif ev is InputEventMouseMotion:
				_process_wire_drag((ev as InputEventMouseMotion).global_position)
			elif ev is InputEventScreenTouch:
				var st = ev as InputEventScreenTouch
				if st.pressed and pin_slots[slot_idx] != null:
					_start_wire_drag(pin_slots[slot_idx], slot_idx, st.position)
				elif not st.pressed:
					_end_wire_drag(st.position)
			elif ev is InputEventScreenDrag:
				_process_wire_drag((ev as InputEventScreenDrag).position)
		)
	
	var housing_rect = TextureRect.new()
	housing_rect.texture = tex_rj45_housing
	housing_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	housing_rect.stretch_mode = TextureRect.STRETCH_SCALE
	housing_rect.size = Vector2(280, 308)
	housing_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rj_widget.add_child(housing_rect)
	
	var badges_container = Control.new()
	badges_container.position = Vector2(0, 340)
	badges_container.size = Vector2(280, 32)
	rj_widget.add_child(badges_container)
	
	for i in range(8):
		var ch_x = NATIVE_X[i] * scale_f
		var badge = PanelContainer.new()
		badge.position = Vector2(ch_x - 3, 0)
		badge.custom_minimum_size = Vector2(21, 24)
		badge.size = Vector2(21, 24)
		var sb_b = StyleBoxFlat.new()
		sb_b.bg_color = Color("#e2e8f0")
		sb_b.border_color = Color("#94a3b8")
		sb_b.set_border_width_all(1.5)
		sb_b.set_corner_radius_all(6)
		badge.add_theme_stylebox_override("panel", sb_b)
		
		var b_lbl = Label.new()
		b_lbl.name = "BadgeLabel"
		b_lbl.text = str(i + 1)
		b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b_lbl.add_theme_font_override("font", font_black)
		b_lbl.add_theme_font_size_override("font_size", 13)
		b_lbl.add_theme_color_override("font_color", Color("#475569"))
		badge.add_child(b_lbl)
		
		badges_container.add_child(badge)
		rj45_pin_badges.append(badge)
		
		var s_idx = i
		badge.gui_input.connect(func(ev: InputEvent):
			if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
				_on_slot_clicked(s_idx)
		)
	
	# RIGHT COLUMN: WIRE SELECTION & CONTROLS
	var right_col = VBoxContainer.new()
	right_col.custom_minimum_size = Vector2(550, 420)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 10)
	hb_body.add_child(right_col)
	
	var info_box = PanelContainer.new()
	var sb_info = StyleBoxFlat.new()
	sb_info.bg_color = Color("#f8fafc")
	sb_info.border_color = Color("#cbd5e1")
	sb_info.set_border_width_all(1.5)
	sb_info.set_corner_radius_all(12)
	sb_info.set_content_margin_all(10)
	info_box.add_theme_stylebox_override("panel", sb_info)
	right_col.add_child(info_box)
	
	var vb_info = VBoxContainer.new()
	vb_info.add_theme_constant_override("separation", 3)
	info_box.add_child(vb_info)
	
	var hb_std = HBoxContainer.new()
	hb_std.add_theme_constant_override("separation", 8)
	vb_info.add_child(hb_std)
	
	var title_sec = Label.new()
	title_sec.text = "PILIH & SUSUN PIN RJ45"
	title_sec.add_theme_font_override("font", font_black)
	title_sec.add_theme_font_size_override("font_size", 17)
	title_sec.add_theme_color_override("font_color", Color("#1e293b"))
	hb_std.add_child(title_sec)
	
	var std_pill = PanelContainer.new()
	var sb_sp = StyleBoxFlat.new()
	sb_sp.bg_color = Color("#dcfce7")
	sb_sp.border_color = Color("#16a34a")
	sb_sp.set_border_width_all(1.5)
	sb_sp.set_corner_radius_all(8)
	sb_sp.content_margin_left = 8.0
	sb_sp.content_margin_right = 8.0
	sb_sp.content_margin_top = 3.0
	sb_sp.content_margin_bottom = 3.0
	std_pill.add_theme_stylebox_override("panel", sb_sp)
	var sp_lbl = Label.new()
	sp_lbl.text = "STANDAR T568B"
	sp_lbl.add_theme_font_override("font", font_black)
	sp_lbl.add_theme_font_size_override("font_size", 12)
	sp_lbl.add_theme_color_override("font_color", Color("#15803d"))
	std_pill.add_child(sp_lbl)
	hb_std.add_child(std_pill)
	
	var sub_info = Label.new()
	sub_info.text = "Ketuk kabel warna untuk memasukkan ke pin RJ45 berikutnya secara berurutan, atau seret langsung ke slot konektor di sebelah kiri."
	sub_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_info.add_theme_font_override("font", font_semibold)
	sub_info.add_theme_font_size_override("font_size", 13)
	sub_info.add_theme_color_override("font_color", Color("#64748b"))
	vb_info.add_child(sub_info)
	
	var grid_scroll = PanelContainer.new()
	var sb_grid_bg = StyleBoxFlat.new()
	sb_grid_bg.bg_color = Color.TRANSPARENT
	grid_scroll.add_theme_stylebox_override("panel", sb_grid_bg)
	right_col.add_child(grid_scroll)
	
	grid_wires_container = GridContainer.new()
	grid_wires_container.columns = 4
	grid_wires_container.add_theme_constant_override("h_separation", 10)
	grid_wires_container.add_theme_constant_override("v_separation", 10)
	grid_scroll.add_child(grid_wires_container)
	
	_populate_tray_wires(true)
	
	var footer_row = HBoxContainer.new()
	footer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_row.add_theme_constant_override("separation", 16)
	right_col.add_child(footer_row)
	
	var btn_reset = Button.new()
	btn_reset.text = "RESET"
	btn_reset.custom_minimum_size = Vector2(124, 48)
	btn_reset.add_theme_font_override("font", font_black)
	btn_reset.add_theme_font_size_override("font_size", 16)
	var sb_rst = StyleBoxFlat.new()
	sb_rst.bg_color = Color("#fee2e2")
	sb_rst.border_color = Color("#ef4444")
	sb_rst.set_border_width_all(2.5)
	sb_rst.set_corner_radius_all(12)
	btn_reset.add_theme_stylebox_override("normal", sb_rst)
	btn_reset.add_theme_color_override("font_color", Color("#991b1b"))
	btn_reset.pressed.connect(_reset_minigame_slots)
	_setup_hover_scale(btn_reset, 1.08)
	footer_row.add_child(btn_reset)
	
	var btn_guide_mini = Button.new()
	btn_guide_mini.text = "LIHAT PANDUAN"
	btn_guide_mini.custom_minimum_size = Vector2(165, 48)
	btn_guide_mini.add_theme_font_override("font", font_black)
	btn_guide_mini.add_theme_font_size_override("font_size", 16)
	var sb_gm = StyleBoxFlat.new()
	sb_gm.bg_color = Color("#f5f3ff")
	sb_gm.border_color = Color("#7c3aed")
	sb_gm.set_border_width_all(2.5)
	sb_gm.set_corner_radius_all(12)
	btn_guide_mini.add_theme_stylebox_override("normal", sb_gm)
	btn_guide_mini.add_theme_color_override("font_color", Color("#5b21b6"))
	btn_guide_mini.pressed.connect(_open_guidebook_modal)
	_setup_hover_scale(btn_guide_mini, 1.08)
	footer_row.add_child(btn_guide_mini)
	
	var btn_submit = Button.new()
	btn_submit.text = "KRIMPING KABEL"
	btn_submit.custom_minimum_size = Vector2(200, 48)
	btn_submit.add_theme_font_override("font", font_black)
	btn_submit.add_theme_font_size_override("font_size", 16)
	var sb_sub = StyleBoxFlat.new()
	sb_sub.bg_color = Color("#16a34a")
	sb_sub.border_color = Color("#14532d")
	sb_sub.set_border_width_all(2.5)
	sb_sub.set_corner_radius_all(12)
	btn_submit.add_theme_stylebox_override("normal", sb_sub)
	btn_submit.add_theme_color_override("font_color", Color("#ffffff"))
	btn_submit.pressed.connect(_validate_crimping_submission)
	_setup_hover_scale(btn_submit, 1.1)
	footer_row.add_child(btn_submit)
	
	_refresh_rj45_display()

func _refresh_rj45_display() -> void:
	for i in range(8):
		var wire = pin_slots[i]
		if i < rj45_wire_sprites.size():
			var wire_tex_rect = rj45_wire_sprites[i]
			if wire != null:
				wire_tex_rect.texture = wire["tex"]
				wire_tex_rect.visible = true
			else:
				wire_tex_rect.visible = false
				
		if i < rj45_pin_badges.size():
			var badge = rj45_pin_badges[i]
			var badge_lbl = badge.get_node_or_null("BadgeLabel") as Label
			if wire != null:
				var sb_act = StyleBoxFlat.new()
				sb_act.bg_color = Color("#16a34a")
				sb_act.border_color = Color("#14532d")
				sb_act.set_border_width_all(1.5)
				sb_act.set_corner_radius_all(6)
				badge.add_theme_stylebox_override("panel", sb_act)
				if badge_lbl:
					badge_lbl.add_theme_color_override("font_color", Color.WHITE)
			else:
				var sb_emp = StyleBoxFlat.new()
				sb_emp.bg_color = Color("#e2e8f0")
				sb_emp.border_color = Color("#94a3b8")
				sb_emp.set_border_width_all(1.5)
				sb_emp.set_corner_radius_all(6)
				badge.add_theme_stylebox_override("panel", sb_emp)
				if badge_lbl:
					badge_lbl.add_theme_color_override("font_color", Color("#475569"))
					
	for card in tray_card_nodes:
		if not is_instance_valid(card) or not card.has_meta("wire_data"):
			continue
		var wire_def = card.get_meta("wire_data")
		var is_assigned = false
		for p in pin_slots:
			if p != null and p["id"] == wire_def["id"]:
				is_assigned = true
				break
				
		var name_l = card.get_node_or_null("VBoxContainer/WireName") as Label
		if is_assigned:
			card.modulate.a = 0.35
			if name_l:
				name_l.text = wire_def["name"] + " ✓"
				name_l.add_theme_color_override("font_color", Color("#16a34a"))
		else:
			card.modulate.a = 1.0
			if name_l:
				name_l.text = wire_def["name"]
				name_l.add_theme_color_override("font_color", Color("#1e293b"))

func _populate_tray_wires(shuffle_list: bool = true) -> void:
	if not grid_wires_container:
		return
	for ch in grid_wires_container.get_children():
		ch.queue_free()
	tray_card_nodes.clear()
	
	var wires_list = all_wires_def.duplicate()
	if shuffle_list:
		wires_list.shuffle()
		
	for i in range(wires_list.size()):
		var wire = wires_list[i]
		var wire_card = PanelContainer.new()
		wire_card.name = "TrayCard_%s" % wire["id"]
		wire_card.custom_minimum_size = Vector2(130, 98)
		wire_card.pivot_offset = Vector2(65, 49)
		wire_card.set_meta("wire_data", wire)
		var sb_w = StyleBoxFlat.new()
		sb_w.bg_color = Color("#ffffff")
		sb_w.border_color = Color("#cbd5e1")
		sb_w.set_border_width_all(2.5)
		sb_w.set_corner_radius_all(12)
		sb_w.set_content_margin_all(6)
		sb_w.shadow_color = Color(0, 0, 0, 0.08)
		sb_w.shadow_size = 4
		sb_w.shadow_offset = Vector2(0, 2)
		wire_card.add_theme_stylebox_override("panel", sb_w)
		
		var vb_card = VBoxContainer.new()
		vb_card.name = "VBoxContainer"
		vb_card.alignment = BoxContainer.ALIGNMENT_CENTER
		vb_card.add_theme_constant_override("separation", 5)
		wire_card.add_child(vb_card)
		
		var wire_tex = TextureRect.new()
		wire_tex.texture = wire["tex"]
		wire_tex.custom_minimum_size = Vector2(18, 54)
		wire_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wire_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vb_card.add_child(wire_tex)
		
		var name_l = Label.new()
		name_l.name = "WireName"
		name_l.text = wire["name"]
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.add_theme_font_override("font", font_black)
		name_l.add_theme_font_size_override("font_size", 13)
		name_l.add_theme_color_override("font_color", Color("#1e293b"))
		vb_card.add_child(name_l)
		
		var wire_data = wire
		wire_card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton:
				var mb = ev as InputEventMouseButton
				if mb.button_index == MOUSE_BUTTON_LEFT:
					if mb.pressed:
						_start_wire_drag(wire_data, -1, mb.global_position)
					else:
						_end_wire_drag(mb.global_position)
			elif ev is InputEventMouseMotion:
				_process_wire_drag((ev as InputEventMouseMotion).global_position)
			elif ev is InputEventScreenTouch:
				var st = ev as InputEventScreenTouch
				if st.pressed:
					_start_wire_drag(wire_data, -1, st.position)
				else:
					_end_wire_drag(st.position)
			elif ev is InputEventScreenDrag:
				_process_wire_drag((ev as InputEventScreenDrag).position)
		)
		_setup_hover_scale(wire_card, 1.08)
		grid_wires_container.add_child(wire_card)
		tray_card_nodes.append(wire_card)

var is_dragging: bool = false
var dragged_wire: Dictionary = {}
var drag_from_slot_idx: int = -1
var drag_start_global: Vector2 = Vector2.ZERO

func _init_drag_ghost() -> void:
	if not drag_ghost:
		drag_ghost = Control.new()
		drag_ghost.name = "DragGhost"
		drag_ghost.size = Vector2(24, 80)
		drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		drag_ghost.visible = false
		drag_ghost.z_index = 50
		crimping_modal.add_child(drag_ghost)

func _update_drag_ghost_visual(wire: Dictionary) -> void:
	_init_drag_ghost()
	for ch in drag_ghost.get_children():
		ch.queue_free()
	var tr = TextureRect.new()
	tr.texture = wire["tex"]
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = Vector2(22, 80)
	drag_ghost.add_child(tr)

func _start_wire_drag(wire: Dictionary, from_slot: int, global_pos: Vector2) -> void:
	dragged_wire = wire
	drag_from_slot_idx = from_slot
	drag_start_global = global_pos
	is_dragging = false

func _process_wire_drag(global_pos: Vector2) -> void:
	if dragged_wire.is_empty():
		return
	if not is_dragging and global_pos.distance_to(drag_start_global) > 10.0:
		is_dragging = true
		_update_drag_ghost_visual(dragged_wire)
		drag_ghost.visible = true
		_play_tone(523.25, 0.05, 0.12)
		
	if is_dragging and drag_ghost:
		drag_ghost.global_position = global_pos - Vector2(11, 40)

func _end_wire_drag(global_pos: Vector2) -> void:
	if dragged_wire.is_empty():
		return
		
	if drag_ghost:
		drag_ghost.visible = false
		
	if is_dragging:
		var target_slot_idx = -1
		for i in range(rj45_channel_controls.size()):
			var ch_ctrl = rj45_channel_controls[i]
			var rect = ch_ctrl.get_global_rect()
			rect = rect.grow_individual(6.0, 10.0, 6.0, 20.0)
			if rect.has_point(global_pos):
				target_slot_idx = i
				break
				
		if target_slot_idx != -1:
			for p in range(8):
				if pin_slots[p] != null and pin_slots[p]["id"] == dragged_wire["id"]:
					pin_slots[p] = null
					
			pin_slots[target_slot_idx] = dragged_wire
			_play_tone(587.33 + target_slot_idx * 40.0, 0.08)
		else:
			if drag_from_slot_idx != -1:
				pin_slots[drag_from_slot_idx] = null
				_play_tone(392.0, 0.08)
				
		_refresh_rj45_display()
	else:
		if drag_from_slot_idx != -1:
			_on_slot_clicked(drag_from_slot_idx)
		else:
			_on_tray_wire_clicked(dragged_wire)
			
	dragged_wire = {}
	drag_from_slot_idx = -1
	is_dragging = false

func _on_tray_wire_clicked(wire_data: Dictionary) -> void:
	for i in range(8):
		if pin_slots[i] != null and pin_slots[i]["id"] == wire_data["id"]:
			pin_slots[i] = null
			_play_tone(392.0, 0.08)
			_refresh_rj45_display()
			return
			
	for i in range(8):
		if pin_slots[i] == null:
			pin_slots[i] = wire_data
			_play_tone(587.33 + i * 40.0, 0.08)
			_refresh_rj45_display()
			return
			
	show_toast("Semua 8 pin konektor sudah terisi! Ketuk pin untuk melepasnya.")

func _on_slot_clicked(slot_idx: int) -> void:
	if pin_slots[slot_idx] != null:
		pin_slots[slot_idx] = null
		_play_tone(440.0, 0.08)
		_refresh_rj45_display()

func _reset_minigame_slots() -> void:
	_play_sweep(659.25, 330.0, 0.1, 0.15)
	for i in range(8):
		pin_slots[i] = null
	_populate_tray_wires(true)
	_refresh_rj45_display()

func _validate_crimping_submission() -> void:
	for i in range(8):
		if pin_slots[i] == null:
			_play_tone(220.0, 0.2)
			show_toast("Pin %d masih kosong! Pasang semua 8 kabel ke konektor RJ45." % (i + 1))
			return
			
	var is_correct = true
	var wrong_indices: Array[int] = []
	for i in range(8):
		if pin_slots[i]["id"] != TARGET_SEQUENCE[i]:
			is_correct = false
			wrong_indices.append(i)
			
	if is_correct:
		_play_sweep(440.0, 880.0, 0.15, 0.25)
		_close_crimping_modal()
		if PlayerData:
			PlayerData.set_level_stars(1, 2, hearts)
		_trigger_win()
	else:
		hearts -= 1
		_update_hearts_display()
		_play_tone(180.0, 0.25, 0.3)
		
		if crimping_card:
			var orig_pos = crimping_card.position
			var tw = create_tween()
			tw.tween_property(crimping_card, "position:x", orig_pos.x - 12, 0.05)
			tw.tween_property(crimping_card, "position:x", orig_pos.x + 12, 0.05)
			tw.tween_property(crimping_card, "position:x", orig_pos.x - 6, 0.05)
			tw.tween_property(crimping_card, "position:x", orig_pos.x, 0.05)
			
		if hearts > 0:
			show_toast("Urutan kabel tidak sesuai standar T568B! Cek Buku Panduan.")
		else:
			_close_crimping_modal()
			_trigger_game_over("Nyawa teknisi habis! Urutan kabel salah 3 kali.")

func _open_crimping_modal() -> void:
	if guidebook_modal and guidebook_modal.visible:
		guidebook_modal.visible = false
	_play_sweep(523.25, 783.99, 0.1, 0.15)
	crimping_modal.visible = true
	var all_empty = true
	for p in pin_slots:
		if p != null:
			all_empty = false
			break
	if all_empty:
		_populate_tray_wires(true)
	_refresh_rj45_display()
	if crimping_card:
		var vp_sz = get_viewport_rect().size
		crimping_card.position = Vector2((vp_sz.x - crimping_card.size.x) / 2.0, (vp_sz.y - crimping_card.size.y) / 2.0)
		crimping_card.scale = Vector2(0.85, 0.85)
		crimping_card.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(crimping_card, "scale", Vector2.ONE, 0.22)
		tw.tween_property(crimping_card, "modulate:a", 1.0, 0.18)

func _close_crimping_modal() -> void:
	_play_sweep(659.25, 440.0, 0.1, 0.15)
	if crimping_card:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(crimping_card, "scale", Vector2(0.85, 0.85), 0.12)
		tw.tween_property(crimping_card, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func(): crimping_modal.visible = false)
	else:
		crimping_modal.visible = false

# --- PAUSE MODAL ---
func _build_pause_modal() -> void:
	pause_modal = Control.new()
	pause_modal.name = "PauseModal"
	pause_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_modal.visible = false
	pause_modal.z_index = 200
	add_child(pause_modal)
	
	var bd_p = ColorRect.new()
	bd_p.set_anchors_preset(Control.PRESET_FULL_RECT)
	bd_p.color = Color(0, 0, 0, 0.65)
	bd_p.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			_close_pause_modal()
	)
	pause_modal.add_child(bd_p)
	
	pause_card = Control.new()
	pause_card.name = "PauseCard"
	pause_card.size = Vector2(380, 420)
	pause_card.pivot_offset = Vector2(190, 210)
	pause_modal.add_child(pause_card)
	
	var bg_p = PanelContainer.new()
	bg_p.size = Vector2(380, 420)
	var sb_pause = StyleBoxFlat.new()
	sb_pause.bg_color = Color("#fffdf7")
	sb_pause.border_color = Color("#4a2e2b")
	sb_pause.set_border_width_all(3.5)
	sb_pause.set_corner_radius_all(20)
	sb_pause.set_content_margin_all(24)
	sb_pause.shadow_color = Color(0, 0, 0, 0.3)
	sb_pause.shadow_size = 12
	sb_pause.shadow_offset = Vector2(0, 4)
	bg_p.add_theme_stylebox_override("panel", sb_pause)
	pause_card.add_child(bg_p)
	
	var vb_p = VBoxContainer.new()
	vb_p.alignment = BoxContainer.ALIGNMENT_CENTER
	vb_p.add_theme_constant_override("separation", 14)
	bg_p.add_child(vb_p)
	
	var p_title = Label.new()
	p_title.text = "PERMAINAN JEDA"
	p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_title.add_theme_font_override("font", font_black)
	p_title.add_theme_font_size_override("font_size", 20)
	p_title.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb_p.add_child(p_title)
	
	var btn_resume = _create_modal_btn("Lanjut Main", Color("#bbf7d0"), Color("#14532d"))
	btn_resume.pressed.connect(_close_pause_modal)
	vb_p.add_child(btn_resume)
	
	var btn_p_restart = _create_modal_btn("Ulangi Level", Color("#fed7aa"), Color("#7c2d12"))
	btn_p_restart.pressed.connect(func(): get_tree().reload_current_scene())
	vb_p.add_child(btn_p_restart)
	
	var btn_p_settings = _create_modal_btn("Pengaturan", Color("#e9d5ff"), Color("#581c87"))
	btn_p_settings.pressed.connect(func():
		if settings_modal and settings_modal.has_method("open_settings"):
			settings_modal.open_settings()
	)
	vb_p.add_child(btn_p_settings)
	
	var btn_p_exit = _create_modal_btn("Kembali ke Peta", Color("#fee2e2"), Color("#991b1b"))
	btn_p_exit.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
	vb_p.add_child(btn_p_exit)

func _open_pause_modal() -> void:
	_play_sweep(659.25, 440.0, 0.1, 0.15)
	pause_modal.visible = true
	if pause_card:
		var vp_sz = get_viewport_rect().size
		pause_card.position = Vector2((vp_sz.x - pause_card.size.x) / 2.0, (vp_sz.y - pause_card.size.y) / 2.0)
		pause_card.scale = Vector2(0.85, 0.85)
		pause_card.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(pause_card, "scale", Vector2.ONE, 0.22)
		tw.tween_property(pause_card, "modulate:a", 1.0, 0.18)

func _close_pause_modal() -> void:
	_play_sweep(440.0, 659.25, 0.1, 0.15)
	if pause_card:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(pause_card, "scale", Vector2(0.85, 0.85), 0.12)
		tw.tween_property(pause_card, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func(): pause_modal.visible = false)
	else:
		pause_modal.visible = false

# --- WIN & GAME OVER MODALS ---
func _build_win_gameover_modals() -> void:
	win_modal = Control.new()
	win_modal.name = "WinModal"
	win_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_modal.visible = false
	win_modal.z_index = 220
	add_child(win_modal)
	
	var bd_w = ColorRect.new()
	bd_w.set_anchors_preset(Control.PRESET_FULL_RECT)
	bd_w.color = Color(0, 0, 0, 0.7)
	win_modal.add_child(bd_w)
	
	win_card = Control.new()
	win_card.name = "WinCard"
	win_card.size = Vector2(440, 440)
	win_card.pivot_offset = Vector2(220, 220)
	win_modal.add_child(win_card)
	
	var bg_w = PanelContainer.new()
	bg_w.size = Vector2(440, 440)
	var sb_win = StyleBoxFlat.new()
	sb_win.bg_color = Color("#fffdf7")
	sb_win.border_color = Color("#4a2e2b")
	sb_win.set_border_width_all(3.5)
	sb_win.set_corner_radius_all(22)
	sb_win.set_content_margin_all(24)
	sb_win.shadow_color = Color(0, 0, 0, 0.35)
	sb_win.shadow_size = 14
	sb_win.shadow_offset = Vector2(0, 6)
	bg_w.add_theme_stylebox_override("panel", sb_win)
	win_card.add_child(bg_w)
	
	var vb_w = VBoxContainer.new()
	vb_w.alignment = BoxContainer.ALIGNMENT_CENTER
	vb_w.add_theme_constant_override("separation", 14)
	bg_w.add_child(vb_w)
	
	var w_title = Label.new()
	w_title.text = "LEVEL SELESAI!"
	w_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_title.add_theme_font_override("font", font_black)
	w_title.add_theme_font_size_override("font_size", 24)
	w_title.add_theme_color_override("font_color", Color("#15803d"))
	vb_w.add_child(w_title)
	
	win_stars_row = HBoxContainer.new()
	win_stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	win_stars_row.add_theme_constant_override("separation", 12)
	vb_w.add_child(win_stars_row)
	for i in range(3):
		var star_img = TextureRect.new()
		star_img.texture = tex_star_gold
		star_img.custom_minimum_size = Vector2(44, 44)
		star_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		win_stars_row.add_child(star_img)
		
	var w_sub = Label.new()
	w_sub.text = "Hebat! Kamu berhasil merakit kabel LAN Straight standar T568B dengan urutan warna yang presisi!"
	w_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_sub.add_theme_font_override("font", font_bold)
	w_sub.add_theme_font_size_override("font_size", 14)
	w_sub.add_theme_color_override("font_color", Color("#475569"))
	vb_w.add_child(w_sub)
	
	var btn_map = _create_modal_btn("Menu Peta", Color("#f1f5f9"), Color("#334155"))
	btn_map.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
	vb_w.add_child(btn_map)
	
	var btn_next = _create_modal_btn("Lanjut Level", Color("#bbf7d0"), Color("#14532d"))
	btn_next.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
	vb_w.add_child(btn_next)
	
	# Game Over Modal
	gameover_modal = Control.new()
	gameover_modal.name = "GameOverModal"
	gameover_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_modal.visible = false
	gameover_modal.z_index = 220
	add_child(gameover_modal)
	
	var bd_go = ColorRect.new()
	bd_go.set_anchors_preset(Control.PRESET_FULL_RECT)
	bd_go.color = Color(0, 0, 0, 0.7)
	gameover_modal.add_child(bd_go)
	
	gameover_card = Control.new()
	gameover_card.name = "GameOverCard"
	gameover_card.size = Vector2(440, 380)
	gameover_card.pivot_offset = Vector2(220, 190)
	gameover_modal.add_child(gameover_card)
	
	var bg_go = PanelContainer.new()
	bg_go.size = Vector2(440, 380)
	var sb_go = StyleBoxFlat.new()
	sb_go.bg_color = Color("#fffdf7")
	sb_go.border_color = Color("#4a2e2b")
	sb_go.set_border_width_all(3.5)
	sb_go.set_corner_radius_all(22)
	sb_go.set_content_margin_all(24)
	sb_go.shadow_color = Color(0, 0, 0, 0.35)
	sb_go.shadow_size = 14
	sb_go.shadow_offset = Vector2(0, 6)
	bg_go.add_theme_stylebox_override("panel", sb_go)
	gameover_card.add_child(bg_go)
	
	var vb_go = VBoxContainer.new()
	vb_go.alignment = BoxContainer.ALIGNMENT_CENTER
	vb_go.add_theme_constant_override("separation", 14)
	bg_go.add_child(vb_go)
	
	var go_title = Label.new()
	go_title.text = "MISI GAGAL"
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_title.add_theme_font_override("font", font_black)
	go_title.add_theme_font_size_override("font_size", 24)
	go_title.add_theme_color_override("font_color", Color("#dc2626"))
	vb_go.add_child(go_title)
	
	gameover_reason_lbl = Label.new()
	gameover_reason_lbl.text = "Waktu habis atau nyawa teknisi habis!"
	gameover_reason_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gameover_reason_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameover_reason_lbl.add_theme_font_override("font", font_bold)
	gameover_reason_lbl.add_theme_font_size_override("font_size", 15)
	gameover_reason_lbl.add_theme_color_override("font_color", Color("#7f1d1d"))
	vb_go.add_child(gameover_reason_lbl)
	
	var btn_retry = _create_modal_btn("Coba Lagi", Color("#fecaca"), Color("#991b1b"))
	btn_retry.pressed.connect(func(): get_tree().reload_current_scene())
	vb_go.add_child(btn_retry)
	
	var btn_go_map = _create_modal_btn("Kembali ke Peta", Color("#f1f5f9"), Color("#334155"))
	btn_go_map.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
	vb_go.add_child(btn_go_map)

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
	is_game_active = false
	win_modal.visible = true
	for i in range(3):
		var star_img = win_stars_row.get_child(i) as TextureRect
		star_img.texture = tex_star_gold if (i < hearts) else tex_star_gray
		
	if win_card:
		var vp_sz = get_viewport_rect().size
		win_card.position = Vector2((vp_sz.x - win_card.size.x) / 2.0, (vp_sz.y - win_card.size.y) / 2.0)
		win_card.scale = Vector2(0.85, 0.85)
		win_card.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(win_card, "scale", Vector2.ONE, 0.22)
		tw.tween_property(win_card, "modulate:a", 1.0, 0.18)

func _trigger_game_over(reason: String) -> void:
	is_game_active = false
	gameover_reason_lbl.text = reason
	gameover_modal.visible = true
	if gameover_card:
		var vp_sz = get_viewport_rect().size
		gameover_card.position = Vector2((vp_sz.x - gameover_card.size.x) / 2.0, (vp_sz.y - gameover_card.size.y) / 2.0)
		gameover_card.scale = Vector2(0.85, 0.85)
		gameover_card.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(gameover_card, "scale", Vector2.ONE, 0.22)
		tw.tween_property(gameover_card, "modulate:a", 1.0, 0.18)

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
	var vp_sz = get_viewport_rect().size
	
	if door_arch:
		door_arch.position = Vector2(center_x - 164.0, 46.0)
		door_arch.size = Vector2(328.0, 200.0)
	if potted_plant:
		potted_plant.position = Vector2(center_x + 180.0, 70.0)
		potted_plant.size = Vector2(120.0, 180.0)
	if left_rack_node:
		left_rack_node.position = Vector2(center_x - 560.0, 220.0)
		left_rack_node.size = Vector2(270.0, 340.0)
	if right_rack_node:
		right_rack_node.position = Vector2(center_x + 290.0, 220.0)
		right_rack_node.size = Vector2(270.0, 340.0)
	if cable_table_node:
		cable_table_node.position = Vector2(center_x - 230.0, 520.0)
		cable_table_node.size = Vector2(460.0, 130.0)
		
	if char_pos == Vector2.ZERO:
		char_pos = Vector2(center_x - 128.0, 270.0)
		character_mascot.position = char_pos
		
	if header_ui:
		var back_b = header_ui.get_node_or_null("BackBtn")
		var hearts_p = header_ui.get_node_or_null("HeartsPanel")
		var lvl_p = header_ui.get_node_or_null("LevelBadge")
		var guide_b = header_ui.get_node_or_null("GuidebookTopBtn")
		var timer_p = header_ui.get_node_or_null("TimerPanel")
		var pause_b = header_ui.get_node_or_null("PauseBtn")
		
		if back_b: back_b.position = Vector2(30.0, 18.0)
		if hearts_p: hearts_p.position = Vector2(106.0, 18.0)
		if lvl_p: lvl_p.position = Vector2(314.0, 18.0)
		
		if pause_b: pause_b.position = Vector2(screen_w - 94.0, 18.0)
		if timer_p: timer_p.position = Vector2(screen_w - 325.0, 18.0)
		if guide_b: guide_b.position = Vector2(screen_w - 510.0, 18.0)
		
	if action_btn_node:
		action_btn_node.position = Vector2(screen_w - 150.0, 550.0)
		
	if intro_card:
		intro_card.position = Vector2((vp_sz.x - intro_card.size.x) / 2.0, (vp_sz.y - intro_card.size.y) / 2.0)
	if guidebook_card:
		guidebook_card.position = Vector2((vp_sz.x - guidebook_card.size.x) / 2.0, (vp_sz.y - guidebook_card.size.y) / 2.0)
	if crimping_card:
		crimping_card.position = Vector2((vp_sz.x - crimping_card.size.x) / 2.0, (vp_sz.y - crimping_card.size.y) / 2.0)
	if pause_card:
		pause_card.position = Vector2((vp_sz.x - pause_card.size.x) / 2.0, (vp_sz.y - pause_card.size.y) / 2.0)
	if win_card:
		win_card.position = Vector2((vp_sz.x - win_card.size.x) / 2.0, (vp_sz.y - win_card.size.y) / 2.0)
	if gameover_card:
		gameover_card.position = Vector2((vp_sz.x - gameover_card.size.x) / 2.0, (vp_sz.y - gameover_card.size.y) / 2.0)

func _setup_hover_scale(btn: Control, max_scale: float = 1.08) -> void:
	btn.mouse_entered.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "scale", Vector2.ONE * max_scale, 0.1)
	)
	btn.mouse_exited.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "scale", Vector2.ONE, 0.1)
	)

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
