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

# Stage buttons
@onready var stage1_card: PanelContainer = %Stage1Card
@onready var stage1_play_btn: TextureButton = %Stage1PlayButton
@onready var stage2_card: PanelContainer = %Stage2Card
@onready var stage2_play_btn: TextureButton = %Stage2PlayButton
@onready var stage3_card: PanelContainer = %Stage3Card
@onready var stage3_play_btn: TextureButton = %Stage3PlayButton
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
		
	if "--screenshot" in OS.get_cmdline_args():
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/dashboard_render.png")
		get_tree().quit()
		
	# Setup button animations and events
	_setup_button(profile_btn, func(): show_toast("Profil: %s (Status: Aktif)" % PlayerData.current_username))
	_setup_button(stars_btn, func(): show_toast("Total Bintang: 12 / 57 Bintang terkumpul"))
	_setup_button(settings_btn, func(): show_toast("Membuka Pengaturan Sistem..."))
	if back_btn:
		_setup_button(back_btn, _on_back_pressed)
		
	_setup_button(character_btn, func(): show_toast("Karakter: Kustomisasi Teknisi segera hadir!"))
	_setup_button(guidebook_btn, func(): show_toast("Buku Panduan: Modul Materi Jaringan terbuka!"))
	_setup_button(leaderboard_btn, func(): show_toast("Papan Peringkat: Memuat rekor tercepat..."))
	_setup_button(practice_btn, func(): show_toast("Mode Latihan: Simulasi bebas waktu dimulai!"))
	
	_setup_stage_card(stage1_card, stage1_play_btn, "Stage 1: Gudang Hardware")
	_setup_stage_card(stage2_card, stage2_play_btn, "Stage 2: Koridor Server Utama")
	_setup_stage_card(stage3_card, stage3_play_btn, "Stage 3: Ruang Kontrol Subnet")
	
	_setup_button(chevron_btn, func(): show_toast("Menampilkan stage berikutnya..."))

func _process(delta: float) -> void:
	time_passed += delta
	# Subtle floating bob on the chevron down button
	if chevron_btn and chevron_base_y > 0.0:
		chevron_btn.position.y = chevron_base_y + sin(time_passed * 4.0) * 4.0

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

func _setup_stage_card(card: PanelContainer, play_btn: TextureButton, stage_name: String) -> void:
	if not card:
		return
		
	card.pivot_offset = card.size / 2.0
	
	var on_select = func():
		play_sfx(784.0) # G5 note
		show_toast("Memilih %s..." % stage_name)
		# Pulse animation on card
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(card, "scale", Vector2(1.03, 1.03), 0.1)
		t.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)
		
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
