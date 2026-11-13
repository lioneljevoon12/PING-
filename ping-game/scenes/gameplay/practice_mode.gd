extends Control

# Mode Latihan (Practice Mode) - Interactive Playable FTUE Tutorial
# Stage 1 Level 1 Concept: Perbedaan Kabel Straight vs Cross
# - Interactive step-by-step guided tutorial (First Time User Experience)
# - Tanpa batasan waktu (Waktu Santai)
# - Tanpa penalti Game Over (Bebas Eksplorasi)
# - Animated Guide Arrow & visual pulsing targets
# - Touch-friendly Action Pills & Virtual Joystick
# - Modal Buku Teori & Dialog Selesai

const CloseButtonScene = preload("res://scenes/close_button.tscn")
const PauseModalScene = preload("res://scenes/pause_modal.tscn")

# Preloaded Textures
var tex_rack: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/rak-kabel.png")
var tex_cable_green: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-hijau.png")
var tex_cable_yellow: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-kuning.png")
var tex_cable_blue: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-biru.png")
var tex_cable_red: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/kabel-merah.png")

var tex_joystick_pad: Texture2D = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_pad_a.png")
var tex_joystick_nub: Texture2D = preload("res://art/assets/PING! Assets/mobile-controls-1/Sprites/Style C/Default/joystick_circle_nub_a.png")
var tex_router_idle: Texture2D = preload("res://art/assets/PING! Assets/Character/main-char-router.png")
var tex_star_gold: Texture2D = preload("res://art/ui-ux/levelpath/star_gold.png")

var font_black: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var font_extrabold: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_bold: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_semibold: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-SemiBold.ttf")

# Scene Node References
@onready var background: TextureRect = %Background
@onready var door_arch: TextureRect = %DoorArch
@onready var potted_plant: TextureRect = %PottedPlant
@onready var room_container: Control = %RoomContainer
@onready var left_rack_node: Control = %LeftRack
@onready var right_rack_node: Control = %RightRack
@onready var cable_table_node: Control = %CableTable
@onready var character_mascot: Control = %CharacterMascot
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var footstep_player: AudioStreamPlayer = %FootstepPlayer

# Walk Frames & Movement
var walk_frames: Array[Texture2D] = []
var walk_anim_timer: float = 0.0
var step_timer: float = 0.0
var step_toggle: bool = false
var walk_speed: float = 290.0

var mascot_sprite: TextureRect
var carried_icon: TextureRect
var char_pos: Vector2 = Vector2.ZERO
var move_vec: Vector2 = Vector2.ZERO
var is_moving: bool = false
var time_passed: float = 0.0
var distance_traveled: float = 0.0

# Mobile Joystick
var joystick_base: TextureRect
var joystick_nub: TextureRect
var is_dragging_joystick: bool = false
var joystick_touch_id: int = -1

# Cable Practice Data (4 cables: 2 Straight, 2 Cross)
var cables_data: Array[Dictionary] = []
var cable_item_nodes: Array[Control] = []
var carried_cable_data = null
var sorted_cables_count: int = 0
var active_focused_cable_idx: int = 0

var left_rack_slots: Array[TextureRect] = []
var right_rack_slots: Array[TextureRect] = []

# Interactive Tutorial Steps:
# 0: Gerakkan Karakter
# 1: Dekati Meja & Ambil Kabel Straight (PC <-> Switch)
# 2: Bawa ke Rak Kiri (Straight)
# 3: Kembali ke Meja & Ambil Kabel Cross (PC <-> PC)
# 4: Bawa ke Rak Kanan (Cross)
# 5: Selesai / Bebas Sortir Sisa Kabel
enum TutorialStep {
	MOVE_CHARACTER = 0,
	PICK_STRAIGHT = 1,
	DELIVER_STRAIGHT = 2,
	PICK_CROSS = 3,
	DELIVER_CROSS = 4,
	FREE_PLAY_OR_DONE = 5
}
var current_step: int = TutorialStep.MOVE_CHARACTER

# UI Elements
var header_ui: Control
var step_badge_label: Label
var hint_pill: PanelContainer
var hint_label: Label
var guide_arrow: Control
var guide_arrow_label: Label
var guide_arrow_tween: Tween

var tutorial_modal: Control
var pause_modal: Control
var complete_modal: Control

var table_prompt_pill: PanelContainer
var left_rack_prompt_pill: PanelContainer
var right_rack_prompt_pill: PanelContainer

var is_modal_open: bool = false

func _ready() -> void:
	_load_walk_frames()
	_init_cable_practice_data()
	_build_room_visuals()
	_build_character()
	_build_mobile_controls()
	_build_header_ui()
	_build_floating_hints()
	_build_guide_arrow()
	_build_interaction_pills()
	_build_tutorial_modal()
	_build_completion_modal()
	_build_pause_modal()

	_reposition_responsive()
	get_viewport().size_changed.connect(_reposition_responsive)

	_apply_step(TutorialStep.MOVE_CHARACTER)

func _process(delta: float) -> void:
	time_passed += delta
	if is_modal_open:
		move_vec = Vector2.ZERO
		return

	_handle_movement(delta)
	_update_proximity_and_hints()
	_update_guide_arrow_position()

func _load_walk_frames() -> void:
	walk_frames.clear()
	for i in range(1, 33):
		var p = "res://art/assets/PING! Assets/Sprite animation/router walk/%d.png" % i
		if ResourceLoader.exists(p):
			var tex = load(p)
			if tex is Texture2D:
				walk_frames.append(tex)
	if walk_frames.is_empty():
		walk_frames.append(tex_router_idle)

