import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  bool _animateIn = false;

  static const Color primaryColor = Color(0xFF1F4DF0);
  static const Color neutralColor = Color(0xFF1B1E29);
  static const Color inputBg = Color(0xFFF4F6FF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Title
                _animatedSection(
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Text(
                      "Create Account",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 650),
                  offset: const Offset(0, 0.08),
                ),

                const SizedBox(height: 2),

                /// Subtitle
                _animatedSection(
                  Text(
                    "Join the platform that build smarter",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: neutralColor.withValues(alpha: 0.7),
                    ),
                  ),
                  duration: const Duration(milliseconds: 700),
                ),

                const SizedBox(height: 36),

                /// Email
                _animatedSection(
                  _inputField(hint: "Email", icon: Icons.email_outlined),
                  duration: const Duration(milliseconds: 760),
                ),

                const SizedBox(height: 16),

                /// Password
                _animatedSection(
                  _inputField(
                    hint: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  duration: const Duration(milliseconds: 820),
                ),

                const SizedBox(height: 16),

                /// Confirm Password
                _animatedSection(
                  _inputField(
                    hint: "Confirm Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  duration: const Duration(milliseconds: 880),
                ),

                const SizedBox(height: 20),

                /// Checkbox
                _animatedSection(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: false,
                        onChanged: (value) {},
                        activeColor: primaryColor,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            "I confirm that I am an authorized employee and agree to comply with all IT security policies",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: neutralColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 940),
                ),

                const SizedBox(height: 28),

                /// Sign up Button
                AnimatedScale(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  scale: _animateIn ? 1 : 0.96,
                  child: _animatedSection(
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.dashboard,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 6,
                          shadowColor: primaryColor.withValues(alpha: 0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    duration: const Duration(milliseconds: 980),
                    offset: const Offset(0, 0.1),
                  ),
                ),

                const SizedBox(height: 22),

                /// Login
                _animatedSection(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: neutralColor.withValues(alpha: 0.7),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                          );
                        },
                        child: Text(
                          "Log in",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 1020),
                ),

                const SizedBox(height: 40),

                /// Footer
                _animatedSection(
                  Text(
                    "Secure Access Portal – Managed by the IT Division\nNeed help? Contact: it-support@ICC.com",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: primaryColor.withValues(alpha: 0.85),
                    ),
                  ),
                  duration: const Duration(milliseconds: 1100),
                  offset: const Offset(0, 0.08),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Input Field Widget
  Widget _inputField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        obscureText: isPassword,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            color: neutralColor.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: primaryColor.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: primaryColor.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryColor, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
