import 'package:flutter/material.dart';
import '../models/traditional_prayer.dart';
import '../repositories/traditional_prayer_repository.dart';
import '../services/share_service.dart';
import '../widgets/prayer_reading_experience.dart';

class TraditionalPrayerScreen extends StatefulWidget {
  final String prayerId;
  const TraditionalPrayerScreen({super.key, required this.prayerId});
  @override
  State<TraditionalPrayerScreen> createState() =>
      _TraditionalPrayerScreenState();
}

class _TraditionalPrayerScreenState extends State<TraditionalPrayerScreen> {
  final _repo = TraditionalPrayerRepository();
  bool _loading = true;
  String? _error;
  TraditionalPrayer? _prayer;
  String? _text;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prayer = await _repo.findById(widget.prayerId);
      if (prayer == null) throw Exception('No se encontró la oración.');
      if (prayer.type == 'bible_passage') {
        throw Exception(
          'Este pasaje bíblico todavía no está disponible sin conexión.',
        );
      }
      if (!mounted) return;
      setState(() {
        _prayer = prayer;
        _text = prayer.text ?? '';
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _share() {
    if (_prayer == null || _text == null) return;
    ShareService.shareAsText(
      text: _text!,
      reference: _prayer!.title,
      title: _prayer!.title,
    );
  }

  @override
  Widget build(BuildContext context) => PrayerReadingExperience(
    loading: _loading,
    provenance: _prayer?.provenance,
    error: _error,
    category: 'Oración tradicional',
    title: _prayer?.title,
    text: _text,
    accent: const Color(0xFF8D7BC2),
    onBack: () => Navigator.pop(context),
    onRetry: _load,
    onShare: _share,
  );
}
