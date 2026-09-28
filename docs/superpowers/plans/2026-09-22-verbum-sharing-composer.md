# Verbum Sharing Composer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single, offline-capable Verbum composer that turns supported verses and prayers into branded, readable PNG cards and can share, save, or copy them reliably.

**Architecture:** Screens pass an immutable `ShareContent` to a central composer. Pure domain services select a visual style and paginate the full text; one reusable `VerbumShareCard` renders both the preview and exported pages. Injected platform gateways isolate native sharing, gallery saving, clipboard access, and temporary-file cleanup so behavior can be tested without opening system UI.

**Tech Stack:** Flutter 3.47.4, Dart 3.13.3, Material 3, `share_plus` 13.3.0, `gal` 2.3.3, `path_provider`, Flutter widget/unit tests.

**Spec:** `docs/superpowers/specs/2026-09-22-verbum-sharing-composer-design.md`

## Global Constraints

- Preserve `applicationId = "com.ozcorp.verbum"`.
- Do not change the Google Play App Signing Key, upload-key configuration, `versionCode`, or `versionName`.
- Do not run `flutter build appbundle --release` and do not generate or publish a production AAB.
- The only public store URL is `https://play.google.com/store/apps/details?id=com.ozcorp.verbum`.
- Remove the generic App Store search URL from all spiritual-content sharing.
- Formats are exactly 1080 × 1080, 1080 × 1350, and 1080 × 1920; 4:5 is the default.
- Use only bundled Verbum backgrounds and the real `assets/icon/icon.png` logo.
- Never truncate content silently or reduce body text below the format's tested minimum; paginate instead.
- Community invitations, live-post sharing, and spiritual-path invitations remain outside this composer.
- All implementation tasks follow red-green-refactor and end with focused tests plus a commit.
- Before any implementation, confirm `backup/pre-share-composer-2026-09-22` still points to `7cd27db` and the verified bundle still exists at `D:\Documentos\OZCorp\Verbum_Backups\verbum-pre-share-composer-2026-09-22.bundle`.

## Review Focus

- A multi-paragraph prayer containing accents, curly quotes, blank lines, and one abnormally long word must reconstruct exactly after documented CRLF normalization and outer trimming; Task 2 pins this behavior.
- A user who cancels Android's share sheet must return to the composer without an error banner or success message; Tasks 4 and 5 pin this behavior.
- Failure while rendering page 2 of 3 must prevent sharing pages 1 and 3 as an incomplete set and must leave retry available; Tasks 4 and 5 pin this behavior.
- A 320 × 568 device at 200% text scaling must show all controls without overflow while exported cards retain fixed, readable typography; Task 5 pins this behavior.
- Offline execution must render and export with bundled logo/fonts and no network request; Tasks 3 and 6 pin this behavior.

---

## File Structure

### New production files

- `assets/fonts/Inter-Variable.ttf` — bundled Inter variable font from the official Google Fonts repository.
- `assets/fonts/PlayfairDisplay-Variable.ttf` — bundled Playfair Display variable font from the official Google Fonts repository.
- `assets/licenses/inter-OFL.txt` and `assets/licenses/playfair-display-OFL.txt` — required SIL Open Font License notices.
- `lib/features/sharing/domain/share_content.dart` — normalized immutable input and content kind.
- `lib/features/sharing/domain/share_card_format.dart` — the three output dimensions and labels.
- `lib/features/sharing/domain/share_visual_style.dart` — official Verbum visual styles and deterministic resolver.
- `lib/features/sharing/domain/share_page.dart` — one complete, numbered output page.
- `lib/features/sharing/application/share_paginator.dart` — lossless text measurement and pagination.
- `lib/features/sharing/application/share_message_builder.dart` — Play Store caption and copy text.
- `lib/features/sharing/application/share_export_coordinator.dart` — all-or-nothing rendering, file lifecycle, share/save/copy orchestration.
- `lib/features/sharing/data/share_platform_gateway.dart` — `share_plus`, `gal`, clipboard, and temporary-directory adapter.
- `lib/features/sharing/presentation/verbum_share_card.dart` — reusable card rendered in preview and PNG capture.
- `lib/features/sharing/presentation/share_composer_screen.dart` — responsive composer UI and interaction state.

### New tests

- `test/features/sharing/share_content_test.dart`
- `test/features/sharing/share_style_resolver_test.dart`
- `test/features/sharing/share_paginator_test.dart`
- `test/features/sharing/share_message_builder_test.dart`
- `test/features/sharing/verbum_share_card_test.dart`
- `test/features/sharing/share_export_coordinator_test.dart`
- `test/features/sharing/share_composer_screen_test.dart`
- `test/features/sharing/share_entry_points_test.dart`
- `test/features/sharing/goldens/share_card_light_4x5.png`
- `test/features/sharing/goldens/share_card_night_story.png`
- `test/features/sharing/goldens/share_card_tradition_square.png`

