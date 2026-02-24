/*
  ProcurementService

  Handles the HTTP call to the backend procurement endpoint and parses the
  JSON payload into a ProcurementView model used by the UI.
*/
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/models/procurement_view.dart';
import 'package:procurax_frontend/services/api_service.dart';

/*
  Service class with static helpers so the UI can fetch procurement data
  without instantiating a service object.
*/
class ProcurementService {
  /*
    Base endpoint for procurement data, composed from the API base URL.
  */
  static String get _profileEndpoint =>
      "${ApiService.baseUrl}/api/user/profile";

  static String get _endpoint => "${ApiService.baseUrl}/api/procurement";

  static Future<String?> fetchUserSheetUrl() async {
    final response = await http
        .get(Uri.parse(_profileEndpoint), headers: ApiService.authHeaders)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['user']?['googleSheetUrl'] as String?;
    }
    return null;
  }

  /*
    Fetch the procurement view JSON from the backend, apply a timeout, and
    map it into a ProcurementView model.
  */
  static Future<ProcurementView> fetchView() async {
    try {
      final sheetUrl = await fetchUserSheetUrl();

      /*
        Perform GET with auth headers and a 10s timeout.
      */
      final finalEndpoint = sheetUrl != null && sheetUrl.isNotEmpty
          ? "$_endpoint?sheetUrl=${Uri.encodeComponent(sheetUrl)}"
          : _endpoint;

      final response = await http
          .get(Uri.parse(finalEndpoint), headers: ApiService.authHeaders)
          .timeout(const Duration(seconds: 10));

      /*
        Non-200 responses are treated as failures for the UI to handle.
      */
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to load procurement data (status ${response.statusCode})",
        );
      }

      /*
        Decode JSON into a map and convert to the view model.
      */
      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      return ProcurementView.fromJson(data);
    } on TimeoutException {
      /*
        Timeouts provide a user-friendly error message.
      */
      throw Exception(
        "Request timed out. Check that the backend is running and reachable at ${ApiService.baseUrl}.",
      );
    } on http.ClientException catch (err) {
      /*
        Network failures are surfaced with a clear hint.
      */
      throw Exception(
        "Network error: ${err.message}. Check the backend URL and device network.",
      );
    }
  }
}
