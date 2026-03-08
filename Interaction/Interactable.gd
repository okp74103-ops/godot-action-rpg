extends Area2D
class_name Interactable

@export var require_input := true
var player_inside := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		if not require_input:
			interact(body)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false

func _process(_delta):
	if require_input and player_inside:
		if Input.is_action_just_pressed("interact"):
			var player = get_tree().get_first_node_in_group("player")
			if player:
				interact(player)

func interact(player):
	pass
