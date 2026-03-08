extends CharacterBody2D



enum State { MOVE, ATTACK, Q_SKILL, GUARD, DEAD }
enum Job { BERSERKER, TANK }

@onready var sprite: AnimatedSprite2D = $VisualRoot/Body


@export var job: Job = Job.BERSERKER
@export var move_speed := 190.0

# 베이스 스탯
@export var base_attack := 10.0
@export var base_max_hp := 100.0
@export var base_lifesteal := 0.04
@export var base_guard_reduction := 0.3

# 기본 스킬
@export var q_cooldown := 3.0
@export var attack_range := 60.0
@export var attack_angle := 90.0

# 대시
@export var dash_speed := 420.0
@export var dash_duration := 0.35
@export var dash_cooldown := 2.0

# 스킬 대시(E)
@export var skill_dash_speed := 520.0
@export var skill_dash_distance := 144.0
@export var skill_dash_damage_multiplier := 2.2
@export var skill_dash_hp_cost_ratio := 0.04
@export var skill_dash_cooldown := 3.0

# 내부 상태
var hp := 100.0
var level: int = 1
var current_exp: int = 0
var exp_to_next: int = 10

var current_state := State.MOVE
var state_timer := 0.0
var q_cd_timer := 0.0
var facing_dir := Vector2.RIGHT

var is_dashing := false
var dash_timer := 0.0
var dash_cd_timer := 0.0
var dash_direction := Vector2.ZERO

var is_skill_dashing := false
var skill_dash_travel := 0.0
var skill_dash_cd_timer := 0.0
var data
var stats := PlayerStats.new()
var DamageTextScene = preload("res://ui/DamageText.tscn")
var dmg = DamageTextScene.instantiate()

signal q_cd_changed(value)
signal hp_changed(value, max_value)
signal state_changed(new_state)
signal dash_cd_changed(value)
signal skill_dash_cd_changed(value)
signal exp_changed(current, max_value)
signal stats_changed()
@warning_ignore("unused_signal")
signal stat_points_changed(value)



func _ready():
	add_to_group("player")

	hp = get_max_hp()

	hp_changed.emit(hp, get_max_hp())
	q_cd_changed.emit(q_cd_timer)
	dash_cd_changed.emit(dash_cd_timer)
	skill_dash_cd_changed.emit(skill_dash_cd_timer)
	exp_changed.emit(current_exp, exp_to_next)
	state_changed.emit(current_state)
	

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if Input.is_action_just_pressed("open_status"):
		GameManager.toggle_status_ui()
	_update_timers(delta)
	

	if is_skill_dashing:
		_process_skill_dash(delta)
		return

	if is_dashing:
		_process_dash(delta)
		return

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if Input.is_action_just_pressed("dash"):
		try_dash(input_dir)

	if Input.is_action_just_pressed("skill_e"):
		try_skill_dash(input_dir)

	_update_facing(input_dir)
	_update_state(delta)
	_handle_movement(input_dir)


func _update_timers(delta):
	if state_timer > 0.0:
		state_timer = max(state_timer - delta, 0.0)
		if state_timer == 0.0 and current_state != State.GUARD:
			change_state(State.MOVE)

	if q_cd_timer > 0.0:
		q_cd_timer = max(q_cd_timer - delta, 0.0)
		q_cd_changed.emit(q_cd_timer)

	if dash_cd_timer > 0.0:
		dash_cd_timer = max(dash_cd_timer - delta, 0.0)
		dash_cd_changed.emit(dash_cd_timer)

	if skill_dash_cd_timer > 0.0:
		skill_dash_cd_timer = max(skill_dash_cd_timer - delta, 0.0)
		skill_dash_cd_changed.emit(skill_dash_cd_timer)


func _update_state(delta):
	if current_state == State.GUARD:
		_handle_guard(delta)
		return

	if state_timer > 0.0:
		return

	if Input.is_action_pressed("guard"):
		change_state(State.GUARD)
		return

	if Input.is_action_just_pressed("skill_q"):
		try_use_q_skill()
		return

	if Input.is_action_just_pressed("attack_left"):
		change_state(State.ATTACK)
		state_timer = 0.2
		_perform_attack()
		return

	change_state(State.MOVE)


