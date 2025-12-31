import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan actual', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Plan: free (placeholder)', style: GoogleFonts.inter(fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Suscripciones próximamente')),
                );
              },
              child: const Text('Próximamente'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restaurar compras próximamente')),
                );
              },
              child: const Text('Restaurar compras'),
            ),
          ],
        ),
      ),
    );
  }
}


