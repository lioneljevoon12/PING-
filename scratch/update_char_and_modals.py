import os

# 1. UPDATE LEVEL 1.2 GD
path_12 = r'C:/Projects/PING-/ping-game/scenes/gameplay/level_1_2.gd'
with open(path_12, 'r', encoding='utf-8') as f:
    c12 = f.read()

# Character build
old_bc = """func _build_character() -> void:
	char_sprite = TextureRect.new()
	char_sprite.name = "CharSprite"
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.custom_minimum_size = Vector2(176, 98)
	char_sprite.size = Vector2(176, 98)
	char_sprite.texture = tex_char_idle
	character_mascot.add_child(char_sprite)"""

new_bc = """func _build_character() -> void:
	character_mascot.size = Vector2(256, 144)
	character_mascot.pivot_offset = Vector2(128, 72)
	char_sprite = TextureRect.new()
	char_sprite.name = "CharSprite"
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.custom_minimum_size = Vector2(256, 144)
	char_sprite.size = Vector2(256, 144)
	char_sprite.texture = tex_char_idle
	character_mascot.add_child(char_sprite)"""

assert old_bc in c12, "old_bc not found"
c12 = c12.replace(old_bc, new_bc)

# Collision & Proximity
old_coll = """func _is_room_collision(pos: Vector2, center_x: float) -> bool:
	var screen_w = get_viewport_rect().size.x
	var char_feet = Rect2(pos.x + 36.0, pos.y + 60.0, 104.0, 36.0)
	
	if pos.x < 30.0 or pos.x > screen_w - 200.0 or pos.y < 210.0 or pos.y > 580.0:
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
	var char_center = char_pos + Vector2(88.0, 49.0)
	var dist = table_center.distance_to(char_center)
	var is_near = dist < 210.0
	table_prompt_bubble.visible = is_near"""

new_coll = """func _is_room_collision(pos: Vector2, center_x: float) -> bool:
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
	table_prompt_bubble.visible = is_near"""

assert old_coll in c12, "old_coll not found"
c12 = c12.replace(old_coll, new_coll)

# Spawn Position (Spawn near door at y=270 so not touching table at start!)
old_spawn = """	if char_pos == Vector2.ZERO:
		char_pos = Vector2(center_x - 88.0, 370.0)
		character_mascot.position = char_pos"""

new_spawn = """	if char_pos == Vector2.ZERO:
		char_pos = Vector2(center_x - 128.0, 270.0)
		character_mascot.position = char_pos"""

assert old_spawn in c12, "old_spawn not found"
c12 = c12.replace(old_spawn, new_spawn)

# Action button proximity guard
old_act = """	action_btn_node.pressed.connect(func():
		_open_crimping_modal()
	)"""

new_act = """	action_btn_node.pressed.connect(func():
		if not is_game_active or crimping_modal.visible or guidebook_modal.visible or pause_modal.visible or (settings_modal and settings_modal.visible):
			return
		var table_center = cable_table_node.position + Vector2(230.0, 65.0)
		var char_center = char_pos + Vector2(128.0, 72.0)
		var dist = table_center.distance_to(char_center)
		if dist < 230.0:
			_open_crimping_modal()
		else:
			show_toast("Dekati Meja Kerja untuk merakit urutan kabel!")
	)"""

assert old_act in c12, "old_act not found"
c12 = c12.replace(old_act, new_act)

# Bubble input proximity guard
old_bbl = """	bubble_p.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			_open_crimping_modal()
	)"""

new_bbl = """	bubble_p.gui_input.connect(func(ev: InputEvent):
		if not is_game_active or crimping_modal.visible or guidebook_modal.visible:
			return
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			var table_center = cable_table_node.position + Vector2(230.0, 65.0)
			var char_center = char_pos + Vector2(128.0, 72.0)
			if table_center.distance_to(char_center) < 230.0:
				_open_crimping_modal()
	)"""

