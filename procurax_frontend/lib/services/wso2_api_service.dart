import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// WSO2 API Service
///
/// Handles all interactions with WSO2 API Manager, Identity Server,
/// and other WSO2 products. Provides centralized API management,
/// authentication, and monitoring capabilities.
class WSO2ApiService {
  // WSO2 Configuration - Update these with your WSO2 setup
  static const String _wso2BaseUrl = 'https://your-wso2-instance.com';
  static const String _apiManagerUrl =
      '$_wso2BaseUrl:8243'; // Default API Manager port
  static const String _identityServerUrl =
      '$_wso2BaseUrl:9443'; // Default Identity Server port

  // OAuth2 Configuration
  static const String _clientId = 'your_client_id';
  static const String _clientSecret = 'your_client_secret';
  static const String _redirectUri = 'procurax://oauth-callback';

  // API Context paths
  static const String _procurementApiContext = '/procurement/v1.0';
  static const String _userApiContext = '/user/v1.0';
  static const String _notificationApiContext = '/notification/v1.0';

  static Dio? _dio;
  static oauth2.Client? _oauthClient;
  static String? _accessToken;
  static String? _refreshToken;

  /// Initialize WSO2 service
  static Future<void> initialize() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: _apiManagerUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and token refresh
    _dio!.interceptors.add(_createAuthInterceptor());
    _dio!.interceptors.add(_createLoggingInterceptor());

