#!/usr/bin/env node

/**
 * 校验年度流月数据合同，并输出可供报告路由读取的完整度状态。
 *
 * 用法：
 *   node validate-monthly-flow.js --flow=flow.json --output=flow.validated.json
 *
 * 说明：jieqiMonths 只代表节气月干支；只有同时具备流月命宫、十二宫、
 * 月干四化和叠宫，才会标记为 complete。
 */

const fs = require('fs');
const path = require('path');

const arg = (name, fallback = undefined) => {
  const prefix = `--${name}=`;
  const item = process.argv.find((value) => value.startsWith(prefix));
  return item ? item.slice(prefix.length) : fallback;
};

const inputFile = arg('flow');
if (!inputFile) throw new Error('缺少 --flow=flow.json');

const inputPath = path.resolve(inputFile);
const outputPath = arg('output');
const payload = JSON.parse(fs.readFileSync(inputPath, 'utf8'));

const array = (value) => Array.isArray(value) ? value : [];
const first = (...values) => values.find((value) => value !== undefined && value !== null);
const hasFour = (value) => Array.isArray(value)
  ? value.length === 4
  : value && typeof value === 'object'
    ? ['禄', '权', '科', '忌'].every((key) => value[key] !== undefined)
    : false;

function yearsOf(data) {
  if (Array.isArray(data)) return data;
  return array(first(data?.years, data?.flow, data?.annual, data?.items));
}

function monthsOf(year) {
  return array(first(year?.monthly, year?.months, year?.flowMonths, year?.jieqiMonths));
}

function checkYear(year) {
  const months = monthsOf(year);
  const hasJieqiGanZhi = months.length === 12 && months.every((month) =>
    Boolean(first(month?.monthStem, month?.stem)) && Boolean(first(month?.monthBranch, month?.branch)));

  const hasFlowPalace = months.length === 12 && months.every((month) =>
    Boolean(first(month?.flowPalace, month?.palace, month?.palaceName)));

  const hasPalaces = months.length === 12 && months.every((month) =>
    array(first(month?.palaces, month?.gongs, month?.gongPan)).length === 12);

  const hasMonthlySihua = months.length === 12 && months.every((month) =>
    hasFour(first(month?.sihua, month?.monthlySihua, month?.fourTransformations)));

  const hasOverlays = months.length === 12 && months.every((month) =>
    array(first(month?.overlays, month?.overlay)).length === 12);

  const complete = hasJieqiGanZhi && hasFlowPalace && hasPalaces && hasMonthlySihua && hasOverlays;
  const fallbackUsed = Boolean(year?.fallback?.used || year?.monthlyFallback?.used);
  const status = complete ? (fallbackUsed ? 'fallback' : 'complete')
    : hasJieqiGanZhi ? (fallbackUsed ? 'fallback' : 'partial') : 'unavailable';

  return {
    year: year?.year ?? null,
    status,
    source: year?.source || (year?.jieqiMonths ? 'jieqi-months' : 'unknown'),
    hasJieqiGanZhi,
    hasFlowPalace,
    hasPalaces,
    hasMonthlySihua,
    hasOverlays,
    missing: [
      ['flowPalace', hasFlowPalace],
      ['palaces', hasPalaces],
      ['sihua', hasMonthlySihua],
      ['overlays', hasOverlays],
    ].filter(([, present]) => !present).map(([name]) => name),
    monthCount: months.length,
  };
}

const yearStatuses = yearsOf(payload).map(checkYear);
const statuses = new Set(yearStatuses.map((item) => item.status));
const overall = statuses.has('unavailable') ? 'unavailable'
  : statuses.has('partial') ? 'partial'
    : statuses.has('fallback') ? 'fallback'
      : statuses.size === 0 ? 'unavailable' : 'complete';

const result = {
  ...payload,
  monthlyDataStatus: {
    status: overall,
    hasJieqiGanZhi: yearStatuses.some((item) => item.hasJieqiGanZhi),
    hasFlowPalace: yearStatuses.every((item) => item.hasFlowPalace),
    hasMonthlySihua: yearStatuses.every((item) => item.hasMonthlySihua),
    hasOverlays: yearStatuses.every((item) => item.hasOverlays),
    years: yearStatuses,
    checkedAt: new Date().toISOString(),
    rule: '流月完整度合同 v1：节气月干支不等同于完整紫微流月',
  },
};

const text = `${JSON.stringify(result, null, 2)}\n`;
if (outputPath) fs.writeFileSync(path.resolve(outputPath), text, 'utf8');
else process.stdout.write(text);
