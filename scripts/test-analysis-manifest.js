const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const { buildManifest } = require('./build-analysis-manifest.js');

function fixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'doushu-manifest-'));
  const paths = Object.fromEntries(['chart', 'flow', 'cases', 'report'].map((name) => [name, path.join(root, `${name}.${name === 'report' ? 'md' : 'json'}`)]));
  fs.writeFileSync(paths.chart, JSON.stringify({ziwei:{gongs:Array.from({length:12}, () => ({})),brightnessMetadata:{source:'iztro'}}}));
  fs.writeFileSync(paths.flow, JSON.stringify({metadata:{status:'generated'},years:[{year:2026}]}));
  fs.writeFileSync(paths.cases, '[]');
  const health = [
    '### 健康与恢复',
    '#### 健康 - 专业推论', '疾厄宫 命宫 福德宫',
    '#### 健康 - 主要可能表现',
    '#### 健康 - 替代解释与成立条件',
    '#### 健康 - 现实验证',
    '#### 健康 - 行动建议',
    '#### 健康 - 医学边界',
  ].join('\n');
  fs.writeFileSync(paths.report, `${health}\n${'完整分析。'.repeat(900)}`);
  return {root, paths};
}

test('builds a hash-bound manifest only for a complete health module', () => {
  const {paths} = fixture();
  const manifest = buildManifest({
    chartKey:'fixture-chart', ...paths,
    nihaixiaStatus:'not_used', nihaixiaReason:'主框架无关键歧义',
    healthEvidence:['疾厄宫','命宫','福德宫'], voiceReviewed:true,
  });
  assert.equal(manifest.resources.verification_checklist, 'passed');
  assert.equal(manifest.health.evidence_categories.length, 3);
  assert.match(manifest.hashes.report_sha256, /^[a-f0-9]{64}$/);
});

test('rejects a report missing a required health module', () => {
  const {paths} = fixture();
  fs.writeFileSync(paths.report, '### 健康与恢复\n' + '内容'.repeat(2500));
  assert.throws(() => buildManifest({
    chartKey:'fixture-chart', ...paths,
    nihaixiaStatus:'read', nihaixiaReason:'多流派分析',
    healthEvidence:['疾厄宫','命宫','福德宫'], voiceReviewed:true,
  }), /health module/i);
});
