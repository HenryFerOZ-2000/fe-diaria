import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:verbum/features/sharing/domain/share_card_format.dart';
import 'package:verbum/features/sharing/domain/share_content.dart';
import 'package:verbum/features/sharing/domain/share_page.dart';

const Map<ShareCardFormat, _ShareTypography> _typographyByFormat = {
  ShareCardFormat.square: _ShareTypography(
    bodyFontSize: 42,
    horizontalInset: 96,
    verticalInset: 72,
    logoRegionHeight: 112,
    referenceRegionHeight: 88,
    footerRegionHeight: 80,
    pageMarkerRegionHeight: 64,
  ),
  ShareCardFormat.portrait: _ShareTypography(
    bodyFontSize: 40,
    horizontalInset: 96,
    verticalInset: 80,
    logoRegionHeight: 112,
    referenceRegionHeight: 88,
    footerRegionHeight: 80,
    pageMarkerRegionHeight: 64,
  ),
  ShareCardFormat.story: _ShareTypography(
    bodyFontSize: 38,
    horizontalInset: 104,
    verticalInset: 112,
    logoRegionHeight: 128,
    referenceRegionHeight: 96,
    footerRegionHeight: 88,
    pageMarkerRegionHeight: 72,
  ),
};

class SharePaginator {
  const SharePaginator();

  List<SharePage> paginate(
    ShareContent content, {
    required ShareCardFormat format,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final body = content.body.replaceAll('\r\n', '\n').trim();
    final typography = _typographyByFormat[format]!;

    var chunks = _paginateBody(
      body,
      format: format,
      typography: typography,
      textDirection: textDirection,
      knownPageCount: null,
    );

    if (chunks.length > 1) {
      var knownPageCount = chunks.length;
      while (true) {
        chunks = _paginateBody(
          body,
          format: format,
          typography: typography,
          textDirection: textDirection,
          knownPageCount: knownPageCount,
        );
        if (chunks.length == knownPageCount) {
          break;
        }
        knownPageCount = chunks.length;
      }
    }

    assert(chunks.join() == body, 'Pagination must not change the body.');

    return List<SharePage>.generate(
      chunks.length,
      (index) => SharePage(
        body: chunks[index],
        index: index + 1,
        total: chunks.length,
      ),
      growable: false,
    );
  }

  List<String> _paginateBody(
    String body, {
    required ShareCardFormat format,
    required _ShareTypography typography,
    required TextDirection textDirection,
    required int? knownPageCount,
  }) {
    final layout = _BodyLayout(
      size: typography.bodyBox(
        format.pixelSize,
        reservePageMarker: knownPageCount != null && knownPageCount > 1,
      ),
      typography: typography,
      textDirection: textDirection,
    );
    final builder = _PageBuilder(layout);

    for (final paragraph in _splitParagraphs(body)) {
      builder.addParagraph(paragraph);
    }

    return builder.finish();
  }
}

class _PageBuilder {
  _PageBuilder(this.layout);

  final _BodyLayout layout;
  final List<String> _pages = <String>[];
  String _current = '';

  void addParagraph(String paragraph) {
    if (!layout.fits(paragraph) || layout.containsOversizedToken(paragraph)) {
      for (final sentence in _splitSentences(paragraph)) {
        _addSentence(sentence);
      }
      return;
    }

    _addFittingSegment(paragraph);
  }

  void _addSentence(String sentence) {
    if (!layout.fits(sentence) || layout.containsOversizedToken(sentence)) {
      for (final word in _splitWords(sentence)) {
        _addWord(word);
      }
      return;
    }

    _addFittingSegment(sentence);
  }

  void _addWord(String word) {
    if (layout.containsOversizedToken(word)) {
      _flush();
      _pages.add(word);
      return;
    }

    if (layout.fits(word)) {
      _addFittingSegment(word);
      return;
    }

    _flush();
    _pages.add(word);
  }

  void _addFittingSegment(String segment) {
    if (_current.isEmpty || layout.fits('$_current$segment')) {
      _current += segment;
      return;
    }

    _flush();
    _current = segment;
  }

  List<String> finish() {
    _flush();
    return List<String>.unmodifiable(_pages);
  }

  void _flush() {
    if (_current.trim().isNotEmpty) {
      _pages.add(_current);
    }
    _current = '';
  }
}

class _BodyLayout {
  const _BodyLayout({
    required this.size,
    required this.typography,
    required this.textDirection,
  });

  final Size size;
  final _ShareTypography typography;
  final TextDirection textDirection;

  bool fits(String text) {
    if (text.isEmpty) {
      return true;
    }

    final painter = TextPainter(
      text: TextSpan(text: text, style: typography.bodyStyle),
      textDirection: textDirection,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: size.width);
    final fits = painter.height <= size.height;
    painter.dispose();
    return fits;
  }

  bool containsOversizedToken(String text) {
    for (final match in RegExp(r'\S+').allMatches(text)) {
      final painter = TextPainter(
        text: TextSpan(text: match.group(0), style: typography.bodyStyle),
        textDirection: textDirection,
        textScaler: TextScaler.noScaling,
        maxLines: 1,
      )..layout(maxWidth: double.infinity);
      final tooWide = painter.width > size.width;
      painter.dispose();
      if (tooWide) {
        return true;
      }
    }
    return false;
  }
}

class _ShareTypography {
  const _ShareTypography({
    required this.bodyFontSize,
    required this.horizontalInset,
    required this.verticalInset,
    required this.logoRegionHeight,
    required this.referenceRegionHeight,
    required this.footerRegionHeight,
    required this.pageMarkerRegionHeight,
  });

  final double bodyFontSize;
  final double horizontalInset;
  final double verticalInset;
  final double logoRegionHeight;
  final double referenceRegionHeight;
  final double footerRegionHeight;
  final double pageMarkerRegionHeight;

  TextStyle get bodyStyle => TextStyle(
    fontFamily: 'VerbumInter',
    fontSize: bodyFontSize,
    height: 1.35,
  );

  Size bodyBox(Size canvas, {required bool reservePageMarker}) => Size(
    math.max(1, canvas.width - (horizontalInset * 2)),
    math.max(
      1,
      canvas.height -
          (verticalInset * 2) -
          logoRegionHeight -
          referenceRegionHeight -
          footerRegionHeight -
          (reservePageMarker ? pageMarkerRegionHeight : 0),
    ),
  );
}

List<String> _splitParagraphs(String text) =>
    _splitAfterMatches(text, RegExp(r'\n(?:[ \t]*\n)+'));

List<String> _splitSentences(String text) =>
    _splitAfterMatches(text, RegExp(r'''[.!?…]+["'”»]*(?:[ \t\n]+|$)'''));

List<String> _splitWords(String text) =>
    _splitAfterMatches(text, RegExp(r'\s+'));

List<String> _splitAfterMatches(String text, RegExp separator) {
  final parts = <String>[];
  var start = 0;

  for (final match in separator.allMatches(text)) {
    final candidate = text.substring(start, match.end);
    if (candidate.trim().isNotEmpty) {
      parts.add(candidate);
      start = match.end;
    }
  }

  if (start < text.length) {
    parts.add(text.substring(start));
  }

  return parts.isEmpty ? <String>[text] : parts;
}
