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
Inconsistent progress, it starts with 95%, then progress decreases to zero, and then eventually stalls at 95%

### Upload:
on listen
flutter: --- Upload File --- progress: 95.0

flutter: --- Upload File --- progress: 0.0

flutter: --- Upload File --- progress: 94.05939192034373

flutter: --- Upload File --- progress: 95.0

flutter: --- Upload File --- timed out

on cancel

### Download:
It shows 100% progress instantly, even with a bigger file.

on listen
flutter: --- Download File --- progress: 100.0

on cancel

flutter: --- Download File --- done


