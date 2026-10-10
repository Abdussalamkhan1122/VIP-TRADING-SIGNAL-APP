import 'dart:io';

const firebaseAndroidPackage = 'com.trading.HurrairstradingAPP';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln('AndroidManifest.xml not found. Run flutter create first.');
    exitCode = 1;
    return;
  }

  var xml = manifest.readAsStringSync();
  const permission = '<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />';
  if (!xml.contains('android.permission.POST_NOTIFICATIONS')) {
    xml = xml.replaceFirst(
      '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
      '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    $permission',
    );
  }

  const metadata =
      '<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" android:value="signals" />';
  if (!xml.contains('com.google.firebase.messaging.default_notification_channel_id')) {
    xml = xml.replaceFirst('</application>', '        $metadata\n    </application>');
  }

  manifest.writeAsStringSync(xml);
  configureGradlePackage();
}

void configureGradlePackage() {
  final gradleFiles = [
    File('android/app/build.gradle'),
    File('android/app/build.gradle.kts'),
  ].where((file) => file.existsSync());

  for (final file in gradleFiles) {
    var text = file.readAsStringSync();
    text = text.replaceAll(
      RegExp(r'applicationId\s*=?\s*"[^"]+"'),
      'applicationId = "$firebaseAndroidPackage"',
    );
    text = text.replaceAll(
      RegExp(r'minSdk\s*=\s*flutter\.minSdkVersion'),
      'minSdk = 23',
    );
    text = text.replaceAll(
      RegExp(r'minSdkVersion\s*=?\s*flutter\.minSdkVersion'),
      'minSdkVersion 23',
    );
    file.writeAsStringSync(text);
  }
}