assert old_bbl in c12, "old_bbl not found"
c12 = c12.replace(old_bbl, new_bbl)

# Keyboard interaction (Space / E / Enter)
old_mv = """		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			move_vec.y -= 1.0"""

new_mv = """		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			move_vec.y -= 1.0
			
		if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_ENTER):
			var table_center = cable_table_node.position + Vector2(230.0, 65.0)
			var char_center = char_pos + Vector2(128.0, 72.0)
			if table_center.distance_to(char_center) < 230.0:
				_open_crimping_modal()"""

assert old_mv in c12, "old_mv not found"
c12 = c12.replace(old_mv, new_mv)

# Mouse filter on modals to prevent pass-through click
old_intro = """func _build_intro_modal() -> void:
	intro_modal = Control.new()
	intro_modal.name = "IntroModal"
	intro_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_modal.visible = true
	add_child(intro_modal)
	
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.7)
	intro_modal.add_child(backdrop)"""

new_intro = """func _build_intro_modal() -> void:
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
	intro_modal.add_child(backdrop)"""

assert old_intro in c12, "old_intro not found"
c12 = c12.replace(old_intro, new_intro)

old_gb = """func _build_guidebook_modal() -> void:
	guidebook_modal = Control.new()
	guidebook_modal.name = "GuidebookModal"
	guidebook_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	guidebook_modal.visible = false
	guidebook_modal.z_as_relative = false
	guidebook_modal.z_index = 250
	add_child(guidebook_modal)
	
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.72)"""

new_gb = """func _build_guidebook_modal() -> void:
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
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP"""

assert old_gb in c12, "old_gb not found"
c12 = c12.replace(old_gb, new_gb)

old_cr = """func _build_crimping_modal() -> void:
	crimping_modal = Control.new()
	crimping_modal.name = "CrimpingModal"
	crimping_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	crimping_modal.visible = false
	add_child(crimping_modal)
	
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.72)
	crimping_modal.add_child(backdrop)"""

new_cr = """func _build_crimping_modal() -> void:
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
	crimping_modal.add_child(backdrop)"""

assert old_cr in c12, "old_cr not found"
c12 = c12.replace(old_cr, new_cr)

# In _open_crimping_modal ensure guidebook is closed
old_oc = """func _open_crimping_modal() -> void:
	_play_sweep(523.25, 783.99, 0.1, 0.15)
	crimping_modal.visible = true"""

new_oc = """func _open_crimping_modal() -> void:
	if guidebook_modal and guidebook_modal.visible:
		guidebook_modal.visible = false
	_play_sweep(523.25, 783.99, 0.1, 0.15)
	crimping_modal.visible = true"""

assert old_oc in c12, "old_oc not found"
c12 = c12.replace(old_oc, new_oc)

with open(path_12, 'w', encoding='utf-8') as f:
    f.write(c12)

print("level_1_2.gd updated successfully!")

# 2. UPDATE LEVEL 1.2 TSCN
path_tscn12 = r'C:/Projects/PING-/ping-game/scenes/gameplay/level_1_2.tscn'
with open(path_tscn12, 'r', encoding='utf-8') as f:
    t12 = f.read()

old_tscn12_char = """[node name="CharacterMascot" type="Control" parent="RoomContainer"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 700.0
offset_top = 340.0
offset_right = 876.0
offset_bottom = 438.0
pivot_offset = Vector2(88, 49)"""

new_tscn12_char = """[node name="CharacterMascot" type="Control" parent="RoomContainer"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 652.0
offset_top = 270.0
offset_right = 908.0
offset_bottom = 414.0
pivot_offset = Vector2(128, 72)"""

assert old_tscn12_char in t12, "old_tscn12_char not found"
t12 = t12.replace(old_tscn12_char, new_tscn12_char)

with open(path_tscn12, 'w', encoding='utf-8') as f:
    f.write(t12)

