# 项目架构

## 分层

```text
调用方 / Codex
       │
       ▼
SKILL.md + agents/openai.yaml       ← 发现、入口、默认提示
       │
       ▼
modules/                            ← 阶段编排与门禁
       │
       ├── references/               ← 方法、证据、专项规则、输出契约
       │       ├── core              ← 通用分析与执行契约
       │       ├── domain            ← 事业、关系、健康等专项规则
       │       ├── evidence           ← 来源、案例、模式证据
       │       └── output             ← 用户呈现与报告规范
       │
       ▼
scripts/                             ← 可重复生成、路由、校验和测试
       │
       ▼
用户报告 / execution-manifest.json  ← 可核验交付物
```

仓库保留 `references/` 的平铺兼容路径，因为路由 JSON、门禁脚本和外部调用方都以这些路径作为稳定接口；分类通过文件命名、索引和文档导航实现，不通过一次性移动全部参考文件制造兼容风险。

## 依赖方向

- `SKILL.md` 可以读取 `modules/`、`references/` 和 `scripts/`。
- `modules/` 可以读取 `references/`，并调用 `scripts/`。
- `scripts/` 只处理数据、路由和校验，不反向修改规则正文。
- `references/` 不依赖个人案例或生成报告。
- `cases/`、报告和研究原件属于本地数据，默认不进入公开仓库。

## 运行时与公开仓库的边界

根目录本身就是可安装的 skill 包，不能把 `SKILL.md` 移到 `skill/`、`src/` 或其他二级目录。公开仓库可包含文档与 CI，但全局安装时复制整个仓库即可得到同一份技能包。

## 变更检查表

改动路由或目录时，按下面顺序检查：

1. 更新 `modules/module-registry.json` 或 `modules/knowledge-route-registry.json`。
2. 搜索旧路径，更新脚本、测试和文档链接。
3. 运行技能合同、模块合同、知识路由和门禁测试。
4. 同步到 `~/.codex/skills/szh-doushu`。
5. 提交后确认 GitHub Actions 与远端主分支均通过。