func _init_cable_practice_data() -> void:
	cables_data = [
		{
			"id": "c1",
			"name": "PC ↔ Switch",
			"dev_a": "PC",
			"dev_b": "Switch",
			"type": "straight",
			"tex": tex_cable_green,
			"color": Color("#10b981")
		},
		{
			"id": "c2",
			"name": "PC ↔ PC",
			"dev_a": "PC",
			"dev_b": "PC",
			"type": "cross",
			"tex": tex_cable_yellow,
			"color": Color("#f59e0b")
		},
		{
			"id": "c3",
			"name": "Switch ↔ Router",
			"dev_a": "Switch",
			"dev_b": "Router",
			"type": "straight",
			"tex": tex_cable_blue,
			"color": Color("#3b82f6")
		},
		{
			"id": "c4",
			"name": "Switch ↔ Switch",
			"dev_a": "Switch",
			"dev_b": "Switch",
			"type": "cross",
			"tex": tex_cable_red,
			"color": Color("#ef4444")
		}
	]
	sorted_cables_count = 0
	carried_cable_data = null
	active_focused_cable_idx = 0
	distance_traveled = 0.0

# --- ROOM VISUALS ---
func _build_room_visuals() -> void:
	# 1. Left Rack: Straight
	_setup_rack_panel(left_rack_node, "RAK KABEL STRAIGHT", "Untuk 2 Perangkat Berbeda (PC ↔ Switch)", Color("#10b981"), Color("#047857"), left_rack_slots)

	# 2. Right Rack: Cross
	_setup_rack_panel(right_rack_node, "RAK KABEL CROSS", "Untuk 2 Perangkat Sejenis (PC ↔ PC)", Color("#f59e0b"), Color("#b45309"), right_rack_slots)

	# 3. Cable Table in Middle
	_setup_cable_table()

func _setup_rack_panel(rack_root: Control, title: String, subtitle: String, accent_col: Color, border_col: Color, slots_array: Array[TextureRect]) -> void:
	for c in rack_root.get_children():
		c.queue_free()
	slots_array.clear()

	var rack_tex = TextureRect.new()
	rack_tex.texture = tex_rack
	rack_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rack_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rack_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	rack_root.add_child(rack_tex)

	# Top Badge Header
	var badge = PanelContainer.new()
	badge.position = Vector2(10, -32)
	badge.custom_minimum_size = Vector2(250, 30)
	var sb_b = StyleBoxFlat.new()
	sb_b.bg_color = accent_col
	sb_b.border_color = border_col
	sb_b.set_border_width_all(2)
	sb_b.set_corner_radius_all(10)
	sb_b.set_content_margin_all(4)
	badge.add_theme_stylebox_override("panel", sb_b)

	var l_title = Label.new()
	l_title.text = title
	l_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_title.add_theme_font_override("font", font_black)
	l_title.add_theme_font_size_override("font_size", 12)
	l_title.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(l_title)
	rack_root.add_child(badge)

	# 2 Slots for cables on rack
	for s_idx in range(2):
		var slot_tr = TextureRect.new()
		slot_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_tr.size = Vector2(80, 56)
		slot_tr.position = Vector2(95, 75 + s_idx * 90)
		slot_tr.modulate = Color(1, 1, 1, 0)
		rack_root.add_child(slot_tr)
		slots_array.append(slot_tr)

