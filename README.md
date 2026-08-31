# doushu-v2

一个面向紫微斗数分析的模块化 Codex Skill。

## 工作流

```mermaid
flowchart TD
    A[用户需求与出生资料] --> B{输入是否完整}
    B -- 否或时辰有争议 --> B1[补充资料或比较候选时辰]
    B1 --> B
    B -- 是 --> C[执行契约预检]
    C --> D[主题与时间范围路由]
    D --> E[准备命盘 大限 流年数据]
    E --> F{是否涉及流月}
    F -- 否 --> G[进入结构分析]
    F -- 是 --> H[校验流月完整度]
    H --> I{流月状态}
    I -- complete 或 fallback --> G
    I -- partial 或 unavailable --> I1[降级为观察性结论<br/>不输出具体流月断语]
    I1 --> G
    G --> J[中州结构层<br/>本命→大限→流年→流月]
    J --> K[飞星动态层<br/>生年四化→运限四化→宫位串联]
    K --> L[证据合并<br/>主判断→反证→条件→置信度]
    L --> M{用户需要专项分析}
    M -- 是 --> N[事业 关系 健康等专项模块]
    M -- 否 --> O[通用分析结果]
    N --> P[现实转换与决策支持]
    O --> P
    P --> Q[独立复核<br/>语言 重复 边界 来源]
    Q --> R{全部门禁通过}
    R -- 否 --> Q1[记录失败阶段并修正]
    Q1 --> Q
    R -- 是 --> S[生成 manifest 与 HTML/PDF]
    S --> T[核对输出并交付]

    classDef gate fill:#fff4cc,stroke:#b7791f,color:#3d2b00;
    classDef analysis fill:#e9f5ff,stroke:#2b6cb0,color:#12344d;
    classDef delivery fill:#eaf7ee,stroke:#2f855a,color:#153b25;
    class B,C,F,H,I,R gate;
    class J,K,L,M,N,O,P analysis;
    class Q,S,T delivery;
```

这套流程的核心是：先核验资料和数据，再做结构层与动态层的双主轴推演，最后把结论转换成现实可验证的判断。任何一个前置门禁未通过，都不能直接进入最终交付。

## 功能

- 出生资料核验与时辰边界处理
- 本命、大限、流年、流月的数据分层
- 事业、关系、健康等专项分析路由
- 证据链、反证、现实验证和决策支持
- 流月数据完整度检查与本地排盘兜底
- 报告质量、重复、来源和执行门禁校验

## 目录

- `SKILL.md`：技能入口与工作流
- `modules/`：输入、数据、分析和交付模块
- `references/`：分析规则、证据规范和输出规范
- `scripts/`：校验、路由、报告和兜底工具
- `agents/openai.yaml`：Codex agent 配置

## 使用边界

本 Skill 输出的是传统命理框架下的条件化分析，不保证职业、财务、关系或健康结果；健康、法律和财务问题不能以命盘替代专业意见。

本公开仓库不包含个人案例、出生资料和研究资料原件。研究归档和本地案例应在私有环境中使用。

## 许可

除 `references/` 中另有来源或许可证说明的内容外，本仓库代码和原创文档采用 MIT License，见 `LICENSE`。
