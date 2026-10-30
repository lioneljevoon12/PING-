extends Control

# Nodes
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

# Preloaded Assets
var tex_rack: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/rak-kabel.png")
var tex_cable_green: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-hijau.png")
var tex_cable_yellow: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-kuning.png")
var tex_cable_blue: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-biru.png")
var tex_cable_red: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-merah.png")

var tex_diagram_straight: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/straight_opt.png")
var tex_diagram_cross: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/cross_opt.png")

var tex_joystick_pad: Texture2D = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_pad_a.png")
var tex_joystick_nub: Texture2D = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_nub_a.png")

var tex_star_gold: Texture2D = preload("res://art/ui-ux/levelpath/star_gold.png")
var tex_star_gray: Texture2D = preload("res://art/ui-ux/levelpath/star_gray.png")
var tex_router_idle: Texture2D = preload("res://art/assets/PING! Assets/Character/main-char-router.png")
var tex_frame_jam: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/generals/frame-jam.png")
var tex_vector_heart: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/generals/vector-hearts.png")

var font_black: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var font_extrabold: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_bold: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_semibold: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-SemiBold.ttf")

# Walk frames
var walk_frames: Array[Texture2D] = []
var walk_anim_timer: float = 0.0
var step_timer: float = 0.0
var step_toggle: bool = false

# Character state
var mascot_sprite: TextureRect
var carried_icon: TextureRect
var char_pos: Vector2 = Vector2.ZERO
var move_vec: Vector2 = Vector2.ZERO
var is_moving: bool = false
var walk_speed: float = 290.0
var time_passed: float = 0.0

# Gameplay State
var hearts: int = 3
var hearts_rects: Array[TextureRect] = []
var time_remaining: float = 165.0 # 02:45
var is_game_active: bool = false
var carried_cable_data = null
var sorted_cables_count: int = 0
var active_focused_cable_idx: int = 0

# Cable Definitions
var cables_data: Array[Dictionary] = []
var cable_item_nodes: Array[Control] = []
var left_rack_slots: Array[TextureRect] = []
var right_rack_slots: Array[TextureRect] = []

# Dynamic UI references
var header_ui: Control
var hearts_container: HBoxContainer
var timer_label: Label
var toast_panel: PanelContainer
var toast_label: Label
var toast_tween: Tween



var intro_modal: Control
var intro_card: Control
var guidebook_modal: Control
var pinout_modal: Control
var pinout_card: PanelContainer
var pinout_diagram_rect: TextureRect
var pinout_info_lbl: Label
var pause_modal: Control
var settings_modal: Control
var pause_card: Control
var win_modal: Control
var win_card: Control
var win_stars_row: HBoxContainer
var gameover_modal: Control
var gameover_card: Control
var gameover_reason_lbl: Label

# Interaction Prompt Pills (Figma Style)
var table_prompts_container: Control
var btn_lihat: Button
var btn_ambil: Button
var rack_prompt_left: Button
var rack_prompt_right: Button

# Joystick Variables
var joystick_zone: Control
var joystick_base: TextureRect
var joystick_nub: TextureRect
var joystick_touch_id: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var joystick_max_radius: float = 58.0

var pinout_lbl_u1: Label
var pinout_lbl_u2: Label
var pinout_grid_u1: GridContainer
var pinout_grid_u2: GridContainer
var pinout_hint_panel: PanelContainer
var pinout_hint_lbl: Label

func _ready() -> void:
	settings_modal = preload("res://scenes/settings_modal.tscn").instantiate()
	add_child(settings_modal)
	_load_walk_frames()
	_init_cables_data()
	
	_build_room_visuals()
	_build_character_mascot()
	_build_header_ui()
	_build_interaction_prompts()
	_build_joystick_ui()
	_build_pinout_modal()
	_build_guidebook_modal()
	_build_intro_modal()
	_build_endgame_modals()
	_build_toast_ui()
	
	_reposition_responsive()
	get_viewport().size_changed.connect(_reposition_responsive)
	
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-pause" in all_args:
		await get_tree().create_timer(0.4).timeout
		intro_modal.visible = false
		_open_pause_modal()
		await get_tree().create_timer(0.4).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/gameplay_pause_render.png")
		get_tree().quit()
		
	if "--screenshot-gameplay-inspect" in all_args:
		await get_tree().create_timer(0.4).timeout
		intro_modal.visible = false
		_open_pinout_modal(cables_data[1]) # Show Cross cable pinout matching Figma Screen 3
		await get_tree().create_timer(0.5).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/gameplay_inspect_render.png")
		get_tree().quit()
	
	if "--screenshot-gameplay" in all_args:
		intro_modal.visible = false
		_start_gameplay()
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/gameplay_main_render.png")
		get_tree().quit()

func _load_walk_frames() -> void:
	walk_frames.clear()
	for i in range(1, 33):
		var p = "res://art/assets/PING! Assets/Sprite animation/router walk/%d.png" % i
		if ResourceLoader.exists(p):
			var tex = load(p)
			if tex:
				walk_frames.append(tex)


func _init_cables_data() -> void:
	var straight_pins = [
		"1. Putih-Oranye", "5. Putih-Biru",
		"2. Oranye",       "6. Hijau",
		"3. Putih-Hijau",  "7. Putih-Cokelat",
		"4. Biru",         "8. Cokelat"
	]
	
	var cross_u1_pins = [
		"1. Putih-Hijau",  "5. Putih-Biru",
		"2. Hijau",        "6. Oranye",
		"3. Putih-Oranye", "7. Putih-Cokelat",
		"4. Biru",         "8. Cokelat"
	]
	
	cables_data = [
		{
			"id": 0,
			"name": "Kabel Hijau",
			"type": "Straight",
			"tex": tex_cable_green,
			"diagram": tex_diagram_straight,
			"u1_standard": "Standar T568B",
			"u2_standard": "Standar T568B",
			"u1_pins": straight_pins,
			"u2_pins": straight_pins,
			"rule_hint": "💡 Urutan warna di kedua ujung PERSIS SAMA (Straight) • Letakkan di RAK STRAIGHT!",
			"state": "on_table"
		},
		{
			"id": 1,
			"name": "Kabel Kuning",
			"type": "Cross",
			"tex": tex_cable_yellow,
			"diagram": tex_diagram_cross,
			"u1_standard": "Standar T568A",
			"u2_standard": "Standar T568B",
			"u1_pins": cross_u1_pins,
			"u2_pins": straight_pins,
			"rule_hint": "⚡ Pin 1 & 2 bertukar dengan Pin 3 & 6 (Crossover) • Letakkan di RAK CROSS!",
			"state": "on_table"
		},
		{
			"id": 2,
			"name": "Kabel Biru",
			"type": "Straight",
			"tex": tex_cable_blue,
			"diagram": tex_diagram_straight,
			"u1_standard": "Standar T568B",
			"u2_standard": "Standar T568B",
			"u1_pins": straight_pins,
			"u2_pins": straight_pins,
			"rule_hint": "💡 Urutan warna di kedua ujung PERSIS SAMA (Straight) • Letakkan di RAK STRAIGHT!",
			"state": "on_table"
		},
		{
			"id": 3,
			"name": "Kabel Merah",
			"type": "Cross",
			"tex": tex_cable_red,
			"diagram": tex_diagram_cross,
			"u1_standard": "Standar T568A",
			"u2_standard": "Standar T568B",
			"u1_pins": cross_u1_pins,
			"u2_pins": straight_pins,
			"rule_hint": "⚡ Pin 1 & 2 bertukar dengan Pin 3 & 6 (Crossover) • Letakkan di RAK CROSS!",
			"state": "on_table"
		}
	]

