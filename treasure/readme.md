TileMapLayer：

Ground / Base Layer（最底层）：平地、草地、沙地、道路等基本地形。
Terrain / Obstacle Layer（中间层）：山脉、森林、河流、墙壁、高地等有高度/阻挡/特殊效果的地形。
山脉通常放在这一层，用 Terrain Set 实现边缘平滑过渡（比如山脚到山顶的渐变）。

Decoration / Details Layer（上层）：小草、碎石、花朵、树冠阴影等纯视觉装饰，不影响碰撞或移动。
Highlight / Overlay Layer（动态层，可选）：移动范围、攻击范围、可选中格子的高亮（很多项目用单独的 TileMapLayer + 透明材质来做，便于动态 set_cell）。

典型场景树结构示例（根节点如 Level）：
textLevel (Node2D)
├── Background (CanvasLayer 或 Parallax，如果有远景)
├── TileMapLayers (Node2D，作为容器，便于管理)
│   ├── GroundLayer (TileMapLayer)          # 基础地形
│   ├── TerrainLayer (TileMapLayer)         # 山脉、森林、障碍物（带碰撞和导航）
│   ├── DecorationLayer (TileMapLayer)      # 视觉细节
│   └── HighlightLayer (TileMapLayer)       # 动态范围显示（z_index 更高）
└── Units (Node2D)                          # 所有棋子在这里，独立于 TileMap
	├── PlayerUnits (Node2D)
	└── EnemyUnits (Node2D)

山脉等障碍：直接在 TerrainLayer 的 TileSet 中设置 Physics Layer（碰撞）和 Navigation Layer（阻挡路径寻找），这样 AStarGrid2D 或 NavigationAgent2D 就能自动避开。
不需要把山脉做成独立的节点挂在 TileMapLayer 下面，那样反而破坏了 TileMap 的批处理优势。
