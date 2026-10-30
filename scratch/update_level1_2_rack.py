import os

# We will update level_1_2.gd to implement the exact Figma Header and Rack designs.

with open('ping-game/scenes/gameplay/level_1_2.gd', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Preload new assets
asset_decl = """var tex_frame_jam = preload("res://art/assets/PING! Assets/asset-gameplay/generals/frame-jam.png")
var tex_vector_heart = preload("res://art/assets/PING! Assets/asset-gameplay/generals/vector-hearts.png")"""

if 'tex_frame_jam' not in code:
    code = code.replace(
        'var tex_char_idle = preload("res://art/assets/PING! Assets/Character/main-char-router.png")',
        'var tex_char_idle = preload("res://art/assets/PING! Assets/Character/main-char-router.png")\n' + asset_decl
    )

# 2. Add hearts_rects array
if 'var hearts_rects: Array[TextureRect] = []' not in code:
    code = code.replace(
        'var hearts: int = 3',
        'var hearts: int = 3\nvar hearts_rects: Array[TextureRect] = []'
    )

# 3. Replace _update_hearts_display
old_hearts_disp = """func _update_hearts_display() -> void:
	if hearts_label:
		var h_str = ""
		for i in range(3):
			if i < hearts:
				h_str += "\u2764\ufe0f "
			else:
				h_str += "\U0001f5a4 "
		hearts_label.text = h_str.strip_edges()"""

new_hearts_disp = """func _update_hearts_display() -> void:
	for i in range(hearts_rects.size()):
		if i < hearts:
			hearts_rects[i].modulate = Color.WHITE
		else:
			hearts_rects[i].modulate = Color(0.35, 0.3, 0.3, 0.3)"""

code = code.replace(old_hearts_disp, new_hearts_disp)

# 4. Replace _setup_decorative_rack
old_rack_func = """func _setup_decorative_rack(rack_root: Control, title_text: String, badge_color_hex: String) -> void:
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
			rack_root.add_child(c_img)"""

new_rack_func = """func _setup_decorative_rack(rack_root: Control, title_type: String) -> void:
	rack_root.clip_contents = false
	rack_root.size = Vector2(270, 340)
	
	# Rack Body Graphic
	var rack_tex = TextureRect.new()
	rack_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rack_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rack_tex.custom_minimum_size = Vector2(270, 340)
	rack_tex.size = Vector2(270, 340)
	rack_tex.texture = tex_rack
	rack_root.add_child(rack_tex)
	
	# Rack Title Badge (Exact Figma card: White fill, 3.5px border #4a2e2b, 2 lines)
	var badge = PanelContainer.new()
	badge.custom_minimum_size = Vector2(210, 54)
	badge.size = Vector2(210, 54)
	badge.position = Vector2((270.0 - 210.0) / 2.0, -28.0) # Sitting cleanly at the top without clipping
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
	lbl_bot.text = title_type # "Cross" or "Straight"
	lbl_bot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_bot.add_theme_font_override("font", font_black)
	lbl_bot.add_theme_font_size_override("font_size", 16)
	lbl_bot.add_theme_color_override("font_color", Color("#4a2e2b"))
	vb_badge.add_child(lbl_bot)
	
	# Shelf Cables Container (Clipped to prevent leaking, while rack & badge stay unclipped!)
	var shelf_container = Control.new()
	shelf_container.name = "ShelfCablesContainer"
	shelf_container.position = Vector2(10, 48)
	shelf_container.size = Vector2(250, 260)
	shelf_container.clip_contents = true
	rack_root.add_child(shelf_container)
	
	# Shelf Cables Decoration (row 1 and row 2) matching Figma Level 1.2
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

code = code.replace(old_rack_func, new_rack_func)

# Fix calls to _setup_decorative_rack
code = code.replace(
    '_setup_decorative_rack(left_rack_node, "Rak Kabel Cross", "#c2410c")',
    '_setup_decorative_rack(left_rack_node, "Cross")'
)
code = code.replace(
    '_setup_decorative_rack(right_rack_node, "Rak Kabel Straight", "#0284c7")',
    '_setup_decorative_rack(right_rack_node, "Straight")'
)

with open('ping-game/scenes/gameplay/level_1_2.gd', 'w', encoding='utf-8') as f:
    f.write(code)

print("Updated rack in level_1_2.gd!")
