import assert from 'node:assert/strict';
import { access, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const assetsDirectory = resolve(import.meta.dirname, '../../assets/liturgy');
const calendarPath = resolve(
  assetsDirectory,
  'general_roman_es_2025_2035.json',
);
const manifestPath = resolve(assetsDirectory, 'manifest.json');
const data = JSON.parse(await readFile(calendarPath, 'utf8'));
const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));

assert.equal(data.schemaVersion, 1);
assert.equal(manifest.schemaVersion, 1);
assert.equal(
  manifest.base,
  'assets/liturgy/general_roman_es_2025_2035.json',
);
assert.deepEqual(manifest.verifiedCountries, {});
assert.equal(Object.keys(data.days).length, 4017);
assert.equal(data.days['2026-04-05'].primary.id, 'easter_sunday');
assert.equal(data.days['2026-02-18'].primary.id, 'ash_wednesday');
assert.equal(data.days['2026-11-29'].season, 'advent');
assert.equal(data.source.license, 'MIT');
assert.equal(
  data.source.revision,
  '6246bad8c548c1f2528916df40e433c1f7c97c6a',
);
assert.equal(data.source.reviewedAt, '2026-09-20');

const expectedDates = new Set();
for (
  let cursor = new Date('2025-01-01T00:00:00.000Z');
  cursor <= new Date('2035-12-31T00:00:00.000Z');
  cursor.setUTCDate(cursor.getUTCDate() + 1)
) {
  expectedDates.add(cursor.toISOString().slice(0, 10));
}
assert.deepEqual(new Set(Object.keys(data.days)), expectedDates);

for (const [date, day] of Object.entries(data.days)) {
  assert.match(date, /^\d{4}-\d{2}-\d{2}$/);
  assert.equal(day.date, date);
  assert.ok(day.primary.name.trim().length > 0);
  assert.doesNotMatch(day.primary.name, /Jehová|Yahvé|YHWH/i);
}

for (const [country, path] of Object.entries(manifest.verifiedCountries)) {
  assert.match(country, /^[A-Z]{2}$/);
  assert.match(path, /^assets\/liturgy\/countries\//);
  await access(resolve(import.meta.dirname, '../..', path));
}

console.log('Calendario auditado: 2025-2035, 4017 fechas.');
