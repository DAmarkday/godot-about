## EventBus.gd
## 全局事件总线，作为 AutoLoad 单例注册。
## 各模块通过此节点发出和监听信号，实现模块间解耦通信。
extends Node

# ─── 棋子相关信号 ───────────────────────────────────────────

## 棋子被选中
## unit: 被选中的棋子节点
signal unit_selected(unit:Unit,isPlayerControl:bool)

## 棋子取消选中
## unit: 取消选中的棋子节点
signal unit_deselected(unit:Unit)

## 棋子移动完成
## unit: 移动的棋子节点
## from: 起始格子坐标 (Vector2i)
## to:   目标格子坐标 (Vector2i)
signal unit_moved(unit:Unit, from:Vector2i, to:Vector2i)

## 棋子受到伤害
## unit:         受伤的棋子节点
## damage:       本次伤害值
## remaining_hp: 受伤后剩余血量
signal unit_damaged(unit:Unit, damage, remaining_hp)

## 棋子死亡
## unit: 死亡的棋子节点
## team: 所属阵营（0=玩家，1=敌方）
signal unit_died(unit:Unit, team)

# ─── 战斗相关信号 ───────────────────────────────────────────

## 攻击发生
## attacker: 发起攻击的棋子节点
## target:   被攻击的棋子节点
## damage:   本次造成的伤害值
signal attack_performed(attacker, target, damage)

# ─── 回合相关信号 ───────────────────────────────────────────

## 回合状态发生变化
## new_state:   新的回合状态（对应 TurnManager.TurnState 枚举值，用 int 避免循环依赖）
## turn_number: 当前回合数
signal turn_changed(new_state, turn_number)

## 玩家回合开始
## turn_number: 当前回合数
signal player_turn_started(turn_number)

## 敌方回合开始
## turn_number: 当前回合数
signal enemy_turn_started(turn_number)

# ─── 游戏结果信号 ───────────────────────────────────────────

## 玩家胜利（所有敌方棋子死亡）
signal battle_won()

## 玩家失败（所有玩家棋子死亡）
signal battle_lost()
