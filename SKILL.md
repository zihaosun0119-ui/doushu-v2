---
name: doushu-v2
description: 用户提供生辰或结构化命盘并要求紫微斗数分析、飞星四化、流年、事业、感情、健康或完整报告时使用。按需路由方法模式、分析层与专项报告层。
---

# Doushu v2 总入口

本 skill 采用“总入口 + 四阶段模块 + 参考资料”的结构。模块注册表见 `modules/module-registry.json`，每个模块都必须遵循统一的输入、动作、输出、门禁契约，不能跳过前置阶段。

本 skill 采用固定执行契约，HTML/PDF 属于最后的交付动作。每次先读取 `references/execution-contract-v2.md`、`references/report-selection-gate-v1.md`、`references/methodology-and-user-report-v2.md` 和 `references/feixing-fourhua-method-v1.md`，再按主轴模式读取 `references/helu-specificity-and-preflight-v1.md`（需要河洛主断时），建立并校验 `execution-manifest.json`：

```text
执行契约预检 → 输入层 → 排盘与飞星基础层 → 河洛/飞星主轴分析 → 完整命局模式（按需） → 独立复核层 → 专项报告层 → 方法与具体性 Preflight → 语言/重复/边界检查 → 交付 Preflight → 生成并检查 HTML/PDF → final 验收 → 交付
```

入口只负责流程和路由，不在这里重复事业、感情或健康的详细写作规则。

HARD_GATE: 前置模块未完成或检查失败时，不得进入依赖它的阶段。质量与交付模块内部按 preflight、生成与 QA、final 依次执行；不得提前把 delivery 或整个工作流标为 passed。最终验收失败时不得交付文件，必须报告失败阶段。

执行时读取 `modules/module-registry.json`，按其 `sequence` 字段读取模块文件。每个模块完成后，必须将 `pending/passed/blocked/failed` 状态、实际读取资源、输出摘要和阻塞原因写入 `execution-manifest.json`。

知识库调用必须经过 `modules/knowledge-route-registry.json` 和 `scripts/resolve-knowledge-route.ps1`。先分类主题、宫位和时间范围，再读取路由结果中的 `required_files`；`optional_files` 只能在本次任务确有需要时读取。路由结果为 `failed` 或存在未处理警告时，不得开始分析。

知识扩充任务另读 `references/knowledge-expansion-contract-v3.md`。资料、格局、十二宫和星曜联动分别读取对应注册表，不把所有知识库一次性加载进当前报告。实际命盘分析每次都先读取并执行 `references/feixing-fourhua-method-v1.md` 的飞星基础层；具体主断再按 `method_profile` 读取 `references/helu-specificity-and-preflight-v1.md` 或提升飞星文件为主轴。两种模式不得混飞。

### 方法模式路由

- 用户明确说“飞星断盘、飞星四化、飞宫、自化、准到月”等，设置 `method_profile = feixing`，飞星/四化为主轴；河洛、中州和许铨仁只作分栏对照。
- 用户明确说“河洛、气数位、一六共宗、原盘宫干不重排”等，设置 `method_profile = helu`，继续使用河洛主轴。
- 用户同时要求两种方法时，分别运行两条推理链，再在多派对照表中比较；禁止把大限宫干重排规则和河洛原盘宫干规则混写。
- 用户未指定主轴时，完成飞星基础层并沿用当前河洛主断；用户未指定四化表时，按飞星基础层默认表并在开头声明。
- 用户说“完整命局、全盘分析、完整分析报告、全盘详细分析”等时，设置 `report_mode = complete`，调用 `03-complete-report`；该模式自动分开运行飞星与河洛两条完整链，并按需补充关键三方四正，不要求用户再次粘贴长提示词。


## 1. 强制输入询问与核验

skill 首次调用时必须先展示报告选择页，读取 `references/report-selection-gate-v1.md`，让用户选择一个或多个报告类型并确认。选择未完成时，只停留在选择页，不得开始出生资料询问、排盘、案例检索、知识路由或任何分析。

报告选择结果写入 `task.reportTypes`，对应的中文方向写入 `task.directions`；后续分析和报告只能输出用户已选择的类型。旧请求没有 `reportTypes` 时，才允许使用 `directions` 兼容回退。

