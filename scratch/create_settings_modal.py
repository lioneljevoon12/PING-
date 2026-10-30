import os

# Update scratch/create_settings_modal.py with polished dimensions

tscn_content = """[gd_scene load_steps=18 format=3 uid="uid://cxvsetmod001a"]

[ext_resource type="Script" path="res://scenes/settings_modal.gd" id="1_script"]
[ext_resource type="FontFile" uid="uid://2b0j6ww185b1" path="res://fonts/MADE Tommy Soft Bold PERSONAL USE.otf" id="2_font_bold"]
[ext_resource type="FontFile" uid="uid://dyvkugdedh0xm" path="res://fonts/MADE Tommy Soft Regular PERSONAL USE.otf" id="3_font_reg"]
[ext_resource type="FontFile" uid="uid://mdjxuauhw7j0" path="res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf" id="4_font_black"]
[ext_resource type="FontFile" uid="uid://dwd0sb6ffhlic" path="res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf" id="5_font_extrabold"]
[ext_resource type="FontFile" uid="uid://dsqq4nxtdx5u7" path="res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf" id="6_font_bold"]
[ext_resource type="Texture2D" uid="uid://1ts4rqqvwb0a" path="res://art/ui-ux/close-removebg-preview.png" id="7_close_btn"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_card"]
content_margin_left = 28.0
content_margin_top = 20.0
content_margin_right = 28.0
content_margin_bottom = 20.0
bg_color = Color(0.996078, 0.988235, 0.968627, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 5
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 24
corner_radius_top_right = 24
corner_radius_bottom_right = 24
corner_radius_bottom_left = 24
shadow_color = Color(0.352941, 0.164706, 0.152941, 0.25)
shadow_size = 12
shadow_offset = Vector2(0, 6)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_sec_pill"]
content_margin_left = 12.0
content_margin_top = 3.0
content_margin_right = 14.0
content_margin_bottom = 3.0
bg_color = Color(0.992157, 0.913725, 0.823529, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 14
corner_radius_top_right = 14
corner_radius_bottom_right = 14
corner_radius_bottom_left = 14

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_btn_save"]
content_margin_left = 24.0
content_margin_top = 8.0
content_margin_right = 24.0
content_margin_bottom = 8.0
bg_color = Color(0.968627, 0.87451, 0.360784, 1)
border_width_left = 3
border_width_top = 3
border_width_right = 3
border_width_bottom = 4
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 18
corner_radius_top_right = 18
corner_radius_bottom_right = 18
corner_radius_bottom_left = 18
shadow_color = Color(0.352941, 0.164706, 0.152941, 0.25)
shadow_size = 5
shadow_offset = Vector2(0, 3)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_btn_save_hover"]
content_margin_left = 24.0
content_margin_top = 8.0
content_margin_right = 24.0
content_margin_bottom = 8.0
bg_color = Color(1, 0.917647, 0.45098, 1)
border_width_left = 3
border_width_top = 3
border_width_right = 3
border_width_bottom = 4
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 18
corner_radius_top_right = 18
corner_radius_bottom_right = 18
corner_radius_bottom_left = 18
shadow_color = Color(0.352941, 0.164706, 0.152941, 0.35)
shadow_size = 6
shadow_offset = Vector2(0, 4)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_btn_save_pressed"]
content_margin_left = 24.0
content_margin_top = 10.0
content_margin_right = 24.0
content_margin_bottom = 6.0
bg_color = Color(0.921569, 0.819608, 0.278431, 1)
border_width_left = 3
border_width_top = 3
border_width_right = 3
border_width_bottom = 2
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 18
corner_radius_top_right = 18
corner_radius_bottom_right = 18
corner_radius_bottom_left = 18
shadow_size = 2
shadow_offset = Vector2(0, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_btn_active"]
content_margin_left = 14.0
content_margin_top = 6.0
content_margin_right = 14.0
content_margin_bottom = 6.0
bg_color = Color(0.968627, 0.87451, 0.360784, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 3
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_btn_inactive"]
content_margin_left = 14.0
content_margin_top = 6.0
content_margin_right = 14.0
content_margin_bottom = 6.0
bg_color = Color(0.94902, 0.929412, 0.898039, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.72, 0.68, 0.64, 1)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_info_card"]
content_margin_left = 14.0
content_margin_top = 6.0
content_margin_right = 14.0
content_margin_bottom = 6.0
bg_color = Color(0.952941, 0.937255, 0.909804, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.819608, 0.780392, 0.733333, 1)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[node name="SettingsModal" type="Control"]
process_mode = 3
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_script")

[node name="DimOverlay" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.243137, 0.219608, 0.207843, 0.5)

[node name="CenterBox" type="CenterContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="ModalCard" type="PanelContainer" parent="CenterBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(760, 580)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_card")

[node name="VBox" type="VBoxContainer" parent="CenterBox/ModalCard"]
layout_mode = 2
theme_override_constants/separation = 10

[node name="HeaderHBox" type="HBoxContainer" parent="CenterBox/ModalCard/VBox"]
layout_mode = 2
alignment = 1

[node name="HeaderIcon" type="Label" parent="CenterBox/ModalCard/VBox/HeaderHBox"]
layout_mode = 2
theme_override_fonts/font = ExtResource("5_font_extrabold")
theme_override_font_sizes/font_size = 22
text = "⚙️"

[node name="HeaderTitle" type="Label" parent="CenterBox/ModalCard/VBox/HeaderHBox"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_fonts/font = ExtResource("4_font_black")
theme_override_font_sizes/font_size = 21
text = " PENGATURAN SISTEM"
vertical_alignment = 1

[node name="CloseButton" type="TextureButton" parent="CenterBox/ModalCard/VBox/HeaderHBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(28, 28)
layout_mode = 2
size_flags_horizontal = 8
mouse_default_cursor_shape = 2
texture_normal = ExtResource("7_close_btn")
ignore_texture_size = true
stretch_mode = 5

[node name="HSeparator1" type="HSeparator" parent="CenterBox/ModalCard/VBox"]
layout_mode = 2

[node name="ScrollContainer" type="ScrollContainer" parent="CenterBox/ModalCard/VBox"]
layout_mode = 2
size_flags_vertical = 3
horizontal_scroll_mode = 0

[node name="ContentVBox" type="VBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 12

[node name="SecAudio" type="VBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="PillAudio" type="PanelContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio"]
layout_mode = 2
size_flags_horizontal = 0
theme_override_styles/panel = SubResource("StyleBoxFlat_sec_pill")

[node name="LblAudio" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio/PillAudio"]
layout_mode = 2
theme_override_colors/font_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 12
text = "🎵 PENGATURAN SUARA"

[node name="RowBgm" type="HBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="LblBgm" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio/RowBgm"]
custom_minimum_size = Vector2(170, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.290196, 0.180392, 0.168627, 1)
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 14
text = "Musik Latar (BGM)"

[node name="BgmSlider" type="HSlider" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio/RowBgm"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 30)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 4
max_value = 100.0
step = 1.0
value = 80.0

[node name="BgmValueLabel" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio/RowBgm"]
unique_name_in_owner = true
custom_minimum_size = Vector2(48, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 14
text = "80%"
horizontal_alignment = 2

[node name="BgmMuteButton" type="Button" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio/RowBgm"]
unique_name_in_owner = true
custom_minimum_size = Vector2(44, 32)
layout_mode = 2
mouse_default_cursor_shape = 2
theme_override_fonts/font = ExtResource("5_font_extrabold")
theme_override_font_sizes/font_size = 15
theme_override_styles/normal = SubResource("StyleBoxFlat_btn_inactive")
text = "🔊"

[node name="RowSfx" type="HBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="LblSfx" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio/RowSfx"]
custom_minimum_size = Vector2(170, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.290196, 0.180392, 0.168627, 1)
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 14
text = "Efek Suara (SFX)"

[node name="SfxSlider" type="HSlider" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio/RowSfx"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 30)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 4
max_value = 100.0
step = 1.0
value = 90.0

[node name="SfxValueLabel" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio/RowSfx"]
unique_name_in_owner = true
custom_minimum_size = Vector2(48, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 14
text = "90%"
horizontal_alignment = 2

[node name="SfxMuteButton" type="Button" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecAudio/RowSfx"]
unique_name_in_owner = true
custom_minimum_size = Vector2(44, 32)
layout_mode = 2
mouse_default_cursor_shape = 2
theme_override_fonts/font = ExtResource("5_font_extrabold")
theme_override_font_sizes/font_size = 15
theme_override_styles/normal = SubResource("StyleBoxFlat_btn_inactive")
text = "🔊"

[node name="SecControls" type="VBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="PillControls" type="PanelContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecControls"]
layout_mode = 2
size_flags_horizontal = 0
theme_override_styles/panel = SubResource("StyleBoxFlat_sec_pill")

[node name="LblControls" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecControls/PillControls"]
layout_mode = 2
theme_override_colors/font_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 12
text = "🕹️ KONTROL MOBILE"

[node name="RowJoystick" type="HBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecControls"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="LblJoy" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecControls/RowJoystick"]
custom_minimum_size = Vector2(170, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.290196, 0.180392, 0.168627, 1)
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 14
text = "Ukuran Analog"

[node name="JoystickHBox" type="HBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecControls/RowJoystick"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="BtnJoySmall" type="Button" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecControls/RowJoystick/JoystickHBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(96, 34)
layout_mode = 2
mouse_default_cursor_shape = 2
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 13
text = "Kecil"

[node name="BtnJoyNormal" type="Button" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecControls/RowJoystick/JoystickHBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(106, 34)
layout_mode = 2
mouse_default_cursor_shape = 2
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 13
text = "Normal"

[node name="BtnJoyLarge" type="Button" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecControls/RowJoystick/JoystickHBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(96, 34)
layout_mode = 2
mouse_default_cursor_shape = 2
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 13
text = "Besar"

[node name="RowHaptic" type="HBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecControls"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="LblHaptic" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecControls/RowHaptic"]
custom_minimum_size = Vector2(170, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.290196, 0.180392, 0.168627, 1)
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 14
text = "Getar Layar (Haptic)"

[node name="BtnHapticToggle" type="Button" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecControls/RowHaptic"]
unique_name_in_owner = true
custom_minimum_size = Vector2(130, 34)
layout_mode = 2
mouse_default_cursor_shape = 2
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 13
text = "AKTIF"

[node name="SecSystem" type="VBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="PillSystem" type="PanelContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecSystem"]
layout_mode = 2
size_flags_horizontal = 0
theme_override_styles/panel = SubResource("StyleBoxFlat_sec_pill")

[node name="LblSystem" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecSystem/PillSystem"]
layout_mode = 2
theme_override_colors/font_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 12
text = "⚙️ SISTEM & INFORMASI"

[node name="RowFps" type="HBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecSystem"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="LblFps" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecSystem/RowFps"]
custom_minimum_size = Vector2(170, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.290196, 0.180392, 0.168627, 1)
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 14
text = "Batas FPS (Performa)"

[node name="FpsHBox" type="HBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecSystem/RowFps"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="BtnFps30" type="Button" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecSystem/RowFps/FpsHBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(145, 34)
layout_mode = 2
mouse_default_cursor_shape = 2
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 13
text = "30 FPS (Hemat)"

[node name="BtnFps60" type="Button" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecSystem/RowFps/FpsHBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(145, 34)
layout_mode = 2
mouse_default_cursor_shape = 2
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 13
text = "60 FPS (Lancar)"

[node name="InfoCard" type="PanelContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecSystem"]
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_info_card")

[node name="InfoVBox" type="VBoxContainer" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecSystem/InfoCard"]
layout_mode = 2
theme_override_constants/separation = 1

[node name="AppTitle" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecSystem/InfoCard/InfoVBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_fonts/font = ExtResource("6_font_bold")
theme_override_font_sizes/font_size = 13
text = "PING! — Game Edukasi Teknisi Jaringan Komputer"

[node name="AppMeta" type="Label" parent="CenterBox/ModalCard/VBox/ScrollContainer/ContentVBox/SecSystem/InfoCard/InfoVBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.521569, 0.47451, 0.443137, 1)
theme_override_fonts/font = ExtResource("3_font_reg")
theme_override_font_sizes/font_size = 12
text = "Versi: v1.0.0 (Release Build) • Dikembangkan oleh Tim PING!"

[node name="HSeparator2" type="HSeparator" parent="CenterBox/ModalCard/VBox"]
layout_mode = 2

[node name="FooterHBox" type="HBoxContainer" parent="CenterBox/ModalCard/VBox"]
layout_mode = 2
alignment = 1

[node name="SaveCloseButton" type="Button" parent="CenterBox/ModalCard/VBox/FooterHBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(230, 46)
layout_mode = 2
mouse_default_cursor_shape = 2
theme_override_colors/font_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_colors/font_pressed_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_colors/font_hover_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_fonts/font = ExtResource("4_font_black")
theme_override_font_sizes/font_size = 16
theme_override_styles/normal = SubResource("StyleBoxFlat_btn_save")
theme_override_styles/hover = SubResource("StyleBoxFlat_btn_save_hover")
theme_override_styles/pressed = SubResource("StyleBoxFlat_btn_save_pressed")
theme_override_styles/focus = SubResource("StyleBoxFlat_btn_save")
text = "SIMPAN & KELUAR"
"""

with open('ping-game/scenes/settings_modal.tscn', 'w', encoding='utf-8') as f:
    f.write(tscn_content)

print("Refined settings_modal.tscn!")
