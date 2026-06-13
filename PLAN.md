# AppLocker 产品优化计划

> 更新时间：2026-06-14
> 优化周期：6 小时（一次性完成）
> 核心理念：以终为始，做用户愿意付费的产品

---

## 总体策略

**从终点出发**：用户花 ¥8 买这个 App，期望得到什么？
1. 真的能帮自己专注 🔴 核心功能已就绪
2. 使用起来方便快捷 🟡 Widget + Siri = 一键启动
3. 有成就感，愿意坚持 🟡 预设 + 仪式感 + 统计
4. 觉得值这个价 🟡 "惊喜感"是付费的关键

**本轮目标**：从"能用的工具"升级为"想用的伙伴"

---

## 执行计划

### Phase 1：为产品注入"惊喜感"（3.5 小时）

#### 1a. Widget 小组件（2 小时）⭐ 最高优先级
**目标**：创建 WidgetKit 扩展，用户可以从桌面直接开始/查看专注

**具体实现**：
- 创建 `AppLockerWidget` Widget Extension Target
- 支持三种尺寸：small（当前状态）、medium（状态+快速按钮）、large（完整统计）
- 支持 iOS 17+ StandBy（待机模式）
- 数据通过 App Group 共享

**文件**：
- `AppLockerWidget/WelcomeWidget.swift`
- `AppLockerWidget/AppLockerWidgetBundle.swift`
- 修改 `project.yml` 添加 Widget Extension Target
- 修改 entitlements 添加 App Group

#### 1b. Siri 快捷指令（1 小时）
**目标**：用户可以对 Siri 说"开始专注"、"结束专注"

**具体实现**：
- 创建 `AppLockerIntents` Intents Extension
- 定义 `StartFocusIntent`（参数：时长）
- 定义 `EndFocusIntent`
- 处理 Intents 授权

**文件**：
- `AppLockerIntents/IntentHandler.swift`
- `AppLockerIntents/Info.plist`
- `SiriShortcuts/StartFocusIntent.intentdefinition`
- 修改 `AppLockerApp.swift`（添加 Siri 授权）

#### 1c. 专注预设（0.5 小时）
**目标**：预设"工作"、"学习"、"休息" 三种模式

**具体实现**：
- 定义 Preset 数据模型（名称 + 图标 + App tokens 名称列表）
- 在 HomeView 添加预设选择器
- 持久化预设

**文件**：
- `Models/FocusPreset.swift`
- `Stores/PresetStore.swift`
- `Views/Home/HomeView.swift`（修改）

---

### Phase 2：后台任务和持久化（1 小时）

#### 2a. BGTaskScheduler（0.5 小时）
**目标**：在 App 后台时仍然能准确执行定时解锁

**具体实现**：
- 注册 BGTaskScheduler
- 在 `startLock` 和 `checkAndCompleteExpiredLock` 时调度后台任务
- 注册 `BGTaskSchedulerPermittedIdentifiers` 到 Info.plist

**文件**：
- `Managers/BackgroundTaskManager.swift`
- `AppLocker.entitlements`（添加 bg modes）
- `Info.plist`

#### 2b. 持久化 App 选择 + 历史记录限制（0.5 小时）
**目标**：App 重启后选择的 App 不丢失

**具体实现**：
- 存储 token 名称到 UserDefaults（appTokenNames、categoryTokenNames、webTokenNames）
- 添加历史记录清理（最多保留 1000 条）

**文件**：
- `Managers/ShieldManager.swift`（修改）
- `Stores/LockStore.swift`（修改）

---

### Phase 3：仪式感 + UI 体验修复（1.5 小时）

#### 3a. 仪式感动画/音效（0.5 小时）
**目标**：专注开始/结束有动画反馈

**具体实现**：
- 开始专注：锁屏动画 + 触觉反馈
- 结束专注：庆祝动画 + 通知推送
- 每日目标达成：特殊通知

**文件**：
- `Views/Components/CelebrationView.swift`
- `HomeView.swift`（修改）

#### 3b. 本地化修复（0.5 小时）
**目标**：确保所有本地化 key 正确显示

**具体实现**：
- 检查所有 `LocalizedStringKey` 和 `NSLocalizedString` 调用
- 修复缺失的 key
- 检查中文/英文字符串文件完整性

**文件**：
- `zh-Hans.lproj/Localizable.strings`
- `en.lproj/Localizable.strings`
- 各个 View 文件

#### 3c. 体验优化（0.5 小时）
**目标**：修复 UI/UX 问题

**具体实现**：
- 授权状态检测和引导
- 密码设置改进（旧密码验证）
- 时间线视图
- 空状态处理

**文件**：
- `HomeView.swift`（修改）
- `SettingsView.swift`（修改）
- `StatsView.swift`（修改）

---

## 时间预算

| 阶段 | 内容 | 预估时间 | 实际时间 |
|------|------|----------|----------|
| Phase 1a | Widget 小组件 | 2h | |
| Phase 1b | Siri 快捷指令 | 1h | |
| Phase 1c | 专注预设 | 0.5h | |
| Phase 2a | BGTaskScheduler | 0.5h | |
| Phase 2b | 持久化 + 清理 | 0.5h | |
| Phase 3a | 仪式感 | 0.5h | |
| Phase 3b | 本地化 | 0.5h | |
| Phase 3c | 体验优化 | 0.5h | |
| **总计** | | **6h** | |

---

## 成功标准

优化完成后，用户应该能够：
1. ✅ 从桌面 Widget 一键开始专注
2. ✅ 对 Siri 说"开始专注25分钟"
3. ✅ 快速切换"工作/学习/休息"预设
4. ✅ App 后台时定时器仍然准确
5. ✅ 重启 App 后上一次选择的应用不丢失
6. ✅ 专注开始/结束有仪式感反馈
7. ✅ 所有界面中/英文正确显示
8. ✅ 授权被拒时有明确引导
