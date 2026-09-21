import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../bible/data/bible_db.dart';
import '../bible/domain/bible_book_info.dart';
import '../bible/ui/bible_books_screen.dart';
import '../bible/ui/bible_verses_screen.dart';
import '../data/spiritual_paths_catalog.dart';
import '../screens/spiritual_path_detail_screen.dart';
import 'app_analytics_service.dart';
import 'bible_deep_link.dart';

class DeepLinkService {
  DeepLinkService._();
  static final instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  Uri? _pending;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_subscription != null) return;
    _navigatorKey = navigatorKey;
    final initial = await _appLinks.getInitialLink();
    if (initial != null) await _handle(initial);
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri),
      onError: (_) {},
    );
  }

  Future<void> _handle(Uri uri) async {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      _pending = uri;
      WidgetsBinding.instance.addPostFrameCallback((_) => flushPending());
      return;
    }

    if (uri.scheme == 'verbum' && uri.host == 'biblia') {
      final target = parseBibleDeepLink(uri);
      if (target == null) {
        _openBibleFallback(navigator);
        return;
      }
      try {
        final verse = await BibleDb.instance.getVerse(
          target.bookId,
          target.chapter,
          target.verse,
        );
        if (verse == null) {
          _openBibleFallback(navigator);
          return;
        }
        _openBibleTarget(navigator, target);
      } catch (_) {
        _openBibleFallback(navigator);
      }
      return;
    }

    final id = _pathId(uri);
    if (id == null) return;
    final exists = SpiritualPathsCatalog.paths.any((path) => path.id == id);
    if (exists) _open(navigator, id);
  }

  void openSpiritualPath(String id) {
    final exists = SpiritualPathsCatalog.paths.any((path) => path.id == id);
    if (!exists) return;
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      _pending = Uri(scheme: 'verbum', host: 'camino', path: id);
      WidgetsBinding.instance.addPostFrameCallback((_) => flushPending());
      return;
    }
    _open(navigator, id);
  }

  void flushPending() {
    final uri = _pending;
    final navigator = _navigatorKey?.currentState;
    if (uri == null || navigator == null) return;
    _pending = null;
    _handle(uri);
  }

  String? _pathId(Uri uri) {
    if (uri.scheme == 'verbum' &&
        uri.host == 'camino' &&
        uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'camino') {
      return uri.pathSegments[1];
    }
    return null;
  }

  void _open(NavigatorState navigator, String id) {
    AppAnalyticsService.event(
      'spiritual_path_invite_opened',
      parameters: {'path_id': id},
    );
    navigator.push(
      MaterialPageRoute(
        builder: (_) =>
            SpiritualPathDetailScreen(path: SpiritualPathsCatalog.byId(id)),
      ),
    );
  }

  void _openBibleTarget(NavigatorState navigator, BibleDeepLinkTarget target) {
    final book = bibleBookById(target.bookId)!;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => BibleVersesScreen(
          bookId: target.bookId,
          bookName: book.name,
          chapter: target.chapter,
          initialVerse: target.verse,
        ),
      ),
    );
  }

  void _openBibleFallback(NavigatorState navigator) {
    navigator.push(MaterialPageRoute(builder: (_) => const BibleBooksScreen()));
  }
}
