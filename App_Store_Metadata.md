# App Store 上架元数据

## 应用信息

| 项目 | 内容 |
|------|--------|
| **应用名称** | 应用锁 |
| **副标题** | 隐私应用保护工具 |
| **分类** | 工具 / 效率 |
| **年龄分级** | 4+ |
| **价格** | ¥8 CNY (一次性付费，无内购) |
| **隐私政策 URL** | https://pangtongya.github.io/AppLocker/privacy-policy.html |

---

## 应用描述（中文）

应用锁是一款极简的隐私保护工具，帮助您为微信、支付宝、相册等隐私应用添加密码或Face ID保护。

核心功能：
• 选择要锁定的应用 - 使用iOS屏幕使用时间API
• 设置密码或Face ID - 确保只有您可以解锁
• 一键锁定/解锁 - 简单直观的操作

为什么选择应用锁：
✓ 无广告 - 纯净体验
✓ 无订阅 - 一次性买断
✓ 无注册 - 打开即用
✓ 本地处理 - 零数据收集

适用场景：
- 保护微信聊天隐私
- 防止他人查看支付宝/银行App
- 保护相册中的私人照片
- 任何您想要添加密码保护的应用

技术要求：
- iOS 18.0+
- 需要屏幕使用时间授权
- 纯本地处理，无需网络

---

## App Description (English)

App Locker is a minimalist privacy protection tool that helps you add password or Face ID protection to private apps like WeChat, Alipay, Photos, etc.

Core Features:
• Select apps to lock - Uses iOS Screen Time API
• Set password or Face ID - Ensure only you can unlock
• One-tap lock/unlock - Simple and intuitive

Why Choose App Locker:
✓ No Ads - Clean experience
✓ No Subscription - One-time purchase
✓ No Registration - Ready to use
✓ Local Processing - Zero data collection

Use Cases:
- Protect WeChat chat privacy
- Prevent others from accessing Alipay/Banking apps
- Protect private photos in Photos app
- Any app you want to add password protection

Requirements:
- iOS 18.0+
- Screen Time authorization required
- Local processing, no network needed

---

## 关键词（中文，≤100字符）

```
应用锁,隐私,密码,Face ID,屏幕时间,微信,支付宝,相册,锁定,保护
```
（共58字符）

---

## Keywords (English, ≤100 chars)

```
App Locker, privacy, password, Face ID, Screen Time, WeChat, Alipay, Photos, lock, protect
```
（共74字符）

---

## 截图计划

需要准备的截图尺寸：
1. **6.7英寸（iPhone 17 Pro Max）** - 1290×2796 px
2. **6.5英寸（iPhone 17）** - 1242×2688 px

截图场景（每尺寸5-6张）：
1. 主页 - 未选择应用状态
2. 主页 - 已选择/锁定应用状态
3. 设置页 - 密码/Face ID设置
4. 引导页 - 第1页（欢迎）
5. 引导页 - 第5页（开始使用）

---

## 提审注意事项

### 苹果审核重点关注
| 风险点 | 应对措施 |
|--------|----------|
| Family Controls权限说明不清晰 | 引导页明确说明需要屏幕使用时间授权 |
| 隐私政策不完整 | 已创建隐私政策页面，托管在GitHub Pages |
| 功能与描述不符 | 确保所有描述的功能都已实现 |
| 截图包含未实现功能 | 仅使用已实现功能的截图 |
| 关键词超100字符 | 已控制在100字符内 |

### 审核前检查清单
- [ ] 所有用户可见文本都已本地化（中文+英文）
- [ ] 隐私政策URL可访问
- [ ] 应用图标1024×1024 px（无alpha通道）
- [ ] 无硬编码测试数据
- [ ] 已消除所有force unwrap
- [ ] 已替换print()为Logger
- [ ] Family Controls功能已完整实现并测试
- [ ] 引导页可正常显示并完成
- [ ] 设置页可正常设置密码/Face ID
- [ ] 主页可选择应用并锁定/解锁

---

## 版本规划

| 版本 | 说明 | 计划时间 |
|------|------|----------|
| v1.0.0 | 初始版本，核心锁定功能 | 2026-06-03 |
| v1.0.1 | 修复审核反馈（如需要） | 审核后 |
| v1.1.0 | 用户反馈功能改进 | 上架后 |

---

*本文档由AI助手生成，请根据实际情况调整。*
