# Changelog

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

## [Unreleased]

### Added
- 定时锁定功能：选择时长（25/45/60/90分钟 + 自定义），到期自动解锁
- 锁定状态倒计时显示，脉冲动画
- 提前解锁功能：需要密码或 Face ID 验证
- 锁定记录数据模型（LockSession）
- 全局应用状态管理（AppState，JSON 持久化 + 防抖）
- ShieldManager：FamilyControls 屏蔽管理（授权、锁定/解锁）
- AuthManager：密码哈希存储 + FaceID 验证管理
- 统计页面（StatsView）：总时长、连胜、图表、详细统计
- CSV 数据导出功能
- 每周目标设置
- 15 个单元测试覆盖模型、Store、Auth、性能

### Changed
- 重构架构：从单一体 AppLockerModel 拆分为 AppState/LockStore/ShieldManager/AuthManager
- 重写 HomeView：参考 StartFocus 设计优化（时长选择、状态卡片、统计）
- 重写 SettingsView：密码哈希存储，支持修改/删除
- 重写 ContentView：锁定模式下全屏锁定，隐藏 Tab Bar
- 更新 GuideView：适配新架构
- project.yml：SWIFT_STRICT_CONCURRENCY 改为 complete

### Fixed
- 密码明文存储改为哈希存储
- 解锁时不验证密码的问题：新增 AuthManager 验证流程
- 无定时功能的二态锁定：改为定时锁定，到期自动解锁

## [1.0.0] - 2026-06-02

### Added
- 初始版本发布
- 应用锁定功能（选择 App → 锁定/解锁）
- 屏幕使用时间授权
- 5 页引导流程
- 密码设置
- Face ID 支持
- 品牌色系统
- GlassCard 毛玻璃组件
- 国际化骨架