func _setup_cable_table() -> void:
	for c in cable_table_node.get_children():
		c.queue_free()
	cable_item_nodes.clear()

	var table_bg = PanelContainer.new()
	table_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#e5d0b1")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	table_bg.add_theme_stylebox_override("panel", sb)
	cable_table_node.add_child(table_bg)

	var table_lbl = Label.new()
	table_lbl.text = "MEJA PERSIAPAN KABEL"
	table_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_lbl.position = Vector2(0, 10)
	table_lbl.size = Vector2(cable_table_node.size.x, 20)
	table_lbl.add_theme_font_override("font", font_black)
	table_lbl.add_theme_font_size_override("font_size", 12)
	table_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
	cable_table_node.add_child(table_lbl)

	var cables_hbox = HBoxContainer.new()
	cables_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cables_hbox.add_theme_constant_override("separation", 16)
	cables_hbox.position = Vector2(20, 38)
	cables_hbox.size = Vector2(cable_table_node.size.x - 40, 80)
	cable_table_node.add_child(cables_hbox)

	for i in range(cables_data.size()):
		var c_data = cables_data[i]
		var item_card = PanelContainer.new()
		item_card.custom_minimum_size = Vector2(88, 74)
		var sb_i = StyleBoxFlat.new()
		sb_i.bg_color = Color("#ffffff")
		sb_i.border_color = c_data["color"]
		sb_i.set_border_width_all(2)
		sb_i.set_corner_radius_all(10)
		sb_i.set_content_margin_all(4)
		item_card.add_theme_stylebox_override("panel", sb_i)

		var vb = VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 2)
		item_card.add_child(vb)

		var tr = TextureRect.new()
		tr.texture = c_data["tex"]
		tr.custom_minimum_size = Vector2(48, 36)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vb.add_child(tr)

		var lbl = Label.new()
		lbl.text = c_data["name"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", font_bold)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color("#1e293b"))
		vb.add_child(lbl)

		cables_hbox.add_child(item_card)
		cable_item_nodes.append(item_card)

# --- CHARACTER SETUP ---
func _build_character() -> void:
	character_mascot.pivot_offset = Vector2(110, 60)

	mascot_sprite = TextureRect.new()
	mascot_sprite.texture = tex_router_idle
	mascot_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot_sprite.custom_minimum_size = Vector2(320, 176)
	mascot_sprite.size = Vector2(320, 176)
	mascot_sprite.position = Vector2(-50, -28)
	if PlayerData:
		mascot_sprite.modulate = PlayerData.get_active_skin_color()
	character_mascot.add_child(mascot_sprite)

	# Carried cable icon floating above head
	carried_icon = TextureRect.new()
	carried_icon.custom_minimum_size = Vector2(48, 36)
	carried_icon.size = Vector2(48, 36)
	carried_icon.position = Vector2(86, -30)
	carried_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	carried_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	carried_icon.visible = false
	character_mascot.add_child(carried_icon)

	char_pos = character_mascot.position

# --- FLOATING HINT & GUIDE ARROW ---
func _build_floating_hints() -> void:
	hint_pill = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#1e293b")
	sb.border_color = Color("#f59e0b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	hint_pill.add_theme_stylebox_override("panel", sb)

	hint_label = Label.new()
	hint_label.text = "👉 Cobalah gerakkan karaktermu dengan tombol WASD atau Virtual Joystick!"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_override("font", font_extrabold)
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color("#fef08a"))
	hint_pill.add_child(hint_label)

	add_child(hint_pill)

func _build_guide_arrow() -> void:
	guide_arrow = Control.new()
	guide_arrow.custom_minimum_size = Vector2(160, 50)
	guide_arrow.size = Vector2(160, 50)
	guide_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pill = PanelContainer.new()
	pill.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ef4444")
	sb.border_color = Color("#ffffff")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 6
	pill.add_theme_stylebox_override("panel", sb)
	guide_arrow.add_child(pill)

	guide_arrow_label = Label.new()
	guide_arrow_label.text = "⬇ DI SINI"
	guide_arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	guide_arrow_label.add_theme_font_override("font", font_black)
	guide_arrow_label.add_theme_font_size_override("font_size", 13)
	guide_arrow_label.add_theme_color_override("font_color", Color.WHITE)
	pill.add_child(guide_arrow_label)

	add_child(guide_arrow)

	# Bouncing animation
	guide_arrow_tween = create_tween().set_loops()
	guide_arrow_tween.tween_property(guide_arrow, "position:y", -10.0, 0.4).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	guide_arrow_tween.tween_property(guide_arrow, "position:y", 10.0, 0.4).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _update_guide_arrow_position() -> void:
	if not guide_arrow or not guide_arrow.visible:
		return

	var target_pos = Vector2.ZERO
	match current_step:
		TutorialStep.MOVE_CHARACTER:
			target_pos = char_pos + Vector2(40, -60)
		TutorialStep.PICK_STRAIGHT, TutorialStep.PICK_CROSS:
			target_pos = cable_table_node.position + Vector2(cable_table_node.size.x / 2.0 - 80, -56)
		TutorialStep.DELIVER_STRAIGHT:
			target_pos = left_rack_node.position + Vector2(left_rack_node.size.x / 2.0 - 80, -60)
		TutorialStep.DELIVER_CROSS:
			target_pos = right_rack_node.position + Vector2(right_rack_node.size.x / 2.0 - 80, -60)
		_:
			guide_arrow.visible = false
			return

	guide_arrow.position.x = target_pos.x
	# Only smoothly update Y baseline without disturbing bouncing relative tween
	if abs(guide_arrow.position.y - target_pos.y) > 30.0:
		guide_arrow.position.y = target_pos.y

func _build_interaction_pills() -> void:
	# Table Prompt Pill
	table_prompt_pill = _create_action_pill("📦 Ambil Kabel [SPACE / KETUK]", Color("#10b981"), Color("#047857"), func(): _handle_action_press())
	table_prompt_pill.visible = false
	add_child(table_prompt_pill)

	# Left Rack Prompt Pill
	left_rack_prompt_pill = _create_action_pill("✓ Pasang di Rak Straight [SPACE / KETUK]", Color("#3b82f6"), Color("#1d4ed8"), func(): _handle_action_press())
	left_rack_prompt_pill.visible = false
	add_child(left_rack_prompt_pill)

	# Right Rack Prompt Pill
	right_rack_prompt_pill = _create_action_pill("✓ Pasang di Rak Cross [SPACE / KETUK]", Color("#f59e0b"), Color("#b45309"), func(): _handle_action_press())
	right_rack_prompt_pill.visible = false
	add_child(right_rack_prompt_pill)

func _create_action_pill(text_txt: String, bg_col: Color, border_col: Color, on_click: Callable) -> PanelContainer:
	var pill = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 2)
	pill.add_theme_stylebox_override("panel", sb)

	var lbl = Label.new()
	lbl.text = text_txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_black)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	pill.add_child(lbl)

	# Transparent touch button over entire pill
	var btn = Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(on_click)
	pill.add_child(btn)

	return pill

