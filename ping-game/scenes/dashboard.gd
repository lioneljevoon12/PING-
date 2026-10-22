extends Control

# Top bar nodes
@onready var profile_btn: TextureButton = %ProfileButton
@onready var username_label: Label = %UsernameLabel
@onready var stars_btn: TextureButton = %StarsButton
@onready var settings_btn: TextureButton = %SettingsButton
@onready var back_btn: Button = %BackButton

# 2x2 Grid buttons
@onready var character_btn: TextureButton = %CharacterButton
@onready var guidebook_btn: TextureButton = %GuidebookButton
@onready var leaderboard_btn: TextureButton = %LeaderboardButton
@onready var practice_btn: TextureButton = %PracticeButton
@onready var guidebook_modal: Control = %GuidebookModal

# Stage buttons
@onready var stages_scroll: ScrollContainer = %StagesScroll
@onready var stage1_card: PanelContainer = %Stage1Card
@onready var stage1_play_btn: TextureButton = %Stage1PlayButton
@onready var stage2_card: PanelContainer = %Stage2Card
@onready var stage2_play_btn: TextureButton = %Stage2PlayButton
@onready var stage3_card: PanelContainer = %Stage3Card
@onready var stage3_play_btn: TextureButton = %Stage3PlayButton
@onready var stage4_card: PanelContainer = %Stage4Card
@onready var stage4_play_btn: TextureButton = %Stage4PlayButton
@onready var stage5_card: PanelContainer = %Stage5Card
@onready var stage5_play_btn: TextureButton = %Stage5PlayButton
@onready var chevron_btn: TextureButton = %ChevronButton

# Toast / Notification
@onready var toast_panel: PanelContainer = %ToastPanel
@onready var toast_label: Label = %ToastLabel
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer

var time_passed: float = 0.0
var chevron_base_y: float = 0.0
var toast_tween: Tween

func _ready() -> void:
	# Update player username
	_update_profile(PlayerData.current_username)
	PlayerData.user_changed.connect(_update_profile)
	
	# Initial setup of animations
	if chevron_btn:
		chevron_base_y = chevron_btn.position.y
		chevron_btn.pivot_offset = chevron_btn.size / 2.0
		
	if toast_panel:
		toast_panel.modulate.a = 0.0
		toast_panel.scale = Vector2(0.9, 0.9)
		
	# Responsive layout centering
	_reposition_responsive()
	get_viewport().size_changed.connect(_reposition_responsive)
	
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-scroll" in all_args:
		await get_tree().process_frame
		await get_tree().process_frame
		if stages_scroll:
			stages_scroll.scroll_vertical = 320
		await get_tree().create_timer(0.2).timeout
		var img = get_viewport().get_texture().get_image()
		if img:
			img.save_png("art/dashboard_scroll_render.png")
		get_tree().quit()

	if "--screenshot" in all_args:
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		if img:
			img.save_png("art/dashboard_render.png")
		get_tree().quit()
		
	# Setup button animations and events
	_setup_button(profile_btn, func(): show_toast("Profil: %s (Status: Aktif)" % PlayerData.current_username))
	_setup_button(stars_btn, func(): show_toast("Total Bintang: 12 / 57 Bintang terkumpul"))
	_setup_button(settings_btn, func(): show_toast("Membuka Pengaturan Sistem..."))
	if back_btn:
		_setup_button(back_btn, _on_back_pressed)
		
	_setup_button(character_btn, func(): show_toast("Karakter: Kustomisasi Teknisi segera hadir!"))
	_setup_button(guidebook_btn, func():
		if guidebook_modal:
			guidebook_modal.open()
	)
	_setup_button(leaderboard_btn, func(): show_toast("Papan Peringkat: Memuat rekor tercepat..."))
	_setup_button(practice_btn, func(): show_toast("Mode Latihan: Simulasi bebas waktu dimulai!"))
	
	_setup_stage_card(stage1_card, stage1_play_btn, 1, "Stage 1: Gudang Hardware")
	_setup_stage_card(stage2_card, stage2_play_btn, 2, "Stage 2: Koridor Server Utama")
	_setup_stage_card(stage3_card, stage3_play_btn, 3, "Stage 3: Ruang Kontrol Subnet")
	_setup_stage_card(stage4_card, stage4_play_btn, 4, "Stage 4: Topologi & Infrastruktur")
	_setup_stage_card(stage5_card, stage5_play_btn, 5, "Stage 5: Standardisasi OSI & Transport")
	
	_setup_button(chevron_btn, _on_chevron_pressed)

