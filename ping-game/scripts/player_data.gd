extends Node

signal user_changed(username: String)

var current_username: String = "Tamu"
var is_logged_in: bool = false
var current_stage: int = 1

var stage_progress: Dictionary = {
	1: { "unlocked_level": 3, "stars": { 1: 3, 2: 2, 3: 0 } },
	2: { "unlocked_level": 2, "stars": { 1: 3, 2: 0, 3: 0 } },
	3: { "unlocked_level": 1, "stars": { 1: 0, 2: 0, 3: 0 } },
	4: { "unlocked_level": 1, "stars": { 1: 0, 2: 0, 3: 0 } },
	5: { "unlocked_level": 1, "stars": { 1: 0, 2: 0, 3: 0 } },
}

func get_stage_unlocked_level(stage_num: int) -> int:
	if stage_num in stage_progress:
		return stage_progress[stage_num].get("unlocked_level", 1)
	return 1

func get_level_stars(stage_num: int, level_num: int) -> int:
	if stage_num in stage_progress and "stars" in stage_progress[stage_num]:
		return stage_progress[stage_num]["stars"].get(level_num, 0)
	return 0

func set_level_stars(stage_num: int, level_num: int, stars: int) -> void:
	if stage_num not in stage_progress:
		stage_progress[stage_num] = { "unlocked_level": 1, "stars": {} }
	stage_progress[stage_num]["stars"][level_num] = max(stage_progress[stage_num]["stars"].get(level_num, 0), stars)
	if stars > 0 and level_num < 3:
		stage_progress[stage_num]["unlocked_level"] = max(stage_progress[stage_num]["unlocked_level"], level_num + 1)

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
