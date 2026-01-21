import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/models/procurement_item.dart';

class ProcurementService {
  // ⚠️ Replace with your machine IP if using phone
static const String apiUrl =
    "http://192.168.1.174:3000/api/procurement";


  static Future<List<ProcurementItem>> fetchItems() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      throw Exception("Failed to load procurement data");
    }

    final List data = json.decode(response.body);
    return data.map((e) => ProcurementItem.fromJson(e)).toList();
  }
}
