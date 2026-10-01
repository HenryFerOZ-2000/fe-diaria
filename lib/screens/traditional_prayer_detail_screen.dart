import 'package:flutter/material.dart';
import '../services/traditional_prayers_service.dart';
import '../services/share_service.dart';
import '../widgets/prayer_reading_experience.dart';
import '../faith/content_provenance.dart';
import '../faith/biblical_prayer_passages.dart';
import '../features/sharing/domain/share_content.dart';

/// Pantalla de detalle de una oración tradicional
class TraditionalPrayerDetailScreen extends StatefulWidget {
  final String religion;
  final String category;
  final String prayerKey;

  const TraditionalPrayerDetailScreen({
    super.key,
    required this.religion,
    required this.category,
    required this.prayerKey,
  });

  @override
  State<TraditionalPrayerDetailScreen> createState() =>
      _TraditionalPrayerDetailScreenState();
}

class _TraditionalPrayerDetailScreenState
    extends State<TraditionalPrayerDetailScreen> {
  final TraditionalPrayersService _service = TraditionalPrayersService();
  Map<String, dynamic>? _prayer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayer();
  }

  Future<void> _loadPrayer() async {
    setState(() {
      _isLoading = true;
      _prayer = null;
    });
    try {
      final prayer = await _service.readPrayer(
        widget.religion,
        widget.category,
        widget.prayerKey,
      );
      if (!mounted) return;
      setState(() {
        _prayer = prayer;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading prayer: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _share() {
    if (_prayer == null) return;
    final title = _prayer!['titulo'] as String? ?? widget.prayerKey;
    final text = _prayer!['texto'] as String? ?? '';
    final source = _prayer!['provenance'] as ContentProvenance?;
    final passages = source == ContentProvenance.bible
        ? biblicalPrayerPassages(widget.religion, widget.prayerKey)
        : const <PrayerPassage>[];
    ShareService.openComposer(
      context,
      ShareContent(
        title: title,
        body: text,
        reference: passages.isEmpty
            ? title
            : passages.map((passage) => passage.reference).join('; '),
        sourceLabel: source?.translation,
        kind: passages.isEmpty
            ? ShareContentKind.prayer
            : passages.every((passage) => passage.book == 'PSA')
            ? ShareContentKind.psalm
            : ShareContentKind.verse,
        tradition: switch (widget.religion) {
          'catolica' => ShareTradition.catholic,
          'cristiana' => ShareTradition.evangelical,
          'general' => ShareTradition.ecumenical,
          _ => null,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrayerReadingExperience(
      loading: _isLoading,
      provenance: _prayer?['provenance'] as ContentProvenance?,
      error: !_isLoading && _prayer == null
          ? 'No se encontró esta oración.'
          : null,
      category: _service.getCategoryDisplayName(widget.category),
      title: _prayer?['titulo'] as String? ?? widget.prayerKey,
      text: _prayer?['texto'] as String?,
      onBack: () => Navigator.pop(context),
      onRetry: _loadPrayer,
      onShare: _share,
    );
  }
}
