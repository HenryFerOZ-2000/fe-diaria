import 'dart:convert';
import 'dart:io';

void main() async {
  print('Creando archivos JSON para contenido diario...');
  
  // 1. Crear morning_prayers.json
  await createMorningPrayers();
  
  // 2. Crear night_prayers.json
  await createNightPrayers();
  
  // 3. Verificar verses.json (ya existe)
  print('✓ Versículos ya están en assets/data/verses.json');
  
  print('¡Archivos creados exitosamente!');
}

Future<void> createMorningPrayers() async {
  final file = File('assets/prayers/morning_365.json');
  if (!await file.exists()) {
    print('✗ Error: No se encontró assets/prayers/morning_365.json');
    return;
  }
  
  final content = await file.readAsString();
  final List<dynamic> data = json.decode(content);
  
  final prayers = <String>[];
  for (final item in data) {
    final map = item as Map<String, dynamic>;
    prayers.add(map['text'] as String);
  }
  
  final outputFile = File('assets/data/morning_prayers.json');
  await outputFile.create(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(prayers),
  );
  
  print('✓ Creado: assets/data/morning_prayers.json (${prayers.length} oraciones)');
}

Future<void> createNightPrayers() async {
  final file = File('assets/prayers/night_365.json');
  if (!await file.exists()) {
    print('✗ Error: No se encontró assets/prayers/night_365.json');
    return;
  }
  
  final content = await file.readAsString();
  final List<dynamic> data = json.decode(content);
  
  final prayers = <String>[];
  for (final item in data) {
    final map = item as Map<String, dynamic>;
    prayers.add(map['text'] as String);
  }
  
  final outputFile = File('assets/data/night_prayers.json');
  await outputFile.create(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(prayers),
  );
  
  print('✓ Creado: assets/data/night_prayers.json (${prayers.length} oraciones)');
}