func try_use_q_skill():
	if current_state != State.MOVE:
		return

	if q_cd_timer > 0.0:
		return

	if is_dashing or is_skill_dashing:
		return

	change_state(State.Q_SKILL)
	state_timer = 0.3

	_perform_q()

	q_cd_timer = q_cooldown
	q_cd_changed.emit(q_cd_timer)


func try_dash(input_dir: Vector2 = Vector2.ZERO):
	if current_state != State.MOVE:
		return

	if is_dashing or is_skill_dashing:
		return

	if dash_cd_timer > 0.0:
		return

	if input_dir == Vector2.ZERO:
		input_dir = facing_dir

	if input_dir == Vector2.ZERO:
		return

	is_dashing = true
	dash_timer = dash_duration
	dash_cd_timer = dash_cooldown
	dash_direction = input_dir.normalized()

	dash_cd_changed.emit(dash_cd_timer)


func try_skill_dash(input_dir: Vector2 = Vector2.ZERO):
	if current_state != State.MOVE:
		return

	if is_dashing or is_skill_dashing:
		return

	if skill_dash_cd_timer > 0.0:
		return

	if input_dir == Vector2.ZERO:
		input_dir = facing_dir

	if input_dir == Vector2.ZERO:
		return

	is_skill_dashing = true
	skill_dash_travel = 0.0
	dash_direction = input_dir.normalized()
	skill_dash_cd_timer = skill_dash_cooldown

	skill_dash_cd_changed.emit(skill_dash_cd_timer)

	set_collision_mask_value(2, false)

	var hp_cost = get_max_hp() * skill_dash_hp_cost_ratio
	hp = max(hp - hp_cost, 1.0)
	hp_changed.emit(hp, get_max_hp())

	_area_damage(72.0, 180.0, get_attack() * skill_dash_damage_multiplier)


func _process_dash(delta):
	dash_timer -= delta
	velocity = dash_direction * dash_speed

	if dash_timer <= 0.0:
		is_dashing = false
		velocity = Vector2.ZERO

	move_and_slide()


func _process_skill_dash(delta):
	var motion = dash_direction * skill_dash_speed * delta
	var collision = move_and_collide(motion)

	skill_dash_travel += motion.length()

	if collision or skill_dash_travel >= skill_dash_distance:
		_finish_skill_dash()


func _finish_skill_dash():
	is_skill_dashing = false
	skill_dash_travel = 0.0
	set_collision_mask_value(2, true)


func _handle_movement(input_dir: Vector2):
	if current_state in [State.GUARD, State.ATTACK, State.Q_SKILL]:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if input_dir != Vector2.ZERO:
		facing_dir = input_dir.normalized()

	velocity = input_dir.normalized() * move_speed
	move_and_slide()


func change_state(new_state):
	if current_state == new_state:
		return

	current_state = new_state
	state_changed.emit(new_state)


func _perform_attack():
	_area_damage(attack_range, attack_angle, get_attack())


func _perform_q():
	if job == Job.BERSERKER:
		_perform_berserker_q()
	else:
		_perform_tank_q()


func _perform_berserker_q():
	consume_skill_hp(0.04)
	_area_damage(144.0, 72.0, get_attack() * 2.2)


func _perform_tank_q():
	consume_skill_hp(0.03)
	_area_damage(120.0, 180.0, get_attack() * 1.8)


func consume_skill_hp(percent):
	var max_hp_value = get_max_hp()
	var cost = max_hp_value * percent

	hp -= cost
	hp = max(hp, 1.0)

	hp_changed.emit(hp, max_hp_value)
	show_damage(cost)


func _area_damage(radius, angle_deg, damage):
	var space = get_world_2d().direct_space_state

	var shape = CircleShape2D.new()
	shape.radius = radius

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 2

	var results = space.intersect_shape(query)

	for r in results:
		var enemy = r.collider

		if enemy == null:
			continue

		if not enemy.is_in_group("enemy"):
			continue

		var dir = (enemy.global_position - global_position).normalized()
		var dot = clamp(facing_dir.dot(dir), -1.0, 1.0)
		var deg = rad_to_deg(acos(dot))

		if deg > angle_deg:
			continue

		var ray_query = PhysicsRayQueryParameters2D.create(global_position, enemy.global_position)
		ray_query.collision_mask = 1
		var wall_hit = space.intersect_ray(ray_query)

		if wall_hit.size() > 0:
			continue

		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)

		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(dir * 300.0)

		if enemy.has_method("push_back"):
			enemy.push_back(dir)

		_apply_lifesteal(damage)


