import 'package:flutter/material.dart';
import 'package:verbum/design_system/design_system.dart';

import '../features/today/application/constancy_progress.dart';

class RachaCelebrationDialog extends StatefulWidget {
  final int totalDays;

  const RachaCelebrationDialog({super.key, required this.totalDays});

  @override
  State<RachaCelebrationDialog> createState() => _RachaCelebrationDialogState();
}

class _RachaCelebrationDialogState extends State<RachaCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  bool get _isMilestone =>
      ConstancyProgress.milestones.contains(widget.totalDays);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .72, curve: Curves.easeOut),
    );
    _scale = Tween<double>(
      begin: .88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      _controller.forward();
    });
    if (WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openJourney() {
    final navigator = Navigator.of(context);
    navigator.pop();
    Future.microtask(() => navigator.pushNamed('/streak'));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;

    return Dialog(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbumRadius.sheet),
        side: BorderSide(color: p.line),
      ),
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const VCandle(size: 46),
                  VRubricLabel(
                    _isMilestone
                        ? 'Un hito en tu camino'
                        : 'Tu día está a salvo',
                    color: p.gold,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isMilestone
                        ? '${widget.totalDays} días de constancia'
                        : 'Un día más caminando con Dios',
                    textAlign: TextAlign.center,
                    style: type.display.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isMilestone
                        ? 'Cada uno de estos días comenzó con una pequeña decisión: hacer espacio para Dios.'
                        : 'Hoy hiciste espacio para detenerte, escuchar y volver a lo esencial.',
                    textAlign: TextAlign.center,
                    style: type.body.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 22),
                  VButton(
                    label: 'Continuar mi camino',
                    expanded: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 4),
                  VButton(
                    label: 'Ver mi recorrido',
                    variant: VButtonVariant.text,
                    onPressed: _openJourney,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