print("level_1_2.tscn updated successfully!")

# 3. UPDATE LEVEL 1.1 GD
path_11 = r'C:/Projects/PING-/ping-game/scenes/gameplay/level_1_1.gd'
with open(path_11, 'r', encoding='utf-8') as f:
    c11 = f.read()

old_bc11 = """func _build_character_mascot() -> void:
	character_mascot.size = Vector2(176, 98)
	character_mascot.pivot_offset = Vector2(88, 49)
	
	mascot_sprite = TextureRect.new()
	mascot_sprite.name = "MascotSprite"
	mascot_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot_sprite.size = Vector2(176, 98)
	mascot_sprite.custom_minimum_size = Vector2(176, 98)
	mascot_sprite.texture = tex_char_idle
	mascot_sprite.pivot_offset = Vector2(88, 49)
	character_mascot.add_child(mascot_sprite)
	
	carried_icon = TextureRect.new()
	carried_icon.name = "CarriedIcon"
	carried_icon.custom_minimum_size = Vector2(50, 50)
	carried_icon.size = Vector2(50, 50)
	carried_icon.position = Vector2(63, -35)
	carried_icon.visible = false
	character_mascot.add_child(carried_icon)"""

new_bc11 = """func _build_character_mascot() -> void:
	character_mascot.size = Vector2(256, 144)
	character_mascot.pivot_offset = Vector2(128, 72)
	
	mascot_sprite = TextureRect.new()
	mascot_sprite.name = "MascotSprite"
	mascot_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot_sprite.size = Vector2(256, 144)
	mascot_sprite.custom_minimum_size = Vector2(256, 144)
	mascot_sprite.texture = tex_char_idle
	mascot_sprite.pivot_offset = Vector2(128, 72)
	character_mascot.add_child(mascot_sprite)
	
	carried_icon = TextureRect.new()
	carried_icon.name = "CarriedIcon"
	carried_icon.custom_minimum_size = Vector2(56, 56)
	carried_icon.size = Vector2(56, 56)
	carried_icon.position = Vector2(100, -40)
	carried_icon.visible = false
	character_mascot.add_child(carried_icon)"""

assert old_bc11 in c11, "old_bc11 not found"
c11 = c11.replace(old_bc11, new_bc11)

# Center and spawn points in level_1_1
c11 = c11.replace("var char_center = character_mascot.position + Vector2(88, 49)", "var char_center = character_mascot.position + Vector2(128, 72)")
c11 = c11.replace("var feet_bottom = pos.y + 98.0", "var feet_bottom = pos.y + 144.0")
c11 = c11.replace("char_pos = Vector2(center_x - 88.0, 370.0)", "char_pos = Vector2(center_x - 128.0, 270.0)")

with open(path_11, 'w', encoding='utf-8') as f:
    f.write(c11)

print("level_1_1.gd updated successfully!")

# 4. UPDATE LEVEL 1.1 TSCN
path_tscn11 = r'C:/Projects/PING-/ping-game/scenes/gameplay/level_1_1.tscn'
with open(path_tscn11, 'r', encoding='utf-8') as f:
    t11 = f.read()

old_tscn11_char = """[node name="CharacterMascot" type="Control" parent="RoomContainer"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 700.0
offset_top = 340.0
offset_right = 876.0
offset_bottom = 438.0
pivot_offset = Vector2(88, 49)"""

new_tscn11_char = """[node name="CharacterMascot" type="Control" parent="RoomContainer"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 652.0
offset_top = 270.0
offset_right = 908.0
offset_bottom = 414.0
pivot_offset = Vector2(128, 72)"""

assert old_tscn11_char in t11, "old_tscn11_char not found"
t11 = t11.replace(old_tscn11_char, new_tscn11_char)

with open(path_tscn11, 'w', encoding='utf-8') as f:
    f.write(t11)

print("level_1_1.tscn updated successfully!")
