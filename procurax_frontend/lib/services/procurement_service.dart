import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/models/procurement_view.dart';
import 'package:procurax_frontend/services/api_service.dart';

class ProcurementService {
  static String get _endpoint => "${ApiService.baseUrl}/api/procurement";

  static Future<ProcurementView> fetchView() async {
    try {
      final response = await http
          .get(Uri.parse(_endpoint), headers: ApiService.authHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to load procurement data (status ${response.statusCode})",
        );
      }

      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      return ProcurementView.fromJson(data);
    } on TimeoutException {
      throw Exception(
        "Request timed out. Check that the backend is running and reachable at ${ApiService.baseUrl}.",
      );
    } on http.ClientException catch (err) {
      throw Exception(
        "Network error: ${err.message}. Check the backend URL and device network.",
      );
    }
  }
}