### Existing files changed

- `pubspec.yaml`, `pubspec.lock` — upgrade sharing, add gallery saving, bundle the real logo.
- `android/app/src/main/AndroidManifest.xml` — scoped legacy write permission only through API 29, as required by `gal`.
- `lib/services/share_service.dart` — central composer entry point, modern sharing API, explicit text fallback.
- Spiritual-content entry points listed in Tasks 6 and 7 — replace direct text sharing with `ShareContent`.

## Task 1: Domain contract, dependencies, and deterministic style selection

**Files:**
- Create: `lib/features/sharing/domain/share_content.dart`
- Create: `lib/features/sharing/domain/share_card_format.dart`
- Create: `lib/features/sharing/domain/share_visual_style.dart`
- Create: `lib/features/sharing/domain/share_page.dart`
- Create: `lib/features/sharing/application/share_message_builder.dart`
- Create: `test/features/sharing/share_content_test.dart`
- Create: `test/features/sharing/share_style_resolver_test.dart`
- Create: `test/features/sharing/share_message_builder_test.dart`
- Create: `assets/fonts/Inter-Variable.ttf`
- Create: `assets/fonts/PlayfairDisplay-Variable.ttf`
- Create: `assets/licenses/inter-OFL.txt`
- Create: `assets/licenses/playfair-display-OFL.txt`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Produces: `ShareContent`, `ShareContentKind`, `ShareCardFormat`, `ShareVisualStyle`, `ShareStyleResolver.resolve(ShareContent)`, `SharePage`, and `ShareMessageBuilder.build(ShareContent)`.
- Consumes: no new interfaces.

- [ ] **Step 1: Verify the backup before changing dependencies**

Run:

```powershell
git rev-list -n 1 backup/pre-share-composer-2026-09-22
git bundle verify D:\Documentos\OZCorp\Verbum_Backups\verbum-pre-share-composer-2026-09-22.bundle
```

Expected: the tag resolves to `7cd27db52614bfc446d09e70a5dc3a96cd55a7b4`, and the bundle reports `is okay`.

- [ ] **Step 2: Write failing domain and caption tests**

Cover these exact assertions:

```dart
expect(ShareCardFormat.portrait.pixelSize, const Size(1080, 1350));
expect(ShareCardFormat.square.pixelSize, const Size(1080, 1080));
expect(ShareCardFormat.story.pixelSize, const Size(1080, 1920));

expect(
  ShareStyleResolver.resolve(ShareContent(
    title: 'Oración de la noche',
    body: 'Señor, danos descanso.',
    kind: ShareContentKind.prayer,
    mood: ShareContentMood.night,
  )),
  ShareVisualStyle.contemplativeNight,
);

final message = ShareMessageBuilder.build(content);
expect(message, contains('https://play.google.com/store/apps/details?id=com.ozcorp.verbum'));
expect(message, isNot(contains('apps.apple.com')));
```

Also test value equality, trimmed constructor values, Catholic/evangelical metadata preservation, liturgical color selection only when provided, and an empty body throwing `ArgumentError`.

- [ ] **Step 3: Run the focused tests and confirm red state**

Run:

```powershell
flutter test test/features/sharing/share_content_test.dart test/features/sharing/share_style_resolver_test.dart test/features/sharing/share_message_builder_test.dart
```

Expected: compilation fails because the new domain files do not exist.

- [ ] **Step 4: Implement the immutable domain API**

Use these public contracts:

