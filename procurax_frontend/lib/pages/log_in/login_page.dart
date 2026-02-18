import 'package:flutter/material.dart';
import 'package:procurax_frontend/services/api_service.dart';
import 'package:procurax_frontend/services/auth_service.dart';
import '../../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color primaryColor = Color(0xFF1F4DF0);
  static const Color neutralColor = Color(0xFF1B1E29);
  static const Color inputBg = Color(0xFFF4F6FF);

  bool _animateIn = false;

  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = true;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ApiService.hasToken) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        return;
      }
      setState(() => _animateIn = true);
    });
  }

  Widget _animatedSection(
    Widget child, {
    Duration duration = const Duration(milliseconds: 700),
    Offset offset = const Offset(0, 0.12),
    Curve curve = Curves.easeOutCubic,
  }) {
    return AnimatedSlide(
      duration: duration,
      curve: curve,
      offset: _animateIn ? Offset.zero : offset,
      child: AnimatedOpacity(
        duration: duration,
        curve: curve,
        opacity: _animateIn ? 1 : 0,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  _animatedSection(
                    Text(
                      "Login Here",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    duration: const Duration(milliseconds: 600),
                    offset: const Offset(0, 0.08),
                  ),

                  const SizedBox(height: 8),

                  // subtitle
                  _animatedSection(
                    Text(
                      "Building Efficiency starts with your login",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: neutralColor.withValues(alpha: 0.9),
                      ),
                    ),
                    duration: const Duration(milliseconds: 680),
                  ),

                  const SizedBox(height: 24),

                  // Email - outlined
                  _animatedSection(
                    TextFormField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: neutralColor.withValues(alpha: 0.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        filled: false,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 1.6,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 2.2,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter email';
                        }
                        if (!v.contains('@')) {
                          return 'Enter valid email';
                        }
                        return null;
                      },
                    ),
                    duration: const Duration(milliseconds: 760),
                  ),

                  const SizedBox(height: 16),

                  // Password - filled
                  _animatedSection(
                    TextFormField(
                      controller: _passC,
                      obscureText: _obscure,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: neutralColor.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 2.0,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: primaryColor,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter password';
                        }
                        if (v.trim().length < 6) {
                          return 'Password too short';
                        }
                        return null;
                      },
                    ),
                    duration: const Duration(milliseconds: 820),
                  ),

                  const SizedBox(height: 8),

                  // Remember me toggle
                  _animatedSection(
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? true);
                          },
                          activeColor: primaryColor,
                        ),
                        Text(
                          "Remember me",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: neutralColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 840),
                  ),

                  const SizedBox(height: 4),

                  // Forgot password (right aligned)
                  _animatedSection(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: forgot password action
                          },
                          child: Text(
                            "Forgot your password?",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 860),
                  ),

                  const SizedBox(height: 8),

                  // Sign in button
                  AnimatedScale(
                    duration: const Duration(milliseconds: 850),
                    curve: Curves.easeOutBack,
                    scale: _animateIn ? 1 : 0.96,
                    child: _animatedSection(
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            elevation: 8,
                            shadowColor: primaryColor.withValues(alpha: 0.28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Log in",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      duration: const Duration(milliseconds: 920),
                      offset: const Offset(0, 0.1),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Create new account link
                  _animatedSection(
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.createAccount);
                      },
                      child: Text(
                        "Create new account",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: neutralColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    duration: const Duration(milliseconds: 980),
                  ),

                  const SizedBox(height: 24),

                  // Footer help text
                  _animatedSection(
                    Column(
                      children: [
                        Text(
                          "Need help?",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Contact your Admin officer",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 1040),
                    offset: const Offset(0, 0.08),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await _authService.login(
        email: _emailC.text,
        password: _passC.text,
        rememberMe: _rememberMe,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
