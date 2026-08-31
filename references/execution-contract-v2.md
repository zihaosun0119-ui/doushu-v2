# Doushu v2 强制执行契约

本契约是每次生成报告的必经门禁。任何阶段没有真实执行、没有记录状态，或校验失败，都不得生成或交付最终 HTML/PDF。

## 固定顺序

```text
0 读取契约并建立任务状态
1 强制输入询问门禁
2 命盘/运限/案例数据核验
3 确认报告方向与时间范围
4 知识库路由与通用分析层
5 专项深入分析层
6 独立复核层（子智能体或本地独立审校）
7 用户呈现层
8 restrained-professional-voice 语言审校
9 重复、边界、数据一致性检查
10 执行门禁校验
11 生成并检查 HTML/PDF
12 交付
```

## 状态文件

每次任务建立 `execution-manifest.json`，至少包含：

```json
{
  "schema_version": "doushu-v2-execution-2",
  "workflow_status": "passed",
  "stages": {
    "input_intake": "passed", "input": "passed", "data": "passed", "direction": "passed",
    "analysis": "passed", "specialty": "passed", "independent_review": "passed",
    "rendering": "passed", "voice_review": "passed", "dedupe": "passed", "delivery": "passed"
  },
  "modules": {
    "01-input-intake": "passed",
    "02-chart-data": "passed",
    "03-analysis": "passed",
    "04-quality-delivery": "passed"
  },
  "knowledge_route": {
    "status": "passed",
    "matched_topics": [],
    "matched_time_scopes": [],
    "required_files": [],
    "optional_files": [],
    "actual_files_read": [],
    "warnings": []
  },
  "actual_resources": [],
  "blocking_issues": []
}
```

`actual_resources` 必须记录实际读取的专项规则、呈现规则、语言审校规则和复核结果；只写“计划调用”不算完成。独立复核不可静默跳过：子智能体不可用时，必须完成本地独立审校并记录原因。

## 硬门禁

- 任一阶段不是 `passed`，停止，不输出最终文件链接。
- 没有专项规则、用户呈现规则、独立复核记录或 `restrained-professional-voice` 审校记录，停止。
- 报告泄漏内部 skill 名、流程指令、未解释的盘面术语，停止并返工。
- 健康报告出现医疗确诊/治疗保证；事业或感情报告出现确定性预测，停止并返工。
- HTML/PDF 只在门禁脚本通过后生成或交付。

失败时只报告：`未交付：执行门禁失败`、失败阶段、缺失项和修复动作。不得把草稿伪装成最终报告。
