import 'package:flutter/material.dart';
import 'package:procurax_frontend/pages/log_in/login_page.dart';
import 'package:procurax_frontend/services/api_service.dart';

class AuthGate extends StatelessWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!ApiService.hasToken) {
      return const LoginPage();
    }
    return child;
  }
}
