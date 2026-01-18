extends Node

signal piece_selected(piece: CharacterBody2D)          # 发出选中事件，带棋子引用
signal piece_deselected(piece: CharacterBody2D)        # 可选：明确取消
