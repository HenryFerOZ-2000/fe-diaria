import 'package:flutter/material.dart';
import '../faith/content_provenance.dart';
import '../models/emotion_prayer.dart';
import '../repositories/emotion_prayer_repository.dart';
import '../services/rotation_service.dart';
import '../services/share_service.dart';
import '../widgets/prayer_reading_experience.dart';

class EmotionPassageReadScreen extends StatefulWidget {
  final String emotionKey;
  const EmotionPassageReadScreen({super.key, required this.emotionKey});
  @override
  State<EmotionPassageReadScreen> createState() =>
      _EmotionPassageReadScreenState();
}

class _EmotionPassageReadScreenState extends State<EmotionPassageReadScreen> {
  late final RotationService<EmotionPrayer> _rotation;
  final _repo = EmotionPrayerRepository();
  bool _loading = true;
  String? _error;
  EmotionPrayer? _prayer;

  @override
  void initState() {
    super.initState();
    _rotation = RotationService<EmotionPrayer>(
      sourceKey: 'emotion',
      loader: (category) => _repo.getByCategory(category),
      idSelector: (prayer) => prayer.id,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prayer = await _rotation.next(widget.emotionKey);
      if (prayer == null) {
        throw Exception('No hay oraciones configuradas para esta emoción.');
      }
      if (!mounted) return;
      setState(() {
        _prayer = prayer;
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
    if (_prayer == null) return;
    ShareService.shareAsText(
      text: _prayer!.text,
      reference: _prayer!.verseRef ?? _prayer!.title,
      title: _prayer!.title,
    );
  }

  Color get _accent {
    switch (widget.emotionKey) {
      case 'paz_interior':
        return const Color(0xFF5F8178);
      case 'gratitud':
        return const Color(0xFFB58A45);
      case 'fortaleza':
        return const Color(0xFF536C91);
      case 'perdon':
        return const Color(0xFF9A7054);
      default:
        return const Color(0xFF77649A);
    }
  }

  String get _category => widget.emotionKey.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) => PrayerReadingExperience(
    provenance: ContentProvenance.aiGenerated,
    loading: _loading,
    error: _error,
    category: _category,
    title: _prayer?.title,
    text: _prayer?.text,
    verseReference: _prayer?.verseRef,
    tags: _prayer?.tags ?? const [],
    accent: _accent,
    onBack: () => Navigator.pop(context),
    onRetry: _load,
    onShare: _share,
    onNext: _load,
  );
}
