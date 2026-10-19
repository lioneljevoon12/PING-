extends Node

signal user_changed(username: String)

var current_username: String = "Tamu"
var is_logged_in: bool = false

func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

func login(user: String) -> void:
	if user.strip_edges() != "":
		current_username = user.strip_edges()
	else:
		current_username = "Teknisi"
	is_logged_in = true
	user_changed.emit(current_username)

func logout() -> void:
	current_username = "Tamu"
	is_logged_in = false
	user_changed.emit(current_username)
