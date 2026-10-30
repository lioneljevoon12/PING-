extends Control

# Textures
const TEX_SOUND_ON = preload("res://art/ui-ux/icons/icon_sound.svg")
const TEX_SOUND_OFF = preload("res://art/ui-ux/icons/icon_sound_off.svg")

# Node References
@onready var modal_card: PanelContainer = %ModalCard
@onready var dim_overlay: ColorRect = %DimOverlay
@onready var close_button: TextureButton = %CloseButton
@onready var save_close_button: Button = %SaveCloseButton

# Audio Controls
@onready var bgm_slider: HSlider = %BgmSlider
@onready var bgm_value_label: Label = %BgmValueLabel
@onready var bgm_mute_button: Button = %BgmMuteButton

@onready var sfx_slider: HSlider = %SfxSlider
@onready var sfx_value_label: Label = %SfxValueLabel
@onready var sfx_mute_button: Button = %SfxMuteButton

# Controls & Gameplay
@onready var btn_joy_small: Button = %BtnJoySmall
@onready var btn_joy_normal: Button = %BtnJoyNormal
@onready var btn_joy_large: Button = %BtnJoyLarge
@onready var btn_haptic_toggle: Button = %BtnHapticToggle

# System
@onready var btn_fps_30: Button = %BtnFps30
@onready var btn_fps_60: Button = %BtnFps60

var is_animating: bool = false

# Preloaded Styles for active/inactive buttons
var style_active: StyleBoxFlat
var style_inactive: StyleBoxFlat

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	
	_init_styles()
	_connect_signals()

func _init_styles() -> void:
	# Active Style (Yellow Gold with dark brown border)
	style_active = StyleBoxFlat.new()
	style_active.bg_color = Color("#f7df5c")
	style_active.border_color = Color("#5a2a27")
	style_active.border_width_left = 2
	style_active.border_width_top = 2
	style_active.border_width_right = 2
	style_active.border_width_bottom = 3
	style_active.corner_radius_top_left = 12
	style_active.corner_radius_top_right = 12
	style_active.corner_radius_bottom_right = 12
	style_active.corner_radius_bottom_left = 12
	style_active.content_margin_left = 14
	style_active.content_margin_top = 6
	style_active.content_margin_right = 14
	style_active.content_margin_bottom = 6

	# Inactive Style (Neutral warm grey)
	style_inactive = StyleBoxFlat.new()
	style_inactive.bg_color = Color("#f2ede4")
	style_inactive.border_color = Color("#c7bdb0")
	style_inactive.border_width_left = 2
	style_inactive.border_width_top = 2
	style_inactive.border_width_right = 2
	style_inactive.border_width_bottom = 2
	style_inactive.corner_radius_top_left = 12
	style_inactive.corner_radius_top_right = 12
	style_inactive.corner_radius_bottom_right = 12
	style_inactive.corner_radius_bottom_left = 12
	style_inactive.content_margin_left = 14
	style_inactive.content_margin_top = 6
	style_inactive.content_margin_right = 14
	style_inactive.content_margin_bottom = 6

func _connect_signals() -> void:
	close_button.pressed.connect(close)
	save_close_button.pressed.connect(close)
	
	# BGM Slider & Mute
	bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	bgm_mute_button.pressed.connect(_on_bgm_mute_toggled)
	
	# SFX Slider & Mute
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	sfx_mute_button.pressed.connect(_on_sfx_mute_toggled)
	
	# Joystick Buttons
	btn_joy_small.pressed.connect(func(): _set_joystick_size("small"))
	btn_joy_normal.pressed.connect(func(): _set_joystick_size("normal"))
	btn_joy_large.pressed.connect(func(): _set_joystick_size("large"))
	
	# Haptic Toggle
	btn_haptic_toggle.pressed.connect(_on_haptic_toggled)
	
	# FPS Buttons
	btn_fps_30.pressed.connect(func(): _set_fps(30))
	btn_fps_60.pressed.connect(func(): _set_fps(60))

func open() -> void:
	if is_animating:
		return
	is_animating = true
	visible = true
	
	_load_ui_values()
	
	# Bounce scale animation
	modal_card.pivot_offset = modal_card.size / 2.0
	modal_card.scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	tw.tween_property(modal_card, "scale", Vector2.ONE, 0.25)
	await tw.finished
	is_animating = false

func close() -> void:
	if is_animating or not visible:
		return
	is_animating = true
	
	if SettingsManager:
		SettingsManager.play_sfx(523.25, 0.07) # Closing beep
		SettingsManager.save_settings()
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.16)
	tw.tween_property(modal_card, "scale", Vector2(0.9, 0.9), 0.16)
	await tw.finished
	visible = false
	is_animating = false

