import 'package:flutter/widgets.dart';

import '../tokens/verbum_palette.dart';
import '../tokens/verbum_typography.dart';

/// Acceso corto a los tokens: `context.palette.rubric`, `context.type.heading`.
extension VerbumContext on BuildContext {
  VerbumPalette get palette => VerbumPalette.of(this);
  VerbumTypography get type => VerbumTypography.of(this);
}