func _process(delta: float) -> void:
	time_passed += delta
	
	if is_game_active:
		# Timer countdown
		time_remaining = max(0.0, time_remaining - delta)
		_update_timer_display()
		if time_remaining <= 0.0:
			is_game_active = false
			_trigger_game_over("Waktu habis! Waktu penataan kabel telah berakhir.")
			return
			
		# Character Movement
		_handle_character_movement(delta)
		
		# Proximity Check with Racks & Table
		_update_interaction_prompts()
		
	# Subtle breathing or carried cable bobbing
	if carried_icon and carried_icon.visible:
		carried_icon.position.y = -46.0 + sin(time_passed * 6.0) * 4.0


func _is_room_collision(pos: Vector2, center_x: float) -> bool:
	# Character mascot collision box (feet base)
	var feet_left = pos.x + 36.0
	var feet_right = pos.x + 140.0
	var feet_top = pos.y + 55.0
	var feet_bottom = pos.y + 144.0
	
	# 1. Cable Workbench Table (Bottom Center: center_x - 230 to center_x + 230, Y: 520 to 650)
	var tbl_l = center_x - 230.0
	var tbl_r = center_x + 230.0
	var tbl_t = 515.0
	var tbl_b = 650.0
	if feet_right > tbl_l and feet_left < tbl_r:
		if feet_bottom > tbl_t and feet_top < tbl_b:
			return true
			
	# 2. Left Rack (center_x - 560 to center_x - 290, Y: 220 to 560)
	var lr_l = center_x - 560.0
	var lr_r = center_x - 290.0
	var lr_t = 300.0
	var lr_b = 560.0
	if feet_right > lr_l and feet_left < lr_r:
		if feet_bottom > lr_t and feet_top < lr_b:
			return true
			
	# 3. Right Rack (center_x + 290 to center_x + 560, Y: 220 to 560)
	var rr_l = center_x + 290.0
	var rr_r = center_x + 560.0
	var rr_t = 300.0
	var rr_b = 560.0
	if feet_right > rr_l and feet_left < rr_r:
		if feet_bottom > rr_t and feet_top < rr_b:
			return true
			
	# 4. Top Wall Obstacle (navy wall at top Y < 240)
	if feet_top < 240.0:
		return true
		
	return false

func _handle_character_movement(delta: float) -> void:
	# Combine joystick input with keyboard arrows / WASD for desktop testing
	var input_vec = move_vec
	var k_x = Input.get_axis("ui_left", "ui_right")
	var k_y = Input.get_axis("ui_up", "ui_down")
	var k_vec = Vector2(k_x, k_y)
	if k_vec.length() > 0.1:
		input_vec = k_vec.normalized()
		
	is_moving = input_vec.length() > 0.15
	
	if is_moving:
		# Direction flip
		if input_vec.x > 0.05:
			mascot_sprite.scale.x = 1.0
		elif input_vec.x < -0.05:
			mascot_sprite.scale.x = -1.0
			
		var screen_w = get_viewport_rect().size.x
		var center_x = screen_w / 2.0
		var delta_mov = input_vec * walk_speed * delta
		
		# Independent X movement test (enables smooth sliding along table and rack rims)
		var test_x = clamp(char_pos.x + delta_mov.x, center_x - 560.0, center_x + 560.0)
		if not _is_room_collision(Vector2(test_x, char_pos.y), center_x):
			char_pos.x = test_x
			
		# Independent Y movement test (stops tightly at edge of table without passing through)
		var test_y = clamp(char_pos.y + delta_mov.y, 240.0, 580.0)
		if not _is_room_collision(Vector2(char_pos.x, test_y), center_x):
			char_pos.y = test_y
			
		character_mascot.position = char_pos
		
		# Animate walk frames
		if walk_frames.size() > 0:
			walk_anim_timer += delta * 24.0
			var f_idx = int(walk_anim_timer) % walk_frames.size()
			mascot_sprite.texture = walk_frames[f_idx]
			
		# Step audio
		step_timer += delta
		if step_timer >= 0.16:
			step_timer = 0.0
			step_toggle = !step_toggle
			_play_step_sfx(step_toggle)
	else:
		# Idle pose
		if walk_frames.size() > 0:
			mascot_sprite.texture = walk_frames[0]
		mascot_sprite.scale.y = 1.0 + sin(time_passed * 3.0) * 0.03

func _update_interaction_prompts() -> void:
	var screen_w = get_viewport_rect().size.x
	var center_x = screen_w / 2.0
	
	var char_center = character_mascot.position + Vector2(128, 72)
	var table_pos = cable_table_node.position + Vector2(230, 60)
	var left_rack_pos = left_rack_node.position + Vector2(135, 170)
	var right_rack_pos = right_rack_node.position + Vector2(135, 170)
	
	var dist_table = char_center.distance_to(table_pos)
	var dist_left_rack = char_center.distance_to(left_rack_pos)
	var dist_right_rack = char_center.distance_to(right_rack_pos)
	
	# Table Prompts (Lihat & Ambil pills on left of table / cable)
	if table_prompts_container:
		if dist_table < 220.0:
			table_prompts_container.visible = true
			if carried_cable_data == null:
				var first_idx = _get_first_available_cable_idx()
				if active_focused_cable_idx < 0 or active_focused_cable_idx >= cables_data.size() or cables_data[active_focused_cable_idx]["state"] != "on_table":
					active_focused_cable_idx = first_idx
				
				if active_focused_cable_idx != -1:
					btn_ambil.text = "Ambil"
					btn_ambil.visible = true
					btn_lihat.visible = true
				else:
					btn_ambil.visible = false
					btn_lihat.visible = false
					table_prompts_container.visible = false
			else:
				btn_ambil.text = "Kembalikan"
				btn_ambil.visible = true
				btn_lihat.visible = true
		else:
			table_prompts_container.visible = false
			
	# Left Rack Prompt (Letakkan Kabel pill on right rim of left rack)
	if rack_prompt_left:
		rack_prompt_left.visible = (carried_cable_data != null and dist_left_rack < 250.0)
		
	# Right Rack Prompt (Letakkan Kabel pill on left rim of right rack)
	if rack_prompt_right:
		rack_prompt_right.visible = (carried_cable_data != null and dist_right_rack < 250.0)

func _get_first_available_cable_idx() -> int:
	for i in range(cables_data.size()):
		if cables_data[i]["state"] == "on_table":
			return i
	return -1

func _on_action_button_pressed() -> void:
	var screen_w = get_viewport_rect().size.x
	var center_x = screen_w / 2.0
	var char_center = character_mascot.position + Vector2(128, 72)
	
	var dist_table = char_center.distance_to(cable_table_node.position + Vector2(230, 60))
	var dist_left_rack = char_center.distance_to(left_rack_node.position + Vector2(135, 170))
	var dist_right_rack = char_center.distance_to(right_rack_node.position + Vector2(135, 170))
	
	if dist_table < 180.0:
		if carried_cable_data == null:
			# Pick up cable
			if active_focused_cable_idx >= 0 and active_focused_cable_idx < cables_data.size():
				_pickup_cable(active_focused_cable_idx)
		else:
			# Return carried cable to table
			_return_cable_to_table()
	elif dist_left_rack < 200.0 and carried_cable_data != null:
		_attempt_place_in_rack("Cross")
	elif dist_right_rack < 200.0 and carried_cable_data != null:
		_attempt_place_in_rack("Straight")

func _pickup_cable(c_idx: int) -> void:
	var c_data = cables_data[c_idx]
	if c_data["state"] != "on_table":
		return
		
	c_data["state"] = "carried"
	carried_cable_data = c_data
	
	# Update visual on table
	cable_item_nodes[c_idx].modulate.a = 0.2
	
	# Show carried icon floating above router
	carried_icon.texture = c_data["tex"]
	carried_icon.visible = true
	carried_icon.scale = Vector2(0.2, 0.2)
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(carried_icon, "scale", Vector2.ONE, 0.2)
	
	_play_sweep(440.0, 700.0, 0.1, 0.15)
	show_toast("Membawa %s. Periksa urutan pin lalu bawa ke rak yang tepat!" % c_data["name"])