```dart
enum ShareContentKind { verse, prayer, psalm, mission, reflection }
enum ShareContentMood { neutral, hopeful, night, liturgical }
enum ShareTradition { catholic, evangelical, ecumenical }

@immutable
class ShareContent {
  factory ShareContent({
    required String title,
    required String body,
    required ShareContentKind kind,
    String? reference,
    ShareTradition? tradition,
    ShareContentMood mood = ShareContentMood.neutral,
    Color? liturgicalColor,
    String? sourceLabel,
    String? shareCaption,
  }) {
    final normalizedBody = body.trim();
    if (normalizedBody.isEmpty) {
      throw ArgumentError.value(body, 'body', 'No puede estar vacío');
    }
    return ShareContent._(
      title: title.trim(),
      body: normalizedBody,
      kind: kind,
      reference: reference?.trim(),
      tradition: tradition,
      mood: mood,
      liturgicalColor: liturgicalColor,
      sourceLabel: sourceLabel?.trim(),
      shareCaption: shareCaption?.trim(),
    );
  }

  const ShareContent._({
    required this.title,
    required this.body,
    required this.kind,
    required this.reference,
    required this.tradition,
    required this.mood,
    required this.liturgicalColor,
    required this.sourceLabel,
    required this.shareCaption,
  });

  final String title;
  final String body;
  final ShareContentKind kind;
  final String? reference;
  final ShareTradition? tradition;
  final ShareContentMood mood;
  final Color? liturgicalColor;
  final String? sourceLabel;
  final String? shareCaption;
}

enum ShareCardFormat { square, portrait, story }

extension ShareCardFormatGeometry on ShareCardFormat {
  Size get pixelSize => switch (this) {
        ShareCardFormat.square => const Size(1080, 1080),
        ShareCardFormat.portrait => const Size(1080, 1350),
        ShareCardFormat.story => const Size(1080, 1920),
      };

  String get label => switch (this) {
        ShareCardFormat.square => '1:1',
        ShareCardFormat.portrait => '4:5',
        ShareCardFormat.story => '9:16',
      };
}

enum ShareVisualStyle { sereneLight, contemplativeNight, livingTradition }

abstract final class ShareStyleResolver {
  static ShareVisualStyle resolve(ShareContent content) {
    if (content.mood == ShareContentMood.night) {
      return ShareVisualStyle.contemplativeNight;
    }
    if (content.mood == ShareContentMood.liturgical ||
        content.liturgicalColor != null ||
        content.kind == ShareContentKind.prayer ||
        content.kind == ShareContentKind.psalm) {
      return ShareVisualStyle.livingTradition;
    }
    return ShareVisualStyle.sereneLight;
  }
}

@immutable
class SharePage {
  const SharePage({required this.body, required this.index, required this.total});
  final String body;
  final int index;
  final int total;
}
```

`ShareMessageBuilder` must expose the Play Store URL as a public testable constant and produce title/reference/body plus a short Verbum invitation and only that URL.

- [ ] **Step 5: Update platform dependencies and bundled assets**

Change `pubspec.yaml` to:

```yaml
share_plus: ^13.3.0
gal: ^2.3.3
```

Download and retain the official SIL OFL files from Google Fonts using exact, auditable URLs:

```powershell
New-Item -ItemType Directory -Path assets/fonts -Force | Out-Null
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/google/fonts/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf' -OutFile 'assets/fonts/Inter-Variable.ttf'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/google/fonts/main/ofl/playfairdisplay/PlayfairDisplay%5Bwght%5D.ttf' -OutFile 'assets/fonts/PlayfairDisplay-Variable.ttf'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/google/fonts/main/ofl/inter/OFL.txt' -OutFile 'assets/licenses/inter-OFL.txt'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/google/fonts/main/ofl/playfairdisplay/OFL.txt' -OutFile 'assets/licenses/playfair-display-OFL.txt'
```

Add `assets/icon/icon.png` under `flutter/assets` and register both local font families:

```yaml
fonts:
  - family: VerbumInter
    fonts:
      - asset: assets/fonts/Inter-Variable.ttf
  - family: VerbumPlayfair
    fonts:
      - asset: assets/fonts/PlayfairDisplay-Variable.ttf
```

Add only this Android permission before `<application>`:

```xml
<uses-permission
    android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29" />
```

Do not add broad storage permissions for newer Android versions and do not add `requestLegacyExternalStorage` because Verbum is not creating a named custom album in this delivery.

Run `flutter pub get` and inspect `flutter pub deps` for exactly one resolved `share_plus` and one `gal` tree.

- [ ] **Step 6: Run focused tests and static analysis**

Run:

```powershell
flutter test test/features/sharing/share_content_test.dart test/features/sharing/share_style_resolver_test.dart test/features/sharing/share_message_builder_test.dart
dart analyze lib/features/sharing
```

Expected: all focused tests pass and the new sharing module reports no analyzer issues. Existing entry points are migrated in Tasks 6–8 before the full-project analyzer gate.

- [ ] **Step 7: Commit the foundation**

```powershell
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml assets/fonts assets/licenses lib/features/sharing test/features/sharing
git commit -m "feat: add sharing composer domain"
```

## Task 2: Lossless, measured pagination

**Files:**
- Create: `lib/features/sharing/application/share_paginator.dart`
- Create: `test/features/sharing/share_paginator_test.dart`

**Interfaces:**
- Consumes: `ShareContent`, `ShareCardFormat`, and `SharePage` from Task 1.
- Produces: `SharePaginator.paginate(ShareContent content, {required ShareCardFormat format, TextDirection textDirection = TextDirection.ltr}) -> List<SharePage>`.

- [ ] **Step 1: Write failing tests for all pagination invariants**

Use representative content and assert:

