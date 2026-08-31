# mingli-mcp 接入与兜底规则

## 目标

优先使用 `mingli-mcp` 的结构化结果；只要某个动态层或字段缺失，就用项目内置 `iztro` 补齐。外部结果已有的字段不覆盖。

## 调用顺序

1. 调用 `get_ziwei_chart` 获取本命十二宫、星曜、四化和大限基础数据。
2. 调用 `get_ziwei_fortune`，传入同一出生资料与 `query_date`，获取目标流年、流月数据。
3. 检查以下必需字段：
   - 本命宫位数组长度为 12；
   - 流月宫位映射长度为 12；
   - 月干四化包含禄、权、科、忌四项；
   - 本命、流年、流月叠宫关系均可定位到 12 个物理宫位；
   - 闰月、真太阳时和出生时辰规则有明确标记。
4. 对年度流月文件运行 `scripts/validate-monthly-flow.js`，区分 `complete`、`partial`、`fallback` 和 `unavailable`。
5. 缺失时运行 `scripts/merge-mingli-fallback.js`，使用本地 `iztro` 仅补空字段。

## 兜底输出

兜底后统一输出：

- `layers.natal.palaces`：本命十二宫；
- `layers.decadal`：大限；
- `layers.yearly`：流年命宫、流年四化和流年星曜；
- `layers.monthly`：流月命宫、月干、月支、月干四化和流月星曜；
- `overlays[]`：每个物理宫位的本命宫、 大限宫、流年宫、流月宫对应关系；
- `fallback.used`、`fallback.engine`、`fallback.reason`：是否发生补算及原因；
- `completeness.beforeFallback/afterFallback`：补算前后完整性。
- `monthlyDataStatus`：年度流月数据完整度、缺失字段和逐年校验结果。

## 边界

补算不是无依据生成。只允许使用出生资料、目标日期和项目内置排盘规则推导；若出生日期、时辰、性别或历法缺失，必须停止并标记无法补算。闰月规则和真太阳时规则不明确时，不输出确定的具体月份结论，先标记待核验。

注意：`jieqiMonths` 只证明节气月干支已经生成，不证明流月命宫、十二宫、月干四化和叠宫已经生成。
