extends "res://World/dungeon_base.gd"

@export var enemy_scene: PackedScene

func _setup_dungeon():
	_spawn_enemies()

func _spawn_enemies():
	var spawns = [
		$WorldObjects/F1_NormalSpawn_01,
		$WorldObjects/F1_NormalSpawn_02,
		$WorldObjects/F1_NormalSpawn_03,
		$WorldObjects/F1_NormalSpawn_04
	]

	for spawn in spawns:
		for i in range(3):
			var e = enemy_scene.instantiate()
			add_child(e)
			e.global_position = spawn.global_position + Vector2(i * 30, 0)
