import 'package:flutter/material.dart';
import 'package:patra_initial/services/config_service.dart';

/// 🔧 Configuration Verification Widget
/// Use this to verify that all environment variables are loaded correctly
class ConfigVerificationWidget extends StatefulWidget {
  const ConfigVerificationWidget({Key? key}) : super(key: key);

  @override
  _ConfigVerificationWidgetState createState() =>
      _ConfigVerificationWidgetState();
}

class _ConfigVerificationWidgetState extends State<ConfigVerificationWidget> {
  bool _isLoading = true;
  Map<String, dynamic> _configStatus = {};

  @override
  void initState() {
    super.initState();
    _verifyConfiguration();
  }

  Future<void> _verifyConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize ConfigService if not already done
      if (!ConfigService.isInitialized) {
        await ConfigService.initialize();
      }

      // Check each configuration category
      Map<String, dynamic> status = {
        'general': _checkGeneralConfig(),
        'firebase': _checkFirebaseConfig(),
        'cloudinary': _checkCloudinaryConfig(),
        // 'ml_service': _checkMLServiceConfig(), // DISABLED ML SERVICE
        'features': _checkFeatureFlags(),
        'security': _checkSecurityConfig(),
      };

      setState(() {
        _configStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _configStatus = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  Map<String, bool> _checkGeneralConfig() {
    return {
      'Environment Set': ConfigService.environment.isNotEmpty,
      'Debug Mode': ConfigService.debugMode,
      'App Version': ConfigService.appVersion.isNotEmpty,
    };
  }

  Map<String, bool> _checkFirebaseConfig() {
    return {
      'Web API Key': ConfigService.firebaseWebApiKey.isNotEmpty,
      'Project ID': ConfigService.firebaseProjectId.isNotEmpty,
      'App ID': ConfigService.firebaseAppId.isNotEmpty,
      'Storage Bucket': ConfigService.firebaseStorageBucket.isNotEmpty,
    };
  }

  Map<String, bool> _checkCloudinaryConfig() {
    return {
      'Cloud Name': ConfigService.cloudinaryCloudName.isNotEmpty,
      'API Key': ConfigService.cloudinaryApiKey.isNotEmpty,
      'Upload Preset': ConfigService.cloudinaryUploadPreset.isNotEmpty,
    };
  }

  // DISABLED ML SERVICE CONFIGURATION CHECK
  // Map<String, bool> _checkMLServiceConfig() {
  //   return {
  //     'Service URL': ConfigService.mlServiceBaseUrl.isNotEmpty,
  //     'ML Enabled': ConfigService.mlMatchingEnabled,
  //     'API Timeout': ConfigService.apiTimeoutMs > 0,
  //   };
  // }

  Map<String, bool> _checkFeatureFlags() {
    return {
      'Chat Enabled': ConfigService.chatEnabled,
      'Location Services': ConfigService.locationServicesEnabled,
      'Push Notifications': ConfigService.pushNotificationsEnabled,
      'Analytics': ConfigService.analyticsEnabled,
    };
  }

  Map<String, bool> _checkSecurityConfig() {
    return {
      'JWT Secret Set': ConfigService.jwtSecret.isNotEmpty,
      'Encryption Key Set': ConfigService.encryptionKey.isNotEmpty,
      'Min Password Length': ConfigService.minPasswordLength >= 8,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('🔧 Verifying Configuration...'),
            ],
          ),
        ),
      );
    }

    if (_configStatus.containsKey('error')) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('❌ Configuration Error'),
          backgroundColor: Colors.red,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Configuration Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error: ${_configStatus['error']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                '🛠️ Troubleshooting Steps:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('1. Ensure .env and api_keys.env files exist'),
              const Text('2. Check file permissions'),
              const Text('3. Verify flutter_dotenv is installed'),
              const Text('4. Review API_SETUP_GUIDE.md'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _verifyConfiguration,
                child: const Text('🔄 Retry Verification'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Configuration Status'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 32),
                        SizedBox(width: 12),
                        Text(
                          '✅ Configuration Loaded Successfully',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Environment: ${ConfigService.environment}'),
                    Text('Debug Mode: ${ConfigService.debugMode}'),
                    Text('App Version: ${ConfigService.appVersion}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Configuration Categories
            ...(_configStatus.entries
                .map((entry) => _buildConfigSection(entry.key, entry.value))),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _verifyConfiguration,
                    icon: const Icon(Icons.refresh),
                    label: const Text('🔄 Refresh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('✅ Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection(String title, Map<String, bool> configs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              configs.values.every((v) => v)
                  ? Icons.check_circle
                  : Icons.warning,
              color:
                  configs.values.every((v) => v) ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              _formatTitle(title),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        children: configs.entries.map((entry) {
          return ListTile(
            leading: Icon(
              entry.value ? Icons.check : Icons.close,
              color: entry.value ? Colors.green : Colors.red,
            ),
            title: Text(entry.key),
            trailing: Text(
              entry.value ? '✅ OK' : '❌ Missing',
              style: TextStyle(
                color: entry.value ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTitle(String title) {
    switch (title) {
      case 'general':
        return '🌍 General Settings';
      case 'firebase':
        return '🔥 Firebase Configuration';
      case 'cloudinary':
        return '☁️ Cloudinary Settings';
      // case 'ml_service':
      //   return '🤖 ML Service Configuration'; // DISABLED ML SERVICE
      case 'features':
        return '🎯 Feature Flags';
      case 'security':
        return '🔐 Security Settings';
      default:
        return title.toUpperCase();
    }
  }
}

/// 🚀 Quick access function to show configuration verification
void showConfigVerification(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const ConfigVerificationWidget(),
    ),
  );
}
