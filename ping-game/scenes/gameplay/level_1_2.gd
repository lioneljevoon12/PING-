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
var tex_action_btn = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_pad_a.png")

# --- NODES IN SCENE ---
@onready var background: TextureRect = %Background
@onready var top_dark_wall: ColorRect = %TopDarkWall
@onready var door_arch: TextureRect = %DoorArch
@onready var potted_plant: TextureRect = %PottedPlant
@onready var room_container: Control = %RoomContainer
@onready var left_rack_node: Control = %LeftRack
@onready var right_rack_node: Control = %RightRack
@onready var cable_table_node: Control = %CableTable
@onready var character_mascot: Control = %CharacterMascot
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer

# --- UI CONTAINERS ---
var header_ui: Control
var dpad_container: Control
var action_btn_node: TextureButton
var table_prompt_bubble: Control

# Modals
var intro_modal: Control
var intro_card: Control

var guidebook_modal: Control
var guidebook_card: Control

var crimping_modal: Control
var crimping_card: Control

var pause_modal: Control
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
var char_pos: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO
var footstep_timer: float = 0.0

# D-Pad Virtual Joystick State
var dpad_touch_id: int = -1
var dpad_center: Vector2 = Vector2.ZERO
var dpad_knob_sprite: TextureRect
var dpad_radius: float = 55.0

# --- MINIGAME WIRE ORDERING DATA ---
# Target Standard T568B:
# 1. Putih-Oranye, 2. Oranye, 3. Putih-Hijau, 4. Biru, 5. Putih-Biru, 6. Hijau, 7. Putih-Cokelat, 8. Cokelat
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

# Slots array holds null or wire dictionary
var pin_slots: Array = [null, null, null, null, null, null, null, null]
var tray_wires: Array[Dictionary] = []

# Minigame Drag & Drop State
var dragging_wire_data: Dictionary = {}
var drag_ghost: Control = null
var slot_containers: Array[PanelContainer] = []
var tray_container: HBoxContainer = null
var rj45_channel_controls: Array[Control] = []
var rj45_wire_sprites: Array[TextureRect] = []
var rj45_pin_badges: Array[PanelContainer] = []
var tray_card_nodes: Array[PanelContainer] = []

func _ready() -> void:
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
	
	# Screenshot automation arguments for testing & verification
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-level1-2-intro" in all_args:
		await get_tree().create_timer(0.4).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_2_intro_render.png")
		get_tree().quit()
		
	if "--screenshot-level1-2-gameplay" in all_args:
		await get_tree().create_timer(0.3).timeout
		intro_modal.visible = false
		_start_gameplay()
		await get_tree().create_timer(0.4).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_2_gameplay_render.png")
		get_tree().quit()
		
	if "--screenshot-level1-2-guide" in all_args:
		await get_tree().create_timer(0.3).timeout
		intro_modal.visible = false
		_open_guidebook_modal()
		await get_tree().create_timer(0.4).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_2_guide_render.png")
		get_tree().quit()
		
	if "--screenshot-level1-2-win" in all_args:
		await get_tree().create_timer(0.3).timeout
		intro_modal.visible = false
		_trigger_win()
		await get_tree().create_timer(0.4).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_2_win_render.png")
		get_tree().quit()
		
	if "--screenshot-level1-2-minigame" in all_args:
		await get_tree().create_timer(0.3).timeout
		intro_modal.visible = false
		_open_crimping_modal()
		await get_tree().create_timer(0.4).timeout
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
	if timer_label:
		var mins = int(time_remaining) / 60
		var secs = int(time_remaining) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		if time_remaining <= 30.0:
			timer_label.add_theme_color_override("font_color", Color("#dc2626"))
		else:
			timer_label.add_theme_color_override("font_color", Color("#4a2e2b"))

func _update_hearts_display() -> void:
	if hearts_label:
		var h_str = ""
		for i in range(3):
			if i < hearts:
				h_str += "\u2764\ufe0f "
			else:
				h_str += "\U0001f5a4 "
		hearts_label.text = h_str.strip_edges()

# --- MOVEMENT & COLLISION ---
func _handle_character_movement(delta: float) -> void:
	var move_vec = input_dir
	
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_vec.x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_vec.x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_vec.y += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_vec.y -= 1.0
		
	if move_vec.length() > 0.05:
		move_vec = move_vec.normalized()
		
		# Facing
		if move_vec.x > 0.1 and not char_facing_right:
			char_facing_right = true
			char_sprite.scale.x = 1.0
		elif move_vec.x < -0.1 and char_facing_right:
			char_facing_right = false
			char_sprite.scale.x = -1.0
			
		# Walk frames
		walk_anim_time += delta * walk_anim_fps
		if not walk_frames.is_empty():
			var f_idx = int(walk_anim_time) % walk_frames.size()
			char_sprite.texture = walk_frames[f_idx]
			
		footstep_timer += delta
		if footstep_timer >= 0.22:
			footstep_timer = 0.0
			_play_step_sfx(int(walk_anim_time) % 2 == 0)
			
		var center_x = get_viewport_rect().size.x / 2.0
		var next_x = char_pos + Vector2(move_vec.x * MOVE_SPEED * delta, 0)
		if not _is_room_collision(next_x, center_x):
			char_pos.x = next_x.x
			
		var next_y = char_pos + Vector2(0, move_vec.y * MOVE_SPEED * delta)
		if not _is_room_collision(next_y, center_x):
			char_pos.y = next_y.y
			
		character_mascot.position = char_pos
	else:
		if tex_char_idle:
			char_sprite.texture = tex_char_idle
		walk_anim_time = 0.0

func _is_room_collision(pos: Vector2, center_x: float) -> bool:
	var screen_w = get_viewport_rect().size.x
	# Screen bounds
	if pos.x < 60.0 or pos.x > screen_w - 240.0:
		return true
	if pos.y < 225.0 or pos.y > 580.0:
		return true
		
	# Table collision
	var table_rect = Rect2(center_x - 240.0, 418.0, 480.0, 200.0)
	var char_feet = Rect2(pos.x + 30.0, pos.y + 40.0, 116.0, 50.0)
	if table_rect.intersects(char_feet):
		return true
		
	# Left rack collision
	var left_rack = Rect2(center_x - 560.0, 210.0, 270.0, 320.0)
	if left_rack.intersects(char_feet):
		return true
		
	# Right rack collision
	var right_rack = Rect2(center_x + 290.0, 210.0, 270.0, 320.0)
	if right_rack.intersects(char_feet):
		return true
		
	return false

func _update_table_proximity() -> void:
	if not cable_table_node or not table_prompt_bubble:
		return
	var center_x = get_viewport_rect().size.x / 2.0
	var table_center = Vector2(center_x, 480.0)
	var dist = char_pos.distance_to(table_center)
	var is_near = dist < 230.0
	
	table_prompt_bubble.visible = is_near

