extends CharacterBody2D

@export var move_speed := 100.0
@export var stop_range := 60.0
@export var attack_damage := 5
@export var attack_cooldown := 1.5
@export var max_hp := 100
@export var separation_radius := 60.0
@export var separation_force := 350.0
@export var detection_range := 200.0
@export var exp_reward := 3

@onready var hp_bar = get_node_or_null("ProgressBar")

var hp: float = 0.0
var attack_timer := 0.0
var player = null

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 800.0


func push_back(dir):
	velocity += dir * 200.0


func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force


func _ready():
	add_to_group("enemy")
	hp = max_hp

	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp


func _physics_process(delta):
	if hp <= 0:
		return

	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return

	if knockback_velocity.length() > 0.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		move_and_slide()
		return

	var dist = global_position.distance_to(player.global_position)
	var desired_velocity = Vector2.ZERO

	if dist < detection_range and dist > stop_range:
		var dir = (player.global_position - global_position).normalized()
		desired_velocity = dir * move_speed
	elif dist <= stop_range:
		attack_timer -= delta
		if attack_timer <= 0.0:
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
			attack_timer = attack_cooldown

	var separation = Vector2.ZERO

	for other in get_tree().get_nodes_in_group("enemy"):
		if other == self:
			continue

		var dist_to_other = global_position.distance_to(other.global_position)

		if dist_to_other < separation_radius and dist_to_other > 0.0:
			var push_dir = (global_position - other.global_position).normalized()
			var strength = (separation_radius - dist_to_other) / separation_radius
			separation += push_dir * separation_force * strength

	velocity = desired_velocity + separation
	velocity = velocity.limit_length(move_speed)

	move_and_slide()


func take_damage(amount: float):
	hp -= amount

	if hp_bar:
		hp_bar.value = hp

	_show_damage(amount)

	if hp <= 0.0:
		if player and player.has_method("gain_exp"):
			player.gain_exp(exp_reward)
		queue_free()


func _show_damage(amount: float):
	var dmg_scene = load("res://ui/DamageText.tscn")
	var dmg = dmg_scene.instantiate()

	dmg.text = str(int(amount))
	dmg.global_position = global_position + Vector2(0, -40)

	get_tree().current_scene.add_child(dmg)