```dart
final pages = paginator.paginate(longPrayer, format: ShareCardFormat.portrait);
expect(pages.length, greaterThan(1));
expect(
  pages.map((page) => page.index),
  orderedEquals(List<int>.generate(pages.length, (index) => index + 1)),
);
expect(pages.every((page) => page.total == pages.length), isTrue);
expect(pages.map((page) => page.body).join(), longPrayer.body.trim());
expect(pages.every((page) => page.body.trim().isNotEmpty), isTrue);
```

Add cases for a short verse, blank lines, Spanish accents, curly quotes, punctuation, a 120-character unbroken token, leading/trailing whitespace, and each of the three formats. Explicitly assert that an oversized prayer creates more pages for square than portrait when the measured area requires it.

- [ ] **Step 2: Run the paginator test and confirm it fails**

Run:

```powershell
flutter test test/features/sharing/share_paginator_test.dart
```

Expected: failure because `SharePaginator` is undefined.

- [ ] **Step 3: Implement measurement without content loss**

Implement the public class with internal helpers that:

1. normalize only outer whitespace and CRLF to LF;
2. preserve paragraph boundaries;
3. greedily add paragraphs while a `TextPainter` fits the format's safe body box;
4. split an oversized paragraph by sentence boundaries;
5. split an oversized sentence by word boundaries;
6. place a single unbroken token on its own page rather than deleting characters;
7. rerun measurement after page-number space is known;
8. assign final `index` and `total` values.

Use one typography table keyed by `ShareCardFormat`; minimum exported body sizes must be 42 px for square, 40 px for portrait, and 38 px for story at target resolution. Reserve fixed regions for the logo, reference, footer, and page marker.

- [ ] **Step 4: Run pagination tests and the domain suite**

Run:

```powershell
flutter test test/features/sharing/share_paginator_test.dart test/features/sharing/share_content_test.dart
```

Expected: all tests pass, including exact reconstruction.

- [ ] **Step 5: Commit pagination**

```powershell
git add lib/features/sharing/application/share_paginator.dart test/features/sharing/share_paginator_test.dart
git commit -m "feat: paginate shared spiritual content"
```

## Task 3: Branded card rendering

**Files:**
- Create: `lib/features/sharing/presentation/verbum_share_card.dart`
- Create: `test/features/sharing/verbum_share_card_test.dart`
- Create after visual review: `test/features/sharing/goldens/share_card_light_4x5.png`
- Create after visual review: `test/features/sharing/goldens/share_card_night_story.png`
- Create after visual review: `test/features/sharing/goldens/share_card_tradition_square.png`

**Interfaces:**
- Consumes: `ShareContent`, `SharePage`, `ShareCardFormat`, and `ShareVisualStyle`.
- Produces: `VerbumShareCard(content:, page:, format:, style:)`, used unchanged by preview and export.

- [ ] **Step 1: Write failing widget and golden tests**

Assert the widget contains:

```dart
expect(find.byKey(const Key('share-card-logo')), findsOneWidget);
expect(find.byKey(const Key('share-card-body')), findsOneWidget);
expect(find.text('Salmo 23, 1'), findsOneWidget);
expect(find.text('2 de 3'), findsOneWidget);
expect(find.textContaining('apps.apple.com'), findsNothing);
```

Pump each format in a fixed `SizedBox` using its aspect ratio. Add semantic assertions for the logo, body, reference, and page count. Add one test that temporarily blocks all network through `HttpOverrides` and still pumps successfully.

- [ ] **Step 2: Run the card test and confirm red state**

Run:

```powershell
flutter test test/features/sharing/verbum_share_card_test.dart
```

Expected: compilation fails because `VerbumShareCard` does not exist.

- [ ] **Step 3: Implement the three official Verbum environments**

Build `VerbumShareCard` from Flutter widgets, not a second canvas-only design. Use:

- `Image.asset('assets/icon/icon.png', key: Key('share-card-logo'))`;
- bundled `VerbumPlayfair` for spiritual text and bundled `VerbumInter` for metadata, with no runtime font download;
- `AppColors.primary`, `primaryDark`, `secondary`, `surface`, and explicit approved gradient stops;
- a fixed `AspectRatio` derived from `ShareCardFormat`;
- an internal `FittedBox(fit: BoxFit.contain)` only for scaling the whole fixed design into the preview, never for shrinking body text independently;
- decorative circles/lines created locally with gradients and borders;
- no URL or QR inside the image.

The widget must accept a fixed logical design size proportional to the output size, so a `RepaintBoundary` capture produces the same composition as the preview.

- [ ] **Step 4: Generate and inspect the three goldens**

Run:

```powershell
flutter test --update-goldens test/features/sharing/verbum_share_card_test.dart
flutter test test/features/sharing/verbum_share_card_test.dart
```

