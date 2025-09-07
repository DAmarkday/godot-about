extends Node
var _player:Player
func create(player):
	_player = player

func getPlayerPos():
	return _player.global_position
