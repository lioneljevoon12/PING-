import os

tscn_content = """[gd_scene load_steps=12 format=3 uid="uid://c6xk7b2v1y5np"]

[ext_resource type="Script" path="res://scenes/title_screen.gd" id="1_script"]
[ext_resource type="FontFile" uid="uid://2b0j6ww185b1" path="res://fonts/MADE Tommy Soft Bold PERSONAL USE.otf" id="2_font_bold"]
[ext_resource type="Texture2D" uid="uid://cxvh871u3s2e2" path="res://art/ui-ux/dashboard/bg_dashboard.png" id="3_bg"]
[ext_resource type="Texture2D" uid="uid://bv8v70g5yff86" path="res://art/assets/PING! Assets/Titles/PING-JUDUL.png" id="4_logo"]
[ext_resource type="Texture2D" uid="uid://75ukddvk2pe8" path="res://art/assets/scattered/Paket_data-removebg-preview.png" id="5_packet"]
[ext_resource type="PackedScene" uid="uid://b3y7kx8v4pq2n" path="res://scenes/auth_modal.tscn" id="6_auth_modal"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_greeting"]
content_margin_left = 6.0
content_margin_top = 4.0
content_margin_right = 16.0
content_margin_bottom = 4.0
bg_color = Color(0.972549, 0.945098, 0.94902, 1)
border_width_left = 3
border_width_top = 3
border_width_right = 3
border_width_bottom = 3
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 26
corner_radius_top_right = 26
corner_radius_bottom_right = 26
corner_radius_bottom_left = 26
shadow_color = Color(0.352941, 0.164706, 0.152941, 0.22)
shadow_size = 6
shadow_offset = Vector2(0, 3)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_avatar_circle"]
content_margin_left = 2.0
content_margin_top = 2.0
content_margin_right = 2.0
content_margin_bottom = 2.0
bg_color = Color(0.956863, 0.921569, 0.952941, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 21
corner_radius_top_right = 21
corner_radius_bottom_right = 21
corner_radius_bottom_left = 21

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_btn_play"]
content_margin_left = 20.0
content_margin_top = 10.0
content_margin_right = 20.0
content_margin_bottom = 10.0
bg_color = Color(1, 0.952941, 0.690196, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 20
corner_radius_top_right = 20
corner_radius_bottom_right = 20
corner_radius_bottom_left = 20
shadow_color = Color(0.352941, 0.164706, 0.152941, 0.3)
shadow_size = 6
shadow_offset = Vector2(0, 4)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_btn_play_pressed"]
content_margin_left = 20.0
content_margin_top = 10.0
content_margin_right = 20.0
content_margin_bottom = 10.0
bg_color = Color(0.98, 0.92, 0.62, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 20
corner_radius_top_right = 20
corner_radius_bottom_right = 20
corner_radius_bottom_left = 20
shadow_color = Color(0.352941, 0.164706, 0.152941, 0.15)
shadow_size = 2
shadow_offset = Vector2(0, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_btn_login"]
content_margin_left = 20.0
content_margin_top = 10.0
content_margin_right = 20.0
content_margin_bottom = 10.0
bg_color = Color(0.968627, 0.87451, 0.360784, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 20
corner_radius_top_right = 20
corner_radius_bottom_right = 20
corner_radius_bottom_left = 20
shadow_color = Color(0.352941, 0.164706, 0.152941, 0.3)
shadow_size = 6
shadow_offset = Vector2(0, 4)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_btn_login_pressed"]
content_margin_left = 20.0
content_margin_top = 10.0
content_margin_right = 20.0
content_margin_bottom = 10.0
bg_color = Color(0.92, 0.82, 0.3, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.352941, 0.164706, 0.152941, 1)
corner_radius_top_left = 20
corner_radius_top_right = 20
corner_radius_bottom_right = 20
corner_radius_bottom_left = 20
shadow_color = Color(0.352941, 0.164706, 0.152941, 0.15)
shadow_size = 2
shadow_offset = Vector2(0, 1)

[node name="TitleScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_script")

[node name="Background" type="TextureRect" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("3_bg")
expand_mode = 1
stretch_mode = 6

[node name="GreetingBadge" type="PanelContainer" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 50.0
offset_top = 38.0
offset_right = 280.0
offset_bottom = 92.0
mouse_default_cursor_shape = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_greeting")

[node name="GreetingHBox" type="HBoxContainer" parent="GreetingBadge"]
layout_mode = 2
theme_override_constants/separation = 10
alignment = 0

[node name="AvatarCircle" type="PanelContainer" parent="GreetingBadge/GreetingHBox"]
custom_minimum_size = Vector2(42, 42)
layout_mode = 2
mouse_filter = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_avatar_circle")

[node name="AvatarIcon" type="TextureRect" parent="GreetingBadge/GreetingHBox/AvatarCircle"]
layout_mode = 2
mouse_filter = 2
texture = ExtResource("5_packet")
expand_mode = 1
stretch_mode = 5

[node name="UserGreetingLabel" type="Label" parent="GreetingBadge/GreetingHBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_fonts/font = ExtResource("2_font_bold")
theme_override_font_sizes/font_size = 15
text = "Halo, Player"
vertical_alignment = 1

[node name="CenterUI" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -270.0
offset_top = -185.0
offset_right = 270.0
offset_bottom = 225.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 22
alignment = 1

[node name="LogoPing" type="TextureRect" parent="CenterUI"]
unique_name_in_owner = true
custom_minimum_size = Vector2(540, 224)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("4_logo")
expand_mode = 1
stretch_mode = 5

[node name="ButtonsVBox" type="VBoxContainer" parent="CenterUI"]
layout_mode = 2
theme_override_constants/separation = 16
alignment = 1

[node name="PlayButton" type="Button" parent="CenterUI/ButtonsVBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(260, 62)
layout_mode = 2
size_flags_horizontal = 4
mouse_default_cursor_shape = 2
theme_override_colors/font_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_colors/font_pressed_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_colors/font_hover_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_fonts/font = ExtResource("2_font_bold")
theme_override_font_sizes/font_size = 21
theme_override_styles/normal = SubResource("StyleBoxFlat_btn_play")
theme_override_styles/hover = SubResource("StyleBoxFlat_btn_play")
theme_override_styles/pressed = SubResource("StyleBoxFlat_btn_play_pressed")
theme_override_styles/focus = SubResource("StyleBoxFlat_btn_play")
text = "MAINKAN"

[node name="LoginButton" type="Button" parent="CenterUI/ButtonsVBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(260, 62)
layout_mode = 2
size_flags_horizontal = 4
mouse_default_cursor_shape = 2
theme_override_colors/font_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_colors/font_pressed_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_colors/font_hover_color = Color(0.352941, 0.164706, 0.152941, 1)
theme_override_fonts/font = ExtResource("2_font_bold")
theme_override_font_sizes/font_size = 21
theme_override_styles/normal = SubResource("StyleBoxFlat_btn_login")
theme_override_styles/hover = SubResource("StyleBoxFlat_btn_login")
theme_override_styles/pressed = SubResource("StyleBoxFlat_btn_login_pressed")
theme_override_styles/focus = SubResource("StyleBoxFlat_btn_login")
text = "MASUK"

[node name="AuthModal" parent="." instance=ExtResource("6_auth_modal")]
unique_name_in_owner = true
visible = false
layout_mode = 1

[node name="AudioStreamPlayer" type="AudioStreamPlayer" parent="."]
unique_name_in_owner = true
"""

