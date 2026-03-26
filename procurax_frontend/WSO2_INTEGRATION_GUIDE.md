# WSO2 Integration Guide for ProcuraX

This guide explains how to integrate WSO2 API Manager and Identity Server with your ProcuraX Flutter application.

## Overview

WSO2 provides enterprise-grade API management, security, and integration capabilities that enhance your ProcuraX application with:

- **API Gateway**: Centralized API management, rate limiting, and monitoring
- **Identity Server**: OAuth2/OpenID Connect authentication and authorization
- **API Analytics**: Detailed usage statistics and performance metrics
- **Enterprise Security**: Token management, API keys, and access control

## Prerequisites

1. **WSO2 API Manager**: Version 4.x or higher
2. **WSO2 Identity Server**: Version 6.x or higher (can be integrated with API Manager)
3. **Flutter**: Version 3.x with Dart 3.x
4. **ProcuraX Backend**: Your existing Node.js backend should remain running

## Setup Steps

### 1. WSO2 Configuration

#### API Manager Setup
1. Install and start WSO2 API Manager
2. Access the Publisher portal: `https://your-wso2-server:9443/publisher`
3. Create APIs for your existing services:
   - Procurement API (`/procurement/v1.0`)
   - User Management API (`/user/v1.0`)
   - Notifications API (`/notification/v1.0`)
   - Tasks API (`/tasks/v1.0`)
   - Documents API (`/documents/v1.0`)

#### Identity Server Setup
1. Access the Management Console: `https://your-wso2-server:9443/carbon`
2. Create a new Service Provider:
   - Name: `ProcuraX Mobile App`
   - OAuth/OpenID Connect Configuration:
     - Grant Types: `authorization_code`, `password`, `refresh_token`
     - Callback URL: `procurax://oauth-callback`

### 2. Flutter App Configuration

#### Update Configuration File
Edit `lib/config/wso2_config.dart`:

```dart
class WSO2Config {
  // Update these URLs with your WSO2 deployment
  static const String devBaseUrl = 'https://your-wso2-dev-server.com';
  static const String prodBaseUrl = 'https://your-wso2-prod-server.com';
  
  // OAuth2 Client Configuration (from WSO2 Identity Server)
  static const String clientId = 'your_client_id_from_wso2';
  static const String clientSecret = 'your_client_secret_from_wso2';
  
  // API Context paths (must match your WSO2 API definitions)
  static const Map<String, String> apiContexts = {
    'procurement': '/procurement/v1.0',
    'user': '/user/v1.0',
    'notification': '/notification/v1.0',
    // ... add other APIs
  };
}
```

#### Environment Variables (Optional)
You can also set these via build arguments:

```bash
flutter run --dart-define=WSO2_CLIENT_ID=your_client_id --dart-define=WSO2_CLIENT_SECRET=your_secret
```

### 3. Backend Integration

Your existing Node.js backend can work alongside WSO2 APIs:

#### Option A: Route Through WSO2 (Recommended)
- Configure WSO2 to proxy requests to your existing backend
- Benefits: Centralized security, monitoring, rate limiting

#### Option B: Dual Integration (Current Implementation)
- Flutter app decides which API to use (WSO2 vs. direct backend)
- Automatic fallback if one service is unavailable
- Benefits: Gradual migration, redundancy

### 4. API Mappings

Configure WSO2 to expose your existing APIs:

#### Procurement API
```yaml
# WSO2 API Definition
name: Procurement API
context: /procurement/v1.0
version: 1.0
backend: https://your-procurax-backend.railway.app/api/procurement
endpoints:
  - GET /procurements -> GET /api/procurement
  - POST /procurements -> POST /api/procurement
```

#### User Management API
```yaml
name: User API
context: /user/v1.0
version: 1.0
backend: https://your-procurax-backend.railway.app/api/user
```

## Usage Examples

### 1. Initialize WSO2 Services
```dart
// In your main.dart
await WSO2ApiService.initialize();
await EnhancedProcurementService.initialize();
```

### 2. Authenticate Users
```dart
// OAuth2 authentication
final success = await WSO2ApiService.authenticate(
  username: 'user@company.com',
  password: 'password123',
);

if (success) {
  print('Authentication successful!');
  // User is now authenticated with WSO2
}
```

### 3. Fetch Data with Automatic Fallback
```dart
// This automatically uses WSO2 if available, falls back to direct backend
final procurements = await EnhancedProcurementService.getProcurementData(
  limit: 20,
  status: 'pending',
);
```

