# 维护与发布

## 本地验证

在仓库根目录运行：

```powershell
git diff --check
node --test scripts/test-analysis-manifest.js
pwsh -NoProfile -File scripts/test-skill-contract.ps1
pwsh -NoProfile -File scripts/test-modular-contract.ps1
pwsh -NoProfile -File scripts/test-knowledge-routing.ps1
pwsh -NoProfile -File scripts/test-execution-gates.ps1
```

## 全局同步

Windows：

```powershell
$source = (Resolve-Path .).Path
$target = "$HOME\.codex\skills\szh-doushu"
New-Item -ItemType Directory -Force -Path $target | Out-Null
Get-ChildItem -LiteralPath $source -Force | Where-Object Name -ne '.git' | Copy-Item -Destination $target -Recurse -Force
```

同步后至少核对 `SKILL.md` 和 `agents/openai.yaml` 的内容一致。

## 发布

1. 更新 `CHANGELOG.md`。
2. 运行全部测试并检查 `git diff --check`。
3. 使用 Conventional Commits 提交。
4. 推送 `main`，等待 `.github/workflows/validate.yml` 通过。
5. 确认远端提交和全局技能副本一致。
