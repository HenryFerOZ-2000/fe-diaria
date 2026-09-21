import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/services/widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ozcorp.verbum/widget-test');

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('solicita fijación cuando Android la soporta', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'isPinWidgetSupported') return true;
          if (call.method == 'requestPinWidget') return true;
          return false;
        });
    final service = WidgetService.forTesting(channel: channel, isAndroid: true);

    expect(await service.requestPinWidget(), WidgetPinRequestResult.requested);
    expect(calls, ['isPinWidgetSupported', 'requestPinWidget']);
  });

  test('devuelve unsupported sin intentar fijar', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => false);
    final service = WidgetService.forTesting(channel: channel, isAndroid: true);

    expect(
      await service.requestPinWidget(),
      WidgetPinRequestResult.unsupported,
    );
  });

  test('plataforma no Android no invoca el canal', () async {
    final service = WidgetService.forTesting(
      channel: channel,
      isAndroid: false,
    );

    expect(
      await service.requestPinWidget(),
      WidgetPinRequestResult.unsupported,
    );
    expect(await service.hasWidgets(), isFalse);
  });
}