# --- HEADER UI ---
func _build_header_ui() -> void:
	header_ui = Control.new()
	header_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_ui)

	# 1. Back Button (Top Left)
	var back_btn = Button.new()
	back_btn.text = "◀ KELUAR"
	back_btn.position = Vector2(24, 20)
	back_btn.custom_minimum_size = Vector2(100, 42)
	var sb_b = StyleBoxFlat.new()
	sb_b.bg_color = Color("#fed0cf")
	sb_b.border_color = Color("#4a2e2b")
	sb_b.set_border_width_all(2.5)
	sb_b.set_corner_radius_all(14)
	sb_b.shadow_color = Color(0, 0, 0, 0.15)
	sb_b.shadow_size = 4
	sb_b.shadow_offset = Vector2(0, 2)
	back_btn.add_theme_stylebox_override("normal", sb_b)
	back_btn.add_theme_font_override("font", font_black)
	back_btn.add_theme_font_size_override("font_size", 13)
	back_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.pressed.connect(func():
		_play_chime([440.0], 0.1)
		get_tree().change_scene_to_file("res://scenes/dashboard.tscn")
	)
	header_ui.add_child(back_btn)

	# 2. Step Badge / Title (Center Top)
	var badge = PanelContainer.new()
	badge.position = Vector2(140, 20)
	badge.custom_minimum_size = Vector2(300, 42)
	var sb_m = StyleBoxFlat.new()
	sb_m.bg_color = Color("#fef3c7")
	sb_m.border_color = Color("#b45309")
	sb_m.set_border_width_all(2.5)
	sb_m.set_corner_radius_all(14)
	sb_m.set_content_margin_all(8)
	badge.add_theme_stylebox_override("panel", sb_m)

	step_badge_label = Label.new()
	step_badge_label.text = "🎓 MODE LATIHAN: LANGKAH 1/5"
	step_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_badge_label.add_theme_font_override("font", font_black)
	step_badge_label.add_theme_font_size_override("font_size", 13)
	step_badge_label.add_theme_color_override("font_color", Color("#92400e"))
	badge.add_child(step_badge_label)
	header_ui.add_child(badge)

	# 3. Top Right Buttons: "📖 Buku Teori" & "⏸ Pause"
	var tr_hb = HBoxContainer.new()
	tr_hb.position = Vector2(1000, 20)
	tr_hb.add_theme_constant_override("separation", 12)
	header_ui.add_child(tr_hb)

	var book_btn = Button.new()
	book_btn.text = "📖 BUKU TEORI"
	book_btn.custom_minimum_size = Vector2(130, 42)
	var sb_g = StyleBoxFlat.new()
	sb_g.bg_color = Color("#38bdf8")
	sb_g.border_color = Color("#0284c7")
	sb_g.set_border_width_all(2.5)
	sb_g.set_corner_radius_all(14)
	book_btn.add_theme_stylebox_override("normal", sb_g)
	book_btn.add_theme_font_override("font", font_black)
	book_btn.add_theme_font_size_override("font_size", 12)
	book_btn.add_theme_color_override("font_color", Color.WHITE)
	book_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	book_btn.pressed.connect(open_tutorial_modal)
	tr_hb.add_child(book_btn)

	var pause_btn = Button.new()
	pause_btn.text = "⏸"
	pause_btn.custom_minimum_size = Vector2(44, 42)
	var sb_p = StyleBoxFlat.new()
	sb_p.bg_color = Color("#ffffff")
	sb_p.border_color = Color("#4a2e2b")
	sb_p.set_border_width_all(2.5)
	sb_p.set_corner_radius_all(14)
	pause_btn.add_theme_stylebox_override("normal", sb_p)
	pause_btn.add_theme_font_override("font", font_black)
	pause_btn.add_theme_font_size_override("font_size", 16)
	pause_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
	pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pause_btn.pressed.connect(open_pause_modal)
	tr_hb.add_child(pause_btn)

# --- TUTORIAL STEP CONTROLLER ---
func _apply_step(step: int) -> void:
	current_step = step
	match step:
		TutorialStep.MOVE_CHARACTER:
			step_badge_label.text = "🎓 TUTORIAL: LANGKAH 1/5 (KONTROL)"
			hint_label.text = "🕹️ Gunakan WASD / Panah Keyboard atau Virtual Joystick di kiri bawah untuk bergerak!"
			guide_arrow.visible = true
			guide_arrow_label.text = "⬇ GERAK"
		TutorialStep.PICK_STRAIGHT:
			step_badge_label.text = "🎓 TUTORIAL: LANGKAH 2/5 (MEJA KABEL)"
			hint_label.text = "📦 Dekati Meja Tengah dan ambil kabel pertama (Kabel Hijau: PC ↔ Switch)!"
			guide_arrow.visible = true
			guide_arrow_label.text = "⬇ MEJA TENGAH"
		TutorialStep.DELIVER_STRAIGHT:
			step_badge_label.text = "🎓 TUTORIAL: LANGKAH 3/5 (KABEL STRAIGHT)"
			hint_label.text = "🟢 PC ↔ Switch adalah PERANGKAT BERBEDA! Gunakan KABEL STRAIGHT, bawa ke RAK KIRI!"
			guide_arrow.visible = true
			guide_arrow_label.text = "⬅ RAK STRAIGHT"
		TutorialStep.PICK_CROSS:
			step_badge_label.text = "🎓 TUTORIAL: LANGKAH 4/5 (AMBIL CROSS)"
			hint_label.text = "📦 Kembali ke meja tengah dan ambil kabel kedua (Kabel Kuning: PC ↔ PC)!"
			guide_arrow.visible = true
			guide_arrow_label.text = "⬇ MEJA TENGAH"
		TutorialStep.DELIVER_CROSS:
			step_badge_label.text = "🎓 TUTORIAL: LANGKAH 5/5 (KABEL CROSS)"
			hint_label.text = "🟡 PC ↔ PC adalah PERANGKAT SEJENIS! Gunakan KABEL CROSS, bawa ke RAK KANAN!"
			guide_arrow.visible = true
			guide_arrow_label.text = "➡ RAK CROSS"
		TutorialStep.FREE_PLAY_OR_DONE:
			step_badge_label.text = "🏆 TUTORIAL SELESAI!"
			hint_label.text = "🎉 Hebat! Semua kabel dasar sudah dikuasai! Kamu siap memulai petualangan Stage 1!"
			guide_arrow.visible = false

