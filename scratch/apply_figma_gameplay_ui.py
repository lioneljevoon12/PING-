import re

# Update Level 1.2
with open('ping-game/scenes/gameplay/level_1_2.gd', 'r', encoding='utf-8') as f:
    c12 = f.read()

# Replace _setup_decorative_rack in level_1_2.gd
rack_code_12 = """func _setup_decorative_rack(rack_root: Control, title_text: String, badge_color_hex: String) -> void:
	rack_root.clip_contents = false
	rack_root.size = Vector2(270, 340)
	
	var rack_tex = TextureRect.new()
	rack_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rack_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rack_tex.custom_minimum_size = Vector2(270, 340)
	rack_tex.size = Vector2(270, 340)
	rack_tex.texture = tex_rack
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
	
	# Shelf Cables Container (clipped inside shelf so cables don't leak)
	var shelf_container = Control.new()
	shelf_container.name = "ShelfCablesContainer"
	shelf_container.position = Vector2(10, 48)
	shelf_container.size = Vector2(250, 260)
	shelf_container.clip_contents = true
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
			shelf_container.add_child(c_img)"""

c12 = re.sub(r'func _setup_decorative_rack\(rack_root: Control, title_text: String, badge_color_hex: String\) -> void:[\s\S]*?(?=func _setup_cable_workbench)', rack_code_12 + '\n\n', c12)

with open('ping-game/scenes/gameplay/level_1_2.gd', 'w', encoding='utf-8') as f:
    f.write(c12)

# Update Level 1.1
with open('ping-game/scenes/gameplay/level_1_1.gd', 'r', encoding='utf-8') as f:
    c11 = f.read()

# Preload assets in 1.1 if missing
if 'tex_frame_jam' not in c11:
    c11 = c11.replace(
        'var tex_router_idle: Texture2D = preload("res://art/assets/PING! Assets/Character/main-char-router.png")',
        'var tex_router_idle: Texture2D = preload("res://art/assets/PING! Assets/Character/main-char-router.png")\nvar tex_frame_jam: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/generals/frame-jam.png")\nvar tex_vector_heart: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/generals/vector-hearts.png")'
    )

if 'var hearts_rects: Array[TextureRect] = []' not in c11:
    c11 = c11.replace('var hearts: int = 3', 'var hearts: int = 3\nvar hearts_rects: Array[TextureRect] = []')

# Update _update_hearts_display in 1.1
old_h11 = """func _update_hearts_display() -> void:
	if hearts_container:
		for i in range(hearts_container.get_child_count()):
			var h_node = hearts_container.get_child(i) as Label
			if h_node:
				if i < hearts:
					h_node.text = "\u2764\ufe0f"
				else:
					h_node.text = "\U0001f5a4" """

new_h11 = """func _update_hearts_display() -> void:
	for i in range(hearts_rects.size()):
		if i < hearts:
			hearts_rects[i].modulate = Color.WHITE
		else:
			hearts_rects[i].modulate = Color(0.35, 0.3, 0.3, 0.3)"""

c11 = c11.replace(old_h11, new_h11)

# Update _setup_rack_node in 1.1 (Figma White Badge with 2 lines, no clipping)
new_rack_11 = """func _setup_rack_node(rack_root: Control, title_text: String, badge_color_hex: String, slots_array: Array[TextureRect]) -> void:
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
		slots_array.append(slot_rect)"""

c11 = re.sub(r'func _setup_rack_node\(rack_root: Control, title_text: String, badge_color_hex: String, slots_array: Array\[TextureRect\]\) -> void:[\s\S]*?(?=func _select_cable_on_table)', new_rack_11 + '\n\n', c11)

# Replace _build_header_ui in 1.1 with exact Figma Header
new_header_11 = """func _build_header_ui() -> void:
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
	header_ui.add_child(pause_btn)"""

c11 = re.sub(r'func _build_header_ui\(\) -> void:[\s\S]*?(?=func _build_interaction_prompts)', new_header_11 + '\n\n', c11)

# Reposition header in 1.1
new_repo_11 = """	if header_ui:
		var back_b = header_ui.get_node_or_null("BackBtn")
		var hearts_p = header_ui.get_node_or_null("HeartsPanel")
		var lvl_p = header_ui.get_node_or_null("LevelBadge")
		var timer_p = header_ui.get_node_or_null("TimerPanel")
		var pause_b = header_ui.get_node_or_null("PauseBtn")
		
		if back_b: back_b.position = Vector2(30.0, 18.0)
		if hearts_p: hearts_p.position = Vector2(106.0, 18.0)
		if lvl_p: lvl_p.position = Vector2(314.0, 18.0)
		
		if pause_b: pause_b.position = Vector2(screen_w - 94.0, 18.0)
		if timer_p: timer_p.position = Vector2(screen_w - 325.0, 18.0)"""

c11 = re.sub(r'if header_ui:[\s\S]*?(?=if pinout_card:)', new_repo_11 + '\n\t\n\t', c11)

with open('ping-game/scenes/gameplay/level_1_1.gd', 'w', encoding='utf-8') as f:
    f.write(c11)

print("Applied Figma templates & assets to Level 1.1 & 1.2 successfully!")