Open all three PNG files and verify the real logo, accents, reference, page marker, readable text, and safe margins. If a golden reveals clipping or weak contrast, fix the widget and regenerate before proceeding.

- [ ] **Step 5: Commit the visual card**

```powershell
git add lib/features/sharing/presentation/verbum_share_card.dart test/features/sharing/verbum_share_card_test.dart test/features/sharing/goldens
git commit -m "feat: render branded Verbum share cards"
```

## Task 4: Native platform gateway and all-or-nothing export

**Files:**
- Create: `lib/features/sharing/data/share_platform_gateway.dart`
- Create: `lib/features/sharing/application/share_export_coordinator.dart`
- Create: `test/features/sharing/share_export_coordinator_test.dart`

**Interfaces:**
- Consumes: PNG bytes generated from `VerbumShareCard`, `ShareMessageBuilder`, and `ShareContent`.
- Produces: `SharePlatformGateway`, `SystemSharePlatformGateway`, `ShareExportCoordinator`, `ShareExportResult`, and `ShareExportFailure`.

- [ ] **Step 1: Write failing coordinator tests using a fake gateway**

Define a fake that records calls, then test:

```dart
final result = await coordinator.share(
  content: content,
  renderPages: () async => [png1, png2, png3],
);
expect(fakeGateway.sharedPaths, hasLength(3));
expect(fakeGateway.sharedText, contains(ShareMessageBuilder.playStoreUrl));
expect(result, ShareExportResult.shared);
```

Also pin: dismissed share returns `dismissed`; renderer failure on page 2 makes zero share calls; saving calls `Gal.putImage` once per complete page through the fake; clipboard receives text/reference/link; temporary files use unique names; cleanup runs after success, dismissal, and exception; cleanup failure does not replace the primary result.

- [ ] **Step 2: Run the coordinator test and confirm red state**

Run:

```powershell
flutter test test/features/sharing/share_export_coordinator_test.dart
```

Expected: failure because coordinator and gateway types are absent.

- [ ] **Step 3: Implement the injected platform boundary**

Use this contract:

```dart
enum NativeShareStatus { success, dismissed, unavailable }

abstract interface class SharePlatformGateway {
  Future<Directory> temporaryDirectory();
  Future<NativeShareStatus> shareFiles(List<String> paths, String text);
  Future<NativeShareStatus> shareText(String text);
  Future<void> saveImage(String path);
  Future<void> copyText(String text);
  Future<void> deleteFile(String path);
}
```

`SystemSharePlatformGateway.shareFiles` must call:

```dart
final result = await SharePlus.instance.share(
  ShareParams(
    files: paths.map(XFile.new).toList(growable: false),
    text: text,
    subject: 'Verbum',
    title: 'Compartir desde Verbum',
  ),
);
```

Map `ShareResultStatus.dismissed` to `NativeShareStatus.dismissed` without throwing. `saveImage` calls `Gal.putImage(path)` without a custom album to avoid Android 10 legacy-album configuration. `copyText` uses `Clipboard.setData`.

- [ ] **Step 4: Implement atomic coordination and typed failures**

Expose:

```dart
typedef SharePageRenderer = Future<List<Uint8List>> Function();

class ShareExportCoordinator {
  const ShareExportCoordinator(this.gateway);
  final SharePlatformGateway gateway;

  Future<ShareExportResult> share({
    required ShareContent content,
    required SharePageRenderer renderPages,
  });

  Future<ShareExportResult> save({
    required ShareContent content,
    required SharePageRenderer renderPages,
  });

  Future<void> copy(ShareContent content);
}

enum ShareExportResult { shared, saved, dismissed, copied }
enum ShareExportStage { render, write, share, save }

class ShareExportFailure implements Exception {
  const ShareExportFailure(this.stage, this.userMessage, [this.cause]);
  const ShareExportFailure.render([Object? cause])
      : this(
          ShareExportStage.render,
          'No pudimos crear la tarjeta.',
          cause,
        );

  final ShareExportStage stage;
  final String userMessage;
  final Object? cause;
}
```

Render every page before writing or sharing any path. If rendering or writing fails, delete anything created and throw a typed `ShareExportFailure` containing an end-user-safe message. Always clean temporary files in `finally` after native sharing returns.

- [ ] **Step 5: Run gateway tests and analyzer**

Run:

```powershell
flutter test test/features/sharing/share_export_coordinator_test.dart
dart analyze lib/features/sharing
```

Expected: all tests pass and no deprecated `Share.share*` API appears in the new module.

- [ ] **Step 6: Commit export infrastructure**

```powershell
git add lib/features/sharing/data lib/features/sharing/application/share_export_coordinator.dart test/features/sharing/share_export_coordinator_test.dart
git commit -m "feat: export and save Verbum share cards"
```

