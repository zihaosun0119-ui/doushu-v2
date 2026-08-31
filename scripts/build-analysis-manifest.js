#!/usr/bin/env node
const fs = require('node:fs');
const crypto = require('node:crypto');
const path = require('node:path');

const HEALTH_MODULES = [
  '健康 - 专业推论',
  '健康 - 主要可能表现',
  '健康 - 替代解释与成立条件',
  '健康 - 现实验证',
  '健康 - 行动建议',
  '健康 - 医学边界',
];

function readFile(file, label) {
  if (!file || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
    throw new Error(`${label} file missing: ${file || '(empty)'}`);
  }
  return fs.readFileSync(file);
}

function jsonFile(file, label) {
  return JSON.parse(readFile(file, label).toString('utf8'));
}

function sha256(file) {
  return crypto.createHash('sha256').update(readFile(file, 'hash input')).digest('hex');
}

function buildManifest(options) {
  const chartKey = String(options.chartKey || '').trim();
  if (!chartKey) throw new Error('chartKey is required');

  const chart = jsonFile(options.chart, 'chart');
  if (!Array.isArray(chart?.ziwei?.gongs) || chart.ziwei.gongs.length !== 12) {
    throw new Error('chart must contain 12 ziwei gongs');
  }
  if (!chart.ziwei.brightnessMetadata?.source) {
    throw new Error('chart missing brightness metadata');
  }

  const flow = jsonFile(options.flow, 'flow');
  if (!Array.isArray(flow?.years) || flow.years.length < 1 || !['generated', 'partial'].includes(flow?.metadata?.status)) {
    throw new Error('flow file has no usable annual data');
  }
  jsonFile(options.cases, 'cases');

  const report = readFile(options.report, 'report').toString('utf8');
  if (report.replace(/\s/g, '').length < 4000) {
    throw new Error('report is too short for a complete life report');
  }
  const missingHealth = HEALTH_MODULES.filter((name) => !report.includes(name));
  if (missingHealth.length) {
    throw new Error(`health module incomplete: ${missingHealth.join(', ')}`);
  }

  const evidence = [...new Set((options.healthEvidence || []).map(String).map((value) => value.trim()).filter(Boolean))];
  if (evidence.length < 3) throw new Error('health evidence requires at least three categories');
  const absentEvidence = evidence.filter((value) => !report.includes(value));
  if (absentEvidence.length) throw new Error(`health evidence absent from report: ${absentEvidence.join(', ')}`);
  if (options.voiceReviewed !== true) throw new Error('restrained-professional-voice review is required');

  const nihaixiaStatus = options.nihaixiaStatus;
  if (!['read', 'not_used'].includes(nihaixiaStatus)) throw new Error('nihaixiaStatus must be read or not_used');
  const nihaixiaReason = String(options.nihaixiaReason || '').trim();
  if (!nihaixiaReason) throw new Error('nihaixiaReason is required');

  return {
    schema_version: 1,
    chart_key: chartKey,
    files: {
      chart: path.resolve(options.chart),
      flow: path.resolve(options.flow),
      cases: path.resolve(options.cases),
      report: path.resolve(options.report),
    },
    hashes: {
      chart_sha256: sha256(options.chart),
      flow_sha256: sha256(options.flow),
      cases_sha256: sha256(options.cases),
      report_sha256: sha256(options.report),
    },
    resources: {
      analysis_rules: 'read',
      brightness_source: 'read',
      brightness_enrichment: 'executed',
      flow_extension: 'executed',
      case_search: 'executed',
      nihaixia: {status: nihaixiaStatus, reason: nihaixiaReason},
      voice_review: 'executed',
      verification_checklist: 'passed',
    },
    health: {
      evidence_categories: evidence,
      modules: HEALTH_MODULES,
      medical_boundary: 'passed',
    },
    created_at: new Date().toISOString(),
  };
}

function parseArgs(argv) {
  return Object.fromEntries(argv.map((value) => {
    const index = value.indexOf('=');
    return index > 0 ? [value.slice(2, index), value.slice(index + 1)] : [value.slice(2), 'true'];
  }));
}

if (require.main === module) {
  try {
    const args = parseArgs(process.argv.slice(2));
    if (!args.output) throw new Error('output is required');
    const manifest = buildManifest({
      chartKey: args['chart-key'],
      chart: args.chart,
      flow: args.flow,
      cases: args.cases,
      report: args.report,
      nihaixiaStatus: args['nihaixia-status'],
      nihaixiaReason: args['nihaixia-reason'],
      healthEvidence: String(args['health-evidence'] || '').split(','),
      voiceReviewed: args['voice-reviewed'] === 'true',
    });
    fs.writeFileSync(args.output, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
    process.stdout.write(`${path.resolve(args.output)}\n`);
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}

module.exports = {buildManifest, HEALTH_MODULES};
