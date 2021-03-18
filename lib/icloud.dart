import 'dart:async';

import 'package:flutter/services.dart';

class ICloud {
  static const MethodChannel _channel = const MethodChannel('icloud');
  static const EventChannel _eventChannel =
      const EventChannel('icloud/event/availability');

  static Future<bool> get available async {
    return await _channel.invokeMethod('isAvailable');
  }

  static Future<Stream<bool>> watchAvailability() async {
    await _channel.invokeMethod('watchAvailability');
    return _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is bool)
        .map((event) => event as bool);
  }
}