### 4. Force Specific API Source
```dart
// Force WSO2 API
final wso2Data = await EnhancedProcurementService.getProcurementData(
  forceWSO2: true,
);

// Force direct backend
final backendData = await EnhancedProcurementService.getProcurementData(
  forceBackend: true,
);
```

### 5. Health Check
```dart
final health = await EnhancedProcurementService.performHealthCheck();
print('Backend Status: ${health['backend']['status']}');
print('WSO2 Status: ${health['wso2']['status']}');
```

## Configuration Options

### API Rate Limiting
```dart
// In WSO2Config
static const int maxRequestsPerMinute = 100;
static const Duration requestTimeout = Duration(seconds: 30);
```

### Security Settings
```dart
// Enable/disable features
static const bool validateSSLCertificates = true;
static const bool enableCertificatePinning = true; // Production only
```

### Caching
```dart
// Cache configuration
static const Duration cacheExpiry = Duration(minutes: 15);
static const int maxCacheSize = 100;
```

## Testing

### 1. Unit Tests
```bash
flutter test test/services/wso2_api_service_test.dart
```

### 2. Integration Tests
```bash
flutter test integration_test/wso2_integration_test.dart
```

### 3. Demo Page
Access the WSO2 integration demo:
```dart
// Add to your app's routing
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const WSO2IntegrationExample(),
  ),
);
```

## Monitoring and Analytics

### 1. API Usage Statistics
```dart
final analytics = await WSO2ApiService.getApiAnalytics(
  fromDate: DateTime.now().subtract(Duration(days: 7)),
  toDate: DateTime.now(),
);

print('Total Requests: ${analytics['totalRequests']}');
print('Average Response Time: ${analytics['averageResponseTime']}ms');
```

### 2. Service Health
```dart
final status = EnhancedProcurementService.getServiceStatus();
print('Using WSO2: ${status['useWSO2']}');
print('Fallback Enabled: ${status['enableFallback']}');
```

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify client ID and secret in WSO2 Identity Server
   - Check OAuth2 grant types are enabled
   - Ensure callback URL matches configuration

2. **API Not Found (404)**
   - Verify API context paths in WSO2 Publisher
   - Check API deployment status
   - Confirm API subscription and throttling policies

3. **Certificate Errors**
   - For development: Set `validateSSLCertificates = false`
   - For production: Ensure proper SSL certificates are installed

4. **Token Expired**
   - The service automatically refreshes tokens
   - Check token refresh configuration in WSO2

### Debug Mode

Enable detailed logging:
```dart
// In WSO2Config
static const bool enableDetailedLogging = true;
static const bool logRequestBodies = true;
static const bool logResponseBodies = true;
```

## Migration Strategy

### Phase 1: Setup and Testing
1. Install WSO2 in development environment
2. Configure demo APIs
3. Test authentication and basic API calls
4. Run integration tests

### Phase 2: Gradual Migration
1. Enable fallback mode (`enableFallback = true`)
2. Migrate one API at a time
3. Monitor performance and error rates
4. Gather user feedback

### Phase 3: Full WSO2 Integration
1. Direct all API traffic through WSO2
2. Implement advanced features (analytics, rate limiting)
3. Disable fallback mode
4. Retire direct backend access (optional)

## Security Best Practices

1. **Token Security**
   - Use secure storage for refresh tokens
   - Implement token rotation
   - Monitor for suspicious token usage

2. **API Security**
   - Enable rate limiting
   - Implement IP whitelisting for sensitive APIs
   - Use API keys for additional security

3. **SSL/TLS**
   - Enable certificate pinning in production
   - Use strong cipher suites
   - Regularly update certificates

## Performance Optimization

1. **Caching**
   - Enable response caching where appropriate
   - Use ETags for conditional requests
   - Implement client-side caching

2. **Connection Pooling**
   - Reuse HTTP connections
   - Configure appropriate timeout values
   - Monitor connection health

3. **Payload Optimization**
   - Use compression for large payloads
   - Implement pagination for large datasets
   - Only request needed fields

## Support and Resources

- **WSO2 Documentation**: https://wso2.com/api-manager/
- **WSO2 Community**: https://wso2.org/community/
- **Flutter HTTP Client**: https://pub.dev/packages/dio
- **OAuth2 Library**: https://pub.dev/packages/oauth2

## License

This integration code is part of the ProcuraX project and follows the same licensing terms as the main application.