gd_content = """extends Control

# Node References
@onready var play_button: Button = %PlayButton
@onready var login_button: Button = %LoginButton
@onready var logo_ping: TextureRect = %LogoPing
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var auth_modal: Control = %AuthModal
@onready var user_greeting_label: Label = %UserGreetingLabel
@onready var greeting_badge: PanelContainer = %GreetingBadge

var time_passed: float = 0.0

func _ready() -> void:
	await get_tree().process_frame
	
	# Connect button events
	_setup_button(play_button, "PLAY")
	_setup_button(login_button, "LOG-IN")
	
	# Update User Greeting
	_update_greeting(PlayerData.current_username)
	PlayerData.user_changed.connect(_update_greeting)
	
	# Greeting badge click to log in
	if greeting_badge:
		greeting_badge.gui_input.connect(_on_greeting_badge_gui_input)
		
	if "--screenshot-title" in OS.get_cmdline_args():
		await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/title_render.png")
		get_tree().quit()

func _update_greeting(username: String) -> void:
	if user_greeting_label:
		if username.is_empty() or username == "Tamu":
			user_greeting_label.text = "Halo, Player"
		else:
			user_greeting_label.text = "Halo, %s" % username
		
		# Animate small bounce on name update
		if greeting_badge:
			greeting_badge.pivot_offset = greeting_badge.size / 2.0
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(greeting_badge, "scale", Vector2(1.1, 1.1), 0.15)
			tween.tween_property(greeting_badge, "scale", Vector2(1.0, 1.0), 0.15)

func _on_greeting_badge_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		play_sfx(659.25)
		if auth_modal:
			auth_modal.open("login")

func _setup_button(btn: Button, btn_name: String) -> void:
	if not btn:
		return
	btn.pivot_offset = btn.size / 2.0
	
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		_animate_button_scale(btn, Vector2(1.05, 1.05))
		play_sfx(659.25)
	)
	btn.mouse_exited.connect(func():
		btn.pivot_offset = btn.size / 2.0
		_animate_button_scale(btn, Vector2(1.0, 1.0))
	)
	btn.button_down.connect(func():
		btn.pivot_offset = btn.size / 2.0
		_animate_button_scale(btn, Vector2(0.95, 0.95))
		play_sfx(880.0)
	)
	btn.button_up.connect(func():
		btn.pivot_offset = btn.size / 2.0
		var target = Vector2(1.05, 1.05) if btn.is_hovered() else Vector2(1.0, 1.0)
		_animate_button_scale(btn, target)
	)
	btn.pressed.connect(func():
		_on_button_clicked(btn_name)
	)

func _animate_button_scale(btn: Button, target_scale: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, 0.12)

func _process(delta: float) -> void:
	time_passed += delta
	# Subtle breathing pulse on PING! logo
	if logo_ping:
		var s = 1.0 + sin(time_passed * 1.8) * 0.015
		logo_ping.scale = Vector2(s, s)
		logo_ping.pivot_offset = logo_ping.size / 2.0

func _on_button_clicked(button_name: String) -> void:
	match button_name:
		"PLAY":
			print("Memulai Game untuk user: %s" % PlayerData.current_username)
			get_tree().change_scene_to_file("res://scenes/dashboard.tscn")
		"LOG-IN":
			if auth_modal:
				auth_modal.open("login")

# Procedural Audio Synth for cute pop sounds
func play_sfx(freq: float) -> void:
	if not audio_player:
		return
	var sample_rate = 44100
	var duration = 0.08
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
		var val = sin(2.0 * PI * freq * t) * env * 0.3
		var sample_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()
"""

with open('ping-game/scenes/title_screen.tscn', 'w', encoding='utf-8') as f:
    f.write(tscn_content)

with open('ping-game/scenes/title_screen.gd', 'w', encoding='utf-8') as f:
    f.write(gd_content)

print("Updated title_screen.tscn and title_screen.gd successfully!")
