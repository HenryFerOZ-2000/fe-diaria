import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../faith/faith_tradition.dart';
import '../features/prayers/domain/prayer_catalog.dart';
import '../features/prayers/presentation/prayer_entry_icons.dart';
import '../features/prayers/presentation/prayer_routes.dart';
import '../services/storage_service.dart';
import '../widgets/cover_tab_page.dart';
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

    final type = context.type;
    return CoverTabPage(
      cover: VPhotoCover(
        image: AssetImage(VerbumPhotos.prayingHands.asset),
        minHeight: 340,
        bottomPadding: 26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CoverTopActions(),
            const SizedBox(height: 96),
            Text(
              'ORACIONES',
              style: type.rubric.copyWith(color: p.butter, letterSpacing: 1.5),
            ),
            const SizedBox(height: 4),
            Semantics(
              header: true,
              child: Text(
                'Ora por lo que vives hoy',
                style: type.display.copyWith(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              usesBiblicalPrayers(tradition)
                  ? 'Oraciones nacidas de la Palabra para cada emoción e intención'
                  : 'Oraciones para cada emoción e intención',
              style: type.body.copyWith(
                color: Colors.white.withValues(alpha: .9),
              ),
            ),
          ],
        ),
      ),
      children: [
        // Intenciones como chips: un toque y a orar.
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: VerbumSpace.gutter),
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
          height: VPhotoCard.rowHeight(context, 164),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: VerbumSpace.gutter),
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
    );
  }
}