func _return_cable_to_table() -> void:
	if carried_cable_data == null:
		return
	var c_idx = carried_cable_data["id"]
	cables_data[c_idx]["state"] = "on_table"
	cable_item_nodes[c_idx].modulate.a = 1.0
	
	carried_cable_data = null
	carried_icon.visible = false
	_play_sweep(500.0, 350.0, 0.1, 0.15)
	show_toast("Kabel dikembalikan ke meja kerja.")

func _attempt_place_in_rack(target_rack_type: String) -> void:
	if carried_cable_data == null:
		return
		
	var c_data = carried_cable_data
	var is_correct = (c_data["type"] == target_rack_type)
	
	if is_correct:
		# SUCCESS!
		_play_notes([523.25, 659.25, 783.99, 1046.5], 0.08, 0.2)
		c_data["state"] = "placed"
		carried_cable_data = null
		carried_icon.visible = false
		
		# Place visual cable sprite in rack slot
		_add_cable_to_rack_display(target_rack_type, c_data["tex"])
		
		sorted_cables_count += 1
		show_toast("BENAR! %s berhasil dikelompokkan ke Rak %s." % [c_data["name"], target_rack_type])
		
		# Check level completion
		if sorted_cables_count >= 4:
			await get_tree().create_timer(0.6).timeout
			_trigger_victory()
	else:
		# MISTAKE!
		_play_tone(140.0, 0.25, 0.25)
		hearts = max(0, hearts - 1)
		_update_hearts_display()
		
		# Shake rack
		var target_rack_node = left_rack_node if target_rack_type == "Cross" else right_rack_node
		var orig_x = target_rack_node.position.x
		var sh = create_tween()
		sh.tween_property(target_rack_node, "position:x", orig_x - 8.0, 0.04)
		sh.chain().tween_property(target_rack_node, "position:x", orig_x + 8.0, 0.06)
		sh.chain().tween_property(target_rack_node, "position:x", orig_x - 4.0, 0.05)
		sh.chain().tween_property(target_rack_node, "position:x", orig_x, 0.04)
		
		show_toast("SALAH! %s BUKAN kabel %s! Periksa urutan pin warnanya." % [c_data["name"], target_rack_type])
		
		if hearts <= 0:
			await get_tree().create_timer(0.5).timeout
			_trigger_game_over("Nyawa teknisi habis! Pelajari kembali standar kabel T568A dan T568B.")

func _add_cable_to_rack_display(rack_type: String, tex: Texture2D) -> void:
	var slots = left_rack_slots if rack_type == "Cross" else right_rack_slots
	for slot in slots:
		if not slot.visible:
			slot.texture = tex
			slot.visible = true
			slot.scale = Vector2(0.5, 0.5)
			var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(slot, "scale", Vector2.ONE, 0.2)
			break

func _update_hearts_display() -> void:
	for i in range(3):
		var heart_label = hearts_container.get_child(i) as Label
		if heart_label:
			if i < hearts:
				heart_label.text = "❤️"
				heart_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
			else:
				heart_label.text = "🖤"
				heart_label.modulate = Color(0.6, 0.6, 0.6, 0.5)

func _update_timer_display() -> void:
	var total_sec = int(time_remaining)
	var mins = total_sec / 60
	var secs = total_sec % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	if total_sec <= 30:
		timer_label.add_theme_color_override("font_color", Color("#ef4444"))
	else:
		timer_label.add_theme_color_override("font_color", Color("#4a2e2b"))

func _start_gameplay() -> void:
	is_game_active = true
	intro_modal.visible = false
	_play_sweep(440.0, 880.0, 0.15, 0.18)
	show_toast("Misi dimulai! Analisis kabel di meja dan kelompokkan ke rak yang sesuai.")

func _trigger_victory() -> void:
	is_game_active = false
	_play_notes([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.1, 0.22)
	
	# Save progress in PlayerData
	if PlayerData:
		PlayerData.set_level_stars(1, 1, hearts)
		
	win_modal.visible = true
	if win_card:
		var vp_sz_w = get_viewport_rect().size
		win_card.position = Vector2((vp_sz_w.x - win_card.size.x) / 2.0, (vp_sz_w.y - win_card.size.y) / 2.0)
		win_card.scale = Vector2(0.7, 0.7)
		win_card.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(win_card, "scale", Vector2.ONE, 0.28)
		tw.tween_property(win_card, "modulate:a", 1.0, 0.2)
	
	# Update stars in modal
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

# --- INSPECTION MODAL ---


func _open_pinout_modal(c_data: Dictionary = {}) -> void:
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
	if toast_panel:
		toast_panel.visible = false
		
	_play_sweep(523.25, 783.99, 0.1, 0.15)
	
	if c_data.is_empty():
		c_data = cables_data[1] if cables_data.size() > 1 else cables_data[0]
		
	if pinout_diagram_rect and c_data.has("diagram"):
		pinout_diagram_rect.texture = c_data["diagram"]
		
	if pinout_lbl_u1:
		if c_data.get("type") == "Cross":
			pinout_lbl_u1.text = "568A"
		else:
			pinout_lbl_u1.text = "568B"
	if pinout_lbl_u2:
		pinout_lbl_u2.text = "568B"
		
	pinout_modal.visible = true
	if pinout_card:
		var vp_size = get_viewport_rect().size
		pinout_card.position = Vector2((vp_size.x - pinout_card.size.x) / 2.0, (vp_size.y - pinout_card.size.y) / 2.0)
		pinout_card.scale = Vector2(0.85, 0.85)
		pinout_card.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(pinout_card, "scale", Vector2.ONE, 0.22)
		tw.tween_property(pinout_card, "modulate:a", 1.0, 0.18)

func _close_pinout_modal() -> void:
	_play_sweep(659.25, 440.0, 0.1, 0.15)
	if pinout_card:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(pinout_card, "scale", Vector2(0.85, 0.85), 0.12)
		tw.tween_property(pinout_card, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func(): pinout_modal.visible = false)
	else:
		pinout_modal.visible = false

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

func _open_inspect_modal(c_data: Dictionary = {}) -> void:
	if SettingsManager: SettingsManager.vibrate(35)
	_open_pinout_modal(c_data)

func _close_inspect_modal() -> void:
	_close_pinout_modal()

func _build_room_visuals() -> void:
	# Left Rack (Rak Kabel Cross)
	_setup_rack_node(left_rack_node, "Rak Kabel Cross", "#c2410c", left_rack_slots)
	# Right Rack (Rak Kabel Straight)
	_setup_rack_node(right_rack_node, "Rak Kabel Straight", "#0284c7", right_rack_slots)
	# Cable Workbench
	_setup_cable_workbench()

func _setup_rack_node(rack_root: Control, title_text: String, badge_color_hex: String, slots_array: Array[TextureRect]) -> void:
	rack_root.clip_contents = false
	rack_root.size = Vector2(270, 340)
	
	var rack_tex = TextureRect.new()
	rack_tex.texture = tex_rack
	rack_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rack_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rack_tex.size = Vector2(270, 340)
	rack_root.add_child(rack_tex)
	
	# Figma Rack Badge: White background, 3.5px border #4a2e2b, centered on top, no clipping
	var badge = PanelContainer.new()
	badge.custom_minimum_size = Vector2(210, 56)
	badge.size = Vector2(210, 56)
	badge.position = Vector2((270.0 - 210.0) / 2.0, -30.0)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0.29, 0.18, 0.17, 0.22)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 3)
	badge.add_theme_stylebox_override("panel", sb)
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
	lbl_top.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb_badge.add_child(lbl_top)
	
	var lbl_bot = Label.new()
	var type_name = "Cross" if "Cross" in title_text else "Straight"
	lbl_bot.text = type_name
	lbl_bot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_bot.add_theme_font_override("font", font_black)
	lbl_bot.add_theme_font_size_override("font_size", 16)
	lbl_bot.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb_badge.add_child(lbl_bot)
	
	# 4 shelf slots inside the rack
	slots_array.clear()
	var slot_positions = [
		Vector2(45, 60),
		Vector2(145, 60),
		Vector2(45, 170),
		Vector2(145, 170)
	]
	for sp in slot_positions:
		var slot_rect = TextureRect.new()
		slot_rect.size = Vector2(75, 75)
		slot_rect.position = sp
		slot_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_rect.pivot_offset = Vector2(37, 37)
		slot_rect.visible = false
		rack_root.add_child(slot_rect)
		slots_array.append(slot_rect)

