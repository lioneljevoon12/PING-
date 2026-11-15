extends Control

# Pilih Stage Screen - Redesigned to match Figma "Pilih Stage" (Screen 2)
@onready var back_btn: Button = %BackButton
@onready var stars_label: Label = %StarsLabel
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var stages_container: VBoxContainer = %StagesContainer
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer

func _ready() -> void:
	# Update stars count
	_update_stars_display()
	
	# Hide ugly scrollbar line while keeping smooth scroll
	if scroll_container:
		var vsb = scroll_container.get_v_scroll_bar()
		if vsb:
			var empty = StyleBoxEmpty.new()
			vsb.add_theme_stylebox_override("scroll", empty)
			vsb.add_theme_stylebox_override("scroll_focus", empty)
			vsb.add_theme_stylebox_override("grabber", empty)
			vsb.add_theme_stylebox_override("grabber_highlight", empty)
			vsb.add_theme_stylebox_override("grabber_pressed", empty)
			vsb.custom_minimum_size = Vector2.ZERO
			vsb.modulate.a = 0.0
	
	# Back Button
	if back_btn:
		UiKit.style_back_button(back_btn)
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
		stars_label.text = "BINTANG\n%d / %d" % [total, max_s]

func _build_stage_cards() -> void:
	for ch in stages_container.get_children():
		ch.queue_free()
		
	var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
	var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
	
	var tex_plug = preload("res://art/ui-ux/icons/figma_icon_plug.png")
	var tex_packet = preload("res://art/assets/PING! Assets/Sprite animation/paket data/1.png")
	var tex_stage3 = preload("res://art/ui-ux/dashboard/icon_stage3_router.png")
	var tex_stage4 = preload("res://art/ui-ux/dashboard/icon_stage4_topology.png")
	var tex_stage5 = preload("res://art/ui-ux/dashboard/icon_stage5_osi.png")
	
	var raw_stages = [
		{
			"num": 1,
			"title": "Stage 1: Gudang Hardware",
			"sub": "Physical & Data Link\nPerakitan Kabel UTP & Switch",
			"bg": Color("#fed0cf"),
			"icon": tex_plug
		},
		{
			"num": 2,
			"title": "Stage 2: Koridor Server Utama",
			"sub": "Network & Addressing\nPengalamatan IP & ARP",
			"bg": Color("#fef08a"),
			"icon": tex_packet
		},
		{
			"num": 3,
			"title": "Stage 3: Ruang Kontrol Subnet",
			"sub": "Subnetting & Routing\nNetID, HostID & CIDR",
			"bg": Color("#dbeafe"),
			"icon": tex_stage3
		},
		{
			"num": 4,
			"title": "Stage 4: Fasilitas Eksternal",
			"sub": "Topology & Infrastructure\nStar, Ring & Mesh",
			"bg": Color("#dcfce7"),
			"icon": tex_stage4
		},
		{
			"num": 5,
			"title": "Stage 5: Gerbang Internet",
			"sub": "Application & Security\nPort & Protokol",
			"bg": Color("#f3e8ff"),
			"icon": tex_stage5
		}
	]
	
	for raw in raw_stages:
		var s_num = int(raw["num"])
		var is_locked = not PlayerData.is_stage_unlocked(s_num)
		var cleared_count = PlayerData.get_stage_cleared_count(s_num)
		var total_lvls = PlayerData.get_stage_level_count(s_num)
		var score_str = "%d/%d" % [cleared_count, total_lvls] if not is_locked else "0/%d" % total_lvls
		
		var s = {
			"num": s_num,
			"title": raw["title"],
			"sub": raw["sub"],
			"bg": raw["bg"] if not is_locked else Color("#f1f5f9"),
			"border": Color("#4a2e2b") if not is_locked else Color("#94a3b8"),
			"icon": raw["icon"],
			"is_locked": is_locked,
			"score": score_str
		}
		var card = _create_stage_card(s, font_black, font_bold)
		stages_container.add_child(card)
		
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 30)
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stages_container.add_child(bottom_spacer)

func _create_stage_card(data: Dictionary, font_black: FontFile, font_bold: FontFile) -> Control:
	var card = PanelContainer.new()
	# Proportional height 86px so 4 cards fit cleanly without clipping
	card.custom_minimum_size = Vector2(940, 86)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = data["bg"]
	sb.border_color = data["border"]
	sb.set_border_width_all(3.0)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 22
	sb.content_margin_right = 40 # 40px safe breathing room from right border
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0.29, 0.18, 0.17, 0.22)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 3)
	card.add_theme_stylebox_override("panel", sb)
	
	var hb = HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 20)
	card.add_child(hb)
	
	# 1. Left Icon Container (Modular StageRowIcon component)
	var stage_icon = preload("res://scenes/stage_row_icon.tscn").instantiate()
	stage_icon.setup(data["icon"], data["is_locked"])
	hb.add_child(stage_icon)
	
	# 2. Middle Title & Subtitle
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 2)
	
	var t = Label.new()
	t.text = data["title"]
	t.add_theme_font_override("font", font_black)
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", Color("#2b1810") if not data["is_locked"] else Color("#64748b"))
	vb.add_child(t)
	
	var sub = Label.new()
	sub.text = data["sub"]
	sub.add_theme_font_override("font", font_bold)
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color("#78350f") if not data["is_locked"] else Color("#94a3b8"))
	vb.add_child(sub)
	hb.add_child(vb)
	
	# 3. Right Score
	var score_lbl = Label.new()
	score_lbl.text = data["score"]
	score_lbl.add_theme_font_override("font", font_black)
	score_lbl.add_theme_font_size_override("font_size", 22)
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
