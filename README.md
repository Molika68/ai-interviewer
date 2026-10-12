# AI Interviewer

AI 模拟面试 App，Flutter 跨端实现。输入目标岗位与技术栈，App 会连续追问 5 道技术问题，对每一条回答即时给出评分与改进建议，最终生成一份含技能雷达图的面试报告。

这是 [AIMockInterviewer](https://github.com/Molika68/next-project)（Next.js + Nest.js 全栈版）的移动端实现，同一个 AI 能力复用到了 C 端跨端场景。

## 下载安装

Android APK（arm64，约 21 MB，已签名）：<https://github.com/Molika68/ai-interviewer/releases>

安装时若系统提示"未知来源"，允许即可——这是个人开发者直发包的正常流程，未上架应用商店。

## 三种面试引擎

| 引擎 | 数据来源 | 适用场景 |
|---|---|---|
| 离线题库 | 内置 30+ 道前端 / 全栈题，关键词规则评分 | 无网络、无 API Key 时仍可完整体验 |
| 大模型直连 | DeepSeek（OpenAI 兼容协议），流式出题 + 结构化评分 | 默认推荐的完整体验 |
| 自建后端 | 预留接口 | 需要鉴权、审计与配额控制的场景 |

UI 层只依赖 `InterviewEngine` 抽象接口，不感知数据来源，新增一种引擎无需改动任何页面代码。

## 功能

- 岗位与技术栈自定义，题目随回答动态调整（答得浅就追问更具体，答得好就换考察点）
- 题目流式生成，逐字输出（打字机效果）
- 单题三维评分：技术深度 / 表达清晰度 / 工程经验，外加各技术栈单独打分
- 面试结束生成综合评价 + 技能雷达图，历史记录本地持久化，支持逐题回看
- API Key 只保存在本机（SharedPreferences），不会上传

## 技术栈

Flutter 3.47 / Dart 3.13 · Riverpod（状态管理）· Dio（网络与 SSE 流式解析）· SharedPreferences（本地持久化）

技能雷达图为 `CustomPainter` 自绘，未引入第三方图表库，以此控制包体积。

### 关键实现

**SSE 流式解析** — Dio 设 `ResponseType.stream` 拿到字节流，UTF-8 解码后按 `LineSplitter` 逐行读取，过滤空行、心跳包与非 `data:` 前缀的行，遇 `[DONE]` 结束。解析失败或网络异常时自动降级为普通非流式请求，流程不中断。

**结构化评分** — 要求模型走 JSON 输出，客户端再做首尾花括号截取容错（模型经常在 JSON 外包一层 markdown 代码块）。解析失败返回默认分并提示，不会崩。

## 本地运行

```bash
flutter pub get
flutter run
```

构建发布包：

```bash
flutter build apk --release --target-platform android-arm64
```

连接大模型：在 App「设置」页填入 DeepSeek API Key 即可，留空则自动使用离线题库引擎。

## 项目结构

```
lib/
├── main.dart                        应用入口与路由
├── models/interview.dart            题目 / 回答 / 评分 / 结果数据模型
├── data/question_bank.dart          内置题库（30+ 道，含评分关键词）
├── services/
│   ├── storage_service.dart         历史记录本地持久化
│   └── engines/
│       ├── interview_engine.dart    引擎抽象接口
│       ├── local_engine.dart        离线题库引擎
│       └── deepseek_engine.dart     大模型直连引擎（SSE + JSON 评分）
├── providers/                       Riverpod 状态层
├── pages/                           首页 / 面试 / 结果 / 历史 / 设置
└── widgets/radar_chart.dart         自绘雷达图
```

## 测试

```bash
flutter test
```

覆盖离线引擎主流程、评分区分度与首页渲染。

## 说明

未上架应用商店，通过 GitHub Releases 直发 APK。目前仅在静态分析与单元测试层面验证，未做大规模真机兼容性测试。
