#!/usr/bin/env node
// 为 doushu 支持的结构化命盘增加流年、节气流月和实验性四柱命卦数据。
// 同时兼容旧版 bazi-ziwei 结构与 iztro 风格 palaces 结构。

const fs = require('fs');

const args = Object.fromEntries(process.argv.slice(2).map((value) => {
  const index = value.indexOf('=');
  return index > 0 ? [value.slice(2, index), value.slice(index + 1)] : [value.slice(2), 'true'];
}));

if (!args.input) {
  console.error('Usage: node enrich-flow.js --input=chart.json --startYear=2026 --endYear=2030 [--output=flow.json]');
  process.exit(1);
}

const source = JSON.parse(fs.readFileSync(args.input, 'utf8'));
const iztro = source.chart || source;
const legacy = source.ziwei;
const palaces = legacy?.gongs || iztro?.palaces;

if (!Array.isArray(palaces) || palaces.length !== 12) {
  throw new Error('命盘结构中未找到完整的十二宫数据');
}

const ganList = ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸'];
const zhiList = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];
const sihua = {
  甲: {禄:'廉贞',权:'破军',科:'武曲',忌:'太阳'},
  乙: {禄:'天机',权:'天梁',科:'紫微',忌:'太阴'},
  丙: {禄:'天同',权:'天机',科:'文昌',忌:'廉贞'},
  丁: {禄:'太阴',权:'天同',科:'天机',忌:'巨门'},
  戊: {禄:'贪狼',权:'太阴',科:'右弼',忌:'天机'},
  己: {禄:'武曲',权:'贪狼',科:'天梁',忌:'文曲'},
  庚: {禄:'太阳',权:'武曲',科:'太阴',忌:'天同'},
  辛: {禄:'巨门',权:'太阳',科:'文曲',忌:'文昌'},
  壬: {禄:'天梁',权:'紫微',科:'左辅',忌:'武曲'},
  癸: {禄:'破军',权:'巨门',科:'太阴',忌:'贪狼'},
};
const stemNumbers = {甲:6,乙:2,丙:8,丁:7,戊:1,己:9,庚:3,辛:4,壬:6,癸:2};
const branchNumberCandidates = {
  子:[1,6], 丑:[5,10], 寅:[3,8], 卯:[3,8], 辰:[5,10], 巳:[2,7],
  午:[2,7], 未:[5,10], 申:[4,9], 酉:[4,9], 戌:[5,10], 亥:[1,6],
};
const monthStemStart = {甲:'丙',己:'丙',乙:'戊',庚:'戊',丙:'庚',辛:'庚',丁:'壬',壬:'壬',戊:'甲',癸:'甲'};

function modulo(value, base) {
  return ((value % base) + base) % base;
}

function yearGanZhi(year) {
  return {gan: ganList[modulo(year - 4, 10)], zhi: zhiList[modulo(year - 4, 12)]};
}

function palaceName(palace) {
  return palace.gong || palace.name || null;
}

function palaceBranch(palace) {
  return palace.dizhi || palace.earthlyBranch || null;
}

function starNames(palace) {
  const stars = [
    ...(palace.mainStars || []),
    ...(palace.auxStars || []),
    ...(palace.majorStars || []),
    ...(palace.minorStars || []),
  ];
  return stars.map((star) => typeof star === 'string' ? star : star?.name).filter(Boolean);
}

function targetPalace(star) {
  const palace = palaces.find((item) => starNames(item).includes(star));
  return palace ? {gong: palaceName(palace), dizhi: palaceBranch(palace), star} : null;
}

function lunarBirthYear() {
  return Number(
    legacy?.lunarDate?.year
    || source.bazi?.birthInfo?.year
    || iztro?.rawDates?.lunarDate?.lunarYear
    || String(source.metadata?.birthDate || iztro?.solarDate || '').slice(0, 4)
  );
}

function flowAges(palace) {
  return palace.liuNian || palace.ages || [];
}

