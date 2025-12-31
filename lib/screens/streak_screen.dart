import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/streak_service.dart';
import '../services/storage_service.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  late final StreakService _streakService;
  bool _loading = true;
  int _current = 0;
  int _best = 0;
  String? _last;
  Set<String> _completedYmd = {};

  @override
  void initState() {
    super.initState();
    _streakService = StreakService(StorageService());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final state = await _streakService.getStreak();
    if (!mounted) return;

    // Reconstruir días completados basados en racha actual (contigua hasta lastDate)
    final completed = <String>{};
    if (state.lastDateYmd != null && state.current > 0) {
      final lastDate = _parseYmd(state.lastDateYmd!);
      if (lastDate != null) {
        for (int i = 0; i < state.current; i++) {
          final date = lastDate.subtract(Duration(days: i));
          completed.add(_toYmd(date));
        }
      }
    }

    setState(() {
      _current = state.current;
      _best = state.best;
      _last = state.lastDateYmd;
      _completedYmd = completed;
      _loading = false;
    });
  }

  DateTime? _parseYmd(String ymd) {
    try {
      final parts = ymd.split('-');
      if (parts.length != 3) return null;
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  String _toYmd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi racha')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Racha actual: $_current días',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Mejor racha: $_best días',
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text('Último día registrado: ${_last ?? 'N/A'}',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    child: const Text('Actualizar'),
                  ),
                  const SizedBox(height: 24),
                  _buildCalendar(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _legendBox(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCalendar() {
    // Últimos 35 días (5 semanas) hasta hoy
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 34));
    final days = List<DateTime>.generate(35, (i) => DateTime(start.year, start.month, start.day + i));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tus últimos 35 días',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mini calendario', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                        const SizedBox(width: 6),
                        const Text('Hecho'),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _legendBox(Colors.grey),
                        const SizedBox(width: 6),
                        const Text('Hoy'),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _legendBox(Colors.grey.shade300),
                        const SizedBox(width: 6),
                        const Text('Pendiente'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemBuilder: (context, index) {
                    final date = days[index];
                    final ymd = _toYmd(date);
                    final isToday = _toYmd(today) == ymd;
                    final done = _completedYmd.contains(ymd);
                    if (done) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                      );
                    }
                    final color = isToday ? Colors.grey : Colors.grey[300];
                    return Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isToday ? Colors.white : Colors.grey[800],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Se marcan en verde los días completados de tu racha (contigua).',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}


