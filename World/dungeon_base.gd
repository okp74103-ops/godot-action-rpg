extends Node2D
class_name DungeonBase

@onready var player = $Player
@onready var spawn_point = $WorldObjects/PlayerSpawn


func _ready():
	_initialize_player()
	_register_system()
	_setup_dungeon()


# =========================
# 공통 시스템 연결
# =========================
func _register_system():
	GameManager.register_player(player)
	GameManager.register_hud($UI/HUD)


# =========================
# 플레이어 초기 위치 설정
# =========================
func _initialize_player():
	if spawn_point:
		player.global_position = spawn_point.global_position
		GameManager.set_spawn(spawn_point.global_position)


# =========================
# 던전별 콘텐츠 초기화 (override 전용)
# =========================
func _setup_dungeon():
	pass
	
