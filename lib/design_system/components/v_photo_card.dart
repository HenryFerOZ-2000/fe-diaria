import 'package:flutter/material.dart';

import '../photos/verbum_photos.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_photo_frame.dart';

/// Foto enmarcada con título y leyenda debajo; toda la tarjeta es tocable.
class VPhotoCard extends StatelessWidget {
  const VPhotoCard({
    super.key,
    required this.photo,
    required this.title,
    required this.onTap,
    this.caption,
    this.width = 164,
  });

  final VerbumPhotos photo;
  final String title;
  final String? caption;
  final VoidCallback onTap;
  final double width;

  /// Alto que necesita una fila de tarjetas de [width]: foto con marco,
  /// título de hasta dos líneas y leyenda, según el tamaño de letra.
  static double rowHeight(BuildContext context, double width) {
    const frame = 5.0;
    final photo = (width - frame * 2) * 5 / 4 + frame * 2;
    return photo + 10 + MediaQuery.textScalerOf(context).scale(62);
  }

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Semantics(
      button: true,
      label: caption == null ? title : '$title, $caption',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VerbumRadius.tile),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VPhotoFrame(photo, width: width),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodyStrong,
                ),
              ),
              if (caption != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.caption,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
