import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Cabecera del recorrido inicial: marca, volver opcional y paso actual.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, this.step, this.onBack});

  /// "Paso 1 de 2"; `null` lo oculta.
  final String? step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        if (onBack != null)
          VIconButton(
            icon: VerbumIcons.arrowLeft,
            semanticLabel: 'Volver',
            variant: VIconButtonVariant.ghost,
            onPressed: onBack,
          )
        else
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: p.goldSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: VIcon(
              VerbumIcons.bookOpenText,
              weight: VIconWeight.duotone,
              size: 22,
              color: p.gold,
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Verbum',
            style: context.type.title.copyWith(fontSize: 26),
          ),
        ),
        if (step != null) VMetaChip(label: step!.toUpperCase()),
      ],
    );
  }
}

/// Barra inferior fija para la acción principal del paso.
class OnboardingBottomBar extends StatelessWidget {
  const OnboardingBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: child,
        ),
      ),
    );
  }
}
