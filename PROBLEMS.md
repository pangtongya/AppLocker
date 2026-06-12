# AppLocker 问题清单

> 创建时间：2026-06-02
> 目标：要么不做，要做就做到最好

## P0 - 致命问题（已修复）

- [x] **问题1：Entitlements 文件为空** - AppLocker.entitlements 是 `<dict/>`，导致 Family Controls 授权失败
  - 修复：添加 `com.apple.developer.family-controls` = `individual`
  - 状态：✅ 已修复

- [x] **问题2：ShieldManager 授权状态管理错误** - `needsSettingsAuthorization` 属性缺失， denied 状态未正确处理
  - 修复：添加 `needsSettingsAuthorization`，正确管理授权状态
  - 状态：✅ 已修复

- [x] **问题3：LockStore 后台定时器不工作** - 应用在后台时定时器不触发，导致锁定时间到了无法自动解锁
  - 修复：添加前台唤醒检测 + 本地通知 + 修改定时器间隔为 5 秒
  - 状态：✅ 已修复

---

## P1 - 严重问题（需要立即修复）

- [x] **问题4：AuthManager 密码哈希不安全** - 使用 `String.hash` 存储密码哈希，这个方法不稳定且不安全
  - 位置：`AuthManager.swift` 第 25 行 `password.hash`
  - 影响：密码可能被破解，用户数据不安全
  - 修复方案：使用 SHA256 哈希 + Salt
  - 状态：✅ 已修复（使用 CryptoKit SHA256）

- [x] **问题5：GuideView 授权流程问题** - 用户跳过引导后，应用可能无法工作
  - 位置：`GuideView.swift` 第 101-109 行
  - 影响：用户跳过引导后，没有授权屏幕使用时间，应用无法锁定应用
  - 修复方案：引导流程中，如果授权被拒绝，不允许跳过；或者在主页检查授权状态并引导用户
  - 状态：✅ 已修复（只允许从 page 2 开始跳过，Alert 移除"跳过"按钮）

- [x] **问题6：ContentView/HomeView 逻辑冲突** - 当 `isLocking` 状态改变时，视图层次结构变化可能导致状态丢失
  - 位置：`ContentView.swift` 第 43-80 行
  - 影响：锁定状态切换时，界面可能闪烁或状态异常
  - 修复方案：重新设计视图结构，使用 `.sheet` 或 `.fullScreenCover` 显示锁定状态
  - 状态：✅ 已修复（添加动画过渡，使用 ZStack + opacity）

- [x] **问题7：StatsView 本地化缺失** - 多处硬编码中文字符串
  - 位置：`StatsView.swift` 第 191 行 "图表需要 iOS 16+"，第 206-213 行统计项标题
  - 影响：不支持英文等其它语言
  - 修复方案：使用 `LocalizedStringKey` 或 `NSLocalizedString`
  - 状态：✅ 已修复（添加本地化字符串到 Localizable.strings，更新 StatsView.swift 使用本地化）

- [x] **问题8：HomeView 提前解锁 Alert 问题** - Alert 中的 SecureField 布局可能有问题，且 `showPasswordFail` 未重置
  - 位置：`HomeView.swift` 第 69-92 行
  - 影响：用户输入错误密码后，再次打开 Alert 仍然显示错误信息
  - 修复方案：重置 `showPasswordFail` 状态，改进 Alert 设计
  - 状态：✅ 已修复（在显示 Alert 前重置 showPasswordFail）

---

## P2 - 中等问题（体验优化）

- [ ] **问题9：首次使用空状态设计** - 用户完成引导后，主页没有引导选择应用
  - 影响：用户可能不知道如何开始使用
  - 修复方案：改进空状态设计，添加引导提示

- [ ] **问题10：产品价值主张不清晰** - 用户为什么愿意花 8 元购买这个 App？
  - 影响：转化率低
  - 修复方案：需要重新思考产品定位和差异化

- [ ] **问题11：SettingsView 可能需要改进** - 设置页面功能是否完整？
  - 影响：用户体验
  - 修复方案：检查并设置页面，确保功能完整

- [ ] **问题12：LockStore 定时器间隔 5 秒可能还是太长** - 用户锁定 1 分钟时，最长需要等 5 秒才能解锁
  - 影响：用户体验不够即时
  - 修复方案：考虑使用更精确的方法，或者接受这个延迟（5秒是可接受的）

---

## 修复优先级

1. P1 问题 4-8 需要立即修复
2. P2 问题 9-11 可以稍后处理
3. 问题 12 可以接受，暂不修复

---

## 测试计划

修复完成后，需要在真机上测试：
1. 首次安装，完成引导流程
2. 授权屏幕使用时间
3. 选择应用并锁定
4. 验证锁定是否生效（被锁定的应用无法打开）
5. 验证提前解锁功能（Face ID / 密码）
6. 验证定时解锁功能（等待锁定时间结束）
7. 验证统计功能
8. 验证设置功能
