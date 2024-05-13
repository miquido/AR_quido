_Ahoy, me hearties! Set sail on the high seas of image recognition with our Flutter plugin. Arrr! 🦜_

# 🏴‍☠️ ar_quido 🏴‍☠️

Image recognition using Augmented Reality (AR) features for mobile Flutter apps.
It uses [EasyAR Sense](https://www.easyar.com/view/sdk.html) on Android and native
[ARKit](https://developer.apple.com/documentation/arkit/content_anchors/detecting_images_in_an_ar_experience)
on iOS.

The plugin has been built by Flutter Division at [Miquido Software development company](https://www.miquido.com).

## Getting started 🚢

Add the dependency in your `pubspec.yaml`:

- from command line:

  ```bash
  flutter pub add ar_quido
  flutter pub get
  ```

- directly in pubspec.yaml:

  ```yaml
  dependencies:
     ar_quido: 0.2.0
  ```

### Android

Since the Android version depends on the EasyAR solution, you need to
[sign up](https://www.easyar.com/view/signUp.html) on their page and obtain
a "Sense Authorization" License Key. It can be done through the [EasyAR Dashboard](https://portal.easyar.com/sdk/list).

After doing so, provide the key in Android Manifest file as
`application`'s metadata:

```xml
<meta-data
           android:name="com.miquido.ar_quido.API_KEY"
           android:value="<YOUR_SENSE_LICENSE_KEY>" />
```

#### Proguard

By default, proguard removes the EasyAR library files from a release build. To fix
this, add the following code to the `android/app/src/proguard-rules.pro` file (create
the file if it doesn't exist):

```proguard
-keep class cn.easyar.** { *; }
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
```

### iOS

`ARKit` uses the device camera, so do not forget to provide the `NSCameraUsageDescription`
in Info.plist:

```xml
<key>NSCameraUsageDescription</key>
<string>Describe why your app needs camera (AR) here.</string>
```

Also make sure, that your deployment target in project settings is set to at least 14.0.
Set the same version in `ios/Podfile`:

```ruby
platform :ios, '15.0'
```

## Usage 🌴

1. Put your reference images inside `assets/reference_images` directory (make
sure to reference them in `pubspec.yaml`).
    - please note, that only `.jpg` images are supported at this time
2. Place `ARQuidoView` widget in your view's code. Provide at least an array of
image names you want to detect (through `referenceImageNames` property) and a
callback for detected images (through `onImageDetected` property):

   ```dart
    ARQuidoView(
      referenceImageNames: const ['applandroid'],
      onImageDetected: (imageName) {
        // handle detected image
      },
    ),
   ```

3. That's it, you're all set ⚓

Please see the [example](https://github.com/miquido/AR_quido/tree/main/example)
for more info. You can also check the details in [API Documentation](https://pub.dev/documentation/ar_quido/latest/).

## Disclaimer

"EasyAR" is the registered trademark or trademark of VisionStar Information
Technology (Shanghai) Co., Ltd in China and other countries for the augmented
reality technology developed by VisionStar Information Technology (Shanghai) Co., Ltd.

The copyright notices in the Software and this entire statement, including the above
license grant, this restriction and the following disclaimer, must be included
in all copies of the Software, in whole or in part, and all derivative works
of the Software.

---
#### About Miquido

- [About](https://careers.miquido.com/about-us/)
- [Careers](https://careers.miquido.com/job-offers/)
- [Internship at Miquido](https://careers.miquido.com/students/)
