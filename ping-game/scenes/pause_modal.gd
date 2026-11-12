extends Control

# Modular Pause Modal - "PERMAINAN JEDA"
# Standardized across all levels (Level 1.1, 1.2, 1.3, etc.)

signal resume_requested
signal restart_requested
signal settings_requested
signal exit_requested

@onready var dim_overlay: ColorRect = %DimOverlay
@onready var pause_card: Control = %PauseCard
@onready var btn_resume: Button = %BtnResume
@onready var btn_restart: Button = %BtnRestart
@onready var btn_settings: Button = %BtnSettings
@onready var btn_exit: Button = %BtnExit
@onready var audio_player: AudioStreamPlayer = %AudioPlayer

var is_animating: bool = false
var settings_modal: Control

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	
	_setup_hover(btn_resume)
	_setup_hover(btn_restart)
	_setup_hover(btn_settings)
	_setup_hover(btn_exit)
	
	dim_overlay.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			_on_resume_pressed()
	)

func open() -> void:
	if is_animating:
		return
	is_animating = true
	visible = true
	
	_play_sfx(659.25, 440.0)
	
	var vp_sz = get_viewport_rect().size
	pause_card.position = Vector2((vp_sz.x - pause_card.size.x) / 2.0, (vp_sz.y - pause_card.size.y) / 2.0)
	pause_card.pivot_offset = pause_card.size / 2.0
	pause_card.scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(pause_card, "scale", Vector2.ONE, 0.22)
	await tw.finished
	is_animating = false

func close() -> void:
	if is_animating or not visible:
		return
	is_animating = true
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.14)
	tw.tween_property(pause_card, "scale", Vector2(0.85, 0.85), 0.14)
	await tw.finished
	visible = false
	is_animating = false

func _on_resume_pressed() -> void:
	_play_sfx(523.25, 659.25)
	await close()
	resume_requested.emit()

func _on_restart_pressed() -> void:
	_play_sfx(440.0, 330.0)
	await close()
	restart_requested.emit()
	get_tree().reload_current_scene()

func _on_settings_pressed() -> void:
	_play_sfx(587.33, 784.0)
	settings_requested.emit()
	if settings_modal:
		if settings_modal.has_method("open"):
			settings_modal.open()
		elif settings_modal.has_method("open_settings"):
			settings_modal.open_settings()
	else:
		# Check if parent or root has settings_modal
		var p_settings = get_tree().current_scene.find_child("SettingsModal", true, false)
		if p_settings and p_settings.has_method("open"):
			p_settings.open()

func _on_exit_pressed() -> void:
	_play_sfx(330.0, 220.0)
	await close()
	exit_requested.emit()
	get_tree().change_scene_to_file("res://scenes/level_path.tscn")

func _setup_hover(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.1)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.1)
	)

func _play_sfx(f1: float, f2: float) -> void:
	if not audio_player:
		return
	var sample_rate = 44100
	var duration = 0.12
	var num_samples = int(sample_rate * duration)
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var freq = lerp(f1, f2, t)
		var env = sin(t * PI)
		var val = sin(2.0 * PI * freq * (float(i) / float(sample_rate))) * env * 0.25
		var sample_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()