func _process(delta: float) -> void:
	time_passed += delta
	# Subtle floating bob and direction flip on chevron button
	if chevron_btn and chevron_base_y > 0.0:
		chevron_btn.position.y = chevron_base_y + sin(time_passed * 4.0) * 4.0
		if stages_scroll:
			var v_bar = stages_scroll.get_v_scroll_bar()
			var max_v = v_bar.max_value - stages_scroll.size.y
			if max_v > 10.0 and stages_scroll.scroll_vertical > max_v * 0.4:
				chevron_btn.rotation = lerp_angle(chevron_btn.rotation, PI, 10.0 * delta)
			else:
				chevron_btn.rotation = lerp_angle(chevron_btn.rotation, 0.0, 10.0 * delta)

func _on_chevron_pressed() -> void:
	if not stages_scroll:
		return
	var v_bar = stages_scroll.get_v_scroll_bar()
	var max_v = v_bar.max_value - stages_scroll.size.y
	if max_v <= 0.0:
		return
	var target_v = max_v if stages_scroll.scroll_vertical < max_v * 0.4 else 0.0
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(stages_scroll, "scroll_vertical", int(target_v), 0.35)
	play_sfx(659.25)

func _update_profile(user: String) -> void:
	if username_label:
		if user == "Tamu" or user == "Teknisi":
			username_label.text = "AKUN"
		else:
			username_label.text = user.to_upper()

func _setup_button(btn: Control, on_click: Callable) -> void:
	if not btn:
		return
		
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12)
		play_sfx(659.25)
	)
	btn.mouse_exited.connect(func():
		btn.pivot_offset = btn.size / 2.0
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
	)
	
	if btn is BaseButton:
		btn.button_down.connect(func():
			btn.pivot_offset = btn.size / 2.0
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)
			play_sfx(880.0)
		)
		btn.button_up.connect(func():
			btn.pivot_offset = btn.size / 2.0
			var target = Vector2(1.05, 1.05) if btn.is_hovered() else Vector2(1.0, 1.0)
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(btn, "scale", target, 0.1)
		)
		btn.pressed.connect(on_click)

func _setup_stage_card(card: PanelContainer, play_btn: TextureButton, stage_id: int, stage_name: String) -> void:
	if not card:
		return
		
	card.pivot_offset = card.size / 2.0
	
	var on_select = func():
		play_sfx(784.0) # G5 note
		# Pulse animation on card
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(card, "scale", Vector2(1.04, 1.04), 0.1)
		t.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)
		t.chain().tween_callback(func():
			if PlayerData:
				PlayerData.current_stage = stage_id
			get_tree().change_scene_to_file("res://scenes/level_path.tscn")
		)
		
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			on_select.call()
	)
	
	card.mouse_entered.connect(func():
		card.pivot_offset = card.size / 2.0
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "scale", Vector2(1.02, 1.02), 0.12)
		play_sfx(587.33) # D5
	)
	card.mouse_exited.connect(func():
		card.pivot_offset = card.size / 2.0
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.12)
	)
	
	if play_btn:
		_setup_button(play_btn, on_select)

func _on_back_pressed() -> void:
	play_sfx(523.25)
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func show_toast(message: String) -> void:
	if not toast_panel or not toast_label:
		return
		
	toast_label.text = message
	toast_panel.pivot_offset = toast_panel.size / 2.0
	
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_tween = create_tween()
	toast_tween.set_parallel(true)
	toast_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	toast_tween.tween_property(toast_panel, "scale", Vector2(1.0, 1.0), 0.2)
	
	toast_tween.chain().tween_interval(1.6)
	
	toast_tween.chain().set_parallel(true)
	toast_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.25)
	toast_tween.tween_property(toast_panel, "scale", Vector2(0.9, 0.9), 0.25)

func play_sfx(freq: float) -> void:
	if not audio_player:
		return
	var sample_rate = 44100
	var duration = 0.07
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 45.0)
		var sample_val = sin(t * freq * TAU) * envelope * 0.35
		var int_val = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _reposition_responsive() -> void:
	var screen_w = get_viewport_rect().size.x
	var content_w = 1163.0
	var target_left = max(24.0, (screen_w - content_w) / 2.0)
	var dx = target_left - 58.0
	
	if has_node("HeaderContainer"):
		$HeaderContainer.position.x = 58.0 + dx
	if has_node("Cardatas"):
		$Cardatas.position.x = 58.0 + dx
	if has_node("GridCards"):
		$GridCards.position.x = dx
	if has_node("StagesContainer"):
		$StagesContainer.position.x = dx
	if back_btn:
		back_btn.position.x = screen_w - back_btn.size.x - 36.0
	if toast_panel:
		toast_panel.position.x = (screen_w - toast_panel.size.x) / 2.0
