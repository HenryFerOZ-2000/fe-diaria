import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Pestañas de Comunidad.
enum CommunityTab { live, mine }

/// Portada de Comunidad: foto real, rótulo, título, un dato vivo y el
/// selector de pestañas translúcido al pie.
class CommunityCover extends StatelessWidget {
  const CommunityCover({
    super.key,
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.tab,
    required this.onTab,
    this.subtitle,
    this.extra,
  });

  final ImageProvider image;
  final String eyebrow;
  final String title;
  final String? subtitle;

  /// Contador de intenciones, miembros, código…
  final Widget? extra;
  final CommunityTab tab;
  final ValueChanged<CommunityTab> onTab;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return VPhotoCover(
      image: image,
      minHeight: 380,
      bottomPadding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VGlassButton(
                icon: VerbumIcons.slidersHorizontal,
                tooltip: 'Configuración',
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
              ),
              const Spacer(),
              VGlassButton(
                icon: VerbumIcons.user,
                tooltip: 'Mi perfil',
                onPressed: () => Navigator.of(context).pushNamed('/profile'),
              ),
            ],
          ),
          const SizedBox(height: 92),
          Text(
            eyebrow.toUpperCase(),
            style: type.rubric.copyWith(color: p.butter, letterSpacing: 1.5),
          ),
          const SizedBox(height: 4),
          Semantics(
            header: true,
            child: Text(
              title,
              style: type.display.copyWith(color: Colors.white, fontSize: 32),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: type.body.copyWith(
                color: Colors.white.withValues(alpha: .9),
              ),
            ),
          if (extra != null) ...[const SizedBox(height: 10), extra!],
          const SizedBox(height: 18),
          _Tabs(tab: tab, onTab: onTab),
        ],
      ),
    );
  }
}

/// Chip translúcido para datos sobre la portada.
class CommunityGlassChip extends StatelessWidget {
  const CommunityGlassChip({
    super.key,
    required this.label,
    this.icon,
    this.dotColor,
    this.onTap,
  });

  final String label;
  final VerbumIcons? icon;

  /// Punto de "en vivo".
  final Color? dotColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(99);
    return Material(
      color: Colors.white.withValues(alpha: .18),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor!.withValues(alpha: .4),
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (icon != null) ...[
                VIcon(icon!, size: 14, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.bodyStrong.copyWith(
                    color: Colors.white,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.onTab});

  final CommunityTab tab;
  final ValueChanged<CommunityTab> onTab;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget option(CommunityTab value, VerbumIcons icon, String label) {
      final selected = value == tab;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: selected ? p.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            elevation: selected ? 2 : 0,
            shadowColor: p.ink.withValues(alpha: .25),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTab(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VIcon(
                      icon,
                      size: 16,
                      color: selected ? p.ink : p.inkMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.bodyStrong.copyWith(
                          color: selected ? p.ink : p.inkMuted,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          option(CommunityTab.live, VerbumIcons.broadcast, 'En vivo'),
          const SizedBox(width: 4),
          option(CommunityTab.mine, VerbumIcons.usersThree, 'Mi comunidad'),
        ],
      ),
    );
  }
}
