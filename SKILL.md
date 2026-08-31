---
name: doushu-v2
description: 用户提供生辰或结构化命盘并要求紫微斗数分析、流年、事业、感情、健康或完整报告时使用。按需路由分析层与专项报告层。
---

# Doushu v2 总入口

本 skill 采用“总入口 + 四阶段模块 + 参考资料”的结构。模块注册表见 `modules/module-registry.json`，每个模块都必须遵循统一的输入、动作、输出、门禁契约，不能跳过前置阶段。

本 skill 采用固定执行契约，HTML/PDF 属于最后的交付动作。每次先读取 `references/execution-contract-v2.md`，建立并校验 `execution-manifest.json`：

```text
执行契约预检 → 输入层 → 数据层 → 条件化深入分析层 → 独立复核层 → 专项报告层 → 用户呈现层 → 语言/重复/边界检查 → 门禁校验 → HTML/PDF 交付
```

入口只负责流程和路由，不在这里重复事业、感情或健康的详细写作规则。

HARD_GATE: 任一模块未真实执行、状态不是 `passed` 或未通过门禁，禁止进入下一模块和输出最终文件；必须报告失败阶段，不得静默省略。

执行时读取 `modules/module-registry.json`，按其 `sequence` 字段读取模块文件。每个模块完成后，必须将 `pending/passed/blocked/failed` 状态、实际读取资源、输出摘要和阻塞原因写入 `execution-manifest.json`。

知识库调用必须经过 `modules/knowledge-route-registry.json` 和 `scripts/resolve-knowledge-route.ps1`。先分类主题、宫位和时间范围，再读取路由结果中的 `required_files`；`optional_files` 只能在本次任务确有需要时读取。路由结果为 `failed` 或存在未处理警告时，不得开始分析。

知识扩充任务另读 `references/knowledge-expansion-contract-v3.md`。资料、格局、十二宫和星曜联动分别读取对应注册表，不把所有知识库一次性加载进当前报告。


## 1. 强制输入询问与核验

开始排盘、案例检索或任何分析前，必须先读取 `references/input-intake-gate-v2.md` 并执行输入询问门禁。

对应模块：`modules/01-input-intake.md`。该模块未通过时，不得进入 `02-chart-data` 或 `03-analysis`。

HARD_GATE: 缺少任一必填资料时，必须暂停并向用户询问；不得生成命盘、检索案例、进行分析或交付报告。已有资料不得重复询问，只询问缺失项。

首次询问必须明确列出：历法、出生日期、出生时间、时间准确程度、性别、出生地、时区、真太阳时校正、分析需求和分析时间范围。可直接使用 `input-intake-gate-v2.md` 中的询问模板。

确认或标记：

- 公历/农历日期；
- 出生时间和准确程度；
- 性别；
- 出生地、时区和真太阳时风险；
- 用户要生成的报告类型；
- 用户当前现实背景或关注问题。

出生时间不明确、有争议或可能跨时辰时，先暂停排盘，询问时间范围，给出候选时辰的现象、行为和经历对比，并等待用户确认。只有用户明确要求比较时，才进行双盘/多盘比较。出生时间已明确时，不做无必要的双盘。

## 2. 准备可复用数据

按 `chart_key` 复用或生成：

- 结构化命盘；
- 庙旺补充数据；
- 当前大限和所需流年数据；
- 案例检索结果；
- 用户已确认的前事。

数据未变化时不得重复排盘、重复扩展流年或重复检索案例。

### 流月数据完整度

涉及流月时，先运行 `scripts/validate-monthly-flow.js` 并读取输出中的 `monthlyDataStatus`。`jieqiMonths` 只代表节气月干支，不等于完整紫微流月。

- `complete`：月干支、流月命宫、十二宫、月干四化和叠宫完整；
- `partial`：只有节气月干支；
- `fallback`：缺失字段已由 `scripts/merge-mingli-fallback.js` 使用本地 iztro 补齐；
- `unavailable`：没有可靠流月数据。

