import 'package:flutter/foundation.dart';

class WebAssetHelper {
  /// Get the correct asset path for web deployment
  static String getAssetPath(String assetPath) {
    if (kIsWeb) {
      // For web, we need to ensure assets are served correctly
      return assetPath;
    }
    return assetPath;
  }
  
  /// Check if we're running on web platform
  static bool get isWeb => kIsWeb;
}