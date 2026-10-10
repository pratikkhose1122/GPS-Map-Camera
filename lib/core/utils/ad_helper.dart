import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5938421881119594/4399040817'; // Production ad unit for Android
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Google's test ad unit for iOS
    }
    throw UnsupportedError('Unsupported platform');
  }
}
