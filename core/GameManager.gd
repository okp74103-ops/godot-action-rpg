extends Node

# ===== 등록 대상 =====
var player: Node = null
var hud: Node = null
var world_root: Node = null
var status_ui = null
var player_data = {
	"STR": 10,
	"DEX": 10,
	"VIT": 10,
	"stat_points": 10
}

# ===== 전역 상태 =====
enum Job { BERSERKER, TANK }
enum Weapon { TWO_HAND, ONE_HAND, SHIELD }

var selected_job: Job = Job.BERSERKER
var selected_weapon: Weapon = Weapon.ONE_HAND
var current_difficulty: int = 1

var pending_spawn_position: Vector2 = Vector2.ZERO



# ===== 등록 =====
func register_player(p):
	self.player = p

	if player:
		player.apply_data(player_data)

	if status_ui:
		status_ui.connect_player(player)


func register_hud(h):
	hud = h
	_try_connect()


func _try_connect():
	if player and hud:
		hud.connect_player(player)


func _apply_pending_spawn():
	if player and pending_spawn_position != Vector2.ZERO:
		player.global_position = pending_spawn_position
		pending_spawn_position = Vector2.ZERO


# ===== 스폰 =====
func set_spawn(pos: Vector2):
	pending_spawn_position = pos


# ===== 씬 전환 =====
func change_scene(path: String):
	call_deferred("_deferred_change_scene", path)


func _deferred_change_scene(path: String):
	player = null
	hud = null
	get_tree().change_scene_to_file(path)


func go_to_dungeon(id: int):
	if id <= 0:
		push_error("Invalid dungeon id")
		return

	var path = "res://World/dungeon_%d.tscn" % id
	change_scene(path)

func register_status_ui(ui):
	status_ui = ui
	status_ui.visible = false

	if player:
		status_ui.connect_player(player)


func toggle_status_ui():
	if status_ui:
		status_ui.visible = !status_ui.visible
