import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icloud/icloud.dart';

void main() {
  const MethodChannel channel = MethodChannel('icloud');
  const MethodChannel eventChannel = MethodChannel('icloud/event/availability');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return true;
    });
    eventChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
          "icloud/event/availability",
          const StandardMethodCodec().encodeSuccessEnvelope(true),
              (ByteData data) {});
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
    eventChannel.setMethodCallHandler(null);
  });

  test('available', () async {
    expect(await ICloud.available, true);
  });

  test('watchAvailability', () async {
    var stream = await ICloud.watchAvailability();
    expect(await stream.first, true);
  });
}
