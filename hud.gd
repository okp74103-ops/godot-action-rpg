extends CanvasLayer

@onready var hp_bar = $HP_Bar
@onready var q_cd_bar = $Q_CD
@onready var dash_cd_bar = $Dash_CD
@onready var skill_dash_bar = $skill_dash
@onready var exp_bar = $EXPBar
@onready var status_ui = $StatusUI

var player = null


func connect_player(p):
	player = p
	status_ui.connect_player(player)
	

	player.hp_changed.connect(_on_hp_changed)
	player.q_cd_changed.connect(_on_q_cd_changed)
	player.dash_cd_changed.connect(_on_dash_cd_changed)
	player.skill_dash_cd_changed.connect(_on_skill_dash_cd_changed)
	player.state_changed.connect(_on_state_changed)
	player.exp_changed.connect(update_exp)

	_on_hp_changed(player.hp, player.get_max_hp())
	_on_q_cd_changed(player.q_cd_timer)
	_on_dash_cd_changed(player.dash_cd_timer)
	_on_skill_dash_cd_changed(player.skill_dash_cd_timer)
	update_exp(player.current_exp, player.exp_to_next)


func _on_hp_changed(value, max_value):
	hp_bar.max_value = max_value
	hp_bar.value = value


func _on_q_cd_changed(value):
	q_cd_bar.max_value = player.q_cooldown
	q_cd_bar.value = value


func _on_dash_cd_changed(value):
	dash_cd_bar.max_value = player.dash_cooldown
	dash_cd_bar.value = value


func _on_skill_dash_cd_changed(value):
	skill_dash_bar.max_value = player.skill_dash_cooldown
	skill_dash_bar.value = value


func update_exp(current, max_value):
	exp_bar.max_value = max_value
	exp_bar.value = current


func _on_state_changed(_new_state):
	pass
