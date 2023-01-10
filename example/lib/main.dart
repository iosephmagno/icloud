import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icloud/icloud.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

export 'package:path_provider_platform_interface/path_provider_platform_interface.dart'
    show StorageDirectory;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const iCloudContainerId = 'iCloud.com.presence.app';

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
                child: Text('List Files'),
                onPressed: testListFiles,
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

  Future<void> testListFiles() async {
    try {
      final iCloud = await ICloud.getInstance(containerId: iCloudContainerId);
      final files = await iCloud.listFiles();
      files.forEach((file) => print('--- List Files --- file: $file'));
    } catch (err) {
      handleError(err);
    }
  }

  Future<void> testWatchFile() async {
    try {
      final iCloud = await ICloud.getInstance(containerId: iCloudContainerId);
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
      final iCloud = await ICloud.getInstance(containerId: iCloudContainerId);
      StreamSubscription<double?>? uploadProgressSubscription;
      var isUploadComplete = false;

      //Get file from web
      final tempDir = await getTemporaryDirectory();
      final dio = Dio();
      Response response = await dio.download(
        //  64KB image - use this link to test with small filesize
        //  'https://res.cloudinary.com/dornu6mmy/image/upload/v1637745528/POSTS/l9flihokyfchdjauhgkz.jpg',
        // 1.2MB image - use this link to test with medium filesize
        //   'https://images.unsplash.com/flagged/photo-1568164017397-00f2cec55c97?ixlib=rb-4.0.3&q=80&fm=jpg&crop=entropy&cs=tinysrgb',
        // 21MB pic
           'https://images.pexels.com/photos/1168742/pexels-photo-1168742.jpeg',
          '${tempDir.path}/image.jpg');
      print(tempDir.path);
      if (response.statusCode == 200){
        print("File fetched from web successfully");
      } else{
        print("Couldn't fetch file from web");
      }

      await iCloud.startUpload(

        filePath: '${tempDir.path}/image.jpg',
        //destinationFileName: 'test_icloud_file',
        destinationFileName: 'image.jpg',
        onProgress: (stream) {
          uploadProgressSubscription = stream.listen(
                (progress) => print('--- Upload File --- progress: $progress'),
            onDone: () {
              isUploadComplete = true;
              print('--- Upload File --- done');
            },
            onError: (err) => print('--- Upload File --- error: $err'),
            cancelOnError: false,
          );
        },
      );

      // a 10sec timeout is used to workaround an issue by which upload progress gets stalled
      // the file gets uploaded but onDone is never called without this timeout
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
      final iCloud = await ICloud.getInstance(containerId: iCloudContainerId);
      StreamSubscription<double?>? downloadProgressSubscription;
      var isDownloadComplete = false;
      final tempDir = await getTemporaryDirectory();

      await iCloud.startDownload(
        fileName: 'image.jpg',
        destinationFilePath: '${tempDir.path}/image.jpg',
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
      final iCloud = await ICloud.getInstance(containerId: iCloudContainerId);
      await iCloud.delete('image.jpg');
    } catch (err) {
      handleError(err);
    }
  }
}
