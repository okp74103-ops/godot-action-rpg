extends Node2D

@onready var player = $Player
@onready var spawn = $PlayerSpawn
@onready var hud = $ui


func _ready():
	player.global_position = spawn.global_position
	GameManager.set_spawn(spawn.global_position)

	GameManager.register_player(player)
	GameManager.register_hud(hud)

	player.apply_build(GameManager.selected_job)
