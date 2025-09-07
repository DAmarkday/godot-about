extends Node
var _player:Player
var _map:Map
func create(player,map):
	_player = player
	_map = map

func getPlayerPos():
	return _player.global_position
	
func getMapInstance():
	return _map
