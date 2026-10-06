extends Control

signal auth_successful(username: String)

@onready var modal_card: PanelContainer = %ModalCard
@onready var title_label: Label = %TitleLabel
@onready var tab_texture_rect: TextureRect = %TabTextureRect
@onready var username_input: LineEdit = %UsernameInput
@onready var password_input: LineEdit = %PasswordInput
@onready var confirm_pwd_container: VBoxContainer = %ConfirmPwdContainer
@onready var confirm_pwd_input: LineEdit = %ConfirmPwdInput
@onready var options_row: HBoxContainer = %OptionsRow
@onready var submit_btn_label: Label = %SubmitBtnLabel
@onready var submit_button: Button = %SubmitButton
@onready var google_btn: TextureButton = %GooglePlayButton
@onready var close_btn: TextureButton = %CloseButton

const TAB_LOGIN_TEX = preload("res://art/ui-ux/masuk-left-button.png")
const TAB_SIGNUP_TEX = preload("res://art/ui-ux/daftar-right-button.png")

var is_login_mode: bool = true

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	
	close_btn.pressed.connect(close_modal)
	google_btn.pressed.connect(_on_google_play_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	
	# Setup button animations
	_setup_button_effects(google_btn)
	_setup_button_effects(close_btn)
	_setup_button_effects(submit_button)

func _setup_button_effects(btn: Control) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(func(): 
		btn.pivot_offset = btn.size / 2.0
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.1)
	)
	btn.mouse_exited.connect(func(): 
		btn.pivot_offset = btn.size / 2.0
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)
	if btn is BaseButton:
		btn.button_down.connect(func(): 
			btn.pivot_offset = btn.size / 2.0
			var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)
		)
		btn.button_up.connect(func(): 
			btn.pivot_offset = btn.size / 2.0
			var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2(1.04, 1.04) if btn.is_hovered() else Vector2(1.0, 1.0), 0.08)
		)

func open(mode: String = "login") -> void:
	set_mode(mode)
	visible = true
	
	# Animate card pop-in
	modal_card.pivot_offset = modal_card.size / 2.0
	modal_card.scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(modal_card, "scale", Vector2(1.0, 1.0), 0.25)
	
	# Focus on username input
	username_input.grab_focus()

func close_modal() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_property(modal_card, "scale", Vector2(0.9, 0.9), 0.15)
	await tween.finished
	visible = false

func set_mode(mode: String) -> void:
	is_login_mode = (mode == "login")
	
	if is_login_mode:
		title_label.text = "Masuk ke PING!"
		tab_texture_rect.texture = TAB_LOGIN_TEX
		confirm_pwd_container.visible = false
		options_row.visible = true
		submit_btn_label.text = "MASUK"
	else:
		title_label.text = "Daftar Akun Baru"
		tab_texture_rect.texture = TAB_SIGNUP_TEX
		confirm_pwd_container.visible = true
		options_row.visible = false
		submit_btn_label.text = "DAFTAR SEKARANG"

func _on_tab_login_clicked() -> void:
	if not is_login_mode:
		set_mode("login")

func _on_tab_signup_clicked() -> void:
	if is_login_mode:
		set_mode("signup")

func _on_google_play_pressed() -> void:
	var user = "Google_Player"
	PlayerData.login(user)
	auth_successful.emit(user)
	close_modal()

func _on_submit_pressed() -> void:
	var user = username_input.text.strip_edges()
	if user == "":
		user = "Teknisi"
		
	PlayerData.login(user)
	auth_successful.emit(user)
	close_modal()

func _on_bg_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_modal()