# --- ROOM VISUALS ---
func _build_room_visuals() -> void:
	# Left Rack ("Rak Kabel Cross" - decorated with coiled cables)
	_setup_decorative_rack(left_rack_node, "Rak Kabel Cross", "#c2410c")
	
	# Right Rack ("Rak Kabel Straight" - decorated with coiled cables)
	_setup_decorative_rack(right_rack_node, "Rak Kabel Straight", "#0284c7")
	
	# Center Cable Workbench (Tang Crimping + Kabel UTP Roll)
	_setup_cable_workbench()

func _setup_decorative_rack(rack_root: Control, title_text: String, badge_color_hex: String) -> void:
	rack_root.clip_contents = true
	var rack_tex = TextureRect.new()
	rack_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rack_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rack_tex.custom_minimum_size = Vector2(270, 340)
	rack_tex.size = Vector2(270, 340)
	rack_tex.texture = tex_rack
	rack_root.add_child(rack_tex)
	
	var badge = PanelContainer.new()
	badge.position = Vector2(25, -20)
	badge.custom_minimum_size = Vector2(220, 34)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(badge_color_hex)
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	badge.add_theme_stylebox_override("panel", sb)
	rack_root.add_child(badge)
	
	var lbl = Label.new()
	lbl.text = title_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(lbl)
	
	# Shelf Cables Decoration (row 1 and row 2) matching Figma Level 1.2
	var sample_cables = [tex_cable_green, tex_cable_yellow, tex_cable_blue, tex_cable_red]
	for row in range(2):
		for col in range(4):
			var c_img = TextureRect.new()
			c_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			c_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			c_img.custom_minimum_size = Vector2(50, 50)
			c_img.size = Vector2(50, 50)
			c_img.position = Vector2(22 + col * 56, 75 + row * 92)
			c_img.texture = sample_cables[(row * 4 + col) % sample_cables.size()]
			rack_root.add_child(c_img)

func _setup_cable_workbench() -> void:
	cable_table_node.size = Vector2(460, 130)
	
	var t_panel = PanelContainer.new()
	t_panel.size = Vector2(460, 130)
	var sb_table = StyleBoxFlat.new()
	sb_table.bg_color = Color("#dfcaa9") # Table surface
	sb_table.border_color = Color("#593717")
	sb_table.set_border_width_all(3)
	sb_table.set_corner_radius_all(12)
	t_panel.add_theme_stylebox_override("panel", sb_table)
	cable_table_node.add_child(t_panel)
	
	# Items Row on Table (Tang Crimping & Kabel UTP)
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
	
	# Speech Bubble "Urutkan Kabel"
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
	exc_lbl.text = "\u2757"
	exc_lbl.add_theme_font_size_override("font_size", 14)
	hb_b.add_child(exc_lbl)
	
	var text_lbl = Label.new()
	text_lbl.text = "Urutkan Kabel"
	text_lbl.add_theme_font_override("font", font_black)
	text_lbl.add_theme_font_size_override("font_size", 12)
	text_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	hb_b.add_child(text_lbl)
	
	# Tap bubble to open minigame
	bubble_p.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			_open_crimping_modal()
	)
	_setup_hover_scale(bubble_p, 1.1)
	cable_table_node.add_child(table_prompt_bubble)

func _build_character() -> void:
	character_mascot.size = Vector2(176, 98)
	char_sprite = TextureRect.new()
	char_sprite.name = "RouterSprite"
	char_sprite.texture = tex_char_idle
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.size = Vector2(176, 98)
	char_sprite.pivot_offset = Vector2(88, 49)
	character_mascot.add_child(char_sprite)

# --- HEADER UI ---
func _build_header_ui() -> void:
	header_ui = Control.new()
	header_ui.name = "HeaderUI"
	header_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_ui)
	
	# 1. Back Button (<)
	var back_btn = TextureButton.new()
	back_btn.position = Vector2(30, 20)
	back_btn.custom_minimum_size = Vector2(50, 50)
	back_btn.pivot_offset = Vector2(25, 25)
	var p_back = PanelContainer.new()
	p_back.size = Vector2(50, 50)
	p_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_back = StyleBoxFlat.new()
	sb_back.bg_color = Color("#fcddec")
	sb_back.border_color = Color("#4a2e2b")
	sb_back.set_border_width_all(3)
	sb_back.set_corner_radius_all(25)
	p_back.add_theme_stylebox_override("panel", sb_back)
	back_btn.add_child(p_back)
	
	var lbl_back = Label.new()
	lbl_back.text = "\u276e"
	lbl_back.size = Vector2(50, 50)
	lbl_back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_back.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_back.add_theme_font_override("font", font_black)
	lbl_back.add_theme_font_size_override("font_size", 20)
	lbl_back.add_theme_color_override("font_color", Color("#4a2e2b"))
	back_btn.add_child(lbl_back)
	back_btn.pressed.connect(_open_pause_modal)
	_setup_hover_scale(back_btn, 1.1)
	header_ui.add_child(back_btn)
	
	# 2. Hearts Panel
	var hearts_panel = PanelContainer.new()
	hearts_panel.position = Vector2(95, 23)
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color("#fef2f2")
	sb_h.border_color = Color("#ef4444")
	sb_h.set_border_width_all(3)
	sb_h.set_corner_radius_all(14)
	sb_h.set_content_margin_all(8)
	hearts_panel.add_theme_stylebox_override("panel", sb_h)
	header_ui.add_child(hearts_panel)
	
	hearts_label = Label.new()
	hearts_label.text = "\u2764\ufe0f \u2764\ufe0f \u2764\ufe0f"
	hearts_label.add_theme_font_size_override("font_size", 16)
	hearts_panel.add_child(hearts_label)
	
	# 3. Level Badge (Level 1.2)
	var lvl_panel = PanelContainer.new()
	lvl_panel.position = Vector2(220, 23)
	var sb_lvl = StyleBoxFlat.new()
	sb_lvl.bg_color = Color("#fdf4eb")
	sb_lvl.border_color = Color("#4a2e2b")
	sb_lvl.set_border_width_all(3)
	sb_lvl.set_corner_radius_all(12)
	sb_lvl.set_content_margin_all(6)
	lvl_panel.add_theme_stylebox_override("panel", sb_lvl)
	header_ui.add_child(lvl_panel)
	
	var lvl_lbl = Label.new()
	lvl_lbl.text = "LEVEL 1.2"
	lvl_lbl.add_theme_font_override("font", font_black)
	lvl_lbl.add_theme_font_size_override("font_size", 13)
	lvl_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	lvl_panel.add_child(lvl_lbl)
	
	# 4. Guidebook Button on Top Bar ("nah nanti kita kasih guidebook urutan diatas wes")
	var guide_top_btn = TextureButton.new()
	guide_top_btn.name = "GuidebookTopBtn"
	guide_top_btn.custom_minimum_size = Vector2(130, 44)
	guide_top_btn.pivot_offset = Vector2(65, 22)
	var p_g = PanelContainer.new()
	p_g.size = Vector2(130, 44)
	p_g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_g = StyleBoxFlat.new()
	sb_g.bg_color = Color("#f5f3ff")
	sb_g.border_color = Color("#7c3aed")
	sb_g.set_border_width_all(2.5)
	sb_g.set_corner_radius_all(14)
	p_g.add_theme_stylebox_override("panel", sb_g)
	guide_top_btn.add_child(p_g)
	
	var hb_g = HBoxContainer.new()
	hb_g.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_g.size = Vector2(130, 44)
	hb_g.add_theme_constant_override("separation", 6)
	p_g.add_child(hb_g)
	
	var text_g = Label.new()
	text_g.text = "Panduan Pin"
	text_g.add_theme_font_override("font", font_black)
	text_g.add_theme_font_size_override("font_size", 12)
	text_g.add_theme_color_override("font_color", Color("#4a2e2b"))
	hb_g.add_child(text_g)
	
	guide_top_btn.pressed.connect(_open_guidebook_modal)
	_setup_hover_scale(guide_top_btn, 1.08)
	header_ui.add_child(guide_top_btn)
	
	# 5. Timer Panel (02:45)
	var timer_panel = PanelContainer.new()
	timer_panel.name = "TimerPanel"
	var sb_timer = StyleBoxFlat.new()
	sb_timer.bg_color = Color("#fdf4eb")
	sb_timer.border_color = Color("#4a2e2b")
	sb_timer.set_border_width_all(3)
	sb_timer.set_corner_radius_all(14)
	sb_timer.set_content_margin_all(6)
	timer_panel.add_theme_stylebox_override("panel", sb_timer)
	header_ui.add_child(timer_panel)
	
	var hb_t = HBoxContainer.new()
	hb_t.add_theme_constant_override("separation", 6)
	timer_panel.add_child(hb_t)
	
	var icon_t = Label.new()
	icon_t.text = "\u23f1"
	icon_t.add_theme_font_size_override("font_size", 14)
	hb_t.add_child(icon_t)
	
	timer_label = Label.new()
	timer_label.text = "02:45"
	timer_label.add_theme_font_override("font", font_black)
	timer_label.add_theme_font_size_override("font_size", 14)
	timer_label.add_theme_color_override("font_color", Color("#4a2e2b"))
	hb_t.add_child(timer_label)
	
	# 6. Pause / Menu Button (☰)
	var pause_btn = TextureButton.new()
	pause_btn.name = "PauseBtn"
	pause_btn.custom_minimum_size = Vector2(50, 50)
	pause_btn.pivot_offset = Vector2(25, 25)
	var p_menu = PanelContainer.new()
	p_menu.size = Vector2(50, 50)
	p_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_menu = StyleBoxFlat.new()
	sb_menu.bg_color = Color("#fdf4eb")
	sb_menu.border_color = Color("#4a2e2b")
	sb_menu.set_border_width_all(3)
	sb_menu.set_corner_radius_all(25)
	p_menu.add_theme_stylebox_override("panel", sb_menu)
	pause_btn.add_child(p_menu)
	
	var lbl_menu = Label.new()
	lbl_menu.text = "\u2630"
	lbl_menu.size = Vector2(50, 50)
	lbl_menu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_menu.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_menu.add_theme_font_override("font", font_black)
	lbl_menu.add_theme_font_size_override("font_size", 18)
	lbl_menu.add_theme_color_override("font_color", Color("#4a2e2b"))
	pause_btn.add_child(lbl_menu)
	pause_btn.pressed.connect(_open_pause_modal)
	_setup_hover_scale(pause_btn, 1.1)
	header_ui.add_child(pause_btn)