# --- TUTORIAL MODAL (BUKU TEORI CARA MAIN) ---
func _build_tutorial_modal() -> void:
	tutorial_modal = Control.new()
	tutorial_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_modal.visible = false
	add_child(tutorial_modal)

	var bg_dim = ColorRect.new()
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_dim.color = Color(0, 0, 0, 0.6)
	tutorial_modal.add_child(bg_dim)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(880, 520)
	card.set_anchors_preset(Control.PRESET_CENTER)
	var sb_c = StyleBoxFlat.new()
	sb_c.bg_color = Color("#fffdf9")
	sb_c.border_color = Color("#4a2e2b")
	sb_c.set_border_width_all(3.5)
	sb_c.set_corner_radius_all(22)
	sb_c.content_margin_left = 28
	sb_c.content_margin_right = 28
	sb_c.content_margin_top = 22
	sb_c.content_margin_bottom = 22
	sb_c.shadow_color = Color(0, 0, 0, 0.3)
	sb_c.shadow_size = 14
	sb_c.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", sb_c)
	tutorial_modal.add_child(card)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)

	# Header
	var h_row = HBoxContainer.new()
	vbox.add_child(h_row)

	var t_pill = PanelContainer.new()
	var sb_tp = StyleBoxFlat.new()
	sb_tp.bg_color = Color("#fed7aa")
	sb_tp.border_color = Color("#ea580c")
	sb_tp.set_border_width_all(2)
	sb_tp.set_corner_radius_all(12)
	sb_tp.set_content_margin_all(6)
	t_pill.add_theme_stylebox_override("panel", sb_tp)
	h_row.add_child(t_pill)

	var t_lbl = Label.new()
	t_lbl.text = "📖 PANDUAN CARA MAIN & TEORI KABEL JARINGAN"
	t_lbl.add_theme_font_override("font", font_black)
	t_lbl.add_theme_font_size_override("font_size", 16)
	t_lbl.add_theme_color_override("font_color", Color("#9a3412"))
	t_pill.add_child(t_lbl)

	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_row.add_child(sp)

	var cb = CloseButtonScene.instantiate()
	cb.closed.connect(close_tutorial_modal)
	h_row.add_child(cb)

	# 3 Steps Columns (Kontrol, Teori Straight, Teori Cross)
	var steps_hb = HBoxContainer.new()
	steps_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	steps_hb.add_theme_constant_override("separation", 14)
	vbox.add_child(steps_hb)

	# Step 1: Kontrol & Mekanik
	var p1 = _create_tutorial_column("1. KONTROL & AMBIL", "🕹️ Gerakan:\nGunakan tombol WASD / Panah atau Virtual Joystick di layar.\n\n📦 Ambil Kabel:\nDekati meja tengah, klik tombol 'Ambil Kabel' atau tekan SPACE.", Color("#dbeafe"), Color("#2563eb"))
	steps_hb.add_child(p1)

	# Step 2: Teori Straight
	var p2 = _create_tutorial_column("2. KABEL STRAIGHT", "🟢 Perangkat BERBEDA:\nDigunakan untuk menghubungkan 2 perangkat bertingkat beda:\n• PC ↔ Switch\n• Switch ↔ Router\n\n👉 Letakkan di RAK KIRI!", Color("#dcfce7"), Color("#059669"))
	steps_hb.add_child(p2)

	# Step 3: Teori Cross
	var p3 = _create_tutorial_column("3. KABEL CROSS", "🟡 Perangkat SEJENIS:\nDigunakan untuk menghubungkan 2 perangkat yang setara:\n• PC ↔ PC\n• Switch ↔ Switch\n• Router ↔ Router\n\n👉 Letakkan di RAK KANAN!", Color("#fef3c7"), Color("#d97706"))
	steps_hb.add_child(p3)

	# Bottom Start Button
	var bot_btn = Button.new()
	bot_btn.text = "SIAP, LANJUTKAN LATIHAN! ▶"
	bot_btn.custom_minimum_size = Vector2(280, 48)
	bot_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb_bot = StyleBoxFlat.new()
	sb_bot.bg_color = Color("#10b981")
	sb_bot.border_color = Color("#047857")
	sb_bot.set_border_width_all(2.5)
	sb_bot.set_corner_radius_all(14)
	bot_btn.add_theme_stylebox_override("normal", sb_bot)
	bot_btn.add_theme_font_override("font", font_black)
	bot_btn.add_theme_font_size_override("font_size", 16)
	bot_btn.add_theme_color_override("font_color", Color.WHITE)
	bot_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bot_btn.pressed.connect(close_tutorial_modal)
	vbox.add_child(bot_btn)

func _create_tutorial_column(title_txt: String, body_txt: String, bg_col: Color, border_col: Color) -> Control:
	var col = PanelContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(16)
	col.add_theme_stylebox_override("panel", sb)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	col.add_child(vb)

	var h_lbl = Label.new()
	h_lbl.text = title_txt
	h_lbl.add_theme_font_override("font", font_black)
	h_lbl.add_theme_font_size_override("font_size", 15)
	h_lbl.add_theme_color_override("font_color", border_col)
	vb.add_child(h_lbl)

	var b_lbl = Label.new()
	b_lbl.text = body_txt
	b_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b_lbl.add_theme_font_override("font", font_semibold)
	b_lbl.add_theme_font_size_override("font_size", 12)
	b_lbl.add_theme_color_override("font_color", Color("#1e293b"))
	vb.add_child(b_lbl)

	return col