func _select_cable_on_table(cable_idx: int) -> void:
	if cable_idx < 0 or cable_idx >= cables_data.size():
		return
	if cables_data[cable_idx]["state"] != "on_table":
		return
		
	active_focused_cable_idx = cable_idx
	_play_tone(659.25, 0.06, 0.15)
	
	# Subtle scale bounce highlight on focused cable
	var c_node = cable_item_nodes[cable_idx]
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c_node, "scale", Vector2(1.15, 1.15), 0.1)
	tw.chain().tween_property(c_node, "scale", Vector2.ONE, 0.1)
	
	# Update prompts
	if table_prompts_container:
		table_prompts_container.visible = true
		btn_ambil.text = "Ambil" if carried_cable_data == null else "Kembalikan"
		btn_ambil.visible = true
		btn_lihat.visible = true

func _setup_cable_workbench() -> void:
	cable_item_nodes.clear()
	
	# Table Base Mat
	var table_bg = PanelContainer.new()
	table_bg.size = Vector2(460, 130)
	var sb_table = StyleBoxFlat.new()
	sb_table.bg_color = Color("#e8cfb5")
	sb_table.border_color = Color("#854d0e")
	sb_table.set_border_width_all(3)
	sb_table.set_corner_radius_all(16)
	sb_table.shadow_color = Color(0, 0, 0, 0.25)
	sb_table.shadow_size = 6
	sb_table.shadow_offset = Vector2(0, 3)
	table_bg.add_theme_stylebox_override("panel", sb_table)
	cable_table_node.add_child(table_bg)
	
	# Table Label
	var table_tag = Label.new()
	table_tag.text = "MEJA KERJA KABEL UTP"
	table_tag.position = Vector2(16, 8)
	table_tag.add_theme_font_override("font", font_black)
	table_tag.add_theme_font_size_override("font_size", 12)
	table_tag.add_theme_color_override("font_color", Color("#78350f"))
	cable_table_node.add_child(table_tag)
	
	# Row of 4 Cables
	var cables_row = HBoxContainer.new()
	cables_row.position = Vector2(15, 30)
	cables_row.size = Vector2(430, 90)
	cables_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cables_row.add_theme_constant_override("separation", 15)
	cable_table_node.add_child(cables_row)
	
	for i in range(cables_data.size()):
		var c_data = cables_data[i]
		var c_box = VBoxContainer.new()
		c_box.alignment = BoxContainer.ALIGNMENT_CENTER
		c_box.add_theme_constant_override("separation", 2)
		
		var btn_cable = TextureButton.new()
		btn_cable.texture_normal = c_data["tex"]
		btn_cable.ignore_texture_size = true
		btn_cable.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn_cable.custom_minimum_size = Vector2(72, 72)
		btn_cable.pivot_offset = Vector2(36, 36)
		
		var cable_idx = i
		btn_cable.pressed.connect(func():
			_select_cable_on_table(cable_idx)
		)
		_setup_hover_scale(btn_cable, 1.1)
		c_box.add_child(btn_cable)
		
		cables_row.add_child(c_box)
		cable_item_nodes.append(c_box)

func _build_character_mascot() -> void:
	character_mascot.size = Vector2(256, 144)
	character_mascot.pivot_offset = Vector2(128, 72)
	
	mascot_sprite = TextureRect.new()
	mascot_sprite.size = Vector2(256, 144)
	mascot_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot_sprite.pivot_offset = Vector2(128, 72)
	mascot_sprite.texture = walk_frames[0] if walk_frames.size() > 0 else tex_router_idle
	character_mascot.add_child(mascot_sprite)
	
	# Floating Carried Cable Icon
	carried_icon = TextureRect.new()
	carried_icon.size = Vector2(64, 64)
	carried_icon.position = Vector2(96, -52)
	carried_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	carried_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	carried_icon.visible = false
	character_mascot.add_child(carried_icon)

