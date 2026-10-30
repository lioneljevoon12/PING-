# 3. UPDATE LEVEL 1.1 GD
path_11 = r'C:/Projects/PING-/ping-game/scenes/gameplay/level_1_1.gd'
with open(path_11, 'r', encoding='utf-8') as f:
    c11 = f.read()

old_bc11 = """func _build_character_mascot() -> void:
	character_mascot.size = Vector2(176, 98)
	character_mascot.pivot_offset = Vector2(88, 49)
	
	mascot_sprite = TextureRect.new()
	mascot_sprite.size = Vector2(176, 98)
	mascot_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot_sprite.pivot_offset = Vector2(88, 49)
	mascot_sprite.texture = walk_frames[0] if walk_frames.size() > 0 else tex_router_idle
	character_mascot.add_child(mascot_sprite)
	
	# Floating Carried Cable Icon
	carried_icon = TextureRect.new()
	carried_icon.size = Vector2(58, 58)
	carried_icon.position = Vector2(59, -46)
	carried_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	carried_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	carried_icon.visible = false
	character_mascot.add_child(carried_icon)"""

new_bc11 = """func _build_character_mascot() -> void:
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
	character_mascot.add_child(carried_icon)"""

assert old_bc11 in c11, "old_bc11 not found in level_1_1.gd"
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

assert old_tscn11_char in t11, "old_tscn11_char not found in level_1_1.tscn"
t11 = t11.replace(old_tscn11_char, new_tscn11_char)

with open(path_tscn11, 'w', encoding='utf-8') as f:
    f.write(t11)

print("level_1_1.tscn updated successfully!")
