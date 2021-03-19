import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icloud/icloud.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const iCloudContainerId = '{your icloud container id}';

  StreamSubscription? subscription;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('icloud plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              TextButton(
                child: Text('Check Availability'),
                onPressed: () async => print(
                    '--- Check Availability --- value: ${await ICloud.available}'),
              ),
              TextButton(
                child: Text('Watch Availability'),
                onPressed: testWatchAvailability,
              ),
              TextButton(
                child: Text('Cancel Watch Availability'),
                onPressed: cancelWatchAvailability,
              ),
              TextButton(
                child: Text('List File'),
                onPressed: testListFile,
              ),
              TextButton(
                child: Text('Watch File'),
                onPressed: testWatchFile,
              ),
              TextButton(
                child: Text('Start Upload'),
                onPressed: testUploadFile,
              ),
              TextButton(
                child: Text('Start Download'),
                onPressed: testDownloadFile,
              ),
              TextButton(
                child: Text('Delete File'),
                onPressed: testDeleteFile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> testWatchAvailability() async {
    print('--- Watch Availability --- start');
    final stream = await ICloud.watchAvailability();
    subscription = stream.listen((available) {
      print('--- Watch Availability --- value: $available');
    });
  }

  cancelWatchAvailability() {
    subscription?.cancel();
    print('--- Watch Availability --- canceled');
  }

  void handleError(dynamic err) {
    if (err is PlatformException) {
      if (err.code == PlatformExceptionCode.iCloudConnectionOrPermission) {
        print(
            'Platform Exception: iCloud container ID is not valid, or user is not signed in for iCloud, or user denied iCloud permission for this app');
      } else {
        print('Platform Exception: ${err.message}; Details: ${err.details}');
      }
    } else {
      print(err.toString());
    }
  }

  Future<void> testListFile() async {
    try {
      final iCloud = await ICloud.getInstance(iCloudContainerId);
      final files = await iCloud.listFiles();
      files.forEach((file) => print('--- List Files --- file: $file'));
    } catch (err) {
      handleError(err);
    }
  }

  Future<void> testWatchFile() async {
    try {
      final iCloud = await ICloud.getInstance(iCloudContainerId);
      final fileListStream = await iCloud.watchFiles();
      final fileListSubscription = fileListStream.listen((files) {
        files.forEach((file) => print('--- Watch Files --- file: $file'));
      });

      Future.delayed(Duration(seconds: 10), () {
        fileListSubscription.cancel();
        print('--- Watch Files --- canceled');
      });
    } catch (err) {
      handleError(err);
    }
  }

  Future<void> testUploadFile() async {
    try {
      final iCloud = await ICloud.getInstance(iCloudContainerId);
      StreamSubscription<double?>? uploadProgressSubscription;
      var isUploadComplete = false;

      await iCloud.startUpload(
        filePath: '{your local file}',
        destinationFileName: 'test_icloud_file',
        onProgress: (stream) {
          uploadProgressSubscription = stream.listen(
            (progress) => print('--- Upload File --- progress: $progress'),
            onDone: () {
              isUploadComplete = true;
              print('--- Upload File --- done');
            },
            onError: (err) => print('--- Upload File --- error: $err'),
            cancelOnError: true,
          );
        },
      );

      Future.delayed(Duration(seconds: 10), () {
        if (!isUploadComplete) {
          uploadProgressSubscription?.cancel();
          print('--- Upload File --- timed out');
        }
      });
    } catch (err) {
      handleError(err);
    }
  }

  Future<void> testDownloadFile() async {
    try {
      final iCloud = await ICloud.getInstance(iCloudContainerId);
      StreamSubscription<double?>? downloadProgressSubscription;
      var isDownloadComplete = false;

      await iCloud.startDownload(
        fileName: 'test_icloud_file',
        destinationFilePath: '{your destination file path}',
        onProgress: (stream) {
          downloadProgressSubscription = stream.listen(
            (progress) => print('--- Download File --- progress: $progress'),
            onDone: () {
              isDownloadComplete = true;
              print('--- Download File --- done');
            },
            onError: (err) => print('--- Download File --- error: $err'),
            cancelOnError: true,
          );
        },
      );

      Future.delayed(Duration(seconds: 20), () {
        if (!isDownloadComplete) {
          downloadProgressSubscription?.cancel();
          print('--- Download File --- timed out');
        }
      });
    } catch (err) {
      handleError(err);
    }
  }

  Future<void> testDeleteFile() async {
    try {
      final iCloud = await ICloud.getInstance(iCloudContainerId);
      await iCloud.delete('test_icloud_file');
    } catch (err) {
      handleError(err);
    }
  }
}
