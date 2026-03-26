/// WSO2 Configuration
///
/// Centralizes all WSO2-related configuration settings.
/// Update these values according to your WSO2 deployment.
class WSO2Config {
  // Environment-specific settings
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  // WSO2 Instance URLs - Update these with your actual WSO2 deployment
  static const String devBaseUrl = 'https://dev-wso2.your-company.com';
  static const String prodBaseUrl = 'https://prod-wso2.your-company.com';

  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;

  // API Manager Configuration
  static const int apiManagerPort = 8243;
  static const int apiManagerSecurePort = 8243;
  static const String apiManagerContext = '';

  static String get apiManagerUrl =>
      '$baseUrl:$apiManagerPort$apiManagerContext';

  // Identity Server Configuration
  static const int identityServerPort = 9443;
  static const String identityServerContext = '';

  static String get identityServerUrl =>
      '$baseUrl:$identityServerPort$identityServerContext';

  // OAuth2 Client Configuration - Register your app in WSO2 Identity Server
  static const String clientId = String.fromEnvironment(
    'WSO2_CLIENT_ID',
    defaultValue: 'procurax_mobile_app', // Default client ID
  );

  static const String clientSecret = String.fromEnvironment(
    'WSO2_CLIENT_SECRET',
    defaultValue: 'your_client_secret_here', // Default client secret
  );

  // OAuth2 Configuration
  static const String redirectUri = 'procurax://oauth-callback';
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'procurement_read',
    'procurement_write',
    'user_profile',
    'notifications',
  ];

  // API Context Paths - These should match your WSO2 API definitions
  static const Map<String, String> apiContexts = {
    'procurement': '/procurement/v1.0',
    'user': '/user/v1.0',
    'notification': '/notification/v1.0',
    'analytics': '/analytics/v1.0',
    'meetings': '/meetings/v1.0',
    'tasks': '/tasks/v1.0',
    'documents': '/documents/v1.0',
  };

  // API Rate Limiting
  static const int maxRequestsPerMinute = 100;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // Token Configuration
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const String tokenStorageKey = 'wso2_tokens';

  // Logging Configuration
  static const bool enableDetailedLogging = !isProduction;
  static const bool logRequestBodies = !isProduction;
  static const bool logResponseBodies = !isProduction;

  // Security Configuration
  static const bool validateSSLCertificates = true;
  static const bool enableCertificatePinning = isProduction;

  // Cache Configuration
  static const Duration cacheExpiry = Duration(minutes: 15);
  static const int maxCacheSize = 100; // Maximum number of cached responses

  // Error Handling Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // API Health Check
  static const String healthCheckEndpoint = '/health';
  static const Duration healthCheckInterval = Duration(minutes: 5);

  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enablePushNotifications = true;
  static const bool enableRealTimeUpdates = true;

  // WSO2 API Manager Subscription Tiers
  static const Map<String, Map<String, dynamic>> subscriptionTiers = {
    'bronze': {
      'requestsPerMinute': 20,
      'requestsPerHour': 1000,
      'requestsPerDay': 20000,
    },
    'silver': {
      'requestsPerMinute': 50,
      'requestsPerHour': 2500,
      'requestsPerDay': 50000,
    },
    'gold': {
      'requestsPerMinute': 100,
      'requestsPerHour': 5000,
      'requestsPerDay': 100000,
    },
    'unlimited': {
      'requestsPerMinute': -1,
      'requestsPerHour': -1,
      'requestsPerDay': -1,
    },
  };

  // Get full API URL
  static String getApiUrl(String contextKey) {
    final context = apiContexts[contextKey];
    if (context == null) {
      throw ArgumentError('Unknown API context: $contextKey');
    }
    return '$apiManagerUrl$context';
  }

  // Validate configuration
  static bool get isConfigurationValid {
    return clientId.isNotEmpty &&
        clientSecret.isNotEmpty &&
        baseUrl.isNotEmpty &&
        apiContexts.isNotEmpty;
  }

  // Get environment info
  static Map<String, dynamic> get environmentInfo => {
    'environment': isProduction ? 'production' : 'development',
    'baseUrl': baseUrl,
    'apiManagerUrl': apiManagerUrl,
    'identityServerUrl': identityServerUrl,
    'clientId': clientId,
    'enableLogging': enableDetailedLogging,
    'validateSSL': validateSSLCertificates,
  };
}
