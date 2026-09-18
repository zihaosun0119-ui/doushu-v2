from __future__ import annotations

import argparse
from pathlib import Path


SUMMARY = """## 一页先看结论

### 一句话判断

这张命盘的主轴是“在变化和复杂问题中建立专业能力，再借助更大的平台、合作关系和明确规则放大成果”。命宫申为七杀，命宫三方见官禄破军、财帛贪狼，对宫迁移为紫微天府并承接壬年化权；这组结构支持主动解决难题，但不支持长期承担无授权、无验收、无回款保障的责任。

### 当前阶段：2026 年

2026 年是合作、合同、客户和关系边界重置的一年。现在最需要确认的不是“要不要马上换方向”，而是每一项新责任是否同时配有负责人、权限、预算、验收标准和付款节点。涉及跳槽、合伙、长期合作或共同支出时，先书面确认条件，再决定投入。

### 未来三年重点

- **2026：边界重置。** 合作与承诺变多，先把范围、权限、收益和退出机制写清楚。
- **2027：表达修正。** 适合把想法做成文档、原型和可验收成果，减少因口头沟通造成的反复。
- **2028：收入与责任同时放大。** 有扩大项目和商业化的机会，但必须先验证回款、合作者和身体恢复能力。

### 你现在最需要做的三件事

1. 选定一个能用作品、数据、证书或项目结果证明的核心能力。
2. 所有合作写明交付范围、验收标准、付款节点、违约责任和退出条件。
3. 连续记录睡眠、精力和现金流，不用未来奖金覆盖当前固定支出。

### 本次盘面校验

本报告以已校验的结构化命盘为准：命宫申七杀、身宫记录在午宫夫妻，官禄宫子破军，财帛宫辰贪狼，迁移宫寅紫微天府；壬年四化为天梁化禄、紫微化权、左辅化科、武曲化忌。八字四柱为壬午、癸丑、壬辰、乙巳，仅作交叉印证。任何与上述盘面不一致的“借宫”“身宫”或四化说法，都应先回到排盘数据复核。

### 流月说明

当前数据已生成年度流年，但尚未生成完整的流月命宫、月干四化和叠宫数据。因此本报告不提供具体月份断语；补齐流月底座后再单独生成 12 个月的主题、表现、依据、资料依据和行动建议。

"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    source = Path(args.source).resolve()
    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    text = source.read_text(encoding="utf-8")
    if not text.lstrip().startswith("# "):
        raise SystemExit("source must start with a markdown title")
    lines = text.splitlines(keepends=True)
    report = lines[0] + "\n" + SUMMARY + "\n" + "".join(lines[1:])
    output.write_text(report, encoding="utf-8")
    print(output)


if __name__ == "__main__":
    main()
