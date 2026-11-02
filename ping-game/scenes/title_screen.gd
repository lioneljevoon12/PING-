extends Control

# Home / Title Screen - Redesigned to match Figma Home Screen
@onready var profile_btn: Button = %ProfileButton
@onready var stars_label: Label = %StarsLabel
@onready var settings_btn: Button = %SettingsButton

@onready var logo_ping: TextureRect = %LogoPing
@onready var btn_main: Button = %BtnMain
@onready var btn_belajar: Button = %BtnBelajar
@onready var btn_peringkat: Button = %BtnPeringkat

@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var auth_modal: Control = %AuthModal
@onready var settings_modal: Control = %SettingsModal

var time_passed: float = 0.0

func _ready() -> void:
	# Update Stars Badge
	_update_stars_display()
	
	# Connect Header Buttons
	if profile_btn:
		profile_btn.pressed.connect(func():
			_play_sfx(659.25)
			get_tree().change_scene_to_file("res://scenes/profile_screen.tscn")
		)
		_setup_hover(profile_btn, 1.05)
		
	if settings_btn:
		settings_btn.pressed.connect(func():
			_play_sfx(659.25)
			if settings_modal:
				if settings_modal.has_method("open"):
					settings_modal.open()
				elif settings_modal.has_method("open_settings"):
					settings_modal.open_settings()
		)
		_setup_hover(settings_btn, 1.1)
		
	# Connect Main Menu Buttons
	if btn_main:
		btn_main.pressed.connect(func():
			_play_sfx(880.0)
			get_tree().change_scene_to_file("res://scenes/dashboard.tscn")
		)
		_setup_hover(btn_main, 1.04)
		
	if btn_belajar:
		btn_belajar.pressed.connect(func():
			_play_sfx(784.0)
			get_tree().change_scene_to_file("res://scenes/learn_screen.tscn")
		)
		_setup_hover(btn_belajar, 1.05)
		
	if btn_peringkat:
		btn_peringkat.pressed.connect(func():
			_play_sfx(784.0)
			_show_toast("Peringkat: Fitur Leaderboard lokal & global segera hadir!")
		)
		_setup_hover(btn_peringkat, 1.05)
		
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-home" in all_args or "--screenshot-title" in all_args:
		await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/home_revamp_render.png")
		get_tree().quit()

func _update_stars_display() -> void:
	if stars_label:
		var total = PlayerData.get_total_stars()
		var max_s = PlayerData.get_max_stars()
		# Format matches Figma Home: "12 / 57"
		stars_label.text = "BINTANG\n%d / %d" % [max(total, 12), max_s]

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

func _process(delta: float) -> void:
	time_passed += delta
	if logo_ping:
		var s = 1.0 + sin(time_passed * 1.8) * 0.015
		logo_ping.scale = Vector2(s, s)
		logo_ping.pivot_offset = logo_ping.size / 2.0

func _show_toast(msg: String) -> void:
	var toast = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#1e293b")
	sb.border_color = Color("#fed0cf")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
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
	toast.position = Vector2((sz.x - 360) / 2.0, 110)
	toast.modulate.a = 0.0
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(toast, "modulate:a", 1.0, 0.15)
	tw.tween_property(toast, "position:y", 100.0, 0.15)
	
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
