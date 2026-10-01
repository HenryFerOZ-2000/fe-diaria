import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';

class VActionBarItem {
  const VActionBarItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  final VerbumIcons icon;
  final String label;
  final VoidCallback onPressed;

  /// Acción principal: icono en mantequilla.
  final bool emphasized;
}

/// Barra flotante en tinta con acciones rotuladas (p. ej. sobre versículos
/// seleccionados). [leading] da contexto al botón de cerrar: "2 versículos".
class VActionBar extends StatelessWidget {
  const VActionBar({
    super.key,
    required this.items,
    this.leading,
    this.onClose,
  });

  final List<VActionBarItem> items;
  final String? leading;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final bg = p.inverse;
    final fg = p.onInverse;

    return Material(
      color: bg,
      elevation: 0,
      borderRadius: BorderRadius.circular(VerbumRadius.tile + 2),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            if (onClose != null)
              IconButton(
                tooltip: leading == null
                    ? 'Cancelar selección'
                    : 'Cancelar selección ($leading)',
                onPressed: onClose,
                icon: VIcon(VerbumIcons.close, size: 20, color: fg),
              ),
            for (final item in items)
              Expanded(
                child: Tooltip(
                  message: item.label,
                  excludeFromSemantics: true,
                  child: Semantics(
                    button: true,
                    label: item.label,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: item.onPressed,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VIcon(
                              item.icon,
                              weight: item.emphasized
                                  ? VIconWeight.fill
                                  : VIconWeight.regular,
                              size: 21,
                              color: item.emphasized ? p.butter : fg,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: type.caption.copyWith(
                                color: fg.withValues(alpha: 0.78),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