# --- MOBILE CONTROLS (STYLE C) ---
func _build_mobile_controls() -> void:
	dpad_container = Control.new()
	dpad_container.name = "DpadContainer"
	dpad_container.size = Vector2(170, 170)
	dpad_container.position = Vector2(60, 500)
	add_child(dpad_container)
	
	var base_spr = TextureRect.new()
	base_spr.texture = tex_dpad_base
	base_spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base_spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	base_spr.size = Vector2(170, 170)
	base_spr.modulate = Color(1, 1, 1, 0.75)
	dpad_container.add_child(base_spr)
	
	dpad_knob_sprite = TextureRect.new()
	dpad_knob_sprite.texture = tex_dpad_knob
	dpad_knob_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dpad_knob_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dpad_knob_sprite.size = Vector2(76, 76)
	dpad_knob_sprite.pivot_offset = Vector2(38, 38)
	dpad_knob_sprite.position = Vector2(47, 47)
	dpad_container.add_child(dpad_knob_sprite)
	
	dpad_center = Vector2(85, 85)
	
	# Action button
	action_btn_node = TextureButton.new()
	action_btn_node.name = "ActionTouchBtn"
	action_btn_node.texture_normal = tex_action_btn
	action_btn_node.custom_minimum_size = Vector2(90, 90)
	action_btn_node.size = Vector2(90, 90)
	action_btn_node.pivot_offset = Vector2(45, 45)
	action_btn_node.modulate = Color(1, 1, 1, 0.85)
	action_btn_node.pressed.connect(func():
		_open_crimping_modal()
	)
	_setup_hover_scale(action_btn_node, 1.1)
	add_child(action_btn_node)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_ev = event as InputEventScreenTouch
		if touch_ev.pressed:
			var local_pos = dpad_container.get_global_transform().affine_inverse() * touch_ev.position
			if local_pos.distance_to(dpad_center) <= dpad_radius * 1.5:
				dpad_touch_id = touch_ev.index
				_update_dpad_knob(local_pos)
		else:
			if touch_ev.index == dpad_touch_id:
				dpad_touch_id = -1
				input_dir = Vector2.ZERO
				dpad_knob_sprite.position = Vector2(47, 47)
				
	elif event is InputEventScreenDrag:
		var drag_ev = event as InputEventScreenDrag
		if drag_ev.index == dpad_touch_id:
			var local_pos = dpad_container.get_global_transform().affine_inverse() * drag_ev.position
			_update_dpad_knob(local_pos)

func _update_dpad_knob(local_pos: Vector2) -> void:
	var offset = local_pos - dpad_center
	if offset.length() > dpad_radius:
		offset = offset.normalized() * dpad_radius
	dpad_knob_sprite.position = dpad_center + offset - Vector2(38, 38)
	input_dir = offset / dpad_radius

