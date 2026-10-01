import 'package:flutter/material.dart';

/// Cuadrícula de tiles que no hace scroll propio (vive dentro de la página).
/// Dos columnas en teléfono, más en pantallas anchas; las filas igualan alto.
class VTileGrid extends StatelessWidget {
  const VTileGrid({
    super.key,
    required this.children,
    this.spacing = 10,
    this.minTileWidth = 150,
  });

  final List<Widget> children;
  final double spacing;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minTileWidth).floor().clamp(
          2,
          4,
        );
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          final cells = <Widget>[];
          for (var c = 0; c < columns; c++) {
            if (c > 0) cells.add(SizedBox(width: spacing));
            final index = i + c;
            cells.add(
              Expanded(
                child: index < children.length
                    ? children[index]
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cells,
              ),
            ),
          );
        }
        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }
}
