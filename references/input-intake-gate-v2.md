# Doushu v2 输入询问门禁

## 零、报告选择页

skill 启动后的第一屏必须先读取并执行 `references/report-selection-gate-v1.md`。让用户从完整命局、事业与工作、财务与现金流、关系与合作、健康与恢复、迁移/家庭/社交、流年/未来三年、流月/12 个月中选择一个或多个报告。用户确认前不得进入本节的出生资料询问，也不得排盘或分析。

## 一、最小输入

先从上下文和用户提供的结构化命盘提取已有信息，不重复询问。将信息分成三类：

- 排盘必需：历法、出生日期、性别、可用出生时刻或候选时间范围。农历输入还需明确是否闰月；只有确实影响换算时才追问。
- 可推定：出生地对应时区，可标记为推定并记录依据。历史时区、夏令时、真太阳时可能导致日期或时辰改变时，先核实；不能无依据猜测。出生地缺失且影响校时，属于阻塞项。`method_profile = feixing` 时，四化表版本、流月规则和分析层级属于排断必需配置；用户未指定时按飞星模式默认值，但必须把默认值写入确认记录。
- 分析偏好：以前置报告选择页确认的方向、时间范围、现实背景。方向未给出且不同选择会明显改变报告时，只问主要方向；没有时间分析需求时，时间范围记为不适用。现实背景可选，不要求填写无关领域。

只有排盘必需项或当前任务所需分析范围缺失时，暂停并询问。一次集中询问缺失项，不能机械发送完整十项问卷。时间准确程度可从“约八点”“只知道辰时”等原话提取；没有说明时记为未说明，仅在影响边界判断时追问。

示例：已有日期、性别、出生地，只缺时间时，可问“请补充出生时间；不确定的话，给一个大致范围即可。”

## 二、出生时间不明确

1. 先确定时间范围，并检查地点、时区和校时是否可能跨时辰。
2. 未获准比较前，只解释时间边界和缺失资料，不输出候选命盘的性格或经历差异。
3. 用户明确要求双盘/多盘比较，且其他排盘资料齐全时，将 birth_time 标记为候选比较，记录候选范围与授权来源；输入门禁可以通过，随后在数据层分别生成候选盘。
4. 只有实际生成候选盘后，才比较盘面差异与验证点。各候选盘独立标识、独立缓存，不得混合结论。
5. 用户反馈“更像某盘”只记为支持线索，保留时间不确定性。只有用户补充可确认的出生记录等事实依据，才更新出生时刻的确认状态。
6. 无可用范围且无法建立候选盘，保持 pending，停止排盘；不得猜测。

时间明确且无边界风险时直接用单盘。资料不足以确认真太阳时风险时，应记录缺口并询问会影响排盘的资料。

## 三、输入状态

在 execution-manifest.json 的 input_intake 中保存实际值、来源与确认状态，而非只写“已确认”。例如：

~~~json
{
  "status": "pending",
  "calendar": {"value": null, "source": null, "status": "missing"},
  "birth_date": {"value": null, "source": null, "status": "missing"},
  "birth_time": {"value": null, "status": "missing"},
  "birth_time_accuracy": "未说明",
  "sex": {"value": null, "source": null, "status": "missing"},
  "birth_place": {"value": null, "source": null, "status": "missing"},
  "timezone": {"value": null, "source": null, "status": "missing"},
  "true_solar_time_risk": "未判断",
  "method_profile": "helu",
  "four_hua_table": "按方法默认，需在报告开头声明",
  "monthly_rules": "未涉及",
  "analysis_scope": null,
  "analysis_period": "不适用",
  "candidate_comparison": {"authorized": false, "authorization_source": null, "candidates": []},
  "pending_questions": []
},
"report_selection": {"status": "passed", "reportTypes": ["health"], "directions": ["健康"]}
~~~

只在必需资料齐全、当前任务可执行且 pending_questions 为空时标记 passed；stages.input_intake 与模块状态同步。候选比较通过不等于某个出生时间已确认。执行状态和产物字段遵循 references/execution-contract-v2.md。
