import 'dart:io' show Platform;

class Secret {
  static const ANDROID_CLIENT_ID =
      "635784511101-043mufmpf7al33o335vho8sdb7t90c8o.apps.googleusercontent.com";
  static const IOS_CLIENT_ID = "<enter your iOS client secret>";

  static String getId() {
    if (Platform.isAndroid) {
      return ANDROID_CLIENT_ID;
    } else if (Platform.isIOS) {
      return IOS_CLIENT_ID;
    } else {
      return ''; // TO DO
    }
  }
}
