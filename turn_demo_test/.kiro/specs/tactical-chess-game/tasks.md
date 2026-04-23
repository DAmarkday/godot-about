# 实现计划：回合制战棋游戏

## 概述

按照设计文档，将旧代码删除重建，逐步搭建模块化战棋系统。每个任务都是独立可验证的步骤，最终将所有模块串联成完整游戏。

> 标注 `*` 的子任务为可选测试任务，可跳过以加快 MVP 进度。

---

## 任务

- [x] 1. 清理旧代码，搭建新项目骨架
  - 删除 `scene/battle/chess/` 目录下的旧脚本（chess.gd、Chessboard.gd、GridOverlay.gd、GridPieceMappingManager.gd）和棋子场景
  - 删除 `scene/battle/map/` 目录下与新架构冲突的旧脚本（MapRoot.gd、Unit.gd、HighlightLayer.gd、TestMap.gd）
  - 保留 `scene/battle/map/MapData.gd`、`MapGenerator.gd`、`MapLoader.gd`、`MovementRangeCalculator.gd`（后续扩展使用）
  - 创建新目录结构：`script/data/`、`script/unit/`、`script/systems/`、`script/map/`
  - 将 `script/Events.gd` 替换为新的 `script/EventBus.gd` 并注册为 AutoLoad
  - _需求：9.1、9.2_

- [x] 2. 实现 EventBus 全局信号总线
  - [x] 2.1 创建 `script/EventBus.gd`，定义设计文档中所有信号
    - 包含：unit_selected、unit_deselected、unit_moved、unit_damaged、unit_died、attack_performed、turn_changed、player_turn_started、enemy_turn_started、battle_won、battle_lost
    - 在 `project.godot` 中注册为 AutoLoad，名称为 `EventBus`
    - _需求：9.1_

- [x] 3. 实现棋子数据与棋子节点
  - [x] 3.1 创建 `script/data/UnitData.gd`（Resource 子类）
    - 定义所有 @export 属性：unit_name、max_hp、movement、attack_power、defense、attack_range、team、sprite_frames
    - _需求：1.1、1.3、9.3_

  - [x] 3.2 创建 `script/unit/Unit.gd`（CharacterBody2D 子类）
    - 实现 `setup(data: UnitData)` 方法，从 UnitData 加载属性
    - 实现 `take_damage(amount: int)` 方法，血量归零时设置 is_alive=false 并发出 unit_died 信号
    - 实现 `reset_actions()` 方法，重置 has_moved 和 has_attacked
    - 在 take_damage 中发出 unit_damaged 信号
    - _需求：1.1、1.2、1.6、1.7_

  - [ ]* 3.3 为 Unit 编写属性测试
    - **属性 4：行动点重置完整性** - 随机生成 1~10 个棋子，设置随机行动状态，调用 reset_actions() 后验证全部重置
    - **属性（信号）**：随机血量棋子受到足够伤害后，unit_damaged 和 unit_died 信号被正确发出
    - `# Feature: tactical-chess-game, Property 6: 行动点重置完整性`
    - _需求：1.2、1.6、1.7、4.4、4.5_

  - [x] 3.4 创建玩家棋子和敌方棋子的 UnitData 资源文件
    - 创建 `resource/units/warrior.tres`（战士：HP=10, 移动=3, 攻击=4, 防御=2, 范围=1）
    - 创建 `resource/units/archer.tres`（弓手：HP=6, 移动=4, 攻击=3, 防御=1, 范围=2）
    - 创建 `resource/units/goblin.tres`（哥布林：HP=5, 移动=3, 攻击=2, 防御=0, 范围=1）
    - 创建 `resource/units/troll.tres`（巨魔：HP=12, 移动=2, 攻击=5, 防御=3, 范围=1）
    - _需求：1.1、1.3_

  - [x] 3.5 创建棋子场景模板 `scene/units/unit_template.tscn`
    - 节点结构：Unit(CharacterBody2D) → AnimatedSprite2D + HealthBar(Node)
    - 复用 `plugin/health/health.gd` 作为血量条组件
    - _需求：1.1、8.3_