func _load_ui_values() -> void:
	if not SettingsManager:
		return
		
	# BGM
	bgm_slider.value = SettingsManager.bgm_volume * 100.0
	bgm_value_label.text = "%d%%" % int(bgm_slider.value)
	_update_mute_btn(bgm_mute_button, SettingsManager.bgm_muted)
	
	# SFX
	sfx_slider.value = SettingsManager.sfx_volume * 100.0
	sfx_value_label.text = "%d%%" % int(sfx_slider.value)
	_update_mute_btn(sfx_mute_button, SettingsManager.sfx_muted)
	
	# Joystick Size
	_update_joystick_ui(SettingsManager.joystick_size)
	
	# Haptic
	_update_haptic_ui(SettingsManager.haptic_enabled)
	
	# FPS
	_update_fps_ui(SettingsManager.fps_limit)

func _on_bgm_slider_changed(val: float) -> void:
	bgm_value_label.text = "%d%%" % int(val)
	if SettingsManager:
		SettingsManager.set_bgm_volume(val / 100.0)
		if SettingsManager.bgm_muted and val > 0:
			SettingsManager.set_bgm_muted(false)
			_update_mute_btn(bgm_mute_button, false)

func _on_bgm_mute_toggled() -> void:
	if not SettingsManager:
		return
	var new_muted = not SettingsManager.bgm_muted
	SettingsManager.set_bgm_muted(new_muted)
	_update_mute_btn(bgm_mute_button, new_muted)

func _on_sfx_slider_changed(val: float) -> void:
	sfx_value_label.text = "%d%%" % int(val)
	if SettingsManager:
		SettingsManager.set_sfx_volume(val / 100.0)
		if SettingsManager.sfx_muted and val > 0:
			SettingsManager.set_sfx_muted(false)
			_update_mute_btn(sfx_mute_button, false)
		# Play test beep so player hears difference
		SettingsManager.play_sfx(784.0, 0.05, 0.3)

func _on_sfx_mute_toggled() -> void:
	if not SettingsManager:
		return
	var new_muted = not SettingsManager.sfx_muted
	SettingsManager.set_sfx_muted(new_muted)
	_update_mute_btn(sfx_mute_button, new_muted)
	if not new_muted:
		SettingsManager.play_sfx(659.25, 0.06)

func _update_mute_btn(btn: Button, is_muted: bool) -> void:
	btn.icon = TEX_SOUND_OFF if is_muted else TEX_SOUND_ON
	btn.modulate = Color(1.0, 1.0, 1.0, 0.5) if is_muted else Color(1.0, 1.0, 1.0, 1.0)

func _set_joystick_size(size_str: String) -> void:
	if SettingsManager:
		SettingsManager.set_joystick_size(size_str)
		SettingsManager.play_sfx(659.25, 0.05)
	_update_joystick_ui(size_str)

func _update_joystick_ui(selected_size: String) -> void:
	_style_button(btn_joy_small, selected_size == "small")
	_style_button(btn_joy_normal, selected_size == "normal")
	_style_button(btn_joy_large, selected_size == "large")

func _on_haptic_toggled() -> void:
	if not SettingsManager:
		return
	var new_state = not SettingsManager.haptic_enabled
	SettingsManager.set_haptic_enabled(new_state)
	SettingsManager.play_sfx(659.25, 0.05)
	if new_state:
		SettingsManager.vibrate(50)
	_update_haptic_ui(new_state)

func _update_haptic_ui(enabled: bool) -> void:
	btn_haptic_toggle.text = "AKTIF" if enabled else "NONAKTIF"
	_style_button(btn_haptic_toggle, enabled)

func _set_fps(fps: int) -> void:
	if SettingsManager:
		SettingsManager.set_fps_limit(fps)
		SettingsManager.play_sfx(659.25, 0.05)
	_update_fps_ui(fps)

func _update_fps_ui(selected_fps: int) -> void:
	_style_button(btn_fps_30, selected_fps == 30)
	_style_button(btn_fps_60, selected_fps == 60)

func _style_button(btn: Button, is_active: bool) -> void:
	if is_active:
		btn.add_theme_stylebox_override("normal", style_active)
		btn.add_theme_stylebox_override("hover", style_active)
		btn.add_theme_stylebox_override("pressed", style_active)
		btn.add_theme_color_override("font_color", Color("#5a2a27"))
	else:
		btn.add_theme_stylebox_override("normal", style_inactive)
		btn.add_theme_stylebox_override("hover", style_inactive)
		btn.add_theme_stylebox_override("pressed", style_inactive)
		btn.add_theme_color_override("font_color", Color("#77706a"))