func open_tutorial_modal() -> void:
	is_modal_open = true
	tutorial_modal.visible = true
	_play_chime([523.25, 659.25], 0.1)

func close_tutorial_modal() -> void:
	tutorial_modal.visible = false
	is_modal_open = false
	_play_chime([440.0], 0.08)

# --- COMPLETION MODAL ---
func _build_completion_modal() -> void:
	complete_modal = Control.new()
	complete_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	complete_modal.visible = false
	add_child(complete_modal)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	complete_modal.add_child(dim)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(620, 460)
	card.set_anchors_preset(Control.PRESET_CENTER)
	var sb_c = StyleBoxFlat.new()
	sb_c.bg_color = Color("#fffdf9")
	sb_c.border_color = Color("#10b981")
	sb_c.set_border_width_all(3.5)
	sb_c.set_corner_radius_all(22)
	sb_c.set_content_margin_all(28)
	sb_c.shadow_color = Color(0, 0, 0, 0.3)
	sb_c.shadow_size = 14
	sb_c.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", sb_c)
	complete_modal.add_child(card)

	var vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	card.add_child(vb)

	var t1 = Label.new()
	t1.text = "🎉 SELAMAT! TUTORIAL LATIHAN SELESAI!"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_override("font", font_black)
	t1.add_theme_font_size_override("font_size", 20)
	t1.add_theme_color_override("font_color", Color("#047857"))
	vb.add_child(t1)

	var desc_pill = PanelContainer.new()
	var sb_dp = StyleBoxFlat.new()
	sb_dp.bg_color = Color("#f0fdf4")
	sb_dp.border_color = Color("#86efac")
	sb_dp.set_border_width_all(2)
	sb_dp.set_corner_radius_all(14)
	sb_dp.set_content_margin_all(14)
	desc_pill.add_theme_stylebox_override("panel", sb_dp)
	vb.add_child(desc_pill)

	var desc_lbl = Label.new()
	desc_lbl.text = "Kamu telah menguasai:\n✓ Menggerakkan karakter maskot Router\n✓ Mengambil kabel dari Meja Tengah\n✓ Kabel STRAIGHT: Perangkat Berbeda (PC ↔ Switch)\n✓ Kabel CROSS: Perangkat Sejenis (PC ↔ PC)\n\nSekarang kamu sudah siap menyelesaikan misi sesungguhnya di Stage 1!"
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_override("font", font_semibold)
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color("#166534"))
	desc_pill.add_child(desc_lbl)

	# 3 Action Buttons
	var btn_row = VBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vb.add_child(btn_row)

	var play_stage1_btn = Button.new()
	play_stage1_btn.text = "MULAI PETUALANGAN (STAGE 1.1) ▶"
	play_stage1_btn.custom_minimum_size = Vector2(340, 48)
	play_stage1_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb_p = StyleBoxFlat.new()
	sb_p.bg_color = Color("#ea580c")
	sb_p.border_color = Color("#9a3412")
	sb_p.set_border_width_all(2.5)
	sb_p.set_corner_radius_all(14)
	play_stage1_btn.add_theme_stylebox_override("normal", sb_p)
	play_stage1_btn.add_theme_font_override("font", font_black)
	play_stage1_btn.add_theme_font_size_override("font_size", 15)
	play_stage1_btn.add_theme_color_override("font_color", Color.WHITE)
	play_stage1_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	play_stage1_btn.pressed.connect(func():
		_play_chime([523.25, 783.99], 0.1)
		get_tree().change_scene_to_file("res://scenes/gameplay/level_1_1.tscn")
	)
	btn_row.add_child(play_stage1_btn)

	var repeat_btn = Button.new()
	repeat_btn.text = "ULANGI LATIHAN 🔄"
	repeat_btn.custom_minimum_size = Vector2(340, 44)
	repeat_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb_r = StyleBoxFlat.new()
	sb_r.bg_color = Color("#fef08a")
	sb_r.border_color = Color("#ca8a04")
	sb_r.set_border_width_all(2)
	sb_r.set_corner_radius_all(14)
	repeat_btn.add_theme_stylebox_override("normal", sb_r)
	repeat_btn.add_theme_font_override("font", font_black)
	repeat_btn.add_theme_font_size_override("font_size", 14)
	repeat_btn.add_theme_color_override("font_color", Color("#854d0e"))
	repeat_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	repeat_btn.pressed.connect(_reset_practice_game)
	btn_row.add_child(repeat_btn)

	var menu_btn = Button.new()
	menu_btn.text = "KEMBALI KE MENU 🏠"
	menu_btn.custom_minimum_size = Vector2(340, 44)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb_m = StyleBoxFlat.new()
	sb_m.bg_color = Color("#e2e8f0")
	sb_m.border_color = Color("#64748b")
	sb_m.set_border_width_all(2)
	sb_m.set_corner_radius_all(14)
	menu_btn.add_theme_stylebox_override("normal", sb_m)
	menu_btn.add_theme_font_override("font", font_black)
	menu_btn.add_theme_font_size_override("font_size", 14)
	menu_btn.add_theme_color_override("font_color", Color("#334155"))
	menu_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	menu_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/dashboard.tscn")
	)
	btn_row.add_child(menu_btn)

func _reset_practice_game() -> void:
	complete_modal.visible = false
	is_modal_open = false
	_init_cable_practice_data()
	_setup_cable_table()
	for s in left_rack_slots:
		s.modulate.a = 0.0
	for s in right_rack_slots:
		s.modulate.a = 0.0
	carried_icon.visible = false
	_apply_step(TutorialStep.MOVE_CHARACTER)