- [x] 4. 实现 UnitManager（棋子管理器）
  - [x] 4.1 创建 `script/systems/UnitManager.gd`
    - 实现 register_unit / unregister_unit 方法
    - 实现 get_unit_at(cell) 查询格子上的棋子
    - 实现 update_unit_position(unit, new_cell) 更新位置记录
    - 实现 get_player_units() / get_enemy_units() 获取存活棋子列表
    - 实现 check_battle_result()：无敌方棋子时发出 battle_won，无玩家棋子时发出 battle_lost
    - 监听 unit_died 信号，自动调用 unregister_unit 并触发 check_battle_result
    - _需求：1.2、7.1、7.2_

- [x] 5. 实现地图系统（扩展现有代码）
  - [x] 5.1 扩展 `scene/battle/map/MapGenerator.gd`，新增 `generate_battle_map` 方法
    - 在生成后强制将玩家出生区域（左下角 3×3）设为 LAND
    - 在生成后强制将敌方出生区域（右上角 3×3）设为 LAND
    - 调用现有的 ensure_connectivity 保证连通性
    - _需求：5.1、5.2、5.3、5.4、5.5、5.6_

  - [ ]* 5.2 为地图生成编写属性测试
    - **属性 9：相同种子生成相同地图** - 随机种子调用两次，比较所有格子
    - **属性 10：出生区域全为陆地** - 随机种子生成后检查两个 3×3 区域
    - **属性 8：序列化往返一致性** - 随机地图序列化后反序列化，比较所有格子
    - `# Feature: tactical-chess-game, Property 9: 相同种子生成相同地图`
    - `# Feature: tactical-chess-game, Property 10: 出生区域全为陆地`
    - `# Feature: tactical-chess-game, Property 8: 地图序列化往返一致性`
    - _需求：5.4、5.5、5.6、5.7、5.8_

- [x] 6. 实现移动系统
  - [x] 6.1 创建 `script/systems/MovementSystem.gd`
    - 实现 `calculate_reachable_cells(unit, map_data, unit_manager)` 方法
      - 使用 BFS 遍历，累计地形成本，不超过 unit.movement
      - 排除被其他棋子占据的格子
    - 实现 `try_move(unit, target_cell, map_data, unit_manager)` 方法
      - 校验：棋子存活、本回合未移动、目标在可达范围内、目标未被占据
      - 成功时：更新 unit.grid_position、unit.has_moved=true，通知 UnitManager，发出 unit_moved 信号
      - 失败时：返回 false，不修改任何状态
    - 实现 `animate_movement(unit, path, layer)` 方法，使用 Tween 逐格移动
    - _需求：2.1、2.2、2.3、2.4、2.5、2.6、2.7_

  - [ ]* 6.2 为移动系统编写属性测试
    - **属性 1：移动范围不超过移动力** - 随机地图和棋子，验证所有可达格子路径成本 ≤ movement
    - **属性 2：移动成功后位置与信号一致** - 随机可达目标，执行移动后验证位置和信号
    - **属性 3：非法移动目标被拒绝** - 被占据格子和超范围格子均返回 false
    - `# Feature: tactical-chess-game, Property 1: 移动范围不超过移动力`
    - `# Feature: tactical-chess-game, Property 2: 移动成功后位置与信号一致`
    - `# Feature: tactical-chess-game, Property 3: 非法移动目标被拒绝`
    - _需求：2.2、2.3、2.5、2.6_

- [x] 7. 检查点 - 确保所有测试通过，如有问题请提问

