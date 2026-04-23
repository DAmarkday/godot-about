## UnitData.gd
## 棋子配置数据 Resource 类，用于定义棋子的静态属性。
## 通过 .tres 资源文件配置，与逻辑代码分离，实现数据驱动设计。
class_name UnitData extends Resource

# 单位名称
@export var unit_name: String = "士兵"
# 最大血量
@export var max_hp: int = 10
# 移动力（每回合最多移动的格子数，考虑地形成本）
@export var movement: int = 3
# 攻击力
@export var attack_power: int = 3
# 防御力（减少受到的伤害）
@export var defense: int = 1
# 攻击范围（曼哈顿距离，1=近战，2+=远程）
@export var attack_range: int = 1
# 所属阵营（0=玩家，1=敌方）
@export var team: int = 0
# 动画帧资源（可为空，为空时使用默认外观）
@export var sprite_frames: SpriteFrames
