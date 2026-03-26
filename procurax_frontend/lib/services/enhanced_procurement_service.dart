import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/models/procurement_view.dart';
import 'package:procurax_frontend/services/api_service.dart';
import 'package:procurax_frontend/services/wso2_api_service.dart';
import 'package:procurax_frontend/config/wso2_config.dart';

/// Enhanced Procurement Service with WSO2 Integration
///
/// This service provides a unified interface for procurement operations
/// that can work with both your existing backend and WSO2 APIs.
/// It automatically chooses the best data source and provides fallback mechanisms.
class EnhancedProcurementService {
  // Configuration flags
  static bool _useWSO2 = false;
  static bool _enableFallback = true;

  /// Initialize the service and determine which APIs to use
  static Future<void> initialize() async {
    try {
      // Check if WSO2 is available and configured
      if (WSO2Config.isConfigurationValid && WSO2ApiService.isAuthenticated) {
        final healthStatus = await WSO2ApiService.getHealthStatus();
        _useWSO2 = healthStatus['status'] == 'healthy';
      }
    } catch (e) {
      _useWSO2 = false;
    }
  }

  /// Get procurement data with intelligent routing
  static Future<List<ProcurementView>> getProcurementData({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
    bool forceWSO2 = false,
    bool forceBackend = false,
  }) async {
    try {
      // Determine which API to use
      bool shouldUseWSO2 = _useWSO2;
      if (forceWSO2) shouldUseWSO2 = true;
      if (forceBackend) shouldUseWSO2 = false;

      List<ProcurementView> results = [];

      if (shouldUseWSO2) {
        results = await _getProcurementDataFromWSO2(
          page: page,
          limit: limit,
          status: status,
          category: category,
        );
      } else {
        results = await _getProcurementDataFromBackend(
          page: page,
          limit: limit,
          status: status,
          category: category,
        );
      }

      return results;
    } catch (e) {
      // If primary source fails and fallback is enabled, try the other source
      if (_enableFallback && !forceWSO2 && !forceBackend) {
        try {
          if (_useWSO2) {
            return await _getProcurementDataFromBackend(
              page: page,
              limit: limit,
              status: status,
              category: category,
            );
          } else {
            return await _getProcurementDataFromWSO2(
              page: page,
              limit: limit,
              status: status,
              category: category,
            );
          }
        } catch (fallbackError) {
          throw Exception(
            'Both primary and fallback sources failed: ${e.toString()}, ${fallbackError.toString()}',
          );
        }
      }
      rethrow;
    }
  }

  /// Get procurement data from WSO2 APIs
  static Future<List<ProcurementView>> _getProcurementDataFromWSO2({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
  }) async {
    try {
      final data = await WSO2ApiService.getProcurementData(
        page: page,
        limit: limit,
        status: status,
        category: category,
      );

      return data.map((item) => _mapWSO2ToProcurementView(item)).toList();
    } catch (e) {
      throw Exception('WSO2 API Error: ${e.toString()}');
    }
  }

  /// Get procurement data from your existing backend
  static Future<List<ProcurementView>> _getProcurementDataFromBackend({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
  }) async {
    try {
      final endpoint = "${ApiService.baseUrl}/api/procurement";
      final uri = Uri.parse(endpoint).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (status != null) 'status': status,
          if (category != null) 'category': category,
        },
      );

      final response = await http
          .get(uri, headers: ApiService.authHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        if (body is List) {
          return body
              .map(
                (item) =>
                    ProcurementView.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        } else if (body is Map && body.containsKey('data')) {
          final List data = body['data'];
          return data
              .map(
                (item) =>
                    ProcurementView.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
        return [];
      } else {
        throw Exception(
          'Backend API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Backend API Error: ${e.toString()}');
    }
  }

  /// Create procurement request with intelligent routing
  static Future<Map<String, dynamic>> createProcurementRequest({
    required String title,
    required String description,
    required String category,
    required double budget,
    required String urgency,
    List<File>? attachments,
    bool forceWSO2 = false,
    bool forceBackend = false,
  }) async {
    try {
      // Determine which API to use
      bool shouldUseWSO2 = _useWSO2;
      if (forceWSO2) shouldUseWSO2 = true;
      if (forceBackend) shouldUseWSO2 = false;

      if (shouldUseWSO2) {
        return await WSO2ApiService.createProcurementRequest(
          title: title,
          description: description,
          category: category,
          budget: budget,
          urgency: urgency,
          attachments: attachments,
        );
      } else {
        return await _createProcurementRequestInBackend(
          title: title,
          description: description,
          category: category,
          budget: budget,
          urgency: urgency,
          attachments: attachments,
        );
      }
    } catch (e) {
      // Try fallback if enabled
      if (_enableFallback && !forceWSO2 && !forceBackend) {
        if (_useWSO2) {
          return await _createProcurementRequestInBackend(
            title: title,
            description: description,
            category: category,
            budget: budget,
            urgency: urgency,
            attachments: attachments,
          );
        } else {
          return await WSO2ApiService.createProcurementRequest(
            title: title,
            description: description,
            category: category,
            budget: budget,
            urgency: urgency,
            attachments: attachments,
          );
        }
      }
      rethrow;
    }
  }

  /// Create procurement request in your existing backend
  static Future<Map<String, dynamic>> _createProcurementRequestInBackend({
    required String title,
    required String description,
    required String category,
    required double budget,
    required String urgency,
    List<File>? attachments,
  }) async {
    try {
      final endpoint = "${ApiService.baseUrl}/api/procurement";

      var request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers.addAll(ApiService.authHeaders);

      // Add form fields
      request.fields.addAll({
        'title': title,
        'description': description,
        'category': category,
        'budget': budget.toString(),
        'urgency': urgency,
      });

      // Add file attachments
      if (attachments != null) {
        for (int i = 0; i < attachments.length; i++) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'attachments',
              attachments[i].path,
              filename: 'attachment_$i.${attachments[i].path.split('.').last}',
            ),
          );
        }
      }

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception(
          'Backend API Error: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      throw Exception('Backend API Error: ${e.toString()}');
    }
  }