- [x] 8. 实现战斗系统
  - [x] 8.1 创建 `script/systems/CombatSystem.gd`
    - 实现 `calculate_attack_cells(unit)` 方法
      - 返回以 unit.grid_position 为中心，曼哈顿距离 ≤ unit.attack_range 的所有格子
    - 实现 `calculate_damage(attacker, target)` 方法
      - 公式：max(1, attacker.attack_power - target.defense)
    - 实现 `try_attack(attacker, target_cell, unit_manager)` 方法
      - 校验：攻击者存活、本回合未攻击、目标格子在攻击范围内、目标格子有敌方棋子
      - 成功时：调用 calculate_damage，调用 target.take_damage，设置 attacker.has_attacked=true，发出 attack_performed 信号
      - 失败时：返回 false
    - _需求：3.1、3.2、3.3、3.4、3.5、3.6、3.7_

  - [ ]* 8.2 为战斗系统编写属性测试
    - **属性 4：伤害计算下界** - 随机攻击力 [1,20] 和防御力 [0,20]，验证伤害 ≥ 1
    - **属性 5：攻击范围格子距离正确性** - 随机棋子位置和攻击范围，验证所有格子曼哈顿距离 ≤ attack_range
    - `# Feature: tactical-chess-game, Property 4: 伤害计算下界`
    - `# Feature: tactical-chess-game, Property 5: 攻击范围格子距离正确性`
    - _需求：3.1、3.3_

- [x] 9. 实现回合管理系统
  - [x] 9.1 创建 `script/systems/TurnManager.gd`
    - 定义 TurnState 枚举：PLAYER_TURN、ENEMY_TURN、GAME_OVER
    - 实现 `start_battle()` 方法：设置 turn_number=1，进入 PLAYER_TURN，发出 player_turn_started 信号
    - 实现 `end_player_turn()` 方法：切换到 ENEMY_TURN，发出 enemy_turn_started 信号
    - 实现 `end_enemy_turn()` 方法：turn_number+1，切换到 PLAYER_TURN，重置所有棋子行动点，发出 player_turn_started 信号
    - 实现 `end_game(player_won)` 方法：切换到 GAME_OVER，发出 battle_won 或 battle_lost 信号
    - 监听 battle_won / battle_lost 信号，自动调用 end_game
    - 所有状态切换时发出 turn_changed 信号
    - _需求：4.1、4.2、4.3、4.4、4.5、4.6、4.7_

  - [ ]* 9.2 为回合管理编写属性测试
    - **属性 7：回合数单调递增** - 随机执行 N 次完整回合循环，验证 turn_number 每次恰好 +1
    - 示例测试：end_player_turn() 后 current_state == ENEMY_TURN
    - 示例测试：end_enemy_turn() 后 current_state == PLAYER_TURN
    - `# Feature: tactical-chess-game, Property 7: 回合数单调递增`
    - _需求：4.2、4.3、4.6_

- [x] 10. 实现敌方 AI 控制器
  - [x] 10.1 创建 `script/systems/AIController.gd`
    - 实现 `execute_enemy_turn(enemy_units, player_units, map_data, movement_system, combat_system)` 异步方法
      - 使用 `await` 逐个处理敌方棋子，每个棋子行动后等待 0.5 秒（视觉反馈）
      - 所有棋子行动完成后调用 TurnManager.end_enemy_turn()
    - 实现 `decide_action(enemy, player_units, map_data, movement_system, combat_system)` 方法
      - 找到最近的玩家棋子（曼哈顿距离）
      - 计算可达格子，找到其中距离目标最近的格子并移动
      - 移动后检查攻击范围，若有玩家棋子则攻击
    - _需求：6.1、6.2、6.3、6.4、6.5_

- [x] 11. 实现高亮层（移动/攻击范围显示）
  - [x] 11.1 创建 `script/map/HighlightLayer.gd`（TileMapLayer 子类）
    - 实现 `show_movement_range(cells: Array[Vector2i])` 方法（蓝色半透明）
    - 实现 `show_attack_range(cells: Array[Vector2i])` 方法（红色半透明）
    - 实现 `clear_highlights()` 方法
    - _需求：2.1、3.1_