func _apply_lifesteal(damage):
	if job != Job.BERSERKER:
		return

	var max_hp_value = get_max_hp()
	var missing_ratio = (max_hp_value - hp) / max_hp_value
	var heal = damage * get_lifesteal() * (1.0 + missing_ratio * 2.0)

	hp = clamp(hp + heal, 0.0, max_hp_value)
	hp_changed.emit(hp, max_hp_value)


func _handle_guard(_delta):
	if not Input.is_action_pressed("guard"):
		change_state(State.MOVE)


func take_damage(amount):
	if current_state == State.DEAD:
		return

	if current_state == State.GUARD:
		amount *= (1.0 - get_guard_reduction())

	hp -= amount
	hp = max(hp, 0.0)

	hp_changed.emit(hp, get_max_hp())
	show_damage(amount)

	if hp <= 0.0:
		_die()


func _die():
	change_state(State.DEAD)
	velocity = Vector2.ZERO
	move_and_slide()





func get_lifesteal():
	return base_lifesteal


func get_guard_reduction():
	var v = base_guard_reduction
	if job == Job.TANK:
		v += 0.2
	return clamp(v, 0.0, 0.8)


func apply_build(new_job):
	job = new_job
	hp = int(get_max_hp())
	hp_changed.emit(hp, get_max_hp())


func _update_facing(dir: Vector2):
	if dir == Vector2.ZERO:
		return

	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			sprite.play("idle_right")
		else:
			sprite.play("idle_left")
	else:
		if dir.y > 0:
			sprite.play("idle_front")
		else:
			sprite.play("idle_back")


func show_damage(amount):

	var dmg_scene = preload("res://ui/DamageText.tscn")
	var dmg_text = dmg_scene.instantiate()

	dmg_text.text = str(int(amount))
	dmg_text.global_position = global_position + Vector2(0, -40)

	get_tree().current_scene.add_child(dmg_text)


func gain_exp(amount: int):
	current_exp += amount
	exp_changed.emit(current_exp, exp_to_next)

	while current_exp >= exp_to_next:
		current_exp -= exp_to_next
		level_up()


func level_up():

	level += 1
	exp_to_next = int(exp_to_next * 1.4)

	data.stat_points += 5

	recalculate_stats()

	stat_points_changed.emit(data.stat_points)
	exp_changed.emit(current_exp, exp_to_next)
	
func add_data_STR():

	if data.stat_points <= 0:
		return

	data.STR += 1
	data.stat_points -= 1

	recalculate_stats()

	stats_changed.emit()
	stat_points_changed.emit(data.stat_points)


func add_data_DEX():

	if data.stat_points <= 0:
		return

	data.DEX += 1
	data.stat_points -= 1

	recalculate_stats()

	stats_changed.emit()
	stat_points_changed.emit(data.stat_points)


func add_data_VIT():

	if data.stat_points <= 0:
		return

	data.VIT += 1
	data.stat_points -= 1

	recalculate_stats()

	stats_changed.emit()
	stat_points_changed.emit(data.stat_points)
	
func recalculate_stats():

	stats.setup(data)

	var old_max = get_max_hp()

	base_attack = 10
	move_speed = stats.get_move_speed(180)
	base_max_hp = 100

	var new_max = get_max_hp()

	if new_max > old_max:
		hp += new_max - old_max

	if hp > new_max:
		hp = new_max

	hp_changed.emit(hp, new_max)
	

	
	
func apply_data(d):
	data = d
	stats.setup(d)

	recalculate_stats()
	stat_points_changed.emit(data.stat_points)
	stats_changed.emit()

func get_attack():
	var v = stats.get_attack(base_attack)

	if job == Job.BERSERKER:
		v *= 1.2

	return v
	
func get_max_hp():
	var v = stats.get_max_hp(base_max_hp)

	if job == Job.TANK:
		v *= 1.3

	return v