# --- PAUSE MODAL ---
func _build_pause_modal() -> void:
	pause_modal = PauseModalScene.instantiate()
	pause_modal.visible = false
	add_child(pause_modal)

func open_pause_modal() -> void:
	is_modal_open = true
	if pause_modal.has_method("open"):
		pause_modal.open()
	else:
		pause_modal.visible = true

# --- MOBILE JOYSTICK ---
func _build_mobile_controls() -> void:
	joystick_base = TextureRect.new()
	joystick_base.texture = tex_joystick_pad
	joystick_base.size = Vector2(130, 130)
	joystick_base.position = Vector2(50, 530)
	joystick_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	joystick_base.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	joystick_base.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(joystick_base)

	joystick_nub = TextureRect.new()
	joystick_nub.texture = tex_joystick_nub
	joystick_nub.size = Vector2(56, 56)
	joystick_nub.position = Vector2(37, 37)
	joystick_nub.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	joystick_nub.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	joystick_nub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(joystick_nub)

	joystick_base.gui_input.connect(_handle_joystick_input)

func _handle_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			is_dragging_joystick = true
			joystick_touch_id = event.index
			_update_joystick(event.position)
		elif event.index == joystick_touch_id:
			_reset_joystick()
	elif event is InputEventScreenDrag:
		if is_dragging_joystick and event.index == joystick_touch_id:
			_update_joystick(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_joystick = true
				_update_joystick(event.position)
			else:
				_reset_joystick()
	elif event is InputEventMouseMotion and is_dragging_joystick:
		_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2) -> void:
	var center = joystick_base.size / 2.0
	var offset = touch_pos - center
	var max_dist = 50.0
	if offset.length() > max_dist:
		offset = offset.normalized() * max_dist
	joystick_nub.position = center + offset - joystick_nub.size / 2.0
	move_vec = offset / max_dist

func _reset_joystick() -> void:
	is_dragging_joystick = false
	joystick_touch_id = -1
	move_vec = Vector2.ZERO
	joystick_nub.position = joystick_base.size / 2.0 - joystick_nub.size / 2.0

# --- MOVEMENT ---
func _handle_movement(delta: float) -> void:
	var key_vec = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		key_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		key_vec.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		key_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		key_vec.x += 1.0

	var final_vec = (key_vec + move_vec).normalized() if (key_vec + move_vec).length() > 0.1 else Vector2.ZERO
	is_moving = final_vec.length() > 0.05

	if is_moving:
		var delta_pos = final_vec * walk_speed * delta
		var sz = get_viewport_rect().size
		char_pos.x = clamp(char_pos.x + delta_pos.x, 60.0, sz.x - 300.0)
		char_pos.y = clamp(char_pos.y + delta_pos.y, 200.0, sz.y - 180.0)
		character_mascot.position = char_pos

		distance_traveled += delta_pos.length()
		if current_step == TutorialStep.MOVE_CHARACTER and distance_traveled > 55.0:
			_play_chime([523.25, 659.25, 783.99], 0.12)
			_apply_step(TutorialStep.PICK_STRAIGHT)

		# Flip character according to horizontal direction
		if final_vec.x < -0.1:
			character_mascot.scale.x = -1.0
		elif final_vec.x > 0.1:
			character_mascot.scale.x = 1.0

		# Animation cycle
		walk_anim_timer += delta * 12.0
		var frame_idx = int(walk_anim_timer) % walk_frames.size()
		mascot_sprite.texture = walk_frames[frame_idx]

		# Step sound
		step_timer += delta
		if step_timer >= 0.28:
			step_timer = 0.0
			step_toggle = not step_toggle
			_play_step_sfx(step_toggle)
	else:
		mascot_sprite.texture = tex_router_idle

# --- PROXIMITY & INTERACTION HINTS ---
func _update_proximity_and_hints() -> void:
	var char_center = char_pos + Vector2(110, 60)
	var table_rect = cable_table_node.get_global_rect()
	var left_rect = left_rack_node.get_global_rect()
	var right_rect = right_rack_node.get_global_rect()

	var dist_table = char_center.distance_to(table_rect.position + table_rect.size / 2.0)
	var dist_left = char_center.distance_to(left_rect.position + left_rect.size / 2.0)
	var dist_right = char_center.distance_to(right_rect.position + right_rect.size / 2.0)

	var near_table = dist_table < 180.0
	var near_left = dist_left < 210.0
	var near_right = dist_right < 210.0

	if carried_cable_data == null:
		table_prompt_pill.visible = near_table and active_focused_cable_idx < cables_data.size()
		left_rack_prompt_pill.visible = false
		right_rack_prompt_pill.visible = false
		if near_table:
			table_prompt_pill.position = cable_table_node.position + Vector2(cable_table_node.size.x / 2.0 - 100, -38)
	else:
		table_prompt_pill.visible = false
		left_rack_prompt_pill.visible = near_left
		right_rack_prompt_pill.visible = near_right

		if near_left:
			left_rack_prompt_pill.position = left_rack_node.position + Vector2(20, -32)
		if near_right:
			right_rack_prompt_pill.position = right_rack_node.position + Vector2(20, -32)

func _unhandled_input(event: InputEvent) -> void:
	if is_modal_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_handle_action_press()