只有 `complete` 或明确标注 `fallback` 时，才允许输出具体流月命宫、月干四化和叠宫判断。规范目录固定为本文件所在的 `.codex/skills/doushu-v2`；工作区根目录的 `doushu-v2` 仅作为指向规范目录的兼容链接。

生成新案例前必须读取 `references/anti-repetition-v1.md`，检索相似案例并登记本案例的独有结构、不可复用表达和专属验证点。

## 3. 生成分析任务配置

根据用户输入生成最小任务配置：

```text
报告类型：完整/专项
分析方向：健康/事业/感情/社交/财务/迁移/家庭/其他
时间范围：本命/大限/未来三年/指定年份
现实问题：用户希望确认的具体问题
用户状态：当前工作、关系、健康或社交背景
```

用户只说“帮我分析一下”时，先询问主要方向；方向明确后，不要求填写无关领域。

用户明确要求某年某月时，读取 `references/monthly-analysis-output-v1.md`；跨领域动态分析同时读取 `references/dynamic-cross-domain-v1.md`。流月字段缺失时先执行本地兜底，仍未通过完整度门禁则只报告缺失项，不生成具体月份断语。

## 4. 按条件选择深入分析方向

分析方向和知识库文件的具体映射以 `modules/knowledge-route-registry.json` 为准；本节保留各方向的解释性说明。修改路由时优先编辑该 JSON，不要只修改文字说明。

### 完整命局报告

读取：

- `references/analysis-core-v2.md`；
- `references/analysis-deep-rules-full-v2.md`；
- `references/report-modes-v2.md`；
- `references/decision-support-v2.md`；
- `references/user-rendering-v3.md`。

### 健康方向

读取：

- `references/analysis-core-v2.md`；
- `references/analysis-deep-rules-full-v2.md`；
- `references/health-rules-full-v2.md`；
- `references/report-modes-v2.md`；
- `references/user-rendering-v3.md`。

### 事业方向

读取通用分析层、完整深度规则、`career-analysis-v2.md`、`report-modes-v2.md`、`decision-support-v2.md` 和用户呈现层。

### 感情方向

读取通用分析层、完整深度规则、`relationship-analysis-v2.md`、`report-modes-v2.md`、`decision-support-v2.md` 和用户呈现层。

### 社交方向

读取通用分析层、完整深度规则、社交模块、`decision-support-v2.md` 和用户呈现层。

深入分析交友宫、兄弟宫、迁移宫、命宫、福德宫、官禄宫、夫妻宫和相关运限，区分朋友、同事、客户、团队、师长和公共社交。

专项报告规则由分析阶段按需路由，用户正文统一使用 v3 呈现契约。只读取当前任务需要的方向模块，不默认加载全部领域。

## 5. 执行条件化深入分析

先完成所有方向共用的最小基础分析：资料、命宫、身宫、三方四正、四化和相关运限；再根据任务配置深入指定领域。完整深度规则和原专项提示词作为详细依据，不被删除，只是不在入口文件重复展开。

例如：用户要健康报告，不必深入事业、感情和社交；用户要事业加感情，只加载事业和感情模块。

深入分析列出该方向有依据的主要可能性；只有结论跨模块复用时才登记编号，避免重复完整解释。用户要求子智能体时必须调用；存在两个以上独立任务时也必须独立复核。工具不可用时，执行本地独立审校并在 manifest 中记录原因，不能跳过。

分析层输出：

- 核心判断；
- 盘面依据；
- 组合推理；
- 可能路径；
- 替代解释；
- 成立条件；
- 时间窗口；
- 置信度；
- 现实验证点。

需要扩充底层知识时，按需读取：

- `references/source-registry-v1.md`：资料和方法；
- `references/pattern-library-v1.md`：100—200 个格局与结构组合；
- `references/palace-analysis-v1.md`：十二宫十二维矩阵；
- `references/star-interaction-v1.md`：主星、辅星、煞曜联动；
- `references/social-source-registry-v1.md`：B站等社交媒体辅助资料；
- `references/anti-repetition-v1.md`：案例差异化。