func _build_header_ui() -> void:
	header_ui = Control.new()
	header_ui.name = "HeaderUI"
	header_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_ui)
	
	# 1. Back Button (<) - Big pink circular button (64x64)
	var back_btn = TextureButton.new()
	back_btn.name = "BackBtn"
	back_btn.position = Vector2(30, 18)
	back_btn.custom_minimum_size = Vector2(64, 64)
	back_btn.size = Vector2(64, 64)
	back_btn.pivot_offset = Vector2(32, 32)
	var p_back = PanelContainer.new()
	p_back.size = Vector2(64, 64)
	p_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_back = StyleBoxFlat.new()
	sb_back.bg_color = Color("#fed0cf") # Soft pastel pink
	sb_back.border_color = Color("#4a2e2b")
	sb_back.set_border_width_all(3.5)
	sb_back.set_corner_radius_all(32)
	sb_back.shadow_color = Color(0.29, 0.18, 0.17, 0.22)
	sb_back.shadow_size = 5
	sb_back.shadow_offset = Vector2(0, 3)
	p_back.add_theme_stylebox_override("panel", sb_back)
	back_btn.add_child(p_back)
	
	var lbl_back = Label.new()
	lbl_back.text = "<"
	lbl_back.size = Vector2(64, 64)
	lbl_back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_back.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_back.add_theme_font_override("font", font_black)
	lbl_back.add_theme_font_size_override("font_size", 28)
	lbl_back.add_theme_color_override("font_color", Color("#4a2e2b"))
	back_btn.add_child(lbl_back)
	back_btn.pressed.connect(_open_pause_modal)
	_setup_hover_scale(back_btn, 1.08)
	header_ui.add_child(back_btn)
	
	# 2. Hearts Panel (Health Bar) - Big cyan pill with 3 vector hearts (196x64)
	var hearts_panel = PanelContainer.new()
	hearts_panel.name = "HeartsPanel"
	hearts_panel.position = Vector2(106, 18)
	hearts_panel.custom_minimum_size = Vector2(196, 64)
	hearts_panel.size = Vector2(196, 64)
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color("#d3f4ee") # Soft mint/cyan
	sb_h.border_color = Color("#4a2e2b")
	sb_h.set_border_width_all(3.5)
	sb_h.set_corner_radius_all(32)
	sb_h.shadow_color = Color(0.29, 0.18, 0.17, 0.22)
	sb_h.shadow_size = 5
	sb_h.shadow_offset = Vector2(0, 3)
	sb_h.content_margin_left = 14
	sb_h.content_margin_right = 14
	hearts_panel.add_theme_stylebox_override("panel", sb_h)
	header_ui.add_child(hearts_panel)
	
	var hb_hearts = HBoxContainer.new()
	hb_hearts.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_hearts.add_theme_constant_override("separation", 8)
	hearts_panel.add_child(hb_hearts)
	
	hearts_rects.clear()
	for i in range(3):
		var h_rect = TextureRect.new()
		h_rect.texture = tex_vector_heart
		h_rect.custom_minimum_size = Vector2(46, 42)
		h_rect.size = Vector2(46, 42)
		h_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb_hearts.add_child(h_rect)
		hearts_rects.append(h_rect)
	
	# 3. Level Badge (Level 1) - 2-row card matching Figma (80x64)
	var lvl_panel = PanelContainer.new()
	lvl_panel.name = "LevelBadge"
	lvl_panel.position = Vector2(314, 18)
	lvl_panel.custom_minimum_size = Vector2(80, 64)
	lvl_panel.size = Vector2(80, 64)
	var sb_lvl = StyleBoxFlat.new()
	sb_lvl.bg_color = Color("#ffffff")
	sb_lvl.border_color = Color("#4a2e2b")
	sb_lvl.set_border_width_all(3.5)
	sb_lvl.set_corner_radius_all(16)
	sb_lvl.shadow_color = Color(0.29, 0.18, 0.17, 0.22)
	sb_lvl.shadow_size = 5
	sb_lvl.shadow_offset = Vector2(0, 3)
	sb_lvl.content_margin_top = 4
	sb_lvl.content_margin_bottom = 4
	lvl_panel.add_theme_stylebox_override("panel", sb_lvl)
	header_ui.add_child(lvl_panel)
	
	var vb_lvl = VBoxContainer.new()
	vb_lvl.alignment = BoxContainer.ALIGNMENT_CENTER
	vb_lvl.add_theme_constant_override("separation", -2)
	lvl_panel.add_child(vb_lvl)
	
	var lbl_lvl_title = Label.new()
	lbl_lvl_title.text = "Level"
	lbl_lvl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_lvl_title.add_theme_font_override("font", font_bold)
	lbl_lvl_title.add_theme_font_size_override("font_size", 12)
	lbl_lvl_title.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb_lvl.add_child(lbl_lvl_title)
	
	var sep_lvl = ColorRect.new()
	sep_lvl.custom_minimum_size = Vector2(48, 1.5)
	sep_lvl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sep_lvl.color = Color("#4a2e2b")
	vb_lvl.add_child(sep_lvl)
	
	var lbl_lvl_num = Label.new()
	lbl_lvl_num.text = "1"
	lbl_lvl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_lvl_num.add_theme_font_override("font", font_black)
	lbl_lvl_num.add_theme_font_size_override("font_size", 22)
	lbl_lvl_num.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb_lvl.add_child(lbl_lvl_num)
	
	# 4. Timer Panel (frame-jam + 02:45) - Big white pill (215x64)
	var timer_panel = PanelContainer.new()
	timer_panel.name = "TimerPanel"
	timer_panel.custom_minimum_size = Vector2(215, 64)
	timer_panel.size = Vector2(215, 64)
	var sb_timer = StyleBoxFlat.new()
	sb_timer.bg_color = Color("#ffffff")
	sb_timer.border_color = Color("#4a2e2b")
	sb_timer.set_border_width_all(3.5)
	sb_timer.set_corner_radius_all(32)
	sb_timer.shadow_color = Color(0.29, 0.18, 0.17, 0.22)
	sb_timer.shadow_size = 5
	sb_timer.shadow_offset = Vector2(0, 3)
	sb_timer.content_margin_left = 14
	sb_timer.content_margin_right = 16
	timer_panel.add_theme_stylebox_override("panel", sb_timer)
	header_ui.add_child(timer_panel)
	
	var hb_t = HBoxContainer.new()
	hb_t.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_t.add_theme_constant_override("separation", 10)
	timer_panel.add_child(hb_t)
	
	var icon_jam = TextureRect.new()
	icon_jam.texture = tex_frame_jam
	icon_jam.custom_minimum_size = Vector2(44, 44)
	icon_jam.size = Vector2(44, 44)
	icon_jam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_jam.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb_t.add_child(icon_jam)
	
	timer_label = Label.new()
	timer_label.text = "02:45"
	timer_label.add_theme_font_override("font", font_black)
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_label.add_theme_color_override("font_color", Color("#4a2e2b"))
	hb_t.add_child(timer_label)
	
	# 5. Pause / Menu Button (☰) - Big white rounded square (64x64)
	var pause_btn = TextureButton.new()
	pause_btn.name = "PauseBtn"
	pause_btn.custom_minimum_size = Vector2(64, 64)
	pause_btn.size = Vector2(64, 64)
	pause_btn.pivot_offset = Vector2(32, 32)
	var p_menu = PanelContainer.new()
	p_menu.size = Vector2(64, 64)
	p_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_menu = StyleBoxFlat.new()
	sb_menu.bg_color = Color("#ffffff")
	sb_menu.border_color = Color("#4a2e2b")
	sb_menu.set_border_width_all(3.5)
	sb_menu.set_corner_radius_all(18)
	sb_menu.shadow_color = Color(0.29, 0.18, 0.17, 0.22)
	sb_menu.shadow_size = 5
	sb_menu.shadow_offset = Vector2(0, 3)
	p_menu.add_theme_stylebox_override("panel", sb_menu)
	pause_btn.add_child(p_menu)
	
	var lbl_menu = Label.new()
	lbl_menu.text = "☰"
	lbl_menu.size = Vector2(64, 64)
	lbl_menu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_menu.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_menu.add_theme_font_override("font", font_black)
	lbl_menu.add_theme_font_size_override("font_size", 28)
	lbl_menu.add_theme_color_override("font_color", Color("#4a2e2b"))
	pause_btn.add_child(lbl_menu)
	pause_btn.pressed.connect(func(): _open_pause_modal())
	_setup_hover_scale(pause_btn, 1.08)
	header_ui.add_child(pause_btn)

func _build_interaction_prompts() -> void:
	# 1. Table Prompts Container (Lihat & Ambil pills on left of table)
	table_prompts_container = Control.new()
	table_prompts_container.name = "TablePrompts"
	table_prompts_container.visible = false
	table_prompts_container.size = Vector2(85, 70)
	add_child(table_prompts_container)
	
	var vb_table = VBoxContainer.new()
	vb_table.size = Vector2(85, 70)
	vb_table.add_theme_constant_override("separation", 6)
	table_prompts_container.add_child(vb_table)
	
	# Helper lambda for creating Figma pill buttons
	var create_figma_pill = func(btn_text: String, btn_size: Vector2) -> Button:
		var b = Button.new()
		b.text = btn_text
		b.custom_minimum_size = btn_size
		b.size = btn_size
		b.add_theme_font_override("font", font_black)
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", Color("#4a2e2b"))
		b.add_theme_color_override("font_hover_color", Color("#1f1412"))
		b.add_theme_color_override("font_pressed_color", Color("#000000"))
		
		var sb_norm = StyleBoxFlat.new()
		sb_norm.bg_color = Color("#fbcfe8") # Soft pastel pink matching Figma
		sb_norm.border_color = Color("#4a2e2b")
		sb_norm.set_border_width_all(2)
		sb_norm.set_corner_radius_all(11)
		sb_norm.set_content_margin_all(3)
		b.add_theme_stylebox_override("normal", sb_norm)
		
		var sb_hover = sb_norm.duplicate()
		sb_hover.bg_color = Color("#f472b6")
		b.add_theme_stylebox_override("hover", sb_hover)
		
		var sb_press = sb_norm.duplicate()
		sb_press.bg_color = Color("#db2777")
		b.add_theme_stylebox_override("pressed", sb_press)
		
		_setup_hover_scale(b, 1.08)
		return b
	
	btn_lihat = create_figma_pill.call("Lihat", Vector2(80, 26))
	btn_lihat.pressed.connect(func():
		var c = carried_cable_data if carried_cable_data != null else (cables_data[active_focused_cable_idx] if active_focused_cable_idx >= 0 and active_focused_cable_idx < cables_data.size() else cables_data[0])
		_open_pinout_modal(c)
	)
	vb_table.add_child(btn_lihat)
	
	btn_ambil = create_figma_pill.call("Ambil", Vector2(80, 26))
	btn_ambil.pressed.connect(func():
		if carried_cable_data == null:
			if active_focused_cable_idx >= 0 and active_focused_cable_idx < cables_data.size():
				_pickup_cable(active_focused_cable_idx)
		else:
			_return_cable_to_table()
	)
	vb_table.add_child(btn_ambil)
	
	# 2. Left Rack "Letakkan Kabel" Pill Button
	rack_prompt_left = create_figma_pill.call("Letakkan Kabel", Vector2(125, 28))
	rack_prompt_left.name = "RackPromptLeft"
	rack_prompt_left.visible = false
	rack_prompt_left.pressed.connect(func():
		_attempt_place_in_rack("Cross")
	)
	add_child(rack_prompt_left)
	
	# 3. Right Rack "Letakkan Kabel" Pill Button
	rack_prompt_right = create_figma_pill.call("Letakkan Kabel", Vector2(125, 28))
	rack_prompt_right.name = "RackPromptRight"
	rack_prompt_right.visible = false
	rack_prompt_right.pressed.connect(func():
		_attempt_place_in_rack("Straight")
	)
	add_child(rack_prompt_right)