func _handle_action_press() -> void:
	var char_center = char_pos + Vector2(110, 60)
	var table_rect = cable_table_node.get_global_rect()
	var left_rect = left_rack_node.get_global_rect()
	var right_rect = right_rack_node.get_global_rect()

	if carried_cable_data == null:
		if char_center.distance_to(table_rect.position + table_rect.size / 2.0) < 220.0:
			_pick_up_cable()
	else:
		if char_center.distance_to(left_rect.position + left_rect.size / 2.0) < 230.0:
			_try_place_cable("straight")
		elif char_center.distance_to(right_rect.position + right_rect.size / 2.0) < 230.0:
			_try_place_cable("cross")

func _pick_up_cable() -> void:
	if active_focused_cable_idx >= cables_data.size():
		return

	carried_cable_data = cables_data[active_focused_cable_idx]
	carried_icon.texture = carried_cable_data["tex"]
	carried_icon.visible = true

	# Dim the cable on table
	cable_item_nodes[active_focused_cable_idx].modulate.a = 0.3
	_play_chime([523.25, 659.25], 0.1)

	if current_step == TutorialStep.PICK_STRAIGHT:
		_apply_step(TutorialStep.DELIVER_STRAIGHT)
	elif current_step == TutorialStep.PICK_CROSS:
		_apply_step(TutorialStep.DELIVER_CROSS)

func _try_place_cable(target_rack: String) -> void:
	if carried_cable_data == null:
		return

	var expected_type = carried_cable_data["type"]
	if target_rack == expected_type:
		# Correct placement!
		_play_chime([523.25, 659.25, 783.99, 1046.5], 0.12)

		if target_rack == "straight":
			var slot_idx = min(sorted_cables_count / 2, left_rack_slots.size() - 1)
			left_rack_slots[slot_idx].texture = carried_cable_data["tex"]
			left_rack_slots[slot_idx].modulate.a = 1.0
		else:
			var slot_idx = min(sorted_cables_count / 2, right_rack_slots.size() - 1)
			right_rack_slots[slot_idx].texture = carried_cable_data["tex"]
			right_rack_slots[slot_idx].modulate.a = 1.0

		sorted_cables_count += 1
		active_focused_cable_idx += 1
		carried_cable_data = null
		carried_icon.visible = false

		if current_step == TutorialStep.DELIVER_STRAIGHT:
			_apply_step(TutorialStep.PICK_CROSS)
		elif current_step == TutorialStep.DELIVER_CROSS:
			_apply_step(TutorialStep.FREE_PLAY_OR_DONE)
			get_tree().create_timer(0.6).timeout.connect(_trigger_complete)
		elif sorted_cables_count >= cables_data.size():
			_trigger_complete()
	else:
		# Gentle practice feedback without penalty
		_play_chime([260.0, 220.0], 0.1)
		var note = "⚠️ Kurang tepat! %s adalah kabel %s. Letakkan di Rak %s!" % [
			carried_cable_data["name"],
			"STRAIGHT (Perangkat Berbeda)" if expected_type == "straight" else "CROSS (Perangkat Sejenis)",
			"KIRI (Straight)" if expected_type == "straight" else "KANAN (Cross)"
		]
		hint_label.text = note

func _trigger_complete() -> void:
	is_modal_open = true
	complete_modal.visible = true
	_play_chime([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.15)

func _reposition_responsive() -> void:
	var sz = get_viewport_rect().size
	var cx = sz.x / 2.0

	if door_arch:
		door_arch.position = Vector2(cx - 164.0, 46.0)
		door_arch.size = Vector2(328.0, 200.0)
	if potted_plant:
		potted_plant.position = Vector2(cx + 180.0, 70.0)
		potted_plant.size = Vector2(120.0, 180.0)

	if hint_pill:
		hint_pill.position = Vector2(cx - 320.0, 85.0)
		hint_pill.custom_minimum_size = Vector2(640, 38)

	if cable_table_node:
		cable_table_node.position = Vector2(cx - 230.0, clamp(sz.y * 0.68, 480.0, 530.0))
		cable_table_node.size = Vector2(460, 140)

	if left_rack_node:
		left_rack_node.position = Vector2(clamp(cx - 560.0, 40.0, 160.0), 220.0)
		left_rack_node.size = Vector2(270, 340)

	if right_rack_node:
		right_rack_node.position = Vector2(clamp(cx + 290.0, sz.x - 310.0, sz.x - 180.0), 220.0)
		right_rack_node.size = Vector2(270, 340)

# --- AUDIO SYNTH HELPERS ---
func _play_chime(notes: Array, dur: float) -> void:
	if not audio_player:
		return
	var sample_rate = 44100
	var total_dur = dur * notes.size()
	var num_samples = int(sample_rate * total_dur)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false

	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var note_idx = min(int(float(i) / (sample_rate * dur)), notes.size() - 1)
		var freq = float(notes[note_idx])
		var t = float(i) / float(sample_rate)
		var local_t = fmod(t, dur)
		var env = 1.0 - (local_t / dur)
		var val = sin(2.0 * PI * freq * t) * env * 0.25
		var sample_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_val)

	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _play_step_sfx(high_pitch: bool) -> void:
	if not footstep_player:
		return
	var sample_rate = 22050
	var dur = 0.05
	var num_samples = int(sample_rate * dur)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false

	var data = PackedByteArray()
	data.resize(num_samples * 2)
	var freq = 160.0 if high_pitch else 140.0
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = 1.0 - (t / dur)
		var val = (sin(2.0 * PI * freq * t) + (randf() * 2.0 - 1.0) * 0.2) * env * 0.15
		var sample_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_val)

	stream.data = data
	footstep_player.stream = stream
	footstep_player.play()