- [x] 12. 实现 BattleScene（主战斗场景）
  - [x] 12.1 创建 `scene/battle/BattleScene.tscn` 和 `scene/battle/BattleScene.gd`
    - 场景树按设计文档搭建：BattleMap + Systems + UILayer
    - 在 `_ready()` 中初始化所有系统，生成地图，放置初始棋子
    - 实现 `_input(event)` 处理玩家点击：
      - 非玩家回合时忽略所有输入
      - 第一次点击己方棋子：选中，显示移动范围和攻击范围
      - 第二次点击可移动格子：调用 MovementSystem.try_move
      - 第二次点击可攻击格子上的敌方棋子：调用 CombatSystem.try_attack
      - 点击空白处：取消选中，清除高亮
    - 监听 enemy_turn_started 信号，触发 AIController.execute_enemy_turn
    - _需求：2.1、2.3、3.1、3.2、4.2、6.1_

  - [x] 12.2 在 BattleScene 中放置初始棋子
    - 玩家棋子：战士放在 (1,7)，弓手放在 (2,7)
    - 敌方棋子：哥布林放在 (7,1)，巨魔放在 (6,1)
    - _需求：1.4、1.5_

- [x] 13. 实现 UI 层
  - [x] 13.1 创建回合信息面板 `scene/ui/TurnPanel.tscn`
    - 显示当前回合数和行动方（"第 N 回合 - 玩家回合" / "第 N 回合 - 敌方回合"）
    - 监听 turn_changed 信号自动更新
    - _需求：8.1_

  - [x] 13.2 创建棋子信息面板 `scene/ui/UnitInfoPanel.tscn`
    - 监听 unit_selected 信号，显示棋子名称、血量、移动力、攻击力、防御力
    - 监听 unit_deselected 信号，隐藏面板
    - _需求：8.2_

  - [x] 13.3 创建"结束回合"按钮
    - 监听 turn_changed 信号：玩家回合时启用，敌方回合时禁用
    - 点击时调用 TurnManager.end_player_turn()
    - _需求：8.6_

  - [x] 13.4 实现棋子行动状态视觉反馈
    - 监听 unit_moved 信号：已移动未攻击的棋子应用半透明效果（modulate.a = 0.6）
    - 监听 attack_performed 信号：已完成所有行动的棋子应用灰色效果（modulate = Color(0.5, 0.5, 0.5)）
    - 监听 player_turn_started 信号：重置所有玩家棋子的视觉效果
    - _需求：8.4、8.5_

  - [x] 13.5 实现游戏结果界面
    - 监听 battle_won 信号，显示"胜利！"提示并停止接受输入
    - 监听 battle_lost 信号，显示"失败！"提示并停止接受输入
    - _需求：7.3、7.4_

- [x] 14. 检查点 - 确保所有测试通过，完整游戏流程可运行，如有问题请提问

- [x] 15. 串联与收尾
  - [x] 15.1 将 BattleScene 设置为项目主场景
    - 在 `project.godot` 中设置 `run/main_scene`
    - 确保 EventBus AutoLoad 在所有场景加载前初始化
    - _需求：9.1_

  - [x] 15.2 验证模块解耦：检查各系统脚本不直接 `$` 引用其他系统节点
    - 所有跨模块通信均通过 EventBus 信号
    - _需求：9.1、9.4_

  - [ ]* 15.3 补充集成测试
    - 测试完整回合流程：玩家移动 → 攻击 → 结束回合 → AI 行动 → 新回合
    - 测试胜负判定：消灭所有敌方棋子后 battle_won 信号被发出
    - _需求：7.1、7.2_

- [x] 16. 最终检查点 - 确保所有测试通过，如有问题请提问

## 备注

- 标注 `*` 的子任务为可选测试任务，跳过后仍可运行游戏
- 每个任务引用了具体的需求编号，便于追溯
- 属性测试使用 GUT 框架，每个属性至少运行 100 次随机输入
- 旧代码中 `MapData.gd`、`MapGenerator.gd`、`MapLoader.gd`、`MovementRangeCalculator.gd` 保留复用
