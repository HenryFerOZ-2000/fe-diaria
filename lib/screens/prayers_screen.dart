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
    final sections = {for (final s in prayerSectionsFor(tradition)) s.id: s};
    final emotions = sections['emotion']!;
    final intentions = sections['intention']!;
    final traditional = sections['traditional']!;

    return AppScaffold(
      showBanner: false,
      centerTitle: false,
      titleWidget: const SizedBox.shrink(),
      actions: const [VerbumHeaderActions()],
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              VerbumSpace.gutter,
              14,
              VerbumSpace.gutter,
              0,
            ),
            child: VTwoToneTitle(
              'lo que vives hoy',
              'Ora por',
              accentFirst: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VerbumSpace.gutter,
              6,
              VerbumSpace.gutter,
              16,
            ),
            child: Text(
              usesBiblicalPrayers(tradition)
                  ? 'Oraciones nacidas de la Palabra para cada emoción e intención'
                  : 'Oraciones para cada emoción e intención',
              style: context.type.body.copyWith(color: p.inkMuted),
            ),
          ),
          // Intenciones como chips: un toque y a orar.
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: VerbumSpace.gutter,
              ),
              itemCount: intentions.entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final entry = intentions.entries[i];
                return ActionChip(
                  avatar: VIcon(
                    iconForPrayerEntry(entry),
                    size: 16,
                    color: p.rubric,
                  ),
                  label: Text(entry.title),
                  tooltip: 'Orar por ${entry.title.toLowerCase()}',
                  onPressed: () => _push(context, screenForPrayerEntry(entry)),
                );
              },
            ),
          ),
          VSectionHeader(
            traditional.title,
            padding: const EdgeInsets.fromLTRB(
              VerbumSpace.gutter + 2,
              24,
              VerbumSpace.gutter + 2,
              12,
            ),
          ),
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(68) + 214,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(
                horizontal: VerbumSpace.gutter,
              ),
              itemCount: traditional.entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final entry = traditional.entries[i];
                return VPhotoCard(
                  photo: photoForPrayerEntry(entry),
                  title: entry.title,
                  caption: entry.subtitle,
                  onTap: () => _push(context, screenForPrayerEntry(entry)),
                );
              },
            ),
          ),
          VSectionHeader(
            '¿Cómo te sientes?',
            padding: const EdgeInsets.fromLTRB(
              VerbumSpace.gutter + 2,
              20,
              VerbumSpace.gutter + 2,
              12,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VerbumSpace.gutter),
            child: VTileGrid(
              children: [
                for (final entry in emotions.entries)
                  VCategoryTile(
                    icon: iconForPrayerEntry(entry),
                    title: entry.title,
                    subtitle: entry.subtitle,
                    onTap: () => _push(context, screenForPrayerEntry(entry)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VerbumSpace.gutter,
              26,
              VerbumSpace.gutter,
              0,
            ),
            child: VActionTile(
              icon: VerbumIcons.books,
              title: 'Tradiciones y fuentes',
              subtitle: 'Conoce el origen de lo que lees',
              iconColor: p.gold,
              onTap: () => _push(context, const ContentSourcesScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
