import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../data/spiritual_paths_catalog.dart';
import '../screens/spiritual_path_detail_screen.dart';
import 'app_analytics_service.dart';

class DeepLinkService {
  DeepLinkService._();
  static final instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  Uri? _pending;

  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    if (_subscription != null) return;
    _navigatorKey = navigatorKey;
    _subscription = _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  void _handle(Uri uri) {
    final id = _pathId(uri);
    if (id == null) return;
    openSpiritualPath(id);
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
    final id = _pathId(uri);
    if (id != null) _open(navigator, id);
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
}