## Task 5: Responsive composer screen and capture loop

**Files:**
- Create: `lib/features/sharing/presentation/share_composer_screen.dart`
- Create: `test/features/sharing/share_composer_screen_test.dart`

**Interfaces:**
- Consumes: domain types, `SharePaginator`, `VerbumShareCard`, and `ShareExportCoordinator`.
- Produces: `ShareComposerScreen(content:, coordinator:)`.

- [ ] **Step 1: Write failing responsive and interaction tests**

Provide a fake coordinator and test:

- opening defaults to `ShareCardFormat.portrait`;
- `ShareStyleResolver` selects the initial style;
- tapping square/story repaginates and updates semantics;
- swiping style changes only presentation, not body/reference;
- page indicator appears only for multiple pages;
- share/save disable all actions while work is active;
- share dismissal closes progress without showing an error;
- typed export failure displays `No pudimos crear la tarjeta` and a `Reintentar` action;
- copy shows `Texto y enlace copiados`;
- closing returns without side effects;
- 320 × 568 at `TextScaler.linear(2)` produces no exception or overflow;
- dark mode produces no exception and preserves the chosen exported style.

- [ ] **Step 2: Run the composer test and confirm red state**

Run:

```powershell
flutter test test/features/sharing/share_composer_screen_test.dart
```

Expected: compilation fails because the screen is missing.

- [ ] **Step 3: Implement the approved Verbum UI**

Build a full-screen route using `VerbumAmbientBackground`, `SafeArea`, Playfair headings, Inter controls, and `VerbumHeaderButton`. The vertical order is:

1. compact editorial header (`CREA Y COMPARTE`, `Comparte la Palabra`);
2. flexible preview surface containing one `RepaintBoundary`;
3. small page indicator when needed;
4. environment thumbnails;
5. segmented 1:1 / 4:5 / 9:16 selector;
6. floating action dock: save, primary share, overflow menu containing copy.

Use `LayoutBuilder` and `SingleChildScrollView` only when height is constrained. Keep actions within `SafeArea` and cap text scaling for compact control labels while leaving accessibility semantics intact.

- [ ] **Step 4: Implement exact PNG capture from the visible card**

Give the `RepaintBoundary` a stable `GlobalKey`. Implement:

```dart
Future<Uint8List> _captureCurrentPage() async {
  await WidgetsBinding.instance.endOfFrame;
  final boundary = _captureKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;
  final target = _format.pixelSize;
  final ratio = target.width / boundary.size.width;
  final image = await boundary.toImage(pixelRatio: ratio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw const ShareExportFailure.render();
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
```

For multiple pages, show a modal progress layer, render each page sequentially under it, wait for `endOfFrame`, capture, and restore the original page in `finally`. Verify the returned PNG dimensions by decoding each captured image before it reaches the coordinator; any mismatch fails the whole set.

- [ ] **Step 5: Run responsive tests and inspect a debug capture**

Run:

```powershell
flutter test test/features/sharing/share_composer_screen_test.dart
flutter test test/features/sharing/verbum_share_card_test.dart
```

Add a test-only decode assertion for exact 1080 × 1350 output from the 4:5 capture path.

- [ ] **Step 6: Commit the composer**

```powershell
git add lib/features/sharing/presentation/share_composer_screen.dart test/features/sharing/share_composer_screen_test.dart
git commit -m "feat: add Verbum sharing composer UI"
```

## Task 6: Facade and Scripture/Hoy entry points

**Files:**
- Modify: `lib/services/share_service.dart`
- Modify: `lib/bible/ui/bible_verses_screen.dart`
- Modify: `lib/screens/favorites_screen.dart`
- Modify: `lib/screens/daily_missions_flow_screen.dart`
- Modify: `lib/screens/mission_read_screen.dart`
- Modify: `lib/screens/spiritual_path_day_screen.dart`
- Create: `test/features/sharing/share_entry_points_test.dart`

**Interfaces:**
- Consumes: `ShareComposerScreen` and `ShareContent`.
- Produces: `ShareService.openComposer(BuildContext context, ShareContent content)` and modern `ShareService.shareTextFallback(ShareContent content)`.

- [ ] **Step 1: Write failing facade and Scripture/Hoy entry tests**

Test that `ShareService.openComposer` pushes one `ShareComposerScreen` with the exact content. Pump representative Bible, favorite, and mission entry points, invoke share, and assert:

```dart
final composer = tester.widget<ShareComposerScreen>(
  find.byType(ShareComposerScreen),
);
expect(composer.content.kind, ShareContentKind.verse);
expect(composer.content.reference, contains('RV1909'));
```

For mission content assert `ShareContentKind.mission`; for daily Scripture assert `ShareContentKind.verse`. Verify title/body/reference are not swapped.