function flowPalace(year) {
  const birthYear = lunarBirthYear();
  if (!Number.isFinite(birthYear)) {
    return {xuSui: null, gong: null, dizhi: null, status: 'missing_birth_year'};
  }
  const xuSui = year - birthYear + 1;
  const palace = palaces.find((item) => flowAges(item).map(Number).includes(xuSui));
  return {
    xuSui,
    gong: palace ? palaceName(palace) : null,
    dizhi: palace ? palaceBranch(palace) : null,
    status: palace ? 'generated' : 'outside_chart_age_range',
  };
}

function monthlyPillars(year) {
  const annual = yearGanZhi(year);
  const firstStemIndex = ganList.indexOf(monthStemStart[annual.gan]);
  return Array.from({length: 12}, (_, index) => ({
    monthBranch: zhiList[(2 + index) % 12],
    monthStem: ganList[(firstStemIndex + index) % 10],
    monthOrder: index + 1,
    basis: '节气月：寅月起于立春，之后每月按节气切换',
  }));
}

function normalizedPillars() {
  const oldPillars = legacy?.siZhu || source.bazi?.siZhu;
  if (oldPillars) return oldPillars;
  const chineseDate = iztro?.rawDates?.chineseDate;
  if (!chineseDate) return null;
  const mapping = {year:'yearly', month:'monthly', day:'daily', hour:'hourly'};
  return Object.fromEntries(Object.entries(mapping).map(([key, sourceKey]) => {
    const value = chineseDate[sourceKey];
    return [key, Array.isArray(value) ? {gan:value[0], zhi:value[1]} : value];
  }));
}

function fourPillarGua() {
  const pillars = normalizedPillars();
  if (!pillars || ['year','month','day','hour'].some((key) => !pillars[key]?.gan || !pillars[key]?.zhi)) {
    return {
      status: 'unavailable',
      method: '四柱命卦实验模块',
      note: '结构化命盘缺少完整四柱，未计算。',
    };
  }
  const rows = ['year','month','day','hour'].map((key) => ({
    pillar: key,
    gan: pillars[key].gan,
    zhi: pillars[key].zhi,
    ganNumber: stemNumbers[pillars[key].gan],
    zhiNumberCandidates: branchNumberCandidates[pillars[key].zhi],
  }));
  return {
    status: 'incomplete',
    method: '公开《天纪·四柱命卦》文字整理的干支取数摘要；不同整理本可能存在差异',
    pillars: rows,
    note: '地支保留候选数组；未确认传本与阴阳取数规则前，不计算最终卦名。',
  };
}

const startYear = Number(args.startYear || new Date().getFullYear());
const endYear = Number(args.endYear || startYear + 7);
if (!Number.isInteger(startYear) || !Number.isInteger(endYear) || endYear < startYear) {
  throw new Error('startYear 和 endYear 必须是有效年份，且 endYear 不小于 startYear');
}

const years = [];
for (let year = startYear; year <= endYear; year += 1) {
  const ganZhi = yearGanZhi(year);
  const annualSihua = Object.fromEntries(
    Object.entries(sihua[ganZhi.gan]).map(([hua, star]) => [hua, targetPalace(star)])
  );
  years.push({
    year,
    ganZhi,
    flowPalace: flowPalace(year),
    annualSihua,
    jieqiMonths: monthlyPillars(year),
  });
}

const unresolvedYears = years.filter((item) => item.flowPalace.status !== 'generated').map((item) => item.year);
const result = {
  metadata: {
    method: 'doushu flow extension v0.2',
    sourceSchema: legacy ? 'bazi-ziwei-legacy' : 'iztro-palaces',
    status: unresolvedYears.length ? 'partial' : 'generated',
    unresolvedYears,
    annualSihua: '按年干四化表定位至本命星曜所在宫',
    flowPalace: '按命盘虚岁数组定位',
    monthly: '生成节气月干支，不冒充紫微流月飞化',
    fourPillarGua: 'experimental；确认取数流派后方可用于结论',
  },
  years,
  fourPillarGua: fourPillarGua(),
};

const output = `${JSON.stringify(result, null, 2)}\n`;
if (args.output) fs.writeFileSync(args.output, output, 'utf8');
else process.stdout.write(output);
