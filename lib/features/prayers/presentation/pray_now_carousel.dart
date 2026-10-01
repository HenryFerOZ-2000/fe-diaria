import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../faith/faith_tradition.dart';
import '../../../services/storage_service.dart';
import '../domain/prayer_catalog.dart';
import 'prayer_entry_icons.dart';
import 'prayer_routes.dart';

/// "Para orar ahora": oraciones con foto enmarcada en un carrusel.
class PrayNowCarousel extends StatelessWidget {
  const PrayNowCarousel({super.key, required this.now, this.onSeeAll});

  final DateTime now;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    // Se reconstruye cuando el usuario cambia de tradición en Ajustes.
    return ValueListenableBuilder(
      valueListenable: StorageService().faithPreferencesListenable(),
      builder: (context, _, _) {
        final tradition = faithTraditionFromStorageString(
          StorageService().getValidatedTraditionalPrayersReligion(),
        );
        final entries = prayNowEntries(tradition, now.hour);
        if (entries.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VSectionHeader(
              'Para orar ahora',
              trailing: onSeeAll == null ? null : 'Ver todo',
              onTrailingTap: onSeeAll,
              padding: const EdgeInsets.fromLTRB(2, 26, 2, 12),
            ),
            SizedBox(
              height: VPhotoCard.rowHeight(context, 132),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) => VPhotoCard(
                  photo: photoForPrayerEntry(entries[i]),
                  title: entries[i].title,
                  caption: entries[i].subtitle,
                  width: 132,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => screenForPrayerEntry(entries[i]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
