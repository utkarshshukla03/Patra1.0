import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService {
  static bool _isInitialized = false;

  // Check if ConfigService has been initialized
  static bool get isInitialized => _isInitialized;

  // Initialize environment variables
  static Future<void> initialize() async {
    try {
      // Load API keys first (contains all secrets)
      await dotenv.load(fileName: "api_keys.env");
      print('✅ Loaded api_keys.env');
    } catch (e) {
      print('⚠️  Warning: Could not load api_keys.env - $e');
    }

    try {
      // Then load main .env (environment-specific overrides)
      await dotenv.load(fileName: ".env");
      print('✅ Loaded .env');
    } catch (e) {
      print('⚠️  Warning: Could not load .env - $e');
    }

    _isInitialized = true;

    // Print initialization summary
    print('🔧 Environment: ${environment}');
    print('🤖 ML Matching: ${mlMatchingEnabled ? "Enabled" : "Disabled"}');
    print('☁️  Cloudinary: ${cloudinaryCloudName}');
    print('🔥 Firebase Project: ${firebaseProjectId}');
  }

  // ========================================
  // 🔥 FIREBASE CONFIGURATION
  // ========================================

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? 'patra-dating-app';
  static String get firebaseAuthDomain =>
      dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'patra-dating-app.firebaseapp.com';
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ??
      'patra-dating-app.firebasestorage.app';

  // Web
  static String get firebaseWebApiKey =>
      dotenv.env['FIREBASE_WEB_API_KEY'] ??
      'AIzaSyD13p6Ff7pygplneL9tRNAbLr_ASwo0H-I';
  static String get firebaseWebAppId =>
      dotenv.env['FIREBASE_WEB_APP_ID'] ??
      '1:88069763481:web:d7c2e6b73aa1124a22a308';
  static String get firebaseWebMessagingSenderId =>
      dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID'] ?? '88069763481';
  static String get firebaseWebMeasurementId =>
      dotenv.env['FIREBASE_WEB_MEASUREMENT_ID'] ?? 'G-MEASUREMENT_ID';

  // Android
  static String get firebaseAndroidApiKey =>
      dotenv.env['FIREBASE_ANDROID_API_KEY'] ??
      'AIzaSyDL1F5KKwV8pZqI1CqGqZPL8vGh3MsOAeU';
  static String get firebaseAndroidAppId =>
      dotenv.env['FIREBASE_ANDROID_APP_ID'] ??
      '1:123456789012:android:abcdef1234567890abcdef';
  static String get firebaseAndroidMessagingSenderId =>
      dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID'] ?? '123456789012';

  // iOS
  static String get firebaseIosApiKey =>
      dotenv.env['FIREBASE_IOS_API_KEY'] ?? '';
  static String get firebaseIosAppId => dotenv.env['FIREBASE_IOS_APP_ID'] ?? '';
  static String get firebaseIosMessagingSenderId =>
      dotenv.env['FIREBASE_IOS_MESSAGING_SENDER_ID'] ?? '';

  // ========================================
  // ☁️  CLOUDINARY CONFIGURATION
  // ========================================

  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dugh2jryo';
  static String get cloudinaryUploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'patra_dating_app';
  static String get cloudinaryApiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get cloudinaryApiSecret =>
      dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  // ========================================
  // 🤖 ML SERVICE CONFIGURATION
  // ========================================

  static String get mlServiceBaseUrl =>
      dotenv.env['ML_SERVICE_BASE_URL'] ?? 'http://localhost:5000';
  static String get mlServiceHealthEndpoint =>
      dotenv.env['ML_SERVICE_HEALTH_ENDPOINT'] ?? '/health';
  static String get mlServiceRecommendationsEndpoint =>
      dotenv.env['ML_SERVICE_RECOMMENDATIONS_ENDPOINT'] ?? '/recommendations';
  static String get mlServiceRefreshEndpoint =>
      dotenv.env['ML_SERVICE_REFRESH_ENDPOINT'] ?? '/refresh-data';

  static int get mlServiceTimeout =>
      int.tryParse(dotenv.env['ML_SERVICE_TIMEOUT'] ?? '10') ?? 10;
  static int get mlServiceHealthTimeout =>
      int.tryParse(dotenv.env['ML_SERVICE_HEALTH_TIMEOUT'] ?? '5') ?? 5;
  static int get mlServiceRefreshTimeout =>
      int.tryParse(dotenv.env['ML_SERVICE_REFRESH_TIMEOUT'] ?? '30') ?? 30;

  // ========================================
  // 🔐 SECURITY & AUTHENTICATION
  // ========================================

  static String get jwtSecret => dotenv.env['JWT_SECRET'] ?? '';
  static String get jwtRefreshSecret => dotenv.env['JWT_REFRESH_SECRET'] ?? '';
  static String get encryptionKey => dotenv.env['ENCRYPTION_KEY'] ?? '';
  static String get appSecret => dotenv.env['APP_SECRET'] ?? '';

  // ========================================
  // 🏗️  DEVELOPMENT ENVIRONMENT
  // ========================================

  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  static bool get verboseLogging =>
      dotenv.env['VERBOSE_LOGGING']?.toLowerCase() == 'true';

  // ========================================
  // 📱 APP CONFIGURATION
  // ========================================

  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get buildNumber => dotenv.env['BUILD_NUMBER'] ?? '1';

  // Feature Flags
  static bool get mlMatchingEnabled =>
      dotenv.env['ML_MATCHING_ENABLED']?.toLowerCase() != 'false';
  static bool get premiumFeaturesEnabled =>
      dotenv.env['PREMIUM_FEATURES_ENABLED']?.toLowerCase() == 'true';
  static bool get chatEnabled =>
      dotenv.env['CHAT_ENABLED']?.toLowerCase() != 'false';
  static bool get videoCallEnabled =>
      dotenv.env['VIDEO_CALL_ENABLED']?.toLowerCase() == 'true';

  // Limits
  static int get maxPhotosPerUser =>
      int.tryParse(dotenv.env['MAX_PHOTOS_PER_USER'] ?? '6') ?? 6;
  static int get maxSwipesPerDay =>
      int.tryParse(dotenv.env['MAX_SWIPES_PER_DAY'] ?? '100') ?? 100;
  static int get maxMatchesPerRequest =>
      int.tryParse(dotenv.env['MAX_MATCHES_PER_REQUEST'] ?? '20') ?? 20;

  // ========================================
  // 🔧 EXTERNAL SERVICES
  // ========================================

  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get googleAnalyticsId =>
      dotenv.env['GOOGLE_ANALYTICS_ID'] ?? '';
  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';

  // Performance and Timeout Settings
  static int get apiTimeoutMs =>
      int.tryParse(dotenv.env['API_TIMEOUT_MS'] ?? '30000') ?? 30000;
  static int get imageUploadTimeoutMs =>
      int.tryParse(dotenv.env['IMAGE_UPLOAD_TIMEOUT_MS'] ?? '60000') ?? 60000;
  static int get mlRequestTimeoutMs =>
      int.tryParse(dotenv.env['ML_REQUEST_TIMEOUT_MS'] ?? '15000') ?? 15000;

  // Additional Feature Flags
  static bool get locationServicesEnabled =>
      dotenv.env['LOCATION_SERVICES_ENABLED']?.toLowerCase() != 'false';
  static bool get pushNotificationsEnabled =>
      dotenv.env['PUSH_NOTIFICATIONS_ENABLED']?.toLowerCase() != 'false';
  static bool get analyticsEnabled =>
      dotenv.env['ANALYTICS_ENABLED']?.toLowerCase() != 'false';

  // Security Settings
  static int get minPasswordLength =>
      int.tryParse(dotenv.env['MIN_PASSWORD_LENGTH'] ?? '8') ?? 8;
  static bool get requireSpecialCharacters =>
      dotenv.env['REQUIRE_SPECIAL_CHARACTERS']?.toLowerCase() != 'false';

  // JWT Token Settings
  static int get jwtExpirationHours =>
      int.tryParse(dotenv.env['JWT_EXPIRATION_HOURS'] ?? '24') ?? 24;
  static int get jwtRefreshExpirationDays =>
      int.tryParse(dotenv.env['JWT_REFRESH_EXPIRATION_DAYS'] ?? '30') ?? 30;

  // Social Authentication
  static bool get googleAuthEnabled =>
      dotenv.env['GOOGLE_AUTH_ENABLED']?.toLowerCase() != 'false';
  static bool get facebookAuthEnabled =>
      dotenv.env['FACEBOOK_AUTH_ENABLED']?.toLowerCase() != 'false';
  static bool get appleAuthEnabled =>
      dotenv.env['APPLE_AUTH_ENABLED']?.toLowerCase() != 'false';

  // Additional Firebase Properties
  static String get firebaseAppId =>
      firebaseWebAppId; // Use web app ID as fallback

  // ========================================
  // 🛠️  UTILITY METHODS
  // ========================================

  static bool get isProduction => environment.toLowerCase() == 'production';
  static bool get isDevelopment => environment.toLowerCase() == 'development';
  static bool get isStaging => environment.toLowerCase() == 'staging';

  /// Get full ML service URL for specific endpoint
  static String getMlServiceUrl(String endpoint) {
    return '$mlServiceBaseUrl$endpoint';
  }

  /// Check if a required environment variable is missing
  static List<String> getMissingRequiredVariables() {
    List<String> missing = [];

    if (cloudinaryCloudName.isEmpty) missing.add('CLOUDINARY_CLOUD_NAME');
    if (cloudinaryUploadPreset.isEmpty) missing.add('CLOUDINARY_UPLOAD_PRESET');
    if (firebaseProjectId.isEmpty) missing.add('FIREBASE_PROJECT_ID');
    if (firebaseWebApiKey.isEmpty) missing.add('FIREBASE_WEB_API_KEY');

    return missing;
  }

  /// Validate configuration and print warnings
  static void validateConfiguration() {
    final missing = getMissingRequiredVariables();
    if (missing.isNotEmpty) {
      print('⚠️  Warning: Missing required environment variables:');
      for (String variable in missing) {
        print('   - $variable');
      }
      print('   Please check your .env and api_keys.env files');
    }

    if (debugMode && isProduction) {
      print('⚠️  Warning: Debug mode is enabled in production environment!');
    }

    print('🔧 Environment: $environment');
    print('🤖 ML Matching: ${mlMatchingEnabled ? 'Enabled' : 'Disabled'}');
    print('🔍 Debug Mode: ${debugMode ? 'Enabled' : 'Disabled'}');
    print('☁️  Cloudinary: $cloudinaryCloudName');
    print('🔥 Firebase Project: $firebaseProjectId');
  }
}