    // Load saved tokens
    await _loadTokensFromStorage();
  }

  /// Create authentication interceptor
  static Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized - try to refresh token
        if (error.response?.statusCode == 401) {
          if (await _refreshAccessToken()) {
            // Retry the request with new token
            final request = error.requestOptions;
            request.headers['Authorization'] = 'Bearer $_accessToken';
            try {
              final response = await _dio!.request(
                request.path,
                options: Options(
                  method: request.method,
                  headers: request.headers,
                ),
                data: request.data,
                queryParameters: request.queryParameters,
              );
              handler.resolve(response);
              return;
            } catch (e) {
              // If retry fails, continue with original error
            }
          }
        }
        handler.next(error);
      },
    );
  }

  /// Create logging interceptor for debugging
  static Interceptor _createLoggingInterceptor() {
    return LogInterceptor(
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      logPrint: (object) => debugPrint('WSO2 API: $object'),
    );
  }

  /// Authenticate with WSO2 Identity Server using OAuth2
  static Future<bool> authenticate({
    required String username,
    required String password,
  }) async {
    try {
      // WSO2 Identity Server OAuth2 endpoints
      final authorizationEndpoint = Uri.parse(
        '$_identityServerUrl/oauth2/authorize',
      );
      final tokenEndpoint = Uri.parse('$_identityServerUrl/oauth2/token');

      // Create OAuth2 authorization code grant
      final grant = oauth2.AuthorizationCodeGrant(
        _clientId,
        authorizationEndpoint,
        tokenEndpoint,
        secret: _clientSecret,
      );

      // For password grant (Resource Owner Password Credentials)
      final client = await oauth2.resourceOwnerPasswordGrant(
        authorizationEndpoint,
        username,
        password,
        identifier: _clientId,
        secret: _clientSecret,
      );

      _oauthClient = client;
      _accessToken = client.credentials.accessToken;
      _refreshToken = client.credentials.refreshToken;

      // Save tokens to secure storage
      await _saveTokensToStorage();

      return true;
    } catch (e) {
      debugPrint('WSO2 Authentication failed: $e');
      return false;
    }
  }

  /// Refresh access token using refresh token
  static Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final tokenEndpoint = Uri.parse('$_identityServerUrl/oauth2/token');

      final response = await _dio!.post(
        tokenEndpoint.toString(),
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _accessToken = data['access_token'];
        if (data['refresh_token'] != null) {
          _refreshToken = data['refresh_token'];
        }

        await _saveTokensToStorage();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return false;
    }
  }

  /// Save tokens to secure storage
  static Future<void> _saveTokensToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('wso2_access_token', _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString('wso2_refresh_token', _refreshToken!);
    }
  }

  /// Load tokens from secure storage
  static Future<void> _loadTokensFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('wso2_access_token');
    _refreshToken = prefs.getString('wso2_refresh_token');

    // Check if access token is still valid
    if (_accessToken != null) {
      try {
        final payload = Jwt.parseJwt(_accessToken!);
        final exp = payload['exp'] as int;
        if (DateTime.fromMillisecondsSinceEpoch(
          exp * 1000,
        ).isBefore(DateTime.now())) {
          // Token expired, try to refresh
          await _refreshAccessToken();
        }
      } catch (e) {
        // Invalid token, clear it
        _accessToken = null;
      }
    }
  }

  /// Clear authentication tokens
  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _oauthClient = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wso2_access_token');
    await prefs.remove('wso2_refresh_token');
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => _accessToken != null;

  /// Get current user info from JWT token
  static Map<String, dynamic>? get currentUser {
    if (_accessToken == null) return null;
    try {
      return Jwt.parseJwt(_accessToken!);
    } catch (e) {
      return null;
    }
  }

  // ==================================================================
  // PROCUREMENT APIS
  // ==================================================================

  /// Get procurement data from WSO2 API
  static Future<List<Map<String, dynamic>>> getProcurementData({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
  }) async {
    try {
      final response = await _dio!.get(
        '$_procurementApiContext/procurements',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
          if (category != null) 'category': category,
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create new procurement request
  static Future<Map<String, dynamic>> createProcurementRequest({
    required String title,
    required String description,
    required String category,
    required double budget,
    required String urgency,
    List<File>? attachments,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        'description': description,
        'category': category,
        'budget': budget,
        'urgency': urgency,
      });

      // Add file attachments
      if (attachments != null) {
        for (int i = 0; i < attachments.length; i++) {
          formData.files.add(
            MapEntry(
              'attachments',
              await MultipartFile.fromFile(
                attachments[i].path,
                filename:
                    'attachment_$i.${attachments[i].path.split('.').last}',
              ),
            ),
          );
        }
      }

      final response = await _dio!.post(
        '$_procurementApiContext/procurements',
        data: formData,
      );

      if (response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Failed to create procurement request');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================================================================
  // USER MANAGEMENT APIS
  // ==================================================================

  /// Get user profile from WSO2
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio!.get('$_userApiContext/profile');

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to fetch user profile');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update user profile
  static Future<bool> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _dio!.put(
        '$_userApiContext/profile',
        data: profileData,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================================================================
  // NOTIFICATION APIS
  // ==================================================================

  /// Get notifications from WSO2
  static Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  }) async {
    try {
      final response = await _dio!.get(
        '$_notificationApiContext/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (type != null) 'type': type,
          if (isRead != null) 'isRead': isRead,
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _dio!.patch(
        '$_notificationApiContext/notifications/$notificationId/read',
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================================================================
  // API ANALYTICS & MONITORING
  // ==================================================================

  /// Get API usage statistics from WSO2 Analytics
  static Future<Map<String, dynamic>> getApiAnalytics({
    DateTime? fromDate,
    DateTime? toDate,
    String? apiName,
  }) async {
    try {
      final response = await _dio!.get(
        '/analytics/api-usage',
        queryParameters: {
          if (fromDate != null) 'from': fromDate.toIso8601String(),
          if (toDate != null) 'to': toDate.toIso8601String(),
          if (apiName != null) 'api': apiName,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================================================================
  // HELPER METHODS
  // ==================================================================

  /// Handle Dio errors and convert to meaningful exceptions
  static Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message =
            error.response?.data?['message'] ?? 'Server error occurred';
        return Exception('Server error ($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      default:
        return Exception('Network error: ${error.message}');
    }
  }

  /// Get API health status
  static Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final response = await _dio!.get('/health');
      return {
        'status': response.statusCode == 200 ? 'healthy' : 'unhealthy',
        'timestamp': DateTime.now().toIso8601String(),
        'response_time': response.extra['response_time'] ?? 0,
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Dispose resources
  static void dispose() {
    _dio?.close();
    _oauthClient?.close();
  }
}
