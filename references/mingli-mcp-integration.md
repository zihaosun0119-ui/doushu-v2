# 排盘数据来源

不使用外部排盘结果与本地结果拼接。紫微、八字、流年和流月统一按 `data-method-contract-v1.md` 由本地 `iztro@2.6.0` 生成。

需要动态层时，按同一份出生资料重新生成：

- 流年：`horoscope(目标年)`；
- 流月：`monthlyList(目标年, true)`；
- 八字：`rawDates.chineseDate`。

生成后记录输入、产物、算法版本、生成时间和 SHA-256。资料不完整时停止，不以外部结果补字段。