- [ ] **Step 2: Run entry tests and confirm red state**

Run:

```powershell
flutter test test/features/sharing/share_entry_points_test.dart
```

Expected: tests fail because the old text-sharing callbacks remain.

- [ ] **Step 3: Replace the legacy service implementation**

Delete the old canvas renderer, delayed five-minute deletion, and App Store search constant. Keep a narrow facade:

```dart
abstract final class ShareService {
  static Future<void> openComposer(
    BuildContext context,
    ShareContent content,
  ) => Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ShareComposerScreen(content: content),
        ),
      );

  static Future<NativeShareStatus> shareTextFallback(
    ShareContent content,
  ) => SystemSharePlatformGateway().shareText(
        ShareMessageBuilder.build(content),
      );
}
```

Use `SharePlus.instance.share(ShareParams(...))` for the explicit fallback; do not retain deprecated static `Share.share` calls in this service.

- [ ] **Step 4: Migrate Bible, favorites, missions, and daily path Scripture**

Map content as follows:

- Bible selections and favorites: `kind: verse`, preserve selected reference and `RV1909` in `reference` or `sourceLabel`.
- Receive-the-Word mission: `kind: verse`.
- Other Today missions: `kind: mission`.
- Spiritual path Scripture: `kind: verse`; do not migrate the separate path invitation.

All callbacks must pass their live `BuildContext`; no screen should import `share_plus` after this migration unless it owns an excluded invitation flow.

- [ ] **Step 5: Run entry-point and existing reader tests**

Run:

```powershell
flutter test test/features/sharing/share_entry_points_test.dart test/prayer_reading_experience_test.dart test/content_and_bible_test.dart
dart analyze lib/features/sharing
```

Expected: all tests pass, no analyzer issues.

- [ ] **Step 6: Commit Scripture/Hoy integration**

```powershell
git add lib/services/share_service.dart lib/bible/ui/bible_verses_screen.dart lib/screens/favorites_screen.dart lib/screens/daily_missions_flow_screen.dart lib/screens/mission_read_screen.dart lib/screens/spiritual_path_day_screen.dart test/features/sharing/share_entry_points_test.dart
git commit -m "feat: compose shared Scripture and missions"
```

## Task 7: Prayer and spiritual-reader entry points

**Files:**
- Modify: `lib/widgets/prayer_reading_experience.dart`
- Modify: `lib/screens/category_prayers_screen.dart`
- Modify: `lib/screens/emotion_passage_read_screen.dart`
- Modify: `lib/screens/intention_prayer_read_screen.dart`
- Modify: `lib/screens/novena_screen.dart`
- Modify: `lib/screens/prayer_read_screen.dart`
- Modify: `lib/screens/reading_screen.dart`
- Modify: `lib/screens/traditional_prayer_detail_screen.dart`
- Modify: `lib/screens/traditional_prayer_screen.dart`
- Modify: `test/features/sharing/share_entry_points_test.dart`
- Modify: `test/traditional_prayers_visual_refresh_test.dart`
- Modify: `test/prayer_reading_experience_test.dart`

**Interfaces:**
- Consumes: `ShareService.openComposer` and domain contracts.
- Produces: no new public interface; completes spiritual-content migration.

- [ ] **Step 1: Extend failing entry tests for every prayer family**

Add cases for generic, traditional, intention, emotion, category, novena, psalm/reading-wrapper, and `PrayerTextReadingScreen`. Assert:

- prayer content uses `ShareContentKind.prayer`;
- psalm/biblical prayer content uses `ShareContentKind.psalm` or `verse` as appropriate;
- Catholic and evangelical traditions remain distinct when known;
- AI-generated provenance is not displayed as a fake biblical reference;
- title, body, and genuine verse reference survive unchanged;
- long prayer entry opens the composer instead of immediately opening the native share sheet.

- [ ] **Step 2: Run the expanded tests and confirm failures**

Run:

```powershell
flutter test test/features/sharing/share_entry_points_test.dart test/traditional_prayers_visual_refresh_test.dart test/prayer_reading_experience_test.dart
```

Expected: failures identify each remaining legacy callback.

- [ ] **Step 3: Migrate the shared reader wrappers first**

Change the default sharing behavior in `PrayerTextReadingScreen` and `ReadingScreen` to call `ShareService.openComposer(context, ShareContent(...))`. Preserve externally supplied `onShare` callbacks so callers with excluded custom flows do not break.

Map `ContentProvenance` only to trustworthy metadata: `translation` may appear in `reference`/`sourceLabel`; never print internal values such as `aiGenerated` or `unverified` on the exported card.

- [ ] **Step 4: Migrate individual prayer screens**

