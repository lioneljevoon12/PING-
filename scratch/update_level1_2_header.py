import re

with open('ping-game/scenes/gameplay/level_1_2.gd', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace _build_header_ui
new_header_code = """func _build_header_ui() -> void:
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
	
	# 3. Level Badge (Level 2) - 2-row card matching Figma (80x64)
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
	lbl_lvl_num.text = "2"
	lbl_lvl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_lvl_num.add_theme_font_override("font", font_black)
	lbl_lvl_num.add_theme_font_size_override("font_size", 22)
	lbl_lvl_num.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb_lvl.add_child(lbl_lvl_num)
	
	# 4. Guidebook Button ("Panduan Pin")
	var guide_top_btn = TextureButton.new()
	guide_top_btn.name = "GuidebookTopBtn"
	guide_top_btn.custom_minimum_size = Vector2(170, 64)
	guide_top_btn.size = Vector2(170, 64)
	guide_top_btn.pivot_offset = Vector2(85, 32)
	var p_g = PanelContainer.new()
	p_g.size = Vector2(170, 64)
	p_g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_g = StyleBoxFlat.new()
	sb_g.bg_color = Color("#fffbf0")
	sb_g.border_color = Color("#4a2e2b")
	sb_g.set_border_width_all(3.5)
	sb_g.set_corner_radius_all(32)
	sb_g.shadow_color = Color(0.29, 0.18, 0.17, 0.22)
	sb_g.shadow_size = 5
	sb_g.shadow_offset = Vector2(0, 3)
	p_g.add_theme_stylebox_override("panel", sb_g)
	guide_top_btn.add_child(p_g)
	
	var text_g = Label.new()
	text_g.text = "Panduan Pin"
	text_g.size = Vector2(170, 64)
	text_g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_g.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_g.add_theme_font_override("font", font_black)
	text_g.add_theme_font_size_override("font_size", 15)
	text_g.add_theme_color_override("font_color", Color("#4a2e2b"))
	guide_top_btn.add_child(text_g)
	guide_top_btn.pressed.connect(_open_guidebook_modal)
	_setup_hover_scale(guide_top_btn, 1.08)
	header_ui.add_child(guide_top_btn)
	
	# 5. Timer Panel (frame-jam + 02:45) - Big white pill (215x64)
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
	
	# 6. Pause / Menu Button (☰) - Big white rounded square (64x64)
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
	pause_btn.pressed.connect(_open_pause_modal)
	_setup_hover_scale(pause_btn, 1.08)
	header_ui.add_child(pause_btn)"""

# Find start of func _build_header_ui() to end of function
start_idx = code.find('func _build_header_ui() -> void:')
end_idx = code.find('func _build_mobile_controls() -> void:')

if start_idx != -1 and end_idx != -1:
    code = code[:start_idx] + new_header_code + '\n\n' + code[end_idx:]

# Update _reposition_responsive for header_ui in level_1_2.gd
old_repo_header = """	if header_ui:
		var guide_b = header_ui.get_node_or_null("GuidebookTopBtn")
		if guide_b:
			guide_b.position = Vector2(screen_w - 410.0, 23.0)
		var timer_p = header_ui.get_node_or_null("TimerPanel")
		if timer_p:
			timer_p.position.x = screen_w - 230.0
		var pause_b = header_ui.get_node_or_null("PauseBtn")
		if pause_b:
			pause_b.position.x = screen_w - 90.0"""

new_repo_header = """	if header_ui:
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
		if guide_b: guide_b.position = Vector2(screen_w - 510.0, 18.0)"""

code = code.replace(old_repo_header, new_repo_header)

with open('ping-game/scenes/gameplay/level_1_2.gd', 'w', encoding='utf-8') as f:
    f.write(code)

print("Updated header in level_1_2.gd!")
