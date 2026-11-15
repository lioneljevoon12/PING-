extends Control

# Belajar Screen - Redesigned to match Figma "Belajar" (Screen 3)
@onready var back_btn: Button = %BackButton
@onready var btn_guidebook: Button = %BtnGuidebook
@onready var btn_practice: Button = %BtnPractice
@onready var guidebook_modal: Control = %GuidebookModal
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer

func _ready() -> void:
	# Back Button
	if back_btn:
		UiKit.style_back_button(back_btn)
		back_btn.pressed.connect(func():
			_play_sfx(493.88)
			get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		)
		_setup_hover(back_btn, 1.1)
		
	# Buku Panduan Button (Opens Guidebook popup modal)
	if btn_guidebook:
		btn_guidebook.pressed.connect(func():
			_play_sfx(659.25)
			if guidebook_modal and guidebook_modal.has_method("open"):
				guidebook_modal.open(0)
			else:
				get_tree().change_scene_to_file("res://scenes/guidebook.tscn")
		)
		_setup_hover(btn_guidebook, 1.04)
		
	# Mode Latihan Button
	if btn_practice:
		btn_practice.pressed.connect(func():
			_play_sfx(659.25)
			# Practice Mode: Start Stage 1 Level 1 without timer pressure
			get_tree().change_scene_to_file("res://scenes/gameplay/practice_mode.tscn")
		)
		_setup_hover(btn_practice, 1.04)
		
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-learn" in all_args:
		await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/belajar_revamp_render.png")
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
