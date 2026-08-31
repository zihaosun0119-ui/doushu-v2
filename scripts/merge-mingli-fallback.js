#!/usr/bin/env node

/**
 * 将 mingli-mcp 的结果规范化，并用本地 iztro 只补齐缺失字段。
 *
 * 用法：
 *   node merge-mingli-fallback.js --birth=birth.json --target=2026-08-25 \
 *     --mingli=mingli.json --output=dynamic-chart.json
 *
 * birth.json 最小结构：
 * { "date": "2000-01-01", "timeIndex": 0, "gender": "女", "fixLeap": true }
 */

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..', '..', '..');
const IZTRO = path.join(ROOT, 'tmp', 'iztro', 'package', 'lib', 'index.js');
const { astro } = require(IZTRO);

const arg = (name, fallback = undefined) => {
  const prefix = `--${name}=`;
  const item = process.argv.find((value) => value.startsWith(prefix));
  return item ? item.slice(prefix.length) : fallback;
};

const readJson = (file, fallback = null) => {
  if (!file) return fallback;
  return JSON.parse(fs.readFileSync(path.resolve(file), 'utf8'));
};

const first = (...values) => values.find((value) => value !== undefined && value !== null);
const array = (value) => Array.isArray(value) ? value : [];
const starName = (star) => typeof star === 'string' ? star : star?.name;

function unwrapMingli(payload) {
  return first(payload?.result, payload?.data, payload?.chart, payload) || {};
}

function getPalaces(payload) {
  return array(first(payload?.palaces, payload?.gongs, payload?.gong_pan, payload?.ziwei?.gongs));
}

function getLayer(payload, names) {
  for (const name of names) {
    const value = payload?.[name] || payload?.layers?.[name] || payload?.fortune?.[name];
    if (value && typeof value === 'object') return value;
  }
  return {};
}

function normalizeStars(palace) {
  return array(first(palace?.stars, palace?.allStars, palace?.mainStars, palace?.majorStars))
    .map(starName).filter(Boolean);
}

function transformations(heavenlyStem, horoscope) {
  const mutagen = array(horoscope?.mutagen);
  const labels = ['禄', '权', '科', '忌'];
  return labels.map((hua, index) => ({
    hua,
    star: starName(mutagen[index]) || null,
  }));
}

function buildFallback(birth, targetDate) {
  const chart = astro.bySolar(
    birth.date,
    Number(birth.timeIndex ?? birth.time_index),
    birth.gender,
    birth.fixLeap ?? birth.fix_leap ?? true,
    'zh-CN',
  );
  const horoscope = chart.horoscope(new Date(targetDate));
  const sourcePalaces = chart.palaces.map((palace) => palace.toJSON());
  const layer = (name, data) => ({
    name,
    index: data.index,
    heavenlyStem: data.heavenlyStem,
    earthlyBranch: data.earthlyBranch,
    monthStem: name === '流月' ? data.heavenlyStem : undefined,
    monthBranch: name === '流月' ? data.earthlyBranch : undefined,
    palaceNames: array(data.palaceNames),
    palaces: array(data.palaceNames).map((palaceName, index) => ({
      index,
      name: palaceName,
      heavenlyStem: data.heavenlyStem,
      earthlyBranch: data.earthlyBranch,
      stars: array(data.stars?.[index]).map(starName).filter(Boolean),
    })),
    mutagen: array(data.mutagen),
    fourTransformations: transformations(data.heavenlyStem, data),
    stars: array(data.stars).map((items) => array(items).map(starName)),
  });
  const layers = {
    natal: {
      name: '本命',
      palaces: sourcePalaces.map((palace) => ({
        index: palace.index,
        name: palace.name,
        heavenlyStem: palace.heavenlyStem,
        earthlyBranch: palace.earthlyBranch,
        stars: [
          ...array(palace.majorStars),
          ...array(palace.minorStars),
          ...array(palace.adjectiveStars),
        ].map(starName).filter(Boolean),
        majorStars: array(palace.majorStars).map(starName).filter(Boolean),
        minorStars: [...array(palace.minorStars), ...array(palace.adjectiveStars)].map(starName).filter(Boolean),
        transformations: array([
          ...array(palace.majorStars),
          ...array(palace.minorStars),
        ]).filter((star) => star.mutagen).map((star) => ({ star: starName(star), hua: `化${star.mutagen}` })),
        decadal: palace.decadal || null,
        ages: palace.ages || [],
      })),
    },
    decadal: layer('大限', horoscope.decadal),
    yearly: layer('流年', horoscope.yearly),
    monthly: layer('流月', horoscope.monthly),
  };

  layers.monthly.lunarDate = horoscope.lunarDate;
  layers.monthly.solarDate = horoscope.solarDate;
  layers.yearly.yearlyDecStar = horoscope.yearly.yearlyDecStar;

  // 以物理宫位 index 对齐四层 palaceNames，形成可直接供分析层使用的叠宫表。
  const overlays = layers.natal.palaces.map((palace) => ({
    index: palace.index,
    natalPalace: palace.name,
    decadalPalace: layers.decadal.palaceNames[palace.index] || null,
    yearlyPalace: layers.yearly.palaceNames[palace.index] || null,
    monthlyPalace: layers.monthly.palaceNames[palace.index] || null,
  }));

  return {
    source: 'iztro-fallback',
    generatedAt: new Date().toISOString(),
    birth,
    targetDate,
    layers,
    overlays,
    chart: chart.toJSON(),
  };
}

