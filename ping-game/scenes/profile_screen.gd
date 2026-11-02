extends Control

# Profil Screen - Redesigned to match Figma "Profil" (Screen 4)
@onready var back_btn: Button = %BackButton
@onready var btn_karakter: Button = %BtnKarakter
@onready var btn_akun: Button = %BtnAkun
@onready var btn_settings: Button = %BtnSettings
@onready var auth_modal: Control = %AuthModal
@onready var settings_modal: Control = %SettingsModal
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer

func _ready() -> void:
	# Back Button
	if back_btn:
		back_btn.pressed.connect(func():
			_play_sfx(493.88)
			get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		)
		_setup_hover(back_btn, 1.1)
		
	# Karakter Button
	if btn_karakter:
		btn_karakter.pressed.connect(func():
			_play_sfx(659.25)
			_show_toast("Karakter: Teknisi Jaringan Muda • Peringkat Junior Specialist")
		)
		_setup_hover(btn_karakter, 1.04)
		
	# Akun Button
	if btn_akun:
		btn_akun.pressed.connect(func():
			_play_sfx(659.25)
			if auth_modal:
				auth_modal.open("login")
		)
		_setup_hover(btn_akun, 1.04)
		
	# Pengaturan Button
	if btn_settings:
		btn_settings.pressed.connect(func():
			_play_sfx(659.25)
			if settings_modal:
				if settings_modal.has_method("open"):
					settings_modal.open()
				elif settings_modal.has_method("open_settings"):
					settings_modal.open_settings()
		)
		_setup_hover(btn_settings, 1.02)
		
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-profile" in all_args:
		await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/profil_revamp_render.png")
		get_tree().quit()

func _setup_hover(node: Control, factor: float) -> void:
	node.pivot_offset = node.size / 2.0
	node.mouse_entered.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector2(factor, factor), 0.1)
		_play_sfx(523.25)
	)
	node.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector2.ONE, 0.1)
	)

func _show_toast(msg: String) -> void:
	var toast = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#1e293b")
	sb.border_color = Color("#fed0cf")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	toast.add_theme_stylebox_override("panel", sb)
	
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_font_override("font", preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf"))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	toast.add_child(lbl)
	
	add_child(toast)
	var sz = get_viewport_rect().size
	toast.position = Vector2((sz.x - 480) / 2.0, 105)
	toast.modulate.a = 0.0
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(toast, "modulate:a", 1.0, 0.15)
	tw.tween_property(toast, "position:y", 95.0, 0.15)
	
	var tw2 = create_tween()
	tw2.tween_interval(2.5)
	tw2.tween_property(toast, "modulate:a", 0.0, 0.2)
	tw2.tween_callback(toast.queue_free)

func _play_sfx(freq: float) -> void:
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
		var val = sin(2.0 * PI * freq * t) * env * 0.25
		var sample_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()
