class_name LevelConfig
extends Resource

# Resource konfigurasi parameter level gameplay
# Memisahkan angka tuning/level design dari logika UI

@export var level_id: String = "2.1"
@export var level_title: String = "Pengelompokan Kelas Alamat IPv4"
@export var packet_count: int = 10
@export var time_limit: float = 165.0 # 02:45 dalam detik
@export var initial_hearts: int = 3

# Ambang batas penilaian bintang
@export var three_star_min_hearts: int = 3
@export var three_star_min_time_ratio: float = 0.25 # Minimal 25% sisa waktu
@export var two_star_min_hearts: int = 2
@export var one_star_min_hearts: int = 1

func calculate_stars(remaining_hearts: int, remaining_time: float) -> int:
	if remaining_hearts <= 0:
		return 0
	if remaining_hearts >= three_star_min_hearts and (remaining_time / max(1.0, time_limit)) >= three_star_min_time_ratio:
		return 3
	elif remaining_hearts >= two_star_min_hearts:
		return 2
	elif remaining_hearts >= one_star_min_hearts:
		return 1
	return 1
