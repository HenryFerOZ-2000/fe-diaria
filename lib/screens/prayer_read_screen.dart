import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/prayer_model.dart';
import '../services/prayer_rotation_service.dart';

class PrayerReadScreen extends StatefulWidget {
  final String category;
  const PrayerReadScreen({super.key, required this.category});

  @override
  State<PrayerReadScreen> createState() => _PrayerReadScreenState();
}

class _PrayerReadScreenState extends State<PrayerReadScreen> {
  final _service = PrayerRotationService();
  PrayerModel? _current;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    setState(() => _loading = true);
    final prayer = await _service.nextPrayer(widget.category);
    if (!mounted) return;
    setState(() {
      _current = prayer;
      _loading = false;
    });
  }

  String _categoryTitle(String key) {
    switch (key) {
      case 'ansiedad':
        return 'Ansiedad';
      case 'tristeza':
        return 'Tristeza';
      case 'paz_interior':
        return 'Paz interior';
      case 'gratitud':
        return 'Gratitud';
      case 'perdon':
        return 'Perdón';
      case 'fortaleza':
        return 'Fortaleza';
      default:
        return key;
    }
  }

  void _sharePrayer() {
    if (_current == null) return;
    final prayer = _current!;
    final verse = prayer.verseRef != null ? '\n\nRef: ${prayer.verseRef}' : '';
    Share.share('${prayer.title}\n\n${prayer.text}$verse');
  }

  @override
  Widget build(BuildContext context) {
    final categoryTitle = _categoryTitle(widget.category);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Oración - $categoryTitle'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _current == null
                ? const Center(child: Text('No se encontró contenido.'))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _current!.title,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _current!.text,
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(height: 1.4),
                                ),
                                if (_current!.verseRef != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _current!.verseRef!,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  children: _current!.tags
                                      .map((t) => Chip(label: Text(t)))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _sharePrayer,
                                child: const Text('Compartir'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _loadNext,
                                child: const Text('Siguiente'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

