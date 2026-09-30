import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../faith/faith_tradition.dart';
import '../features/prayers/domain/prayer_catalog.dart';
import '../features/prayers/presentation/prayer_entry_icons.dart';
import '../features/prayers/presentation/prayer_routes.dart';
import '../services/storage_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/verbum_header_actions.dart';
import 'content_sources_screen.dart';

class PrayersScreen extends StatelessWidget {
  const PrayersScreen({super.key});

  FaithTradition _currentTradition() => faithTraditionFromStorageString(
    StorageService().getValidatedTraditionalPrayersReligion(),
  );

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    // Se reconstruye cuando el usuario cambia de tradición en Ajustes.
    return ValueListenableBuilder(
      valueListenable: StorageService().faithPreferencesListenable(),
      builder: (context, _, _) => _buildFor(context, _currentTradition()),
    );
  }

  Widget _buildFor(BuildContext context, FaithTradition tradition) {
    final p = context.palette;
    final sectionColors = {
      'emotion': p.rubric,
      'intention': p.gold,
      // Con acento neutro (pan de oro) se usa tinta para no repetir el dorado.
      'traditional': p.accent == p.gold ? p.ink : p.accent,
    };

    return AppScaffold(
      showBanner: false,
      centerTitle: false,
      titleWidget: Text('Oraciones', style: context.type.display),
      actions: const [VerbumHeaderActions()],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          VerbumSpace.gutter,
          4,
          VerbumSpace.gutter,
          28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VFeatureCard(
              eyebrow: 'Un momento para ti',
              title: 'Respira. Dios está aquí.',
              body: usesBiblicalPrayers(tradition)
                  ? 'Encuentra una oración nacida de la Palabra.'
                  : 'Encuentra palabras para lo que hoy lleva tu corazón.',
              watermark: VerbumIcons.handsPraying,
            ),
            for (final section in prayerSectionsFor(tradition)) ...[
              VSectionHeader(
                section.title,
                trailing: '${section.entries.length}',
                padding: const EdgeInsets.fromLTRB(2, 26, 2, 12),
              ),
              VTileGrid(
                children: [
                  for (final entry in section.entries)
                    VCategoryTile(
                      icon: iconForPrayerEntry(entry),
                      title: entry.title,
                      subtitle: entry.subtitle,
                      iconColor: sectionColors[section.id],
                      onTap: () => _push(context, screenForPrayerEntry(entry)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 26),
            VActionTile(
              icon: VerbumIcons.books,
              title: 'Tradiciones y fuentes',
              subtitle: 'Conoce el origen de lo que lees',
              iconColor: p.gold,
              onTap: () => _push(context, const ContentSourcesScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