  /// Get user's procurement sheet URL with fallback
  static Future<String?> fetchUserSheetUrl() async {
    try {
      if (_useWSO2) {
        final userProfile = await WSO2ApiService.getUserProfile();
        return userProfile['sheetUrl'] as String?;
      } else {
        // Use existing backend method
        final profileEndpoint = "${ApiService.baseUrl}/api/user/profile";
        final response = await http
            .get(Uri.parse(profileEndpoint), headers: ApiService.authHeaders)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final dynamic body = jsonDecode(response.body);
          if (body is Map && body.containsKey('sheetUrl')) {
            return body['sheetUrl'] as String?;
          }
        }
        return null;
      }
    } catch (e) {
      // Try fallback
      if (_enableFallback) {
        try {
          if (_useWSO2) {
            // Fallback to backend
            final profileEndpoint = "${ApiService.baseUrl}/api/user/profile";
            final response = await http
                .get(
                  Uri.parse(profileEndpoint),
                  headers: ApiService.authHeaders,
                )
                .timeout(const Duration(seconds: 10));

            if (response.statusCode == 200) {
              final dynamic body = jsonDecode(response.body);
              if (body is Map && body.containsKey('sheetUrl')) {
                return body['sheetUrl'] as String?;
              }
            }
          } else {
            // Fallback to WSO2
            final userProfile = await WSO2ApiService.getUserProfile();
            return userProfile['sheetUrl'] as String?;
          }
        } catch (fallbackError) {
          throw Exception(
            'Both sources failed: ${e.toString()}, ${fallbackError.toString()}',
          );
        }
      }
      throw Exception('Failed to fetch user sheet URL: ${e.toString()}');
    }
  }

  /// Map WSO2 response to ProcurementView model
  static ProcurementView _mapWSO2ToProcurementView(
    Map<String, dynamic> wso2Data,
  ) {
    // WSO2 data might be a single procurement request, so we create a view with one item
    final procurementItem = ProcurementItemView.fromJson({
      'materialList': wso2Data['title'] ?? '',
      'responsibility': wso2Data['requester'] ?? '',
      'openingLC': '',
      'etd': '',
      'eta': '',
      'boiApproval': '',
      'revisedDeliveryToSite': wso2Data['required_date'] ?? '',
      'requiredDateCMS': wso2Data['required_date'] ?? '',
      'status': wso2Data['status'] ?? '',
    });

    return ProcurementView(
      procurementItems: [procurementItem],
      upcomingDeliveries: [],
    );
  }

  /// Get service status and configuration
  static Map<String, dynamic> getServiceStatus() {
    return {
      'useWSO2': _useWSO2,
      'enableFallback': _enableFallback,
      'wso2Available': WSO2ApiService.isAuthenticated,
      'wso2ConfigValid': WSO2Config.isConfigurationValid,
      'backendUrl': ApiService.baseUrl,
      'wso2Url': WSO2Config.apiManagerUrl,
    };
  }

  /// Configure service behavior
  static void configure({bool? useWSO2, bool? enableFallback}) {
    if (useWSO2 != null) _useWSO2 = useWSO2;
    if (enableFallback != null) _enableFallback = enableFallback;
  }

  /// Perform health check on all available services
  static Future<Map<String, dynamic>> performHealthCheck() async {
    final results = <String, dynamic>{};

    // Check backend health
    try {
      final backendResponse = await http
          .get(Uri.parse("${ApiService.baseUrl}/health"))
          .timeout(const Duration(seconds: 5));
      results['backend'] = {
        'status': backendResponse.statusCode == 200 ? 'healthy' : 'unhealthy',
        'responseTime':
            '${backendResponse.headers['response-time'] ?? 'unknown'}ms',
      };
    } catch (e) {
      results['backend'] = {'status': 'unhealthy', 'error': e.toString()};
    }

    // Check WSO2 health
    try {
      results['wso2'] = await WSO2ApiService.getHealthStatus();
    } catch (e) {
      results['wso2'] = {'status': 'unhealthy', 'error': e.toString()};
    }

    return results;
  }
}