# --- LEVEL 1.2 INTRO MODAL ---
func _build_intro_modal() -> void:
	intro_modal = Control.new()
	intro_modal.name = "IntroModal"
	intro_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_modal.visible = true
	add_child(intro_modal)
	
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.65)
	intro_modal.add_child(backdrop)
	
	var card = Control.new()
	card.name = "IntroCard"
	card.size = Vector2(620, 360)
	card.pivot_offset = Vector2(310, 180)
	intro_card = card
	intro_modal.add_child(card)
	
	var bg_panel = PanelContainer.new()
	bg_panel.size = Vector2(620, 360)
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
	desc.text = "Perakitan kabel sedang berlangsung dan waktu terus berjalan! Selesaikan tantangan ini dengan merakit urutan pin warna standar TIA/EIA 568A/B secara tepat sebelum batas waktu habis"
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
	sb_btn.bg_color = Color("#bbf7d0") # Soft green pill
	sb_btn.border_color = Color("#4a2e2b")
	sb_btn.set_border_width_all(2.5)
	sb_btn.set_corner_radius_all(14)
	btn_start.add_theme_stylebox_override("normal", sb_btn)
	btn_start.add_theme_color_override("font_color", Color("#14532d"))
	btn_start.pressed.connect(_start_gameplay)
	_setup_hover_scale(btn_start, 1.1)
	vb.add_child(btn_start)
	
	# Character Avatar Badge at bottom-left corner of card (matching Figma)
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
	guidebook_modal.visible = false
	add_child(guidebook_modal)
	
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.65)
	backdrop.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			_close_guidebook_modal()
	)
	guidebook_modal.add_child(backdrop)
	
	guidebook_card = PanelContainer.new()
	guidebook_card.name = "GuidebookCard"
	guidebook_card.size = Vector2(760, 360)
	guidebook_card.pivot_offset = Vector2(380, 180)
	var sb_card = StyleBoxFlat.new()
	sb_card.bg_color = Color("#fffdf7")
	sb_card.border_color = Color("#4a2e2b")
	sb_card.set_border_width_all(3)
	sb_card.set_corner_radius_all(18)
	sb_card.shadow_color = Color(0, 0, 0, 0.3)
	sb_card.shadow_size = 12
	sb_card.shadow_offset = Vector2(0, 4)
	guidebook_card.add_theme_stylebox_override("panel", sb_card)
	guidebook_modal.add_child(guidebook_card)
	
	var vb_main = VBoxContainer.new()
	vb_main.add_theme_constant_override("separation", 0)
	guidebook_card.add_child(vb_main)
	
	# Header
	var header_panel = PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(754, 48)
	var sb_hdr = StyleBoxFlat.new()
	sb_hdr.bg_color = Color("#e8daf8")
	sb_hdr.border_color = Color("#4a2e2b")
	sb_hdr.border_width_bottom = 3
	sb_hdr.corner_radius_top_left = 15
	sb_hdr.corner_radius_top_right = 15
	header_panel.add_theme_stylebox_override("panel", sb_hdr)
	vb_main.add_child(header_panel)
	
	var h_box_hdr = Control.new()
	h_box_hdr.custom_minimum_size = Vector2(754, 48)
	header_panel.add_child(h_box_hdr)
	
	var title_lbl = Label.new()
	title_lbl.text = "URUTKAN PIN WARNA TIA/EIA 568A/B"
	title_lbl.size = Vector2(754, 48)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", font_black)
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	h_box_hdr.add_child(title_lbl)
	
	var close_btn = Button.new()
	close_btn.text = "\u2715"
	close_btn.position = Vector2(754 - 44, 7)
	close_btn.size = Vector2(34, 34)
	close_btn.custom_minimum_size = Vector2(34, 34)
	close_btn.pivot_offset = Vector2(17, 17)
	var sb_close = StyleBoxFlat.new()
	sb_close.bg_color = Color("#fddede")
	sb_close.border_color = Color("#4a2e2b")
	sb_close.set_border_width_all(2.5)
	sb_close.set_corner_radius_all(17)
	close_btn.add_theme_stylebox_override("normal", sb_close)
	close_btn.add_theme_font_override("font", font_black)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	close_btn.pressed.connect(_close_guidebook_modal)
	_setup_hover_scale(close_btn, 1.15)
	h_box_hdr.add_child(close_btn)
	
	# Content Area
	var content_margin = MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_top", 16)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_bottom", 20)
	vb_main.add_child(content_margin)
	
	var dashed_box = Control.new()
	dashed_box.custom_minimum_size = Vector2(706, 260)
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
	lbl_a.text = "568A"
	lbl_a.custom_minimum_size = Vector2(80, 0)
	lbl_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_a.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_a.add_theme_font_override("font", font_black)
	lbl_a.add_theme_font_size_override("font_size", 20)
	lbl_a.add_theme_color_override("font_color", Color("#4a2e2b"))
	hb_content.add_child(lbl_a)
	
	var diagram_rect = TextureRect.new()
	diagram_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	diagram_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	diagram_rect.custom_minimum_size = Vector2(460, 230)
	diagram_rect.texture = tex_diagram_cross
	hb_content.add_child(diagram_rect)
	
	var lbl_b = Label.new()
	lbl_b.text = "568B"
	lbl_b.custom_minimum_size = Vector2(80, 0)
	lbl_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_b.add_theme_font_override("font", font_black)
	lbl_b.add_theme_font_size_override("font_size", 20)
	lbl_b.add_theme_color_override("font_color", Color("#4a2e2b"))
	hb_content.add_child(lbl_b)

