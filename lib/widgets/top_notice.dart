import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

OverlayEntry? _activeTopNotice;
Timer? _activeTopNoticeTimer;

void showTopNotice(
  BuildContext context, {
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final mediaQuery = MediaQuery.of(context);
  final colorScheme = Theme.of(context).colorScheme;

  final backgroundColor =
      isError ? colorScheme.error : colorScheme.surfaceContainerHighest;
  final foregroundColor =
      isError ? colorScheme.onError : colorScheme.onSurface;
  final borderColor =
      isError ? colorScheme.error.withValues(alpha: 0.75) : colorScheme.primary.withValues(alpha: 0.28);

  _activeTopNoticeTimer?.cancel();
  _activeTopNotice?.remove();
  _activeTopNotice = null;

  final entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: mediaQuery.padding.top + 12,
        left: 12,
        right: 12,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: TweenAnimationBuilder<Offset>(
              tween: Tween<Offset>(
                begin: const Offset(0, -0.25),
                end: Offset.zero,
              ),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: Offset(0, offset.dy * 40),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: 1,
                    child: child,
                  ),
                );
              },
              child: IgnorePointer(
                ignoring: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                          color: foregroundColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: foregroundColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  _activeTopNotice = entry;

  _activeTopNoticeTimer = Timer(duration, () {
    if (_activeTopNotice == entry) {
      _activeTopNotice?.remove();
      _activeTopNotice = null;
    }
  });
}