完成报告选择后，开始排盘、案例检索或任何分析前，必须再读取 `references/input-intake-gate-v2.md` 并执行输入询问门禁。

对应模块：`modules/01-input-intake.md`。该模块未通过时，不得进入 `02-chart-data` 或 `03-analysis`。

HARD_GATE: 缺少任一必填资料时，必须暂停并向用户询问；不得生成命盘、检索案例、进行分析或交付报告。已有资料不得重复询问，只询问缺失项。

先从上下文提取已有资料，只集中询问会阻塞当前任务的缺项。时区可按出生地推定并注明；真太阳时由时间边界风险决定是否需要进一步确认。报告类型已经在前置选择页确认；分析方向、时间范围及现实背景按任务需要补充，不默认发送十项问卷。

确认或标记：

- 公历/农历日期；
- 出生时间和准确程度；
- 性别；
- 出生地、时区和真太阳时风险；
- 用户要生成的报告类型；
- 用户当前现实背景或关注问题。

出生时间不明确或可能跨时辰时，先确定可用时间范围和校时依据。尚未获准比较时只说明时间边界，不凭空给出命盘差异。用户明确要求比较后，以候选比较模式通过输入门禁，分别生成候选盘再比较。经历吻合只作为支持线索，不能把候选时间升级为已确认出生事实。出生时间明确且无边界风险时直接使用单盘。

## 2. 准备可复用数据

按 `chart_key` 复用或生成：

- 结构化命盘；
- 庙旺补充数据；
- 当前大限和所需流年数据；
- 案例检索结果；
- 用户已确认的前事。

复用前读取 `references/data-cache-contract-v1.md`，分别核对命盘、运限和案例检索缓存键、产物哈希与覆盖范围。缓存键及产物均有效时复用；算法、校时参数、查询范围或案例库变化时只重建受影响的数据。

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

用户明确要求某年某月或逐月报告时，读取 `references/monthly-analysis-output-v1.md` 和 `references/methodology-and-user-report-v2.md`，先确认目标年份和每个月的流月完整度。跨领域动态分析同时读取 `references/dynamic-cross-domain-v1.md`。只有 `complete` 或明确标注 `fallback` 时才输出 12 个月逐月判断；流月字段缺失时先执行本地兜底，仍未通过完整度门禁则只报告缺失项，不生成具体月份断语。

## 4. 按条件选择深入分析方向

分析方向和知识库文件的具体映射以 `modules/knowledge-route-registry.json` 为准；本节保留各方向的解释性说明。修改路由时优先编辑该 JSON，不要只修改文字说明。

### 完整命局报告

读取 `references/complete-report-mode-v1.md`，并在通用分析完成后进入 `modules/03-complete-report.md`。完整模式自动覆盖全盘、双链推演、关键三方四正和有依据的现实专题；只有用户另指定流年或流月时才追加对应时间层。

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

专项报告规则由分析阶段按需路由，用户正文统一使用 v3 呈现契约。只读取当前任务需要的方向模块，不默认加载全部领域；`report_mode = complete` 时按完整模式路由加载全盘所需规则，并由 `03-complete-report` 汇总，不把专项模块的依据重复写多遍。

## 5. 执行条件化深入分析

先完成所有任务共用的排盘与飞星基础数据：原局生年四化、命宫飞化、自化/互化/连环忌、大限、流年和流月的分层链条。随后按 `method_profile` 确定主轴：`helu` 追加1—12坐标、命疾福、命财官气数位、主问宫气数位和原盘宫干四化；`feixing` 将飞星链提升为主断，并以河洛、中州、许铨仁作分栏对照。若 `report_mode = complete`，在主轴之后调用 `03-complete-report`，将飞星链和河洛链分别完整登记，再做关键三方四正和全盘现实专题。三方四正只有在所选模式需要论格局或流月承接时加载；历史深度规则与当前主轴冲突时不得采用旧规则。

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

每条核心结论还必须明确：方法模式对应的主宫/源宫、气数位或飞星落宫、现实对象和变化、触发条件、至少一个替代解释、可核对现象和具体行动。禁止只写“有机会、遇贵人、压力增加、财运变好、关系有变化”等未落地表达；具体性门禁见所选方法模式的 Preflight 文件。

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

