# Sage（智账）

> [English](README.md) · **简体中文**

**Sage** 是一款基于 Flutter 的本地个人记账应用，支持多账本、预算、统计图表、账单筛选与消费分析，数据保存在设备本地。

---

## 功能概览

| 模块 | 说明 |
|------|------|
| **首页** | 按月浏览收支记录（不含理财结余），滑动编辑/删除，快捷记账，消费提醒入口 |
| **统计** | 按条件筛选账单（含理财类型），查看明细与汇总 |
| **图表** | 支出趋势、分类占比、液体圆盘等可视化统计，支持年/月周期切换 |
| **我的** | 账本、分类、预算、理财、数据备份、主题与字号设置 |

### 核心能力

- **多账本**：创建、切换、重命名；支持账本合并（按月份/自定义区间筛选后合并到目标账本）
- **分类管理**：收入/支出/理财分类，自定义图标与颜色，支持拖拽调整顺序
- **预算**：账本总预算与分类预算（仅支出消费），超支提醒与预算建议
- **理财**：独立记录类型，与收支结余分离；利率、到期日与 App 内提醒；理财管理页（本金、净存入、通用月/年目标、趋势图、到期列表）
- **记账**：新增/编辑记录（支出/收入/理财），详情面板支持编辑与删除
- **银行账单导入**：从 PDF 解析交易流水，审核后批量入账（摘要含定存/理财等时可识别为理财）
- **数据备份**：Excel / PDF 导入导出，跨平台读写本地文件
- **分析**（独立路由）：消费概览、时段对比、分类变化、月度波动、预算风险、异常识别与预算建议
- **主题与无障碍**：多套配色、跟随系统/浅色/深色、字号四档（小/标准/大/特大）

---

## 技术栈

- **框架**：Flutter 3.11+（Dart SDK ^3.11.5）
- **状态与存储**：`ChangeNotifier` + `shared_preferences` 本地持久化
- **文件与解析**：`file_picker`、`excel`、`pdfrx`、`archive`、`xml`
- **UI**：Material 3 风格组件、`flutter_slidable` 滑动操作

---

## 环境要求

- Flutter SDK（与 `pubspec.yaml` 中 SDK 约束一致）
- Android / iOS / macOS / Windows / Linux / Web 中任一 Flutter 支持的平台工具链

---

## 快速开始

```bash
# 克隆仓库后进入项目目录
cd Sage

# 安装依赖
flutter pub get

# 运行（连接设备或模拟器）
flutter run

# 构建 Release APK（Android）
flutter build apk
```

首次启动会自动加载本地账本数据与主题偏好；无网络也可正常使用。

---

## 项目结构

```
lib/
├── app.dart                 # 应用入口、底部导航与路由壳
├── main.dart                # 初始化 ledgerStore / themeController
├── ai/                      # 规则分析引擎、缓存与相关服务
├── components/              # 对话框、底部面板、图表、时间范围选择等通用 UI
├── data/                    # LedgerStore、LedgerRepository 持久化
├── models/                  # 账本、记录、分类、理财元数据等模型
├── pages/                   # 首页、统计、图表、记账、个人中心、分析等页面
├── services/                # 银行账单、理财、账本合并、分析、备份等业务服务
├── theme/                   # 主题、配色、字号、样式
└── utils/                   # 格式化、文件 IO、Excel 解析等工具
```

---

## 版本与更新日志

功能变更记录见 [CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md)（[English](CHANGELOG.md)）。

当前版本：`0.1.0+1`（见 `pubspec.yaml`）。

---

## 开发说明

- 默认语言环境为简体中文（`zh_CN`），同时声明 `en_US` 区域支持。
- 修改数据模型或存储格式时，请同步检查 `LedgerRepository` 的读写与备份导入逻辑。
- 提交前建议执行：`flutter analyze`、`flutter test`（如有测试）。

---

## 参与贡献

欢迎提交 Issue 与 Pull Request。请保持改动聚焦，并遵循 `lib/components/` 与 `lib/theme/` 下的现有代码风格。