func _build_joystick_ui() -> void:
	# Virtual Joystick container (bottom-left)
	joystick_zone = Control.new()
	joystick_zone.name = "JoystickZone"
	joystick_zone.size = Vector2(220, 220)
	joystick_zone.position = Vector2(50, 460)
	add_child(joystick_zone)
	
	# Style C Joystick Base Pad
	joystick_base = TextureRect.new()
	joystick_base.texture = tex_joystick_pad
	joystick_base.size = Vector2(150, 150)
	joystick_base.position = Vector2(35, 35)
	joystick_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	joystick_base.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	joystick_base.modulate = Color(1.0, 1.0, 1.0, 0.75)
	joystick_zone.add_child(joystick_base)
	
	# Style C Joystick Center Nub
	joystick_nub = TextureRect.new()
	joystick_nub.texture = tex_joystick_nub
	joystick_nub.size = Vector2(74, 74)
	joystick_nub.position = Vector2(73, 73)
	joystick_nub.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	joystick_nub.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	joystick_nub.pivot_offset = Vector2(37, 37)
	joystick_zone.add_child(joystick_nub)
	
	joystick_center = Vector2(110, 110)
	
	# Joystick touch handling
	joystick_zone.gui_input.connect(_on_joystick_input)
	if SettingsManager:
		var j_scale = SettingsManager.get_joystick_scale()
		joystick_zone.scale = Vector2(j_scale, j_scale)
		SettingsManager.joystick_size_changed.connect(func(ns: float):
			if is_instance_valid(joystick_zone):
				joystick_zone.scale = Vector2(ns, ns)
		)
	
	# Bottom-right quick action touch button (Style C circle button)
	var action_touch_btn = TextureButton.new()
	action_touch_btn.name = "ActionTouchBtn"
	action_touch_btn.texture_normal = tex_joystick_pad
	action_touch_btn.ignore_texture_size = true
	action_touch_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	action_touch_btn.size = Vector2(96, 96)
	action_touch_btn.position = Vector2(1400, 560)
	action_touch_btn.pivot_offset = Vector2(48, 48)
	action_touch_btn.modulate = Color(1.0, 1.0, 1.0, 0.85)
	
	var act_icon = Label.new()
	act_icon.text = "⚡"
	act_icon.size = Vector2(96, 96)
	act_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	act_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	act_icon.add_theme_font_size_override("font_size", 34)
	action_touch_btn.add_child(act_icon)
	
	action_touch_btn.pressed.connect(_on_action_button_pressed)
	_setup_hover_scale(action_touch_btn, 1.1)
	add_child(action_touch_btn)

func _on_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			joystick_touch_id = event.index
			_update_joystick_nub(event.position)
		elif event.index == joystick_touch_id:
			_reset_joystick()
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_id:
			_update_joystick_nub(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				joystick_touch_id = 999
				_update_joystick_nub(event.position)
			else:
				_reset_joystick()
	elif event is InputEventMouseMotion:
		if joystick_touch_id == 999:
			_update_joystick_nub(event.position)

func _update_joystick_nub(touch_pos: Vector2) -> void:
	var diff = touch_pos - joystick_center
	var dist = diff.length()
	if dist > joystick_max_radius:
		diff = diff.normalized() * joystick_max_radius
	joystick_nub.position = joystick_center + diff - Vector2(37, 37)
	move_vec = diff / joystick_max_radius

func _reset_joystick() -> void:
	joystick_touch_id = -1
	move_vec = Vector2.ZERO
	var t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(joystick_nub, "position", joystick_center - Vector2(37, 37), 0.1)

# --- INSPECTION MODAL (Screen 3 in Mockup) ---


func _build_pinout_modal() -> void:
	pinout_modal = Control.new()
	pinout_modal.name = "PinoutModal"
	pinout_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	pinout_modal.visible = false
	add_child(pinout_modal)
	
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.65)
	backdrop.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			_close_pinout_modal()
	)
	pinout_modal.add_child(backdrop)
	
	# Modal Card (Figma Style)
	pinout_card = PanelContainer.new()
	pinout_card.name = "PinoutCard"
	pinout_card.size = Vector2(760, 360)
	pinout_card.pivot_offset = Vector2(380, 180)
	var sb_card = StyleBoxFlat.new()
	sb_card.bg_color = Color("#fffdf7") # Warm cream matching Figma
	sb_card.border_color = Color("#4a2e2b") # Dark brown matching Figma
	sb_card.set_border_width_all(3)
	sb_card.set_corner_radius_all(18)
	sb_card.shadow_color = Color(0, 0, 0, 0.3)
	sb_card.shadow_size = 12
	sb_card.shadow_offset = Vector2(0, 4)
	pinout_card.add_theme_stylebox_override("panel", sb_card)
	pinout_modal.add_child(pinout_card)
	
	var vb_main = VBoxContainer.new()
	vb_main.add_theme_constant_override("separation", 0)
	pinout_card.add_child(vb_main)
	
	# Header Panel (Figma lavender bar)
	var header_panel = PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(754, 48)
	var sb_hdr = StyleBoxFlat.new()
	sb_hdr.bg_color = Color("#e8daf8") # Soft lavender matching Figma
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
	
	# Circular Close Button at top-right
	var close_btn = Button.new()
	close_btn.text = "\u2715"
	close_btn.position = Vector2(754 - 44, 7)
	close_btn.size = Vector2(34, 34)
	close_btn.custom_minimum_size = Vector2(34, 34)
	close_btn.pivot_offset = Vector2(17, 17)
	var sb_close = StyleBoxFlat.new()
	sb_close.bg_color = Color("#fddede") # Soft peach/pink matching Figma
	sb_close.border_color = Color("#4a2e2b")
	sb_close.set_border_width_all(2.5)
	sb_close.set_corner_radius_all(17)
	close_btn.add_theme_stylebox_override("normal", sb_close)
	var sb_close_h = sb_close.duplicate()
	sb_close_h.bg_color = Color("#fca5a5")
	close_btn.add_theme_stylebox_override("hover", sb_close_h)
	close_btn.add_theme_font_override("font", font_black)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	close_btn.pressed.connect(_close_pinout_modal)
	_setup_hover_scale(close_btn, 1.15)
	h_box_hdr.add_child(close_btn)
	
	# Content Area
	var content_margin = MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_top", 16)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_bottom", 20)
	vb_main.add_child(content_margin)
	
	# Dashed inner box
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
	
	pinout_lbl_u1 = Label.new()
	pinout_lbl_u1.text = "568A"
	pinout_lbl_u1.custom_minimum_size = Vector2(80, 0)
	pinout_lbl_u1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pinout_lbl_u1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pinout_lbl_u1.add_theme_font_override("font", font_black)
	pinout_lbl_u1.add_theme_font_size_override("font_size", 20)
	pinout_lbl_u1.add_theme_color_override("font_color", Color("#4a2e2b"))
	hb_content.add_child(pinout_lbl_u1)
	
	pinout_diagram_rect = TextureRect.new()
	pinout_diagram_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pinout_diagram_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pinout_diagram_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pinout_diagram_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pinout_diagram_rect.custom_minimum_size = Vector2(460, 230)
	pinout_diagram_rect.texture = tex_diagram_cross
	hb_content.add_child(pinout_diagram_rect)
	
	pinout_lbl_u2 = Label.new()
	pinout_lbl_u2.text = "568B"
	pinout_lbl_u2.custom_minimum_size = Vector2(80, 0)
	pinout_lbl_u2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pinout_lbl_u2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pinout_lbl_u2.add_theme_font_override("font", font_black)
	pinout_lbl_u2.add_theme_font_size_override("font_size", 20)
	pinout_lbl_u2.add_theme_color_override("font_color", Color("#4a2e2b"))
	hb_content.add_child(pinout_lbl_u2)