func _open_guidebook_modal() -> void:
	_play_sweep(523.25, 783.99, 0.1, 0.15)
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
	crimping_modal.visible = false
	add_child(crimping_modal)
	
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.72)
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
	
	# Header (Lavender #e8daf8)
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
	t_lbl.add_theme_font_size_override("font_size", 14)
	t_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	c_hdr.add_child(t_lbl)
	
	var c_btn = Button.new()
	c_btn.text = "\u2715"
	c_btn.position = Vector2(914 - 44, 6)
	c_btn.size = Vector2(34, 34)
	c_btn.pivot_offset = Vector2(17, 17)
	var sb_cls = StyleBoxFlat.new()
	sb_cls.bg_color = Color("#fddede")
	sb_cls.border_color = Color("#4a2e2b")
	sb_cls.set_border_width_all(2.5)
	sb_cls.set_corner_radius_all(17)
	c_btn.add_theme_stylebox_override("normal", sb_cls)
	c_btn.add_theme_font_override("font", font_black)
	c_btn.add_theme_font_size_override("font_size", 14)
	c_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	c_btn.pressed.connect(_close_crimping_modal)
	_setup_hover_scale(c_btn, 1.15)
	c_hdr.add_child(c_btn)
	
	# Content Body (Left: RJ45 Connector, Right: Wire Selection & Controls)
	var body_margin = MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 20)
	body_margin.add_theme_constant_override("margin_top", 12)
	body_margin.add_theme_constant_override("margin_right", 20)
	body_margin.add_theme_constant_override("margin_bottom", 12)
	vb_all.add_child(body_margin)
	
	var hb_body = HBoxContainer.new()
	hb_body.add_theme_constant_override("separation", 22)
	body_margin.add_child(hb_body)
	
	# ================= LEFT COLUMN: RJ45 CONNECTOR =================
	var left_col = VBoxContainer.new()
	left_col.alignment = BoxContainer.ALIGNMENT_CENTER
	left_col.add_theme_constant_override("separation", 6)
	hb_body.add_child(left_col)
	
	var rj_label = Label.new()
	rj_label.text = "KONEKTOR RJ45"
	rj_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rj_label.add_theme_font_override("font", font_black)
	rj_label.add_theme_font_size_override("font_size", 13)
	rj_label.add_theme_color_override("font_color", Color("#334155"))
	left_col.add_child(rj_label)
	
	# RJ45 Connector Widget Root
	var rj_widget = Control.new()
	rj_widget.custom_minimum_size = Vector2(280, 390)
	rj_widget.size = Vector2(280, 390)
	left_col.add_child(rj_widget)
	
	# Channel Slots Coordinates (derived from authentic RJ45 vector diagram)
	var NATIVE_X = [47.0, 102.0, 157.0, 211.0, 264.0, 320.0, 374.0, 428.0]
	var scale_f = 280.0 / 502.0
	
	rj45_channel_controls.clear()
	rj45_wire_sprites.clear()
	rj45_pin_badges.clear()
	
	# 1. Base Wire Channels (placed behind the housing)
	var channels_layer = Control.new()
	channels_layer.size = Vector2(280, 390)
	rj_widget.add_child(channels_layer)
	
	for i in range(8):
		var ch_x = NATIVE_X[i] * scale_f
		var ch_w = 15.0
		var ch_y = 108.0
		var ch_h = 224.0
		
		# Channel slot container
		var ch_ctrl = Control.new()
		ch_ctrl.name = "RJChannel_%d" % i
		ch_ctrl.position = Vector2(ch_x, ch_y)
		ch_ctrl.size = Vector2(ch_w, ch_h)
		channels_layer.add_child(ch_ctrl)
		rj45_channel_controls.append(ch_ctrl)
		
		# Faint empty slot background
		var empty_bg = Panel.new()
		empty_bg.size = Vector2(ch_w, ch_h)
		var sb_empty = StyleBoxFlat.new()
		sb_empty.bg_color = Color(0.9, 0.92, 0.95, 0.5)
		sb_empty.border_color = Color(0.75, 0.8, 0.88, 0.8)
		sb_empty.set_border_width_all(1)
		empty_bg.add_theme_stylebox_override("panel", sb_empty)
		ch_ctrl.add_child(empty_bg)
		
		# Wire TextureRect (visible when wire assigned)
		var wire_tex_rect = TextureRect.new()
		wire_tex_rect.name = "WireTex"
		wire_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wire_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		wire_tex_rect.size = Vector2(ch_w, ch_h)
		wire_tex_rect.visible = false
		ch_ctrl.add_child(wire_tex_rect)
		rj45_wire_sprites.append(wire_tex_rect)
		
		# Interactive touch/click handling on channel
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
	
	# 2. RJ45 Housing Overlay (On top of wire channels)
	var housing_rect = TextureRect.new()
	housing_rect.texture = tex_rj45_housing
	housing_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	housing_rect.stretch_mode = TextureRect.STRETCH_SCALE
	housing_rect.size = Vector2(280, 308)
	housing_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rj_widget.add_child(housing_rect)
	
	# 3. Pin Number Badges Row (Below wire tails at y=340)
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
		b_lbl.add_theme_font_size_override("font_size", 10)
		b_lbl.add_theme_color_override("font_color", Color("#475569"))
		badge.add_child(b_lbl)
		
		badges_container.add_child(badge)
		rj45_pin_badges.append(badge)
		
		# Clicking pin badge also removes wire if present
		var s_idx = i
		badge.gui_input.connect(func(ev: InputEvent):
			if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
				_on_slot_clicked(s_idx)
		)
	
	# ================= RIGHT COLUMN: WIRE SELECTION & CONTROLS =================
	var right_col = VBoxContainer.new()
	right_col.custom_minimum_size = Vector2(550, 420)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 10)
	hb_body.add_child(right_col)
	
	# Guide Card
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
	title_sec.add_theme_font_size_override("font_size", 14)
	title_sec.add_theme_color_override("font_color", Color("#1e293b"))
	hb_std.add_child(title_sec)
	
	var std_pill = PanelContainer.new()
	var sb_sp = StyleBoxFlat.new()
	sb_sp.bg_color = Color("#dcfce7")
	sb_sp.border_color = Color("#16a34a")
	sb_sp.set_border_width_all(1)
	sb_sp.set_corner_radius_all(6)
	sb_sp.set_content_margin_all(3)
	std_pill.add_theme_stylebox_override("panel", sb_sp)
	var sp_lbl = Label.new()
	sp_lbl.text = "STANDAR T568B"
	sp_lbl.add_theme_font_override("font", font_black)
	sp_lbl.add_theme_font_size_override("font_size", 10)
	sp_lbl.add_theme_color_override("font_color", Color("#15803d"))
	std_pill.add_child(sp_lbl)
	hb_std.add_child(std_pill)
	
	var sub_info = Label.new()
	sub_info.text = "Ketuk kabel warna untuk memasukkan ke pin RJ45 berikutnya secara berurutan, atau seret langsung ke slot konektor di sebelah kiri."
	sub_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_info.add_theme_font_override("font", font_semibold)
	sub_info.add_theme_font_size_override("font_size", 11)
	sub_info.add_theme_color_override("font_color", Color("#64748b"))
	vb_info.add_child(sub_info)
	
	# Wire Cards Grid (4 columns x 2 rows)
	var grid_scroll = PanelContainer.new()
	var sb_grid_bg = StyleBoxFlat.new()
	sb_grid_bg.bg_color = Color.TRANSPARENT
	grid_scroll.add_theme_stylebox_override("panel", sb_grid_bg)
	right_col.add_child(grid_scroll)
	
	var grid_wires = GridContainer.new()
	grid_wires.columns = 4
	grid_wires.add_theme_constant_override("h_separation", 10)
	grid_wires.add_theme_constant_override("v_separation", 10)
	grid_scroll.add_child(grid_wires)
	
	tray_card_nodes.clear()
	for i in range(all_wires_def.size()):
		var wire = all_wires_def[i]
		var wire_card = PanelContainer.new()
		wire_card.name = "TrayCard_%s" % wire["id"]
		wire_card.custom_minimum_size = Vector2(125, 96)
		wire_card.pivot_offset = Vector2(62, 48)
		var sb_w = StyleBoxFlat.new()
		sb_w.bg_color = Color("#ffffff")
		sb_w.border_color = Color("#cbd5e1")
		sb_w.set_border_width_all(2)
		sb_w.set_corner_radius_all(10)
		sb_w.set_content_margin_all(6)
		sb_w.shadow_color = Color(0, 0, 0, 0.08)
		sb_w.shadow_size = 4
		sb_w.shadow_offset = Vector2(0, 2)
		wire_card.add_theme_stylebox_override("panel", sb_w)
		
		var vb_card = VBoxContainer.new()
		vb_card.alignment = BoxContainer.ALIGNMENT_CENTER
		vb_card.add_theme_constant_override("separation", 4)
		wire_card.add_child(vb_card)
		
		# Wire preview texture
		var wire_tex = TextureRect.new()
		wire_tex.texture = wire["tex"]
		wire_tex.custom_minimum_size = Vector2(16, 52)
		wire_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wire_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vb_card.add_child(wire_tex)
		
		var name_l = Label.new()
		name_l.name = "WireName"
		name_l.text = wire["name"]
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.add_theme_font_override("font", font_black)
		name_l.add_theme_font_size_override("font_size", 10)
		name_l.add_theme_color_override("font_color", Color("#1e293b"))
		vb_card.add_child(name_l)
		
		# Drag & Drop and Tap support for tray card
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
		grid_wires.add_child(wire_card)
		tray_card_nodes.append(wire_card)
	
	# Action Buttons Row
	var footer_row = HBoxContainer.new()
	footer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_row.add_theme_constant_override("separation", 16)
	right_col.add_child(footer_row)
	
	var btn_reset = Button.new()
	btn_reset.text = "RESET"
	btn_reset.custom_minimum_size = Vector2(120, 42)
	btn_reset.add_theme_font_override("font", font_black)
	btn_reset.add_theme_font_size_override("font_size", 13)
	var sb_rst = StyleBoxFlat.new()
	sb_rst.bg_color = Color("#fee2e2")
	sb_rst.border_color = Color("#ef4444")
	sb_rst.set_border_width_all(2)
	sb_rst.set_corner_radius_all(10)
	btn_reset.add_theme_stylebox_override("normal", sb_rst)
	btn_reset.add_theme_color_override("font_color", Color("#991b1b"))
	btn_reset.pressed.connect(_reset_minigame_slots)
	_setup_hover_scale(btn_reset, 1.08)
	footer_row.add_child(btn_reset)
	
	var btn_guide_mini = Button.new()
	btn_guide_mini.text = "LIHAT PANDUAN"
	btn_guide_mini.custom_minimum_size = Vector2(150, 42)
	btn_guide_mini.add_theme_font_override("font", font_black)
	btn_guide_mini.add_theme_font_size_override("font_size", 13)
	var sb_gm = StyleBoxFlat.new()
	sb_gm.bg_color = Color("#f5f3ff")
	sb_gm.border_color = Color("#7c3aed")
	sb_gm.set_border_width_all(2)
	sb_gm.set_corner_radius_all(10)
	btn_guide_mini.add_theme_stylebox_override("normal", sb_gm)
	btn_guide_mini.add_theme_color_override("font_color", Color("#5b21b6"))
	btn_guide_mini.pressed.connect(_open_guidebook_modal)
	_setup_hover_scale(btn_guide_mini, 1.08)
	footer_row.add_child(btn_guide_mini)
	
	var btn_submit = Button.new()
	btn_submit.text = "KRIMPING KABEL"
	btn_submit.custom_minimum_size = Vector2(180, 42)
	btn_submit.add_theme_font_override("font", font_black)
	btn_submit.add_theme_font_size_override("font_size", 14)
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
					
	# Update tray cards (dim if already assigned)
	for i in range(all_wires_def.size()):
		if i >= tray_card_nodes.size():
			continue
		var wire_def = all_wires_def[i]
		var card = tray_card_nodes[i]
		var is_assigned = false
		for p in pin_slots:
			if p != null and p["id"] == wire_def["id"]:
				is_assigned = true
				break
				
		var name_l = card.get_node_or_null("VBoxContainer/WireName") as Label
		if is_assigned:
			card.modulate.a = 0.35
			if name_l:
				name_l.text = wire_def["name"] + " \u2713"
				name_l.add_theme_color_override("font_color", Color("#16a34a"))
		else:
			card.modulate.a = 1.0
		if name_l:
			name_l.text = wire_def["name"]
			name_l.add_theme_color_override("font_color", Color("#1e293b"))

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
		# Check if dropped onto any RJ45 channel
		var target_slot_idx = -1
		for i in range(rj45_channel_controls.size()):
			var ch_ctrl = rj45_channel_controls[i]
			var rect = ch_ctrl.get_global_rect()
			rect = rect.grow_individual(6.0, 10.0, 6.0, 20.0)
			if rect.has_point(global_pos):
				target_slot_idx = i
				break
				
		if target_slot_idx != -1:
			# If this wire is already in another slot, clear that slot
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
	# If wire is already placed, clicking it removes it
	for i in range(8):
		if pin_slots[i] != null and pin_slots[i]["id"] == wire_data["id"]:
			pin_slots[i] = null
			_play_tone(392.0, 0.08)
			_refresh_rj45_display()
			return
			
	# Place in next empty pin
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
	_refresh_rj45_display()
	show_toast("Semua pin konektor RJ45 berhasil dikosongkan.")

