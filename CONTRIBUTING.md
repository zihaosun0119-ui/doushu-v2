# 贡献指南

感谢参与 SZH-Doushu。这里的贡献重点是：修正流程门禁、完善可追溯方法、提高报告输出质量，而不是堆叠未经核验的断语。

## 开始前

1. 先阅读 [SKILL.md](SKILL.md) 与 [docs/architecture.md](docs/architecture.md)。
2. 确认改动属于输入、数据、分析、交付或文档中的哪一层。
3. 不要提交个人出生资料、案例报告、研究原件或本地绝对路径。

## 提交前检查

```powershell
git diff --check
node --test scripts/test-analysis-manifest.js
pwsh -NoProfile -File scripts/test-skill-contract.ps1
pwsh -NoProfile -File scripts/test-modular-contract.ps1
pwsh -NoProfile -File scripts/test-knowledge-routing.ps1
pwsh -NoProfile -File scripts/test-execution-gates.ps1
```

如果修改了 `references/` 的路由或来源登记，还要运行相应的知识库与来源校验脚本。

## 变更原则

- 新增规则先放到最具体的参考文件，再在 `SKILL.md` 中增加简短路由。
- 不把节气月干支当成完整紫微流月。
- 不把搜索摘要、个人经验或单一案例写成普遍成立的传统规则。
- 健康、法律和财务内容必须保留现实专业边界。
- 默认用户报告是 Markdown；HTML/PDF 只有明确要求时才生成。

## 提交信息

提交标题使用简洁的动词开头，例如：

- `feat: add monthly-flow validation`
- `fix: correct relationship route`
- `docs: clarify installation`
- `test: cover health manifest`
