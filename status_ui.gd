extends Control

var player = null


@onready var str_add = $Panel/VBoxContainer/STR_Row/Add
@onready var dex_add = $Panel/VBoxContainer/DEX_Row/Add
@onready var vit_add = $Panel/VBoxContainer/VIT_Row/Add
@onready var str_value = $Panel/VBoxContainer/STR_Row/Value
@onready var dex_value = $Panel/VBoxContainer/DEX_Row/Value
@onready var vit_value = $Panel/VBoxContainer/VIT_Row/Value
@onready var points_label = $Panel/StatPoints
@onready var panel = $Panel


func connect_player(p):

	player = p

	if not player.stats_changed.is_connected(update_stats):
		player.stats_changed.connect(update_stats)

	if not player.stat_points_changed.is_connected(update_points):
		player.stat_points_changed.connect(update_points)

	update_stats()
	update_points(player.data.stat_points)


func update_stats():

	str_value.text = str(player.data.STR)
	dex_value.text = str(player.data.DEX)
	vit_value.text = str(player.data.VIT)


func update_points(value):

	points_label.text = "Points: " + str(value)
		
func _ready():

	GameManager.register_status_ui(self)
	if GameManager.player:
		connect_player(GameManager.player)
	str_add.pressed.connect(_on_str_add_pressed)
	dex_add.pressed.connect(_on_dex_add_pressed)
	vit_add.pressed.connect(_on_vit_add_pressed)


func _on_str_add_pressed():

	if GameManager.player_data.stat_points <= 0:
		return

	GameManager.player_data.STR += 1
	GameManager.player_data.stat_points -= 1


	update_stats()
	update_points(GameManager.player_data.stat_points)
	
func _on_dex_add_pressed():

	if player.stat_points <= 0:
		return

	GameManager.player_data.DEX += 1
	GameManager.player_data.stat_points -= 1

	player.DEX = GameManager.player_data.DEX
	player.stat_points = GameManager.player_data.stat_points

	update_stats()
	update_points(player.stat_points)
	
func _on_vit_add_pressed():

	if player.stat_points <= 0:
		return

	GameManager.player_data.VIT += 1
	GameManager.player_data.stat_points -= 1

	player.VIT = GameManager.player_data.VIT
	player.stat_points = GameManager.player_data.stat_points