func _validate_crimping_submission() -> void:
	# Check if all 8 slots are filled
	for i in range(8):
		if pin_slots[i] == null:
			_play_tone(220.0, 0.2)
			show_toast("Pin %d masih kosong! Pasang semua 8 kabel ke konektor RJ45." % (i + 1))
			return
			
	# Compare with TARGET_SEQUENCE (T568B)
	var is_correct = true
	var wrong_indices: Array[int] = []
	for i in range(8):
		if pin_slots[i]["id"] != TARGET_SEQUENCE[i]:
			is_correct = false
			wrong_indices.append(i)
			
	if is_correct:
		# VICTORY!
		_play_sweep(440.0, 880.0, 0.15, 0.25)
		_close_crimping_modal()
		if PlayerData:
			PlayerData.set_level_stars(1, 2, hearts)
		_trigger_win()
	else:
		# PENALTY
		hearts -= 1
		_update_hearts_display()
		_play_tone(180.0, 0.25, 0.3)
		
		# Visual shake on crimping card
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
	_play_sweep(523.25, 783.99, 0.1, 0.15)
	crimping_modal.visible = true
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
	pause_card.size = Vector2(460, 320)
	pause_card.pivot_offset = Vector2(230, 160)
	pause_modal.add_child(pause_card)
	
	var bg_p = PanelContainer.new()
	bg_p.size = Vector2(460, 320)
	var sb_p = StyleBoxFlat.new()
	sb_p.bg_color = Color("#fffdf7")
	sb_p.border_color = Color("#4a2e2b")
	sb_p.set_border_width_all(3.5)
	sb_p.set_corner_radius_all(20)
	sb_p.set_content_margin_all(24)
	sb_p.shadow_color = Color(0, 0, 0, 0.3)
	sb_p.shadow_size = 14
	sb_p.shadow_offset = Vector2(0, 4)
	bg_p.add_theme_stylebox_override("panel", sb_p)
	pause_card.add_child(bg_p)
	
	var vb_p = VBoxContainer.new()
	vb_p.add_theme_constant_override("separation", 12)
	bg_p.add_child(vb_p)
	
	var p_title = Label.new()
	p_title.text = "GAME DIPERHENTIKAN"
	p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_title.add_theme_font_override("font", font_black)
	p_title.add_theme_font_size_override("font_size", 18)
	p_title.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb_p.add_child(p_title)
	
	var btn_resume = Button.new()
	btn_resume.text = "LANJUTKAN MAIN"
	btn_resume.add_theme_font_override("font", font_black)
	btn_resume.add_theme_font_size_override("font_size", 13)
	var sb_res = StyleBoxFlat.new()
	sb_res.bg_color = Color("#0284c7")
	sb_res.set_corner_radius_all(10)
	sb_res.set_content_margin_all(8)
	btn_resume.add_theme_stylebox_override("normal", sb_res)
	btn_resume.pressed.connect(_close_pause_modal)
	vb_p.add_child(btn_resume)
	
	var btn_p_restart = Button.new()
	btn_p_restart.text = "ULANGI LEVEL"
	btn_p_restart.add_theme_font_override("font", font_black)
	btn_p_restart.add_theme_font_size_override("font_size", 13)
	var sb_bm = StyleBoxFlat.new()
	sb_bm.bg_color = Color("#e2e8f0")
	sb_bm.set_corner_radius_all(10)
	sb_bm.set_content_margin_all(8)
	btn_p_restart.add_theme_stylebox_override("normal", sb_bm)
	btn_p_restart.add_theme_color_override("font_color", Color("#334155"))
	btn_p_restart.pressed.connect(func(): get_tree().reload_current_scene())
	vb_p.add_child(btn_p_restart)
	
	var btn_p_exit = Button.new()
	btn_p_exit.text = "KELUAR KE PETA LEVEL"
	btn_p_exit.add_theme_font_override("font", font_black)
	btn_p_exit.add_theme_font_size_override("font_size", 13)
	btn_p_exit.add_theme_stylebox_override("normal", sb_bm)
	btn_p_exit.add_theme_color_override("font_color", Color("#dc2626"))
	btn_p_exit.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
	vb_p.add_child(btn_p_exit)