资料数量目标为至少 50 条来源/方法、100—200 个格局或组合、12 宫各 12 个观察维度。未完成的数量必须标记为未完成，不得编造或用改名重复凑数。

知识库更新后运行 `scripts/validate-knowledge-base.ps1`；计数、十二宫或十四主星覆盖不通过时，不得宣称扩充完成。

## 5A. 证据优先知识库调用

知识扩充和报告调用必须先读：

- `references/source-index.md`；
- `references/source-digests/digest-schema.md`；
- `references/pattern-evidence-matrix.md`；
- `references/case-evidence-registry.md`。

来源正文、目录、摘要、案例和本地方法分开记录。搜索摘要、书名、课程目录或社交平台作者自述不得直接升级为通用规则；同一书、同一视频、同一案例的转载只计算一个独立来源。下载件以 `references/source-digests/download-manifest.md` 为本地完整性清单，未能公开下载的材料只保留网页访问记录，不绕过登录、付费或版权限制。

深度结构卡按 `references/patterns-deep/index.md` 按需加载，不遍历全部资料。每次专项报告最多选择 3—8 条与当前盘面和主题匹配的卡片；选择前必须检查证据矩阵中的处理状态。证据状态为“暂缓”“暂不调用”的项目禁止进入分析。

当前证据裁决：120 个候选均已形成卡片，并分为结构分析卡、传统候选卡和实现层结构候选。结构卡不冒充古籍格局；传统候选必须保留具体章节位置和成立条件。卡片生成和调用均通过 `scripts/validate-deep-patterns.ps1` 后才可使用。

## 6. 执行专项报告层

专项模块只做两件事：

1. 从通用分析中抽取与当前主题有关的结论；
2. 将结论转换成该领域的现实场景、分流问题和行动建议。

专项报告层不得重新推演命盘，只把已经完成的对应方向分析转换成用户报告。

需要比较选择、评估风险或制定下一步时，读取 `references/decision-support-v2.md`，在专项报告之后增加决策支持，不代替用户作决定。

## 7. 执行用户呈现层

主报告默认使用以下四个用户可见结构，可按问题合并、删减或调整顺序：

1. 先说结论；
2. 可能表现；
3. 如何判断；
4. 现在怎么做。

默认采用“分析稿与用户报告严格分离”模式：专业依据、盘面术语和完整推理链只保留在独立分析稿，不进入用户报告正文。生成用户报告时必须读取 `references/user-report-rewrite-contract-v1.md`；它规定讨论范围、禁用术语、结构、边界和验收标准。完整性通过现实场景分流实现，不通过增加大量标题实现。

呈现层使用 `references/user-rendering-v3.md` 和 `references/user-report-rewrite-contract-v1.md`。用户正文只展示现实结论、可能表现、判断条件、时间窗口、风险和行动建议；完成后必须调用 `restrained-professional-voice` 做语言审校。

用户验证问题不得机械罗列。除非用户明确要求问卷，否则把需要确认的内容写成一段自然的验证引导，最多包含两个核心确认点。

## 8. 交付与检查

完成 `restrained-professional-voice` 审校、重复检查、边界检查并运行 `scripts/validate-execution-gates.ps1` 通过后，才生成或交付 HTML/PDF。检查：

- 关键数据是否一致；
- 同一核心判断是否重复完整出现；
- 用户是否能看懂每个结论；
- 健康是否越过医疗边界；
- 事业和感情是否写成确定性预测；
- PDF 是否存在分页、字体和表格问题。

每次最终交付必须包含已通过的 `execution-manifest.json`；门禁脚本失败时不得交付。

保留现有 `enrich-brightness.js`、`enrich-flow.js`、`case-library.js`、`build-analysis-manifest.js` 和 `run-report.ps1`，它们属于数据与交付层，不需要在 v2 重写。

## 9. 中止条件

- 出生日期、时间或性别缺失且无法从上下文获得；
- 结构化命盘无法可靠生成；
- 流年数据缺失时，不伪造具体年份或月份；
- 用户要求医疗诊断、投资保证或替代现实决策时，保留边界并转换为观察和核对建议。