func _build_guidebook_modal() -> void:
	guidebook_modal = preload("res://scenes/guidebook.tscn").instantiate()
	guidebook_modal.name = "GuidebookModal"
	guidebook_modal.visible = false
	add_child(guidebook_modal)

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
	
	var card = PanelContainer.new()
	card.name = "IntroCard"
	card.size = Vector2(620, 360)
	card.pivot_offset = Vector2(310, 180)
	intro_card = card
	var vp_sz_i = get_viewport_rect().size
	card.position = Vector2((vp_sz_i.x - card.size.x) / 2.0, (vp_sz_i.y - card.size.y) / 2.0)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fffbeb") # Warm cream matching mockup
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(24)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 12
	card.add_theme_stylebox_override("panel", sb)
	intro_modal.add_child(card)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vb)
	
	var title = Label.new()
	title.text = "Level 1.1: Membedakan Kabel Straight dan Cross"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font_black)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb.add_child(title)
	
	var desc = Label.new()
	desc.text = "Persiapan infrastruktur fisik dimulai!\n\nBedakan mana kabel Straight dan mana kabel Cross dengan memeriksa urutan pin warnanya, lalu kelompokkan ke dalam rak sesuai dengan namanya agar siap digunakan teknisi jaringan!"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_override("font", font_semibold)
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color("#78350f"))
	vb.add_child(desc)
	
	var btn_start = Button.new()
	btn_start.text = "MULAI MISI"
	btn_start.custom_minimum_size = Vector2(200, 48)
	btn_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_start.add_theme_font_override("font", font_black)
	btn_start.add_theme_font_size_override("font_size", 16)
	
	var sb_start = StyleBoxFlat.new()
	sb_start.bg_color = Color("#99f6e4") # Teal button matching mockup
	sb_start.border_color = Color("#0f766e")
	sb_start.set_border_width_all(3)
	sb_start.set_corner_radius_all(14)
	btn_start.add_theme_stylebox_override("normal", sb_start)
	btn_start.add_theme_color_override("font_color", Color("#115e59"))
	
	btn_start.pressed.connect(_start_gameplay)
	_setup_hover_scale(btn_start, 1.08)
	vb.add_child(btn_start)

# --- ENDGAME & PAUSE MODALS ---
func _build_endgame_modals() -> void:
	# Victory Modal
	win_modal = Control.new()
	win_modal.name = "WinModal"
	win_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_modal.visible = false
	add_child(win_modal)
	
	var bd_win = ColorRect.new()
	bd_win.set_anchors_preset(Control.PRESET_FULL_RECT)
	bd_win.color = Color(0, 0, 0, 0.75)
	win_modal.add_child(bd_win)
	
	var w_card = PanelContainer.new()
	w_card.name = "WinCard"
	w_card.size = Vector2(560, 360)
	w_card.pivot_offset = Vector2(280, 180)
	win_card = w_card
	var sb_win = StyleBoxFlat.new()
	sb_win.bg_color = Color("#f0fdf4")
	sb_win.border_color = Color("#16a34a")
	sb_win.set_border_width_all(4)
	sb_win.set_corner_radius_all(20)
	sb_win.set_content_margin_all(24)
	w_card.add_theme_stylebox_override("panel", sb_win)
	win_modal.add_child(w_card)
	
	var vb_w = VBoxContainer.new()
	vb_w.alignment = BoxContainer.ALIGNMENT_CENTER
	vb_w.add_theme_constant_override("separation", 14)
	w_card.add_child(vb_w)
	
	var w_title = Label.new()
	w_title.text = "MISI SELESAI!"
	w_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_title.add_theme_font_override("font", font_black)
	w_title.add_theme_font_size_override("font_size", 24)
	w_title.add_theme_color_override("font_color", Color("#15803d"))
	vb_w.add_child(w_title)
	
	var stars_row = HBoxContainer.new()
	stars_row.name = "WinStarsRow"
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_row.add_theme_constant_override("separation", 12)
	win_stars_row = stars_row
	for i in range(3):
		var star_r = TextureRect.new()
		star_r.texture = tex_star_gold
		star_r.custom_minimum_size = Vector2(44, 44)
		star_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stars_row.add_child(star_r)
	vb_w.add_child(stars_row)
	
	var w_sub = Label.new()
	w_sub.text = "Hebat! Semua kabel Straight dan Cross berhasil dikelompokkan dengan benar ke dalam rak hardware."
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
	btn_next.text = "LANJUT LEVEL 1.2"
	btn_next.add_theme_font_override("font", font_black)
	btn_next.add_theme_font_size_override("font_size", 13)
	var sb_bn = StyleBoxFlat.new()
	sb_bn.bg_color = Color("#16a34a")
	sb_bn.set_corner_radius_all(10)
	sb_bn.set_content_margin_all(8)
	btn_next.add_theme_stylebox_override("normal", sb_bn)
	btn_next.add_theme_color_override("font_color", Color("#ffffff"))
	btn_next.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/gameplay/level_1_2.tscn"))
	hb_w_btns.add_child(btn_next)
	vb_w.add_child(hb_w_btns)
	
	# Game Over Modal
	gameover_modal = Control.new()
	gameover_modal.name = "GameOverModal"
	gameover_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_modal.visible = false
	add_child(gameover_modal)
	
	var bd_go = ColorRect.new()
	bd_go.set_anchors_preset(Control.PRESET_FULL_RECT)
	bd_go.color = Color(0, 0, 0, 0.75)
	gameover_modal.add_child(bd_go)
	
	var g_card = PanelContainer.new()
	g_card.name = "GameOverCard"
	g_card.size = Vector2(520, 320)
	g_card.pivot_offset = Vector2(260, 160)
	gameover_card = g_card
	var sb_go = StyleBoxFlat.new()
	sb_go.bg_color = Color("#fef2f2")
	sb_go.border_color = Color("#dc2626")
	sb_go.set_border_width_all(4)
	sb_go.set_corner_radius_all(20)
	sb_go.set_content_margin_all(24)
	g_card.add_theme_stylebox_override("panel", sb_go)
	gameover_modal.add_child(g_card)
	
	var vb_go = VBoxContainer.new()
	vb_go.alignment = BoxContainer.ALIGNMENT_CENTER
	vb_go.add_theme_constant_override("separation", 14)
	g_card.add_child(vb_go)
	
	var go_title = Label.new()
	go_title.text = "MISI GAGAL"
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_title.add_theme_font_override("font", font_black)
	go_title.add_theme_font_size_override("font_size", 24)
	go_title.add_theme_color_override("font_color", Color("#dc2626"))
	vb_go.add_child(go_title)
	
	var go_reason = Label.new()
	go_reason.name = "GameOverReason"
	go_reason.text = "Nyawa teknisi habis!"
	go_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	go_reason.add_theme_font_override("font", font_semibold)
	go_reason.add_theme_font_size_override("font_size", 14)
	gameover_reason_lbl = go_reason
	go_reason.add_theme_color_override("font_color", Color("#991b1b"))
	vb_go.add_child(go_reason)
	
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
	
	# Pause Modal
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
	
	var p_card = PanelContainer.new()
	p_card.name = "PauseCard"
	p_card.size = Vector2(460, 365)
	p_card.pivot_offset = Vector2(230, 182)
	pause_card = p_card
	var sb_p = StyleBoxFlat.new()
	sb_p.bg_color = Color("#fffdf7") # Warm cream
	sb_p.border_color = Color("#4a2e2b")
	sb_p.set_border_width_all(3.5)
	sb_p.set_corner_radius_all(20)
	sb_p.set_content_margin_all(24)
	sb_p.shadow_color = Color(0, 0, 0, 0.3)
	sb_p.shadow_size = 14
	sb_p.shadow_offset = Vector2(0, 4)
	p_card.add_theme_stylebox_override("panel", sb_p)
	pause_modal.add_child(p_card)
	
	var vb_p = VBoxContainer.new()
	vb_p.add_theme_constant_override("separation", 12)
	p_card.add_child(vb_p)
	
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
	btn_p_restart.add_theme_stylebox_override("normal", sb_bm)
	btn_p_restart.add_theme_color_override("font_color", Color("#334155"))
	btn_p_restart.pressed.connect(func(): get_tree().reload_current_scene())
	vb_p.add_child(btn_p_restart)
	
	var btn_p_settings = Button.new()
	btn_p_settings.text = "PENGATURAN"
	btn_p_settings.add_theme_font_override("font", font_black)
	btn_p_settings.add_theme_font_size_override("font_size", 13)
	btn_p_settings.add_theme_stylebox_override("normal", sb_bm)
	btn_p_settings.add_theme_color_override("font_color", Color("#4a2e2b"))
	btn_p_settings.pressed.connect(func():
		if settings_modal:
			settings_modal.open()
	)
	vb_p.add_child(btn_p_settings)
	
	var btn_p_exit = Button.new()
	btn_p_exit.text = "KELUAR KE PETA LEVEL"
	btn_p_exit.add_theme_font_override("font", font_black)
	btn_p_exit.add_theme_font_size_override("font_size", 13)
	btn_p_exit.add_theme_stylebox_override("normal", sb_bm)
	btn_p_exit.add_theme_color_override("font_color", Color("#dc2626"))
	btn_p_exit.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_path.tscn"))
	vb_p.add_child(btn_p_exit)

