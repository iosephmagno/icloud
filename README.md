# icloud_example

Testing icloud plugin

## How to test example
- Tap Check Availability and wait (it might take little time)
- Tap Start Upload (it first download an image from web and upload it to iCloud)
- Tap Download (it download previous image from iCloud)

## Debug Report

## TESTING ON DEVICE: iphone 13 pro ios 16

### Upload:
It instantly shows 95% and stalls with timeout

on listen
flutter: --- Upload File --- progress: 95.0

flutter: --- Upload File --- progress: 95.0

flutter: --- Upload File --- timed out

on cancel

### Download:
It shows 100% progress instantly, even with a bigger file.

flutter: --- Download File --- progress: 100.0

flutter: --- Download File --- done

on cancel


## TESTING ON EMULATOR:

### Upload:
Inconsistent progress, it starts with 100%, then progress decreases to zero, and then shows 95% and goes to 100%.
Unlike with device, on emulator File upload completes. 

flutter: --- Upload File --- progress: 100.0

flutter: --- Upload File --- progress: 0.0

flutter: --- Upload File --- progress: 95.0

flutter: --- Upload File --- progress: 100.0

flutter: --- Upload File --- done


### Download:
It shows 100% progress instantly, even with a bigger file.

flutter: --- Download File --- progress: 100.0

flutter: --- Download File --- done


