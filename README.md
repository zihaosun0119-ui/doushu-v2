# SZH-Doushu

> 面向 Codex 的紫微斗数分析技能包：先核验数据，再按方法模式完成命盘、运限与专项报告。

[![Validate](https://github.com/zihaosun0119-ui/doushu-v2/actions/workflows/validate.yml/badge.svg)](https://github.com/zihaosun0119-ui/doushu-v2/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 项目定位

本仓库是可独立安装的 Codex skill，不是网页应用。根目录的 `SKILL.md` 是唯一入口；命盘计算、报告渲染和导出由外部前端或调用方负责。

项目的核心原则是：

1. 先核验出生资料、历法、时辰和数据完整度。
2. 再按飞星或河洛主轴建立可追溯的分析链。
3. 最后把结论转换为现实对象、触发条件、时间窗口、验证点和行动建议。
4. 任一前置门禁失败，都不输出伪精确的具体断语。

## 快速开始

### 安装到 Codex 全局技能目录

Windows PowerShell：

```powershell
$destination = "$HOME\.codex\skills\szh-doushu"
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Copy-Item -Recurse -Force .\* $destination
```

macOS/Linux：

```bash
mkdir -p ~/.codex/skills/szh-doushu
cp -R ./* ~/.codex/skills/szh-doushu/
```

安装后使用 `$szh-doushu`，或直接提出紫微斗数排盘、流年、事业、感情、健康和完整报告需求。

### 最小调用示例

```text
使用 $szh-doushu。
出生：2003-01-19 09:45，男，江苏常州，真太阳时。
报告：感情专项，输出 Markdown。
```

首次调用会先要求选择报告方向；选择确认前不会开始排盘或分析。

## 工作流

```mermaid
flowchart LR
    A[资料与报告选择] --> B[输入门禁]
    B --> C[命盘与运限数据]
    C --> D{主轴}
    D -->|河洛| E[河洛坐标链]
    D -->|飞星/四化| F[飞星因果链]
    E --> G[专项分析]
    F --> G
    G --> H[现实转换与复核]
    H --> I[Markdown 交付门禁]
```

涉及流月时，固定使用本地 `iztro@2.6.0` 的 `monthlyList(目标年, true)`，并运行流月完整度校验；节气月干支不能代替完整紫微流月。

## 目录结构

```text
.
├── SKILL.md                         # 技能入口与总路由
├── agents/openai.yaml               # Codex 展示信息与默认调用提示
├── modules/                         # 输入、数据、分析、交付模块
├── references/                      # 方法、证据、专项规则与输出契约
│   ├── patterns-deep/               # 按需读取的深层结构卡
│   ├── source-digests/              # 来源摘要与证据索引
│   └── source-archive/              # 本地研究归档，不随公开仓库分发
├── scripts/                         # 路由、排盘数据、校验与测试脚本
├── docs/                            # 面向维护者的架构、流程与版本文档
├── tests/                           # 测试说明与可复现实例索引
├── .github/                         # CI、Issue 模板与 PR 模板
├── CONTRIBUTING.md                  # 贡献与变更约定
├── SECURITY.md                      # 安全与隐私报告流程
├── CHANGELOG.md                     # 版本变更记录
└── LICENSE                          # MIT 许可证
```

## 常用命令

在仓库根目录执行：

```powershell
node --test scripts/test-analysis-manifest.js
pwsh -NoProfile -File scripts/test-skill-contract.ps1
pwsh -NoProfile -File scripts/test-modular-contract.ps1
pwsh -NoProfile -File scripts/test-knowledge-routing.ps1
pwsh -NoProfile -File scripts/test-execution-gates.ps1
```

`git diff --check` 用于提交前检查空白和冲突标记；完整 CI 配置见 `.github/workflows/validate.yml`。

## 维护约定

- `SKILL.md` 只保留入口、路由和不可跳过的门禁；专项规则放在 `references/`。
- `modules/` 只描述阶段职责与输入输出，不重复整套命理知识。
- `scripts/` 负责可重复执行的生成、校验和测试，不把个人命盘写入公开仓库。
- 个人案例、出生资料、报告和研究原件默认被 `.gitignore` 排除。
- 修改目录或文件名时，同时更新路由 JSON、脚本测试、文档链接和全局安装副本。

## 设计参考

本项目的技能包形态参考了 [OpenAI Skills](https://github.com/openai/skills) 与 [Anthropic Skills](https://github.com/anthropics/skills) 的公开组织方式：根目录保留可识别的 `SKILL.md`，辅助资源按用途分目录，并用 UI 元数据和自动化校验保证可发现性与可维护性。

## 使用边界

本 Skill 提供传统命理框架下的结构化分析，不替代医学、法律、财务或其他专业意见。健康内容用于预防和就医准备，不用于诊断；报告不承诺职业、财务或关系结果。

## 许可证

除 `references/` 中另有来源或许可证说明的内容外，本仓库原创代码和文档采用 MIT License，详见 [LICENSE](LICENSE)。
