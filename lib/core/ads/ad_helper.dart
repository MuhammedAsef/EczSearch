// lib/core/ads/ad_helper.dart
import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7997554377934451/8930415482';
    } else if (Platform.isIOS) {
      
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      
      return '';
    }
  }
  
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7997554377934451/5876150386';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      return '';
    }
  }
}
