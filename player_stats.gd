class_name PlayerStats

var data

func setup(d):
	data = d


func get_attack(base_attack):
	if data == null:
		return base_attack

	return base_attack + data.STR * 2


func get_move_speed(base_speed):
	if data == null:
		return base_speed

	return base_speed + data.DEX * 3


func get_max_hp(base_hp):
	if data == null:
		return base_hp

	return base_hp + data.VIT * 15
