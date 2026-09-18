## 变更摘要

<!-- 用 1—3 句话说明改了什么，以及为什么。 -->

## 影响范围

- [ ] `SKILL.md` / agents 元数据
- [ ] modules 流程编排
- [ ] references 方法或证据
- [ ] scripts / tests
- [ ] 文档或 CI

## 验证

- [ ] `git diff --check`
- [ ] `node --test scripts/test-analysis-manifest.js`
- [ ] `pwsh -NoProfile -File scripts/test-skill-contract.ps1`
- [ ] `pwsh -NoProfile -File scripts/test-modular-contract.ps1`
- [ ] `pwsh -NoProfile -File scripts/test-knowledge-routing.ps1`
- [ ] `pwsh -NoProfile -File scripts/test-execution-gates.ps1`

## 隐私与兼容性

- [ ] 未提交个人出生资料、案例报告、研究原件或本地绝对路径
- [ ] 已更新受影响的路由、测试和文档链接
