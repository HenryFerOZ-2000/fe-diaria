import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpiritualStatsScreen extends StatelessWidget {
  const SpiritualStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos espirituales')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Próximamente', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Métricas básicas (placeholder):', style: GoogleFonts.inter(fontSize: 14)),
            const SizedBox(height: 8),
            _metric('Días activos (últimos 30)', '—'),
            _metric('Oraciones completadas', '—'),
            _metric('Versículos leídos', '—'),
            _metric('Posts creados', '—'),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[800])),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}


