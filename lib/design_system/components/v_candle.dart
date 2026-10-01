import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import 'v_icon.dart';

/// Vela encendida con halo cálido. Parpadea suavemente salvo que el sistema
/// pida reducir el movimiento.
class VCandle extends StatefulWidget {
  const VCandle({super.key, this.size = 54});

  final double size;

  @override
  State<VCandle> createState() => _VCandleState();
}

class _VCandleState extends State<VCandle> with SingleTickerProviderStateMixin {
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _flicker.stop();
      _flicker.value = 0.5;
    } else if (!_flicker.isAnimating) {
      _flicker.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = context.palette.gold;
    final halo = widget.size * 3.2;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: halo,
        child: AnimatedBuilder(
          animation: _flicker,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_flicker.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        gold.withValues(alpha: 0.26 + 0.06 * t),
                        gold.withValues(alpha: 0.05),
                        gold.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: (t - 0.5) * 0.045,
                  child: Transform.scale(scale: 0.97 + 0.06 * t, child: child),
                ),
              ],
            );
          },
          child: VIcon(
            VerbumIcons.flame,
            weight: VIconWeight.fill,
            size: widget.size,
            color: gold,
          ),
        ),
      ),
    );
  }
}
