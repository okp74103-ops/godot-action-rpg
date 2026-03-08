extends Interactable

@export var dungeon_id: int

func interact(player: Node) -> void:
	GameManager.go_to_dungeon(dungeon_id)