func _open_pause_modal() -> void:
	_play_sweep(659.25, 523.25, 0.1, 0.15)
	if pause_card:
		var vp_sz = get_viewport_rect().size
		pause_card.position = Vector2((vp_sz.x - pause_card.size.x) / 2.0, (vp_sz.y - pause_card.size.y) / 2.0)
		pause_card.scale = Vector2(0.85, 0.85)
		pause_card.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(pause_card, "scale", Vector2.ONE, 0.22)
		tw.tween_property(pause_card, "modulate:a", 1.0, 0.18)
	pause_modal.visible = true

func _close_pause_modal() -> void:
	_play_sweep(523.25, 659.25, 0.1, 0.15)
	if pause_card:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(pause_card, "scale", Vector2(0.85, 0.85), 0.12)
		tw.tween_property(pause_card, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func(): pause_modal.visible = false)
	else:
		pause_modal.visible = false

# --- WIN & GAMEOVER MODALS ---
func _build_win_gameover_modals() -> void:
	# 1. Victory Modal
	win_modal = Control.new()
	win_modal.name = "WinModal"
	win_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_modal.visible = false
	add_child(win_modal)
	
	var bd_win = ColorRect.new()
	bd_win.set_anchors_preset(Control.PRESET_FULL_RECT)
	bd_win.color = Color(0, 0, 0, 0.75)
	win_modal.add_child(bd_win)
	
	win_card = Control.new()
	win_card.name = "WinCard"
	win_card.size = Vector2(560, 340)
	win_card.pivot_offset = Vector2(280, 170)
	win_modal.add_child(win_card)
	
	var bg_win = PanelContainer.new()
	bg_win.size = Vector2(560, 340)
	var sb_win = StyleBoxFlat.new()
	sb_win.bg_color = Color("#f0fdf4")
	sb_win.border_color = Color("#16a34a")
	sb_win.set_border_width_all(4)
	sb_win.set_corner_radius_all(20)
	sb_win.set_content_margin_all(24)
	sb_win.shadow_color = Color(0, 0, 0, 0.3)
	sb_win.shadow_size = 14
	sb_win.shadow_offset = Vector2(0, 6)
	bg_win.add_theme_stylebox_override("panel", sb_win)
	win_card.add_child(bg_win)
	
	var vb_w = VBoxContainer.new()
	vb_w.alignment = BoxContainer.ALIGNMENT_CENTER
	vb_w.add_theme_constant_override("separation", 14)
	bg_win.add_child(vb_w)
	
	var w_title = Label.new()
	w_title.text = "MISI SELESAI!"
	w_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_title.add_theme_font_override("font", font_black)
	w_title.add_theme_font_size_override("font_size", 24)
	w_title.add_theme_color_override("font_color", Color("#15803d"))
	vb_w.add_child(w_title)
	
	win_stars_row = HBoxContainer.new()
	win_stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	win_stars_row.add_theme_constant_override("separation", 12)
	for i in range(3):
		var star_r = TextureRect.new()
		star_r.texture = tex_star_gold
		star_r.custom_minimum_size = Vector2(44, 44)
		star_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		win_stars_row.add_child(star_r)
	vb_w.add_child(win_stars_row)
	
	var w_sub = Label.new()
	w_sub.text = "Luar biasa! Seluruh 8 pin kabel berhasil disusun dan dikrimping sempurna sesuai standar TIA/EIA 568B."
	w_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_sub.add_theme_font_override("font", font_semibold)
	w_sub.add_theme_font_size_override("font_size", 13)
	w_sub.add_theme_color_override("font_color", Color("#166534"))
	vb_w.add_child(w_sub)
	
	var hb_w_btns = HBoxContainer.new()
	hb_w_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_w_btns.add_theme_constant_override("separation", 16)
	
	var btn_map = Button.new()
	btn_map.text = "KEMBALI KE MAP"
	btn_map.add_theme_font_override("font", font_black)
	btn_map.add_theme_font_size_override("font_size", 13)
	var sb_bm = StyleBoxFlat.new()
	sb_bm.bg_color = Color("#e2e8f0")
	sb_bm.set_corner_radius_all(10)
	sb_bm.set_content_margin_all(8)
	btn_map.add_theme_stylebox_override("normal", sb_bm)
	btn_map.add_theme_color_override("font_color", Color("#334155"))
	btn_map.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
	hb_w_btns.add_child(btn_map)
	
	var btn_next = Button.new()
	btn_next.text = "LANJUT LEVEL 1.3"
	btn_next.add_theme_font_override("font", font_black)
	btn_next.add_theme_font_size_override("font_size", 13)
	var sb_bn = StyleBoxFlat.new()
	sb_bn.bg_color = Color("#16a34a")
	sb_bn.set_corner_radius_all(10)
	sb_bn.set_content_margin_all(8)
	btn_next.add_theme_stylebox_override("normal", sb_bn)
	btn_next.add_theme_color_override("font_color", Color("#ffffff"))
	btn_next.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
	hb_w_btns.add_child(btn_next)
	vb_w.add_child(hb_w_btns)
	
	# 2. Game Over Modal
	gameover_modal = Control.new()
	gameover_modal.name = "GameOverModal"
	gameover_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_modal.visible = false
	add_child(gameover_modal)
	
	var bd_go = ColorRect.new()
	bd_go.set_anchors_preset(Control.PRESET_FULL_RECT)
	bd_go.color = Color(0, 0, 0, 0.75)
	gameover_modal.add_child(bd_go)
	
	gameover_card = Control.new()
	gameover_card.name = "GameOverCard"
	gameover_card.size = Vector2(520, 320)
	gameover_card.pivot_offset = Vector2(260, 160)
	gameover_modal.add_child(gameover_card)
	
	var bg_go = PanelContainer.new()
	bg_go.size = Vector2(520, 320)
	var sb_go = StyleBoxFlat.new()
	sb_go.bg_color = Color("#fef2f2")
	sb_go.border_color = Color("#dc2626")
	sb_go.set_border_width_all(4)
	sb_go.set_corner_radius_all(20)
	sb_go.set_content_margin_all(24)
	sb_go.shadow_color = Color(0, 0, 0, 0.3)
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
	gameover_reason_lbl.text = "Nyawa teknisi habis!"
	gameover_reason_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameover_reason_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gameover_reason_lbl.add_theme_font_override("font", font_semibold)
	gameover_reason_lbl.add_theme_font_size_override("font_size", 14)
	gameover_reason_lbl.add_theme_color_override("font_color", Color("#991b1b"))
	vb_go.add_child(gameover_reason_lbl)
	
	var hb_go_btns = HBoxContainer.new()
	hb_go_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_go_btns.add_theme_constant_override("separation", 16)
	
	var btn_retry = Button.new()
	btn_retry.text = "COBA LAGI"
	btn_retry.add_theme_font_override("font", font_black)
	btn_retry.add_theme_font_size_override("font_size", 13)
	var sb_br = StyleBoxFlat.new()
	sb_br.bg_color = Color("#dc2626")
	sb_br.set_corner_radius_all(10)
	sb_br.set_content_margin_all(8)
	btn_retry.add_theme_stylebox_override("normal", sb_br)
	btn_retry.add_theme_color_override("font_color", Color("#ffffff"))
	btn_retry.pressed.connect(func(): get_tree().reload_current_scene())
	hb_go_btns.add_child(btn_retry)
	
	var btn_go_map = Button.new()
	btn_go_map.text = "KEMBALI KE MAP"
	btn_go_map.add_theme_font_override("font", font_black)
	btn_go_map.add_theme_font_size_override("font_size", 13)
	btn_go_map.add_theme_stylebox_override("normal", sb_bm)
	btn_go_map.add_theme_color_override("font_color", Color("#334155"))
	btn_go_map.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
	hb_go_btns.add_child(btn_go_map)
	vb_go.add_child(hb_go_btns)

