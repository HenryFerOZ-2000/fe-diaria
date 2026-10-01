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