深度结构卡按 `references/patterns-deep/index.md` 按需加载，不遍历全部资料。每次专项报告按相关性选择与当前盘面和主题匹配的卡片，上限 8 条，无匹配可为 0 条；选择前必须检查证据矩阵中的处理状态。证据状态为“暂缓”“暂不调用”的项目禁止进入分析。

卡片按结构分析卡、传统候选卡和实现层结构候选分类；实际数量与验证状态以本次运行 `scripts/validate-deep-patterns.ps1` 的结果为准，将输出保存到任务目录，入口不声明固定完成数量。结构卡不冒充古籍格局；传统候选必须保留具体章节位置和成立条件。卡片生成和调用均通过 `scripts/validate-deep-patterns.ps1` 后才可使用。

## 6. 执行专项报告层

专项模块只做两件事：

1. 从通用分析中抽取与当前主题有关的结论；
2. 将结论转换成该领域的现实场景、分流问题和行动建议。

专项报告层不得重新推演命盘，只把已经完成的对应方向分析转换成用户报告。

需要比较选择、评估风险或制定下一步时，读取 `references/decision-support-v2.md`，在专项报告之后增加决策支持，不代替用户作决定。

## 7. 执行用户呈现层

主报告默认使用以下四个用户可见结构，可按问题合并、删减或调整顺序：

1. 先说结论；
2. 具体对象、现实变化和触发条件；
3. 时间范围、验证点和替代解释；
4. 现在怎么做。

默认采用“分析稿与用户报告严格分离”模式：专业依据、盘面术语和完整推理链只保留在独立分析稿，不进入用户报告正文。生成用户报告时必须读取 `references/user-report-rewrite-contract-v1.md`；它规定讨论范围、禁用术语、结构、边界和验收标准。完整性通过现实场景分流实现，不通过增加大量标题实现。

呈现层使用 `references/user-rendering-v3.md`、`references/user-report-rewrite-contract-v1.md` 和 `references/methodology-and-user-report-v2.md`。PDF 首屏必须先展示一句话总判断、3—5 条重点、当前阶段重点领域、行动卡、数据完整度和限制。用户正文只展示现实结论、可能表现、判断条件、时间窗口、风险和行动建议；完成后必须调用 `restrained-professional-voice` 做语言审校。用户要求逐月时，正文加入按自然月份排序的月度总览；每月包含主题、重点领域、现实表现、行动、依据摘要、置信度和不确定性。

用户验证问题不得机械罗列。除非用户明确要求问卷，否则把需要确认的内容写成一段自然的验证引导，最多包含两个核心确认点。

## 8. 交付与检查

完成所选方法模式的 Preflight、`restrained-professional-voice` 审校、重复检查和边界检查后，按执行契约运行 `scripts/validate-execution-gates.ps1 -Phase preflight`；通过后生成并检查 HTML/PDF，保存产物哈希和 QA 记录，再运行 `-Phase final`。最终验收通过后才交付。检查：

- 关键数据是否一致；
- 同一核心判断是否重复完整出现；
- 用户是否能看懂每个结论；
- 每条核心结论是否落到明确对象、现实变化、触发条件、时间范围、验证点和行动；
- 是否写明所选模式要求的主宫/源宫、气数位或飞星落宫、化曜路径；
- 健康是否越过医疗边界；
- 事业和感情是否写成确定性预测；
- PDF 是否存在分页、字体和表格问题。

每次最终交付必须包含通过 final 验收的 `execution-manifest.json`；门禁脚本失败时不得交付。用户正文按内容覆盖验收，标题可以合并或调整；内容覆盖摘录必须来自实际正文。

保留现有 `enrich-brightness.js`、`enrich-flow.js`、`case-library.js`、`build-analysis-manifest.js` 和 `run-report.ps1`，它们属于数据与交付层，不需要在 v2 重写。

## 9. 中止条件

- 出生日期、时间或性别缺失且无法从上下文获得；
- 结构化命盘无法可靠生成；
- 流年数据缺失时，不伪造具体年份或月份；
- 用户要求医疗诊断、投资保证或替代现实决策时，保留边界并转换为观察和核对建议。
