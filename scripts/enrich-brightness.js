#!/usr/bin/env node
/**
 * 为 bazi-ziwei 命盘 JSON 补充星曜亮度。
 * 数据口径：iztro 2.6.0 默认 brightness 表（MIT）。
 * 宫支顺序：寅、卯、辰、巳、午、未、申、酉、戌、亥、子、丑。
 * 亮度是流派表，不是独立吉凶结论。
 */
const fs = require('fs');

const args = Object.fromEntries(process.argv.slice(2).map((x) => {
  const [k, ...rest] = x.replace(/^--/, '').split('=');
  return [k, rest.join('=')];
}));
if (!args.input || !args.output) {
  console.error('Usage: node enrich-brightness.js --input=chart.json --output=chart-brightness.json');
  process.exit(1);
}

const BRANCHES = ['寅','卯','辰','巳','午','未','申','酉','戌','亥','子','丑'];
const T = {
  紫微:['旺','旺','得','旺','庙','庙','旺','旺','得','旺','平','庙'],
  天机:['得','旺','利','平','庙','陷','得','旺','利','平','庙','陷'],
  太阳:['旺','庙','旺','旺','旺','得','得','陷','不','陷','陷','不'],
  武曲:['得','利','庙','平','旺','庙','得','利','庙','平','旺','庙'],
  天同:['利','平','平','庙','陷','不','旺','平','平','庙','旺','不'],
  廉贞:['庙','平','利','陷','平','利','庙','平','利','陷','平','利'],
  天府:['庙','得','庙','得','旺','庙','得','旺','庙','得','庙','庙'],
  太阴:['旺','陷','陷','陷','不','不','利','不','旺','庙','庙','庙'],
  贪狼:['平','利','庙','陷','旺','庙','平','利','庙','陷','旺','庙'],
  巨门:['庙','庙','陷','旺','旺','不','庙','庙','陷','旺','旺','不'],
  天相:['庙','陷','得','得','庙','得','庙','陷','得','得','庙','庙'],
  天梁:['庙','庙','庙','陷','庙','旺','陷','得','庙','陷','庙','旺'],
  七杀:['庙','旺','庙','平','旺','庙','庙','庙','庙','平','旺','庙'],
  破军:['得','陷','旺','平','庙','旺','得','陷','旺','平','庙','旺'],
  文昌:['陷','利','得','庙','陷','利','得','庙','陷','利','得','庙'],
  文曲:['平','旺','得','庙','陷','旺','得','庙','陷','旺','得','庙'],
  火星:['庙','利','陷','得','庙','利','陷','得','庙','利','陷','得'],
  铃星:['庙','利','陷','得','庙','利','陷','得','庙','利','陷','得'],
  擎羊:['','陷','庙','','陷','庙','','陷','庙','','陷','庙'],
  陀罗:['陷','','庙','陷','','庙','陷','','庙','陷','','庙'],
};

const chart = JSON.parse(fs.readFileSync(args.input, 'utf8'));
for (const gong of chart?.ziwei?.gongs || []) {
  const idx = BRANCHES.indexOf(gong.dizhi);
  const detail = (name) => ({ name, brightness: idx >= 0 && T[name] ? (T[name][idx] || null) : null });
  gong.mainStarDetails = (gong.mainStars || []).map(detail);
  gong.auxStarDetails = (gong.auxStars || []).map(detail);
}
chart.ziwei.brightnessMetadata = {
  source: 'iztro 2.6.0 default brightness table',
  license: 'MIT',
  categories: ['庙','旺','得','利','平','陷','不'],
  note: '亮度流派存在差异；仅作组合分析的一层，不可单独断吉凶。',
};
fs.writeFileSync(args.output, JSON.stringify(chart, null, 2), 'utf8');
console.log(args.output);