func _trigger_win() -> void:
	is_game_active = false
	_play_notes([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.1, 0.22)
	win_modal.visible = true
	if win_card:
		var vp_sz_w = get_viewport_rect().size
		win_card.position = Vector2((vp_sz_w.x - win_card.size.x) / 2.0, (vp_sz_w.y - win_card.size.y) / 2.0)
		win_card.scale = Vector2(0.7, 0.7)
		win_card.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(win_card, "scale", Vector2.ONE, 0.28)
		tw.tween_property(win_card, "modulate:a", 1.0, 0.2)
		
	if win_stars_row:
		for i in range(3):
			var s_rect = win_stars_row.get_child(i) as TextureRect
			s_rect.texture = tex_star_gold if (i < hearts) else tex_star_gray

func _trigger_game_over(msg: String) -> void:
	is_game_active = false
	_play_tone(130.0, 0.35, 0.25)
	gameover_modal.visible = true
	if gameover_reason_lbl:
		gameover_reason_lbl.text = msg
	if gameover_card:
		var vp_sz_go = get_viewport_rect().size
		gameover_card.position = Vector2((vp_sz_go.x - gameover_card.size.x) / 2.0, (vp_sz_go.y - gameover_card.size.y) / 2.0)
		gameover_card.scale = Vector2(0.7, 0.7)
		gameover_card.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(gameover_card, "scale", Vector2.ONE, 0.28)
		tw.tween_property(gameover_card, "modulate:a", 1.0, 0.2)

# --- TOAST NOTIFICATIONS ---
func _build_toast_ui() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.name = "ToastPanel"
	toast_panel.visible = false
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#1e293b")
	sb.border_color = Color("#ffffff")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(12)
	toast_panel.add_theme_stylebox_override("panel", sb)
	add_child(toast_panel)
	
	toast_label = Label.new()
	toast_label.add_theme_font_override("font", font_bold)
	toast_label.add_theme_font_size_override("font_size", 13)
	toast_label.add_theme_color_override("font_color", Color.WHITE)
	toast_panel.add_child(toast_label)

func show_toast(text: String, duration: float = 2.4) -> void:
	if not toast_panel or not toast_label:
		return
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_label.text = text
	toast_panel.reset_size()
	var screen_w = get_viewport_rect().size.x
	toast_panel.position = Vector2((screen_w - toast_panel.size.x) / 2.0, 150.0)
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	
	toast_tween = create_tween()
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	toast_tween.tween_interval(duration)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.25)
	toast_tween.tween_callback(func(): toast_panel.visible = false)

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
		char_pos = Vector2(center_x - 88.0, 370.0)
		character_mascot.position = char_pos
		
	if header_ui:
		var guide_b = header_ui.get_node_or_null("GuidebookTopBtn")
		if guide_b:
			guide_b.position = Vector2(screen_w - 410.0, 23.0)
		var timer_p = header_ui.get_node_or_null("TimerPanel")
		if timer_p:
			timer_p.position.x = screen_w - 230.0
		var pause_b = header_ui.get_node_or_null("PauseBtn")
		if pause_b:
			pause_b.position.x = screen_w - 90.0
			
	if action_btn_node:
		action_btn_node.position = Vector2(screen_w - 150.0, 550.0)
		
	# Modals Centering
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

# --- SYNTH AUDIO FX ---
func _play_step_sfx(pitch_high: bool) -> void:
	if not footstep_player:
		return
	var sample_rate = 22050
	var duration = 0.035
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var freq = 680.0 if pitch_high else 540.0
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var val = sin(t * freq * TAU) * 0.15
		var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
		
	stream.data = data
	footstep_player.stream = stream
	footstep_player.play()

func _play_tone(frequency: float, duration: float, volume: float = 0.2) -> void:
	if not audio_player:
		return
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
		var env = 1.0 - (float(i) / float(num_samples))
		var val = sin(t * frequency * TAU) * volume * env
		var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _play_sweep(freq_start: float, freq_end: float, duration: float, volume: float = 0.15) -> void:
	if not audio_player:
		return
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
		var prog = float(i) / float(num_samples)
		var cur_freq = lerp(freq_start, freq_end, prog)
		var env = 1.0 - prog
		var val = sin(t * cur_freq * TAU) * volume * env
		var s16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _play_notes(freqs: Array, note_duration: float = 0.1, volume: float = 0.2) -> void:
	for f in freqs:
		_play_tone(f, note_duration, volume)
		await get_tree().create_timer(note_duration * 0.85).timeout
