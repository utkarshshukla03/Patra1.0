import '../services/config_service.dart';

class CloudinaryConfig {
  // Cloudinary Configuration from environment variables
  static String get cloudName => ConfigService.cloudinaryCloudName;
  static String get apiKey => ConfigService.cloudinaryApiKey;
  static String get apiSecret => ConfigService.cloudinaryApiSecret;
  static String get uploadPreset => ConfigService.cloudinaryUploadPreset;

  // Folders for organizing uploads
  static const String profileImagesFolder = 'patra_dating_app/profile_images';
  static const String chatImagesFolder = 'patra_dating_app/chat_images';

  // Image transformation settings
  static const int maxImageWidth = 800;
  static const int maxImageHeight = 800;
  static const String imageQuality = 'auto';
  static const String cropMode = 'fill';

  // Generate secure upload URL (if needed for server-side uploads)
  static String getSecureUploadUrl() {
    return 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  }

  // Generate transformation URL
  static String getTransformationUrl(
    String publicId, {
    int? width,
    int? height,
    String? quality,
    String? crop,
  }) {
    final w = width ?? maxImageWidth;
    final h = height ?? maxImageHeight;
    final q = quality ?? imageQuality;
    final c = crop ?? cropMode;

    return 'https://res.cloudinary.com/$cloudName/image/upload/w_$w,h_$h,c_$c,q_$q/$publicId';
  }
}

// Steps to setup Cloudinary:
// 1. Go to https://cloudinary.com/users/register_free
// 2. Create a free account
// 3. Go to Dashboard -> Settings -> Upload
// 4. Create an Upload Preset:
//    - Preset name: 'patra_dating_app'
//    - Signing Mode: 'Unsigned'
//    - Folder: 'patra_dating_app'
//    - Resource Type: 'Image'
//    - Max file size: 10MB
//    - Image and video transformation: Add transformations if needed
// 5. Replace 'YOUR_CLOUD_NAME' with your cloud name from dashboard
// 6. Replace 'YOUR_UPLOAD_PRESET' with 'patra_dating_app'
