import 'package:flutter/material.dart';
import 'package:procurax_frontend/services/auth_service.dart';
import 'package:procurax_frontend/theme/app_theme.dart';
import '../../routes/app_routes.dart';

class AccountApprovalDialog extends StatefulWidget {
  const AccountApprovalDialog({super.key});

  @override
  State<AccountApprovalDialog> createState() => _AccountApprovalDialogState();
}

class _AccountApprovalDialogState extends State<AccountApprovalDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Account Created!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  'Your account has been created successfully.\nPlease wait for admin approval to proceed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                // Progress Indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.grey[400]),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Waiting for approval...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go to Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  bool _animateIn = false;

  static const Color primaryColor = AppColors.primary;
  static const Color neutralColor = AppColors.neutral900;
  static const Color inputBg = Color(0xFFF4F6FF);

  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _acceptTerms = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _animateIn = true);
    });
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
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
            child: Form(
              key: _formKey,
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
                    _inputField(
                      hint: "Email",
                      icon: Icons.email_outlined,
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Email is required";
                        }
                        if (!value.contains("@")) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    duration: const Duration(milliseconds: 760),
                  ),

                  const SizedBox(height: 16),

                  /// Password
                  _animatedSection(
                    _inputField(
                      hint: "Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      controller: _passC,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Password is required";
                        }
                        if (value.trim().length < 6) {
                          return "Password too short";
                        }
                        return null;
                      },
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
                      controller: _confirmC,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Confirm your password";
                        }
                        if (value.trim() != _passC.text.trim()) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
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
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() => _acceptTerms = value ?? false);
                          },
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
                          onPressed: _loading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            elevation: 6,
                            shadowColor: primaryColor.withValues(alpha: 0.25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }

  /// Input Field Widget
  Widget _inputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool isPassword = false,
    String? Function(String?)? validator,
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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        validator: validator,
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

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept the policy to continue")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.register(email: _emailC.text, password: _passC.text);
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AccountApprovalDialog(),
      ).then((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      });
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
