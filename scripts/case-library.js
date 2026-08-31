#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const defaultLibrary = path.resolve(__dirname, '..', 'cases', 'case-library.json');

function arg(name, fallback = undefined) {
  const prefix = `--${name}=`;
  const item = process.argv.slice(2).find((value) => value.startsWith(prefix));
  return item ? item.slice(prefix.length) : fallback;
}

function usage() {
  console.log(`用法：
  node case-library.js add --data='{"chart_key":"...","domain":"career","event_type":"...","user_report":"...","status":"user_confirmed","source":"user"}'
  node case-library.js search --chart_key=... --query=... --domain=...
  node case-library.js list --chart_key=...
  node case-library.js stats --chart_key=...
  node case-library.js update --id=... --data='{"status":"user_confirmed","verification_notes":"..."}'
  node case-library.js remove --id=...
  `);
}

function load(file) {
  if (!fs.existsSync(file)) return { schema_version: 1, updated_at: null, cases: [] };
  const value = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (!Array.isArray(value.cases)) value.cases = [];
  return value;
}

function save(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  value.updated_at = new Date().toISOString();
  const temp = `${file}.tmp`;
  fs.writeFileSync(temp, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
  fs.renameSync(temp, file);
}

function required(record, fields) {
  const missing = fields.filter((field) => !record[field]);
  if (missing.length) throw new Error(`缺少字段：${missing.join(', ')}`);
}

function validateEnums(record) {
  if (record.status && !['user_confirmed', 'partial', 'unverified', 'disputed'].includes(record.status)) {
    throw new Error('status 必须是 user_confirmed、partial、unverified 或 disputed');
  }
  if (record.source && !['user', 'assistant_inference', 'external'].includes(record.source)) {
    throw new Error('source 必须是 user、assistant_inference 或 external');
  }
}

function matches(record, filters) {
  if (filters.chart_key && record.chart_key !== filters.chart_key) return false;
  if (filters.domain && record.domain !== filters.domain) return false;
  if (filters.status && record.status !== filters.status) return false;
  if (filters.query) {
    const haystack = JSON.stringify(record).toLowerCase();
    if (!haystack.includes(filters.query.toLowerCase())) return false;
  }
  return true;
}

const command = process.argv[2];
const file = path.resolve(arg('library', defaultLibrary));
const library = load(file);

try {
  if (!command || command === 'help') {
    usage();
    process.exit(0);
  }

  if (command === 'add') {
    const data = arg('data');
    if (!data) throw new Error('add 必须提供 --data JSON');
    const record = JSON.parse(data);
    required(record, ['chart_key', 'domain', 'event_type', 'user_report', 'status', 'source']);
    validateEnums(record);
    const now = new Date().toISOString();
    const item = {
      id: record.id || `case-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      ...record,
      created_at: record.created_at || now,
      updated_at: now,
    };
    library.cases.push(item);
    save(file, library);
    console.log(JSON.stringify(item, null, 2));
    process.exit(0);
  }

  if (command === 'search' || command === 'list') {
    const filters = {
      chart_key: arg('chart_key'),
      domain: arg('domain'),
      status: arg('status'),
      query: command === 'list' ? undefined : arg('query'),
    };
    const results = library.cases.filter((record) => matches(record, filters));
    console.log(JSON.stringify(results, null, 2));
    process.exit(0);
  }

  if (command === 'stats') {
    const chartKey = arg('chart_key');
    const records = library.cases.filter((record) => !chartKey || record.chart_key === chartKey);
    const by = (field) => records.reduce((out, record) => {
      out[record[field]] = (out[record[field]] || 0) + 1;
      return out;
    }, {});
    console.log(JSON.stringify({ total: records.length, by_domain: by('domain'), by_status: by('status') }, null, 2));
    process.exit(0);
  }

  if (command === 'update') {
    const id = arg('id');
    const data = arg('data');
    if (!id) throw new Error('update 必须提供 --id');
    if (!data) throw new Error('update 必须提供 --data JSON');
    const changes = JSON.parse(data);
    if (Object.prototype.hasOwnProperty.call(changes, 'id')) {
      throw new Error('update 不允许修改 id');
    }
    validateEnums(changes);
    const index = library.cases.findIndex((record) => record.id === id);
    if (index < 0) throw new Error(`未找到案例：${id}`);
    const current = library.cases[index];
    const updated = {
      ...current,
      ...changes,
      id: current.id,
      created_at: current.created_at,
      updated_at: new Date().toISOString(),
    };
    required(updated, ['chart_key', 'domain', 'event_type', 'user_report', 'status', 'source']);
    library.cases[index] = updated;
    save(file, library);
    console.log(JSON.stringify(updated, null, 2));
    process.exit(0);
  }

  if (command === 'remove') {
    const id = arg('id');
    if (!id) throw new Error('remove 必须提供 --id');
    const before = library.cases.length;
    library.cases = library.cases.filter((record) => record.id !== id);
    if (library.cases.length === before) throw new Error(`未找到案例：${id}`);
    save(file, library);
    console.log(`已删除案例：${id}`);
    process.exit(0);
  }

  throw new Error(`未知命令：${command}`);
} catch (error) {
  console.error(`错误：${error.message}`);
  process.exit(1);
}
