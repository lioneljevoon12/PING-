with open('ping-game/scenes/gameplay/level_1_1.gd', 'r', encoding='utf-8') as f:
    c1 = f.read()

# 1. Add var settings_modal to declarations
c1 = c1.replace(
    'var pause_modal: Control',
    'var pause_modal: Control\nvar settings_modal: Control'
)

# 2. Instantiate settings_modal in _ready
c1 = c1.replace(
    'func _ready() -> void:',
    'func _ready() -> void:\n\tsettings_modal = preload("res://scenes/settings_modal.tscn").instantiate()\n\tadd_child(settings_modal)'
)

# 3. Joystick scaling
old_joy_end = 'joystick_zone.gui_input.connect(_on_joystick_input)'
new_joy_end = """joystick_zone.gui_input.connect(_on_joystick_input)
	if SettingsManager:
		var j_scale = SettingsManager.get_joystick_scale()
		joystick_zone.scale = Vector2(j_scale, j_scale)
		SettingsManager.joystick_size_changed.connect(func(ns: float):
			if is_instance_valid(joystick_zone):
				joystick_zone.scale = Vector2(ns, ns)
		)"""
c1 = c1.replace(old_joy_end, new_joy_end)

# 4. Enlarge pause card to 365 height and add Settings Button
c1 = c1.replace(
    'p_card.size = Vector2(460, 320)\n\tp_card.pivot_offset = Vector2(230, 160)',
    'p_card.size = Vector2(460, 365)\n\tp_card.pivot_offset = Vector2(230, 182)'
)
c1 = c1.replace(
    'bg_p.size = Vector2(460, 320)',
    'bg_p.size = Vector2(460, 365)'
)

old_pause_btns = """	btn_p_restart.pressed.connect(func(): get_tree().reload_current_scene())
	vb_p.add_child(btn_p_restart)"""

new_pause_btns = """	btn_p_restart.pressed.connect(func(): get_tree().reload_current_scene())
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
	vb_p.add_child(btn_p_settings)"""

c1 = c1.replace(old_pause_btns, new_pause_btns)

# 5. Add haptic feedback
c1 = c1.replace(
    'func _open_inspect_modal(c_data: Dictionary = {}) -> void:',
    'func _open_inspect_modal(c_data: Dictionary = {}) -> void:\n\tif SettingsManager: SettingsManager.vibrate(35)'
)
c1 = c1.replace(
    'func _place_cable_on_rack(rack_idx: int) -> void:',
    'func _place_cable_on_rack(rack_idx: int) -> void:\n\tif SettingsManager: SettingsManager.vibrate(45)'
)
c1 = c1.replace(
    'func _show_win_modal() -> void:',
    'func _show_win_modal() -> void:\n\tif SettingsManager: SettingsManager.vibrate(80)'
)

with open('ping-game/scenes/gameplay/level_1_1.gd', 'w', encoding='utf-8') as f:
    f.write(c1)

print("level_1_1.gd updated!")

# Now level_1_2.gd
with open('ping-game/scenes/gameplay/level_1_2.gd', 'r', encoding='utf-8') as f:
    c2 = f.read()

c2 = c2.replace(
    'var pause_modal: Control',
    'var pause_modal: Control\nvar settings_modal: Control'
)
c2 = c2.replace(
    'func _ready() -> void:',
    'func _ready() -> void:\n\tsettings_modal = preload("res://scenes/settings_modal.tscn").instantiate()\n\tadd_child(settings_modal)'
)

c2 = c2.replace(
    'pause_card.size = Vector2(460, 320)\n\tpause_card.pivot_offset = Vector2(230, 160)',
    'pause_card.size = Vector2(460, 365)\n\tpause_card.pivot_offset = Vector2(230, 182)'
)
c2 = c2.replace(
    'bg_p.size = Vector2(460, 320)',
    'bg_p.size = Vector2(460, 365)'
)
c2 = c2.replace(old_pause_btns, new_pause_btns)

# Haptic in level 1.2
c2 = c2.replace(
    'func _on_wire_tapped(wire_key: String) -> void:',
    'func _on_wire_tapped(wire_key: String) -> void:\n\tif SettingsManager: SettingsManager.vibrate(35)'
)
c2 = c2.replace(
    'func _show_win_modal() -> void:',
    'func _show_win_modal() -> void:\n\tif SettingsManager: SettingsManager.vibrate(80)'
)

with open('ping-game/scenes/gameplay/level_1_2.gd', 'w', encoding='utf-8') as f:
    f.write(c2)

print("level_1_2.gd updated!")
