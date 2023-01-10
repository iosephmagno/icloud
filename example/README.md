# icloud_example

Testing icloud plugin

## How to test example
- Tap Check Availability and wait (it might take little time)
- Tap Start Upload (it first download an image from web and upload it to iCloud)
- Tap List File to check if sample file "image.jpg" has been successfully uploaded to iCloud
- Tap Download (it download previous image from iCloud)
- Tap Delete File to remove it for next test

## Debug Report

## TESTING ON DEVICE: iphone 13 pro ios 16

### Upload:
It instantly shows 95% and stalls with timeout. However, it seems that file has been uploaded successfully (see List Files).

on listen
flutter: --- Upload File --- progress: 95.0

flutter: --- Upload File --- progress: 95.0

flutter: --- Upload File --- timed out

on cancel

### List Files:
It shows that file image.jpg has been uploaded to iCloud
flutter: --- List Files --- file: ICloudMetadata{url: image.jpg, size: 2146824}

### Download:
It shows 100% progress instantly, even with a bigger file.

flutter: --- Download File --- progress: 100.0

flutter: --- Download File --- done

on cancel

### Delete File:
File is deleted correctly. You can see it by running again List Files


## TESTING ON EMULATOR: iOS 15

### Upload:
Inconsistent progress, it starts with 100%, then progress decreases to zero, and then shows 95% and goes to 100%.
Unlike with device, on emulator File upload completes. 

flutter: --- Upload File --- progress: 100.0

flutter: --- Upload File --- progress: 0.0

flutter: --- Upload File --- progress: 95.0

flutter: --- Upload File --- progress: 100.0

flutter: --- Upload File --- done

### List Files:
It shows that file image.jpg has been uploaded to iCloud
flutter: --- List Files --- file: ICloudMetadata{url: image.jpg, size: 2146824}

### Download:
It shows 100% progress instantly, even with a bigger file.

flutter: --- Download File --- progress: 100.0

flutter: --- Download File --- done

### Delete File:
File is deleted correctly. You can see it by running again List Files