func _build_toast_ui() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.name = "ToastPanel"
	toast_panel.modulate.a = 0.0
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb_t = StyleBoxFlat.new()
	sb_t.bg_color = Color(0.1, 0.1, 0.15, 0.92)
	sb_t.border_color = Color("#ffffff")
	sb_t.set_border_width_all(2)
	sb_t.set_corner_radius_all(16)
	sb_t.set_content_margin_all(10)
	toast_panel.add_theme_stylebox_override("panel", sb_t)
	
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_override("font", font_extrabold)
	toast_label.add_theme_font_size_override("font_size", 13)
	toast_label.add_theme_color_override("font_color", Color("#ffffff"))
	toast_panel.add_child(toast_label)
	add_child(toast_panel)

func show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_panel.reset_size()
	var screen_w = get_viewport_rect().size.x
	toast_panel.position = Vector2((screen_w - toast_panel.size.x) / 2.0, 110.0)
	
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	toast_panel.scale = Vector2(0.9, 0.9)
	toast_tween = create_tween().set_parallel(true)
	toast_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.18)
	toast_tween.tween_property(toast_panel, "scale", Vector2.ONE, 0.18)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(2.6)
	fade_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.25)
	fade_tween.chain().tween_callback(func(): toast_panel.visible = false)


func _reposition_responsive() -> void:
	var vp_sz = get_viewport_rect().size
	var screen_w = vp_sz.x
	var center_x = screen_w / 2.0
	
	# Center DoorArch
	if door_arch:
		door_arch.position = Vector2(center_x - 164.0, 46.0)
		door_arch.size = Vector2(328.0, 200.0)
		
	# Center Potted Plant
	if potted_plant:
		potted_plant.position = Vector2(center_x + 180.0, 70.0)
		potted_plant.size = Vector2(120.0, 180.0)
		
	# Left Rack
	if left_rack_node:
		left_rack_node.position = Vector2(center_x - 560.0, 220.0)
		left_rack_node.size = Vector2(270.0, 340.0)
		
	# Right Rack
	if right_rack_node:
		right_rack_node.position = Vector2(center_x + 290.0, 220.0)
		right_rack_node.size = Vector2(270.0, 340.0)
		
	# Cable Table (Bottom Center)
	if cable_table_node:
		cable_table_node.position = Vector2(center_x - 230.0, 520.0)
		cable_table_node.size = Vector2(460.0, 130.0)
		
	# Table Prompts (Lihat & Ambil pills on left of table)
	if table_prompts_container and cable_table_node:
		table_prompts_container.position = Vector2(cable_table_node.position.x - 90.0, cable_table_node.position.y + 40.0)
		
	# Left Rack Prompt ("Letakkan Kabel" on right rim of left rack)
	if rack_prompt_left and left_rack_node:
		rack_prompt_left.position = Vector2(left_rack_node.position.x + 276.0, left_rack_node.position.y + 115.0)
		
	# Right Rack Prompt ("Letakkan Kabel" on left rim of right rack)
	if rack_prompt_right and right_rack_node:
		rack_prompt_right.position = Vector2(right_rack_node.position.x - 132.0, right_rack_node.position.y + 115.0)
		
	# Character Mascot initial placement
	if char_pos == Vector2.ZERO:
		char_pos = Vector2(center_x - 128.0, 270.0)
		character_mascot.position = char_pos
		
	# Header Elements
	if header_ui:
		var back_b = header_ui.get_node_or_null("BackBtn")
		var hearts_p = header_ui.get_node_or_null("HeartsPanel")
		var lvl_p = header_ui.get_node_or_null("LevelBadge")
		var timer_p = header_ui.get_node_or_null("TimerPanel")
		var pause_b = header_ui.get_node_or_null("PauseBtn")
		
		if back_b: back_b.position = Vector2(30.0, 18.0)
		if hearts_p: hearts_p.position = Vector2(106.0, 18.0)
		if lvl_p: lvl_p.position = Vector2(314.0, 18.0)
		
		if pause_b: pause_b.position = Vector2(screen_w - 94.0, 18.0)
		if timer_p: timer_p.position = Vector2(screen_w - 325.0, 18.0)
	
	if pinout_card:
		pinout_card.position = Vector2((vp_sz.x - pinout_card.size.x) / 2.0, (vp_sz.y - pinout_card.size.y) / 2.0)
		
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
		var t = float(i) / sample_rate
		var envelope = exp(-t * 90.0)
		var val = sin(t * freq * TAU) * envelope * 0.15
		var int_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
	stream.data = data
	footstep_player.stream = stream
	footstep_player.play()

func _play_tone(frequency: float, duration: float, volume: float = 0.2) -> void:
	var sample_rate = 44100
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = sin((float(i) / num_samples) * PI)
		var sample_val = sin(t * frequency * TAU) * envelope * volume
		var int_val = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _play_sweep(start_f: float, end_f: float, duration: float, volume: float = 0.2) -> void:
	var sample_rate = 44100
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = t / duration
		var freq = lerp(start_f, end_f, progress)
		var envelope = sin(progress * PI)
		var sample_val = sin(t * freq * TAU) * envelope * volume
		var int_val = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _play_notes(notes: Array[float], note_duration: float, volume: float = 0.2) -> void:
	var sample_rate = 44100
	var total_duration = note_duration * notes.size()
	var num_samples = int(sample_rate * total_duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t_total = float(i) / sample_rate
		var note_idx = clamp(int(t_total / note_duration), 0, notes.size() - 1)
		var freq = notes[note_idx]
		var t_note = fmod(t_total, note_duration)
		var envelope = exp(-t_note * 12.0)
		var sample_val = sin(t_note * freq * TAU) * envelope * volume
		var int_val = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
	stream.data = data
	audio_player.stream = stream
	audio_player.play()
