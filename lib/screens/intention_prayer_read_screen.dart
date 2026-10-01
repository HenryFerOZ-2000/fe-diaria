import 'package:flutter/material.dart';
import '../faith/content_provenance.dart';
import '../models/intention_prayer.dart';
import '../repositories/intention_prayer_repository.dart';
import '../services/rotation_service.dart';
import '../services/share_service.dart';
import '../widgets/prayer_reading_experience.dart';
import '../features/sharing/domain/share_content.dart';

class IntentionPrayerReadScreen extends StatefulWidget {
  final String categoryKey;
  const IntentionPrayerReadScreen({super.key, required this.categoryKey});
  @override
  State<IntentionPrayerReadScreen> createState() =>
      _IntentionPrayerReadScreenState();
}

class _IntentionPrayerReadScreenState extends State<IntentionPrayerReadScreen> {
  late final RotationService<IntentionPrayer> _rotation;
  final _repo = IntentionPrayerRepository();
  bool _loading = true;
  String? _error;
  IntentionPrayer? _current;

  @override
  void initState() {
    super.initState();
    _rotation = RotationService<IntentionPrayer>(
      sourceKey: 'intention',
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
      final prayer = await _rotation.next(widget.categoryKey);
      if (prayer == null) {
        throw Exception('No hay oraciones configuradas para esta intención.');
      }
      if (!mounted) return;
      setState(() {
        _current = prayer;
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
    if (_current == null) return;
    ShareService.openComposer(
      context,
      ShareContent(
        title: _current!.title,
        body: _current!.text,
        reference: _current!.verseRef ?? _current!.title,
        kind: ShareContentKind.prayer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PrayerReadingExperience(
    provenance: ContentProvenance.aiGenerated,
    loading: _loading,
    error: _error,
    category: widget.categoryKey,
    title: _current?.title,
    text: _current?.text,
    verseReference: _current?.verseRef,
    tags: _current?.tags ?? const [],
    onBack: () => Navigator.pop(context),
    onRetry: _load,
    onShare: _share,
    onNext: _load,
  );
}
