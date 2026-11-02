extends Control

# Pilih Stage Screen - Redesigned to match Figma "Pilih Stage" (Screen 2)
@onready var back_btn: Button = %BackButton
@onready var stars_label: Label = %StarsLabel
@onready var stages_container: VBoxContainer = %StagesContainer
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer

func _ready() -> void:
	# Update stars count
	_update_stars_display()
	
	# Back Button
	if back_btn:
		back_btn.pressed.connect(func():
			_play_sfx(493.88)
			get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		)
		_setup_hover(back_btn, 1.1)
		
	# Build Stage Cards
	_build_stage_cards()
	
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-stages" in all_args or "--screenshot-scroll" in all_args:
		await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/pilih_stage_render.png")
		get_tree().quit()

func _update_stars_display() -> void:
	if stars_label:
		var total = PlayerData.get_total_stars()
		var max_s = PlayerData.get_max_stars()
		stars_label.text = "BINTANG\n%d / %d" % [max(total, 12), max_s]

func _build_stage_cards() -> void:
	# Clear existing children
	for ch in stages_container.get_children():
		ch.queue_free()
		
	var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
	var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
	
	var tex_plug = preload("res://art/ui-ux/icons/figma_icon_plug.png")
	var tex_packet = preload("res://art/ui-ux/dashboard/icon_stage2_packet.png")
	var tex_lock = preload("res://art/ui-ux/icons/figma_icon_lock.png")
	
	var stages_data = [
		{
			"num": 1,
			"title": "Stage 1: Gudang Hardware",
			"sub": "Physical & Data Link\nPerakitan Kabel UTP & Switch",
			"bg": Color("#fed0cf"),
			"border": Color("#4a2e2b"),
			"icon": tex_plug,
			"is_locked": false,
			"score": "3/3"
		},
		{
			"num": 2,
			"title": "Stage 2: Koridor Server Utama",
			"sub": "Network & Addressing\nPengalamatan IP & ARP",
			"bg": Color("#fef08a"),
			"border": Color("#4a2e2b"),
			"icon": tex_packet,
			"is_locked": false,
			"score": "1/3"
		},
		{
			"num": 3,
			"title": "Stage 3: Ruang Kontrol Subnet",
			"sub": "Subnetting & Routing\nNetID, HostID & CIDR",
			"bg": Color("#f3e8ff"),
			"border": Color("#4a2e2b"),
			"icon": tex_lock,
			"is_locked": true,
			"score": "0/3"
		},
		{
			"num": 4,
			"title": "Stage 4: Fasilitas Eksternal",
			"sub": "Topology & Infrastructure\nStar, Ring & Mesh",
			"bg": Color("#f3e8ff"),
			"border": Color("#4a2e2b"),
			"icon": tex_lock,
			"is_locked": true,
			"score": "0/3"
		},
		{
			"num": 5,
			"title": "Stage 5: Gerbang Internet",
			"sub": "Application & Security\nPort & Protokol",
			"bg": Color("#f3e8ff"),
			"border": Color("#4a2e2b"),
			"icon": tex_lock,
			"is_locked": true,
			"score": "0/3"
		}
	]
	
	for s in stages_data:
		var card = _create_stage_card(s, font_black, font_bold)
		stages_container.add_child(card)

func _create_stage_card(data: Dictionary, font_black: FontFile, font_bold: FontFile) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(980, 110)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = data["bg"]
	sb.border_color = data["border"]
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(22)
	sb.content_margin_left = 32
	sb.content_margin_right = 52 # 52px of guaranteed margin from right border!
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	sb.shadow_color = Color(0.29, 0.18, 0.17, 0.25)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", sb)
	
	var hb = HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 24)
	card.add_child(hb)
	
	# 1. Left Icon Container (64x64)
	var icon_box = PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(64, 64)
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_ic = StyleBoxFlat.new()
	sb_ic.bg_color = Color.WHITE if not data["is_locked"] else Color("#e2e8f0")
	sb_ic.border_color = Color("#4a2e2b")
	sb_ic.set_border_width_all(2.5)
	sb_ic.set_corner_radius_all(14)
	icon_box.add_theme_stylebox_override("panel", sb_ic)
	
	var icon_rect = TextureRect.new()
	icon_rect.texture = data["icon"]
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(44, 44)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(icon_rect)
	hb.add_child(icon_box)
	
	# 2. Middle Title & Subtitle
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	
	var t = Label.new()
	t.text = data["title"]
	t.add_theme_font_override("font", font_black)
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Color("#2b1810") if not data["is_locked"] else Color("#64748b"))
	vb.add_child(t)
	
	var sub = Label.new()
	sub.text = data["sub"]
	sub.add_theme_font_override("font", font_bold)
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color("#78350f") if not data["is_locked"] else Color("#94a3b8"))
	vb.add_child(sub)
	hb.add_child(vb)
	
	# 3. Right Score
	var score_lbl = Label.new()
	score_lbl.text = data["score"]
	score_lbl.add_theme_font_override("font", font_black)
	score_lbl.add_theme_font_size_override("font_size", 26)
	score_lbl.add_theme_color_override("font_color", Color("#2b1810") if not data["is_locked"] else Color("#94a3b8"))
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(score_lbl)
	
	# 4. Transparent Clickable Button over the entire card
	var click_btn = Button.new()
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.flat = true
	click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_child(click_btn)
	
	_setup_hover(card, 1.02)
	
	var s_num = data["num"]
	var is_locked = data["is_locked"]
	click_btn.pressed.connect(func():
		if is_locked:
			_play_sfx(220.0)
			_show_toast("Stage %d Terkunci: Selesaikan stage sebelumnya terlebih dahulu!" % s_num)
		else:
			_play_sfx(659.25)
			PlayerData.current_stage = s_num
			get_tree().change_scene_to_file("res://scenes/level_path.tscn")
	)
	
	return card

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
		var val = sin(2.0 * PI * freq * t) * env * 0.3
		var sample_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()
