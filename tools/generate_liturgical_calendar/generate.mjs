import { mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

import { GeneralRoman_Es } from '@romcal/calendar.general-roman';
import { Romcal } from 'romcal';

const revision = '6246bad8c548c1f2528916df40e433c1f7c97c6a';
const packageVersion = '3.0.0-dev.140';
const assetsDirectory = resolve(import.meta.dirname, '../../assets/liturgy');

const romcal = new Romcal({
  localizedCalendar: GeneralRoman_Es,
  scope: 'gregorian',
  epiphanyOnSunday: false,
  ascensionOnSunday: false,
  corpusChristiOnSunday: false,
});

const rankMap = {
  SOLEMNITY: 'solemnity',
  SUNDAY: 'sunday',
  FEAST: 'feast',
  MEMORIAL: 'memorial',
  OPTIONAL_MEMORIAL: 'optionalMemorial',
  WEEKDAY: 'weekday',
};

const colorMap = {
  WHITE: 'white',
  GREEN: 'green',
  RED: 'red',
  PURPLE: 'purple',
  ROSE: 'rose',
  GOLD: 'gold',
  BLACK: 'black',
};

const seasonMap = {
  ADVENT: 'advent',
  CHRISTMAS_TIME: 'christmas',
  ORDINARY_TIME: 'ordinaryTime',
  LENT: 'lent',
  PASCHAL_TRIDUUM: 'triduum',
  EASTER_TIME: 'easter',
};

function requiredMap(map, value, field) {
  const normalized = map[value];
  if (!normalized) throw new Error(`Valor desconocido en ${field}: ${value}`);
  return normalized;
}

function normalizeCelebration(item) {
  if (!item?.id || !item?.name) {
    throw new Error(`Celebración sin id o nombre: ${item?.date ?? 'sin fecha'}`);
  }
  return {
    id: item.id,
    name: item.name,
    rank: requiredMap(rankMap, item.rank, 'rank'),
    colors: item.colors.map((value) => requiredMap(colorMap, value, 'color')),
  };
}

function normalizeCycle(value, prefix) {
  if (value == null) return null;
  if (!value.startsWith(prefix)) throw new Error(`Ciclo desconocido: ${value}`);
  return value.slice(prefix.length);
}

function normalizeDay(date, celebrations) {
  const [primary, ...optional] = celebrations;
  if (!primary) throw new Error(`No existe celebración principal para ${date}`);
  const sundayCycle = normalizeCycle(primary.cycles?.sundayCycle, 'YEAR_');
  const weekdayCycle = normalizeCycle(primary.cycles?.weekdayCycle, 'YEAR_');
  const psalterWeek = normalizeCycle(primary.cycles?.psalterWeek, 'WEEK_');
  if (sundayCycle != null && !['A', 'B', 'C'].includes(sundayCycle)) {
    throw new Error(`Ciclo dominical desconocido: ${sundayCycle}`);
  }
  if (weekdayCycle != null && !['1', '2'].includes(weekdayCycle)) {
    throw new Error(`Ciclo ferial desconocido: ${weekdayCycle}`);
  }
  if (psalterWeek != null && !['1', '2', '3', '4'].includes(psalterWeek)) {
    throw new Error(`Semana del salterio desconocida: ${psalterWeek}`);
  }
  return {
    date,
    primary: normalizeCelebration(primary),
    optional: optional.map(normalizeCelebration),
    season: requiredMap(seasonMap, primary.seasons[0], 'season'),
    sundayCycle,
    weekdayCycle:
      weekdayCycle == null ? null : weekdayCycle === '1' ? 'I' : 'II',
    psalterWeek: psalterWeek == null ? null : Number(psalterWeek),
  };
}

const days = {};
for (let year = 2025; year <= 2035; year += 1) {
  const calendar = await romcal.generateCalendar(year);
  for (const [date, celebrations] of Object.entries(calendar)) {
    days[date] = normalizeDay(date, celebrations);
  }
}

const generatedAt = process.env.SOURCE_DATE_EPOCH
  ? new Date(Number(process.env.SOURCE_DATE_EPOCH) * 1000).toISOString()
  : '2026-09-20T00:00:00.000Z';

const output = {
  schemaVersion: 1,
  source: {
    id: 'romcal-general-roman-es',
    name: 'Romcal — Calendario Romano General',
    url: 'https://github.com/romcal/romcal',
    license: 'MIT',
    revision,
    packageVersion,
    scope: 'generalRoman',
    authorityStatus: 'openEcclesialSource',
    generatedAt,
    reviewedAt: '2026-09-20',
    reviewNotes:
      'Calendario Romano General; propios nacionales y diocesanos no incluidos.',
  },
  days,
};

await mkdir(assetsDirectory, { recursive: true });
await writeFile(
  resolve(assetsDirectory, 'general_roman_es_2025_2035.json'),
  `${JSON.stringify(output)}\n`,
  'utf8',
);

console.log(`Calendario generado: ${Object.keys(days).length} fechas.`);
