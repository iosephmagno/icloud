import 'dart:async';

import 'package:flutter/services.dart';

/// A function-type alias takes a stream as argument and returns void
typedef StreamHandler<T> = void Function(Stream<T>);

class ICloudMetadata {
  final String url;

  final int? size;

  final DateTime? modifiedDate;

  ICloudMetadata(this.url, this.size, this.modifiedDate);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ICloudMetadata &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          size == other.size &&
          modifiedDate == other.modifiedDate;

  @override
  int get hashCode => url.hashCode ^ size.hashCode ^ modifiedDate.hashCode;

  @override
  String toString() {
    return 'ICloudMetadata{url: $url, size: $size, modifiedDate: $modifiedDate}';
  }
}

/// The main class for the plugin. Contains all the API's needed for listing,
/// uploading, downloading and deleting files.
class ICloud {
  ICloud._();

  static final ICloud _instance = ICloud._();
  static const MethodChannel _channel = const MethodChannel('icloud');
  static const EventChannel _availabilityEventChannel =
      const EventChannel('icloud/event/availability');
  static const EventChannel _listEventChannel =
      const EventChannel('icloud/event/list');

  static Future<bool?> get available async {
    return await _channel.invokeMethod('isAvailable');
  }

  static Future<Stream<bool?>> watchAvailability() async {
    await _channel.invokeMethod('watchAvailability');
    return _availabilityEventChannel
        .receiveBroadcastStream()
        .where((event) => event is bool)
        .map((event) => event as bool?);
  }

  /// Get an instance of the ICloudStorage class
  ///
  /// [containerId] is the iCloud Container ID created in the apple developer
  /// account
  ///
  /// Returns a future completing with an instance of the ICloudStorage class
  static Future<ICloud> getInstance(String containerId) async {
    await _channel.invokeMethod('initialize', {
      'containerId': containerId,
    });
    return _instance;
  }

  /// Lists files from the iCloud container directory, which lives on the device
  ///
  /// Returns a future completing with a list of file names
  Future<List<ICloudMetadata>> listFiles() async {
    var list = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'listFiles', {'watchUpdate': false});
    return list
            ?.map((map) => map.cast<String, dynamic>())
            .map(_toMetadata)
            .toList() ??
        [];
  }

  /// Lists files from the iCloud container directory, which lives on the
  /// device. Also watches for updates.
  ///
  /// Returns a future completing with a stream of lists of the file names
  Future<Stream<List<ICloudMetadata>>> watchFiles() async {
    await _channel.invokeMethod('listFiles', {'watchUpdate': true});
    return _listEventChannel
        .receiveBroadcastStream()
        .where((event) => event is List)
        .map<List<ICloudMetadata>>((event) => (event as List<dynamic>)
            .map((e) => e as Map<dynamic, dynamic>)
            .map((map) => map.cast<String, dynamic>())
            .map(_toMetadata)
            .toList());
  }

  ICloudMetadata _toMetadata(map) => ICloudMetadata(
        map['url'] as String,
        map['size'] as int?,
        map['modifiedDate'] != null
            ? DateTime.parse(map['modifiedDate'] as String)
            : null,
      );

  /// Start to upload a file from a local path to iCloud
  ///
  /// [filePath] is the full path of the local file
  ///
  /// [destinationFileName] is the name of the file you want to store in iCloud.
  /// If not specified, the name of the local file is used.
  ///
  /// [onProgress] is an optional callback to to track the progress of the
  /// upload. It takes a Stream<double> as input, which is the percentage of
  /// the data being uploaded.
  ///
  /// The returned future completes without waiting for the file to be uploaded
  /// to iCloud
  Future<void> startUpload({
    required String filePath,
    String? destinationFileName,
    StreamHandler<double?>? onProgress,
  }) async {
    if (filePath.trim().isEmpty) {
      throw InvalidArgumentException('invalid filePath');
    }

    final cloudFileName = destinationFileName ?? filePath.split('/').last;
    await _channel.invokeMethod('upload', {
      'localFilePath': filePath,
      'cloudFileName': cloudFileName,
      'watchUpdate': onProgress != null
    });

    if (onProgress != null) {
      final uploadEventChannel =
          EventChannel('icloud/event/upload/$cloudFileName');
      final stream = uploadEventChannel
          .receiveBroadcastStream()
          .where((event) => event is double)
          .map((event) => event as double?);
      onProgress(stream);
    }
  }

  /// Start to download a file from iCloud
  ///
  /// [fileName] is the name of the file on iCloud
  ///
  /// [destinationFilePath] is the full path of the local file you want the
  /// iCloud file to be saved as
  ///
  /// [onProgress] is an optional callback to to track the progress of the
  /// download. It takes a Stream<double> as input, which is the percentage of
  /// the data being downloaded.
  ///
  /// The returned future completes without waiting for the file to be
  /// downloaded
  Future<void> startDownload({
    required String fileName,
    required String destinationFilePath,
    StreamHandler<double?>? onProgress,
  }) async {
    if (fileName.trim().isEmpty || fileName.contains('/')) {
      throw InvalidArgumentException('invalid fileName');
    }
    if (destinationFilePath.trim().isEmpty ||
        destinationFilePath[destinationFilePath.length - 1] == '/') {
      throw InvalidArgumentException('invalid destinationFilePath');
    }

    await _channel.invokeMethod('download', {
      'cloudFileName': fileName,
      'localFilePath': destinationFilePath,
      'watchUpdate': onProgress != null
    });

    if (onProgress != null) {
      final downloadEventChannel =
          EventChannel('icloud/event/download/$fileName');
      final stream = downloadEventChannel
          .receiveBroadcastStream()
          .where((event) => event is double)
          .map((event) => event as double?);
      onProgress(stream);
    }
  }

  /// Delete a file from iCloud container directory, which lives on the device
  ///
  /// [fileName] is the name of the file on iCloud
  ///
  /// The returned future completes without waiting for the file to be deleted
  /// on iCloud
  Future<void> delete(String fileName) async {
    if (fileName.trim().isEmpty || fileName.contains('/')) {
      throw InvalidArgumentException('invalid fileName');
    }

    await _channel.invokeMethod('delete', {'cloudFileName': fileName});
  }
}

/// An exception class used for development. It's ued when invalid argument
/// is passed to the API
class InvalidArgumentException implements Exception {
  final _message;

  /// Constructor takes the exception message as an argument
  InvalidArgumentException(this._message);

  String toString() => "InvalidArgumentException: $_message";
}

/// A class contains the error code from PlatformException
class PlatformExceptionCode {
  /// The code indicates iCloud container ID is not valid, or user is not signed
  /// in to iCloud, or user denied iCloud permission for this app
  static const String iCloudConnectionOrPermission = 'E_CTR';

  /// The code indicates other error from native code
  static const String nativeCodeError = 'E_NAT';
}
