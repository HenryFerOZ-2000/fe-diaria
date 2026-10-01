import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../photos/verbum_photos.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import '../tokens/verbum_shadows.dart';

/// Foto con marco blanco y sombra suave, como una estampa; puede ir
/// ligeramente girada. Decorativa: no se anuncia a lectores de pantalla.
class VPhotoFrame extends StatelessWidget {
  const VPhotoFrame(
    this.photo, {
    super.key,
    this.width = 96,
    this.aspectRatio = 4 / 5,
    this.tiltDegrees = 0,
  });

  final VerbumPhotos photo;
  final double width;
  final double aspectRatio;
  final double tiltDegrees;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: tiltDegrees * math.pi / 180,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(VerbumRadius.tile),
            boxShadow: VerbumShadows.soft(p),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(VerbumRadius.tile - 5),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Image.asset(
                photo.asset,
                fit: BoxFit.cover,
                // Decodifica al tamaño mostrado, no al original.
                cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                    .round(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