Replace each old call with `ShareContent` and the correct tradition where data already supplies it. Do not infer a tradition from prayer wording. If a screen lacks tradition metadata, leave `tradition` null and use the neutral prayer style resolver path.

For novenas, keep `Novena de Navidad - Día N` as title and the section title as reference. For prayers with a real `verseRef`, keep it as reference; otherwise use the prayer title without manufacturing a citation.

- [ ] **Step 5: Run all focused and legacy visual tests**

Run:

```powershell
flutter test test/features/sharing test/prayer_reading_experience_test.dart test/traditional_prayers_visual_refresh_test.dart test/content_and_bible_test.dart
dart analyze lib/features/sharing
```

Expected: all pass and no included spiritual reader calls deprecated share APIs.

- [ ] **Step 6: Commit prayer integration**

```powershell
git add lib/widgets/prayer_reading_experience.dart lib/screens/category_prayers_screen.dart lib/screens/emotion_passage_read_screen.dart lib/screens/intention_prayer_read_screen.dart lib/screens/novena_screen.dart lib/screens/prayer_read_screen.dart lib/screens/reading_screen.dart lib/screens/traditional_prayer_detail_screen.dart lib/screens/traditional_prayer_screen.dart test/features/sharing/share_entry_points_test.dart test/traditional_prayers_visual_refresh_test.dart test/prayer_reading_experience_test.dart
git commit -m "feat: compose shared prayers and reflections"
```

## Task 8: Independent review, defect correction, and release-safe verification

**Files:**
- Modify only files implicated by review findings.
- Create: `docs/testing/2026-09-22-sharing-composer-manual-checklist.md`

**Interfaces:**
- Consumes: the complete composer and all migrated entry points.
- Produces: a verified debug-ready implementation and a manual device checklist; no production bundle.

- [ ] **Step 1: Run an independent subagent review of the whole diff**

Give a fresh reviewer the spec, this plan, and `git diff backup/pre-share-composer-2026-09-22..HEAD`. Require findings ranked by severity for: content loss, incorrect tradition/reference mapping, render-size mismatch, temporary-file leaks, permission regressions, direct deprecated sharing, overflow, and unrelated changes.

- [ ] **Step 2: Convert each valid finding into a failing regression test**

For every confirmed defect, add the smallest failing unit/widget test in the owning task's test file. Run that individual test and record the expected failure before changing production code. If a finding is invalid, document the concrete code/test evidence and make no speculative change.

- [ ] **Step 3: Fix confirmed defects and rerun focused tests**

Implement only the minimal correction for each failing regression. Run the affected test file after every correction and commit logically related fixes with messages such as:

```powershell
git commit -m "fix: preserve complete prayer pages when sharing"
```

- [ ] **Step 4: Prove legacy references are gone except explicit exclusions**

Run:

```powershell
rg -n "apps\.apple\.com/us/search|Share\.shareXFiles|ShareService\.shareAsImage|ShareService\.shareAsText" lib test
rg -n "Share\.share\(" lib
```

Expected: the first command has no matches. Matches from the second command are permitted only in community invitations, live-post sharing, or spiritual-path invitations; migrate those calls to `SharePlus.instance.share(ShareParams(...))` without routing them through the card composer.

- [ ] **Step 5: Run full automated verification**

Run:

```powershell
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Expected: formatter clean, analyzer clean, all tests pass, and debug APK builds successfully. Do not run an app bundle or release build.

- [ ] **Step 6: Perform targeted device checks and record them**

Create `docs/testing/2026-09-22-sharing-composer-manual-checklist.md` with checkboxes and observed results for:

- one short verse and one three-page prayer;
- WhatsApp multi-image share;
- Instagram selector for 4:5 and 9:16;
- Android generic sharesheet;
- gallery save and visible result;
- copy/paste caption and Play Store link;
- share cancellation;
- airplane-mode rendering;
- 320 px-equivalent device and a large device;
- light/dark mode;
- verification that `versionCode`, `versionName`, `applicationId`, signing files, and release artifacts are unchanged.

Items requiring a physical app target must be recorded as `REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO`; automated verification may not be labeled as proof of an unperformed manual check.

- [ ] **Step 7: Run a final fresh whole-branch reviewer**

Ask a second reviewer to inspect the final diff plus test output. The reviewer must explicitly answer whether every acceptance criterion in the spec is implemented, whether any unrelated functionality changed, and whether the branch is safe for continued development without generating a production AAB.

- [ ] **Step 8: Commit verification documentation**

```powershell
git add docs/testing/2026-09-22-sharing-composer-manual-checklist.md
git commit -m "docs: add sharing composer verification checklist"
```

Do not push until the user asks for a repository update or the entire planned feature has been reviewed and accepted.
