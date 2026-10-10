import 'dart:io';

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
}
