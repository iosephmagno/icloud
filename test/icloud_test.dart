import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icloud/icloud.dart';

void main() {
  const MethodChannel channel = MethodChannel('icloud');
  const MethodChannel availabilityEventChannel =
      MethodChannel('icloud/event/availability');
  const MethodChannel listEventChannel = MethodChannel('icloud/event/list');
  DateTime dateTimeA = DateTime.now().subtract(Duration(days: 1));
  DateTime dateTimeB = DateTime.now().subtract(Duration(days: 2));
  late List<Map<String, dynamic>> fileList;
  final List<ICloudMetadata> metadataList = [
    ICloudMetadata('a', 1, dateTimeA),
    ICloudMetadata('b', 2, dateTimeB)
  ];

  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodCall _methodCall;

  Map<String, dynamic> _fileMap(String url, int size, DateTime modifiedDate) {
    return {
      'url': url,
      'size': size,
      'modifiedDate': modifiedDate.toIso8601String()
    };
  }

  setUp(() {
    fileList = [_fileMap('a', 1, dateTimeA), _fileMap('b', 2, dateTimeB)];
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      _methodCall = methodCall;
      switch (methodCall.method) {
        case 'isAvailable':
          return true;
        case 'listFiles':
          return fileList;
        default:
          return null;
      }
    });
    availabilityEventChannel
        .setMockMethodCallHandler((MethodCall methodCall) async {
      ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
          "icloud/event/availability",
          const StandardMethodCodec().encodeSuccessEnvelope(true),
          (ByteData? data) {});
    });
    listEventChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
          "icloud/event/list",
          const StandardMethodCodec().encodeSuccessEnvelope(fileList),
          (ByteData? data) {});
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
    availabilityEventChannel.setMethodCallHandler(null);
    listEventChannel.setMethodCallHandler(null);
  });

  test('available', () async {
    expect(await ICloud.available, true);
  });

  test('watchAvailability', () async {
    final stream = await ICloud.watchAvailability();
    expect(await stream.first, true);
  });

  test('listFiles', () async {
    final iCloud = await ICloud.getInstance('containerId');
    final files = await iCloud.listFiles();
    expect(files, equals(metadataList));
  });

  test('watchFiles', () async {
    final iCloud = await ICloud.getInstance('containerId');
    final stream = await iCloud.watchFiles();
    expect(_methodCall.arguments, {'watchUpdate': true});
    expect(await stream.first, equals(metadataList));
  });

  test('startUpload', () async {
    final iCloud = await ICloud.getInstance('containerId');
    await iCloud.startUpload(filePath: '/dir/file');
    expect(_methodCall.arguments, {
      'localFilePath': '/dir/file',
      'cloudFileName': 'file',
      'watchUpdate': false
    });

    await iCloud.startUpload(
        filePath: '/dir/file', destinationFileName: 'newFile');
    expect(_methodCall.arguments, {
      'localFilePath': '/dir/file',
      'cloudFileName': 'newFile',
      'watchUpdate': false
    });

    await iCloud.startUpload(
      filePath: '/dir/file',
      destinationFileName: 'newFile',
      onProgress: (stream) {},
    );
    expect(_methodCall.arguments, {
      'localFilePath': '/dir/file',
      'cloudFileName': 'newFile',
      'watchUpdate': true
    });

    expect(() async => await iCloud.startUpload(filePath: ''), throwsException);
  });

  test('startDownload', () async {
    final iCloud = await ICloud.getInstance('containerId');
    await iCloud.startDownload(
      fileName: 'file',
      destinationFilePath: '/dir/file',
    );
    expect(_methodCall.arguments, {
      'cloudFileName': 'file',
      'localFilePath': '/dir/file',
      'watchUpdate': false
    });

    await iCloud.startUpload(
      filePath: '/dir/file',
      destinationFileName: 'newFile',
      onProgress: (stream) {},
    );
    expect(_methodCall.arguments, {
      'localFilePath': '/dir/file',
      'cloudFileName': 'newFile',
      'watchUpdate': true
    });

    expect(
        () async => await iCloud.startDownload(
              fileName: 'file/',
              destinationFilePath: '/dir/file',
            ),
        throwsException);

    expect(
        () async => await iCloud.startDownload(
              fileName: 'file',
              destinationFilePath: '/dir/file/',
            ),
        throwsException);
  });

  test('delete', () async {
    final iCloud = await ICloud.getInstance('containerId');
    await iCloud.delete('file');
    expect(_methodCall.arguments, {'cloudFileName': 'file'});

    expect(() async => await iCloud.delete('dir/file'), throwsException);
  });
}
