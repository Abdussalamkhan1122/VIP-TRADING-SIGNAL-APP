import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.hurrair.hurrairVipTrading',
  );

  static bool get isConfigured {
    if (apiKey.isEmpty || projectId.isEmpty || messagingSenderId.isEmpty) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) return iosAppId.isNotEmpty;
    if (defaultTargetPlatform == TargetPlatform.android) return androidAppId.isNotEmpty;
    return false;
  }

  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return FirebaseOptions(
        apiKey: apiKey,
        appId: iosAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
        iosBundleId: iosBundleId,
      );
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: androidAppId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
    );
  }
}