function isComplete(payload) {
  const layers = payload?.layers || {};
  const monthly = layers.monthly || {};
  const overlays = array(payload?.overlays);
  return Boolean(
    array(layers.natal?.palaces).length === 12 &&
    array(monthly.palaceNames).length === 12 &&
    array(monthly.fourTransformations).length === 4 &&
    overlays.length === 12 &&
    overlays.every((item) => item.natalPalace && item.yearlyPalace && item.monthlyPalace),
  );
}

function monthlyStatus(payload, fallbackUsed = false) {
  const layers = payload?.layers || {};
  const monthly = layers.monthly || {};
  const overlays = array(payload?.overlays);
  const hasFlowPalace = Boolean(
    monthly.palaceNames && array(monthly.palaceNames).length === 12,
  );
  const hasPalaces = array(monthly.palaces).length === 12;
  const hasMonthlySihua = array(monthly.fourTransformations).length === 4 ||
    (monthly.sihua && ['禄', '权', '科', '忌'].every((key) => monthly.sihua[key] !== undefined));
  const hasOverlays = overlays.length === 12 && overlays.every((item) =>
    item.natalPalace && item.monthlyPalace,
  );
  const complete = hasFlowPalace && hasPalaces && hasMonthlySihua && hasOverlays;
  return {
    status: complete ? (fallbackUsed ? 'fallback' : 'complete') : 'partial',
    hasJieqiGanZhi: Boolean(monthly.monthStem || monthly.monthBranch || monthly.lunarDate),
    hasFlowPalace,
    hasMonthlySihua,
    hasOverlays,
    missing: [
      ['flowPalace', hasFlowPalace],
      ['palaces', hasPalaces],
      ['sihua', hasMonthlySihua],
      ['overlays', hasOverlays],
    ].filter(([, present]) => !present).map(([name]) => name),
  };
}

function mergeMissing(external, fallback) {
  if (!external || typeof external !== 'object') return fallback;
  const output = structuredClone(external);
  const fill = (target, source) => {
    if (!target || typeof target !== 'object') return structuredClone(source);
    for (const [key, value] of Object.entries(source || {})) {
      const current = target[key];
      const missing = current === undefined || current === null ||
        (Array.isArray(current) && current.length === 0);
      if (missing) target[key] = structuredClone(value);
      else if (current && value && !Array.isArray(current) && !Array.isArray(value) &&
        typeof current === 'object' && typeof value === 'object') {
        fill(current, value);
      }
    }
    return target;
  };
  output.layers = output.layers || {};
  for (const key of ['natal', 'decadal', 'yearly', 'monthly']) {
    output.layers[key] = fill(output.layers[key], fallback.layers[key]);
  }
  output.overlays = fill(output.overlays, fallback.overlays);
  const complete = isComplete(external);
  output.fallback = {
    used: !complete,
    engine: 'iztro',
    reason: complete ? null : 'mingli-mcp 返回字段不完整，按字段补齐',
  };
  output.externalRaw = external;
  return output;
}

const birthFile = arg('birth');
const targetDate = arg('target', new Date().toISOString().slice(0, 10));
const mingliFile = arg('mingli');
const outputFile = arg('output');
if (!birthFile) throw new Error('缺少 --birth=birth.json');

const birth = readJson(birthFile);
const externalPayload = mingliFile ? unwrapMingli(readJson(mingliFile)) : null;
const fallback = buildFallback(birth, targetDate);
const result = mergeMissing(externalPayload, fallback);
if (!externalPayload) {
  result.fallback = {
    used: true,
    engine: 'iztro',
    reason: '未提供 mingli-mcp 结果，使用本地排盘作为完整兜底',
  };
}
result.completeness = {
  beforeFallback: isComplete(externalPayload),
  afterFallback: isComplete(result),
};
result.monthlyDataStatus = monthlyStatus(result, result.fallback?.used === true);

const text = `${JSON.stringify(result, null, 2)}\n`;
if (outputFile) fs.writeFileSync(path.resolve(outputFile), text, 'utf8');
else process.stdout.write(text);
