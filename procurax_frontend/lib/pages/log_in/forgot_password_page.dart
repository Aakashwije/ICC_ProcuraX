import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:procurax_frontend/services/auth_service.dart';
import 'package:procurax_frontend/widgets/custom_toast.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF1F4DF0);
  static const Color neutralColor = Color(0xFF1B1E29);
  static const Color inputBg = Color(0xFFF4F6FF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);

  final AuthService _authService = AuthService();

  // Controllers
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State
  int _currentStep = 0; // 0 = email, 1 = OTP, 2 = new password, 3 = success
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // ── Production: Timers & tracking ──
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  int _otpExpirySeconds = 0;
  Timer? _otpExpiryTimer;
  int? _attemptsRemaining;
  int _lockoutMinutes = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _cooldownTimer?.cancel();
    _otpExpiryTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _animateToStep(int step) {
    _animController.reset();
    setState(() => _currentStep = step);
    _animController.forward();
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  void _startOTPExpiryTimer(int expiryMinutes) {
    setState(() => _otpExpirySeconds = expiryMinutes * 60);
    _otpExpiryTimer?.cancel();
    _otpExpiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _otpExpirySeconds--;
        if (_otpExpirySeconds <= 0) {
          timer.cancel();
          if (_currentStep == 1) {
            CustomToast.warning(
              context,
              'Your reset code has expired. Please request a new one.',
              title: 'Code Expired',
            );
          }
        }
      });
    });
  }

  String get _formattedExpiry {
    final m = _otpExpirySeconds ~/ 60;
    final s = _otpExpirySeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  // ─── STEP 1: Send OTP ───
  Future<void> _handleSendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      CustomToast.warning(
        context,
        'Please enter a valid email address.',
        title: 'Invalid Email',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _authService.requestPasswordReset(email: email);
      if (!mounted) return;
      final expiresIn = (result['expiresIn'] as int?) ?? 10;
      CustomToast.success(
        context,
        'If an account exists, a 6-digit code has been sent to your email.',
        title: 'Code Sent',
      );
      _startResendCooldown();
      _startOTPExpiryTimer(expiresIn);
      setState(() {
        _attemptsRemaining = null;
      });
      _animateToStep(1);
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      if (e.isLocked) {
        setState(() {
          _lockoutMinutes = e.retryAfter ?? 30;
        });
        CustomToast.error(context, e.message, title: '🔒 Account Locked');
      } else if (e.isRateLimited) {
        CustomToast.warning(context, e.message, title: 'Too Many Requests');
      } else {
        // For security, still navigate to OTP step
        CustomToast.success(
          context,
          'If an account exists, a reset code has been sent to your email.',
          title: 'Code Sent',
        );
        _startResendCooldown();
        _startOTPExpiryTimer(10);
        _animateToStep(1);
      }
    } on TimeoutException {
      if (!mounted) return;
      CustomToast.error(
        context,
        'Server is taking too long. Please check your connection and try again.',
        title: 'Connection Timeout',
      );
    } catch (e) {
      if (!mounted) return;
      CustomToast.success(
        context,
        'If an account exists, a reset code has been sent to your email.',
        title: 'Code Sent',
      );
      _startResendCooldown();
      _startOTPExpiryTimer(10);
      _animateToStep(1);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── STEP 2: Verify OTP ───
  Future<void> _handleVerifyOTP() async {
    final code = _otpCode;
    if (code.length != 6) {
      CustomToast.warning(
        context,
        'Please enter the complete 6-digit code.',
        title: 'Incomplete Code',
      );
      return;
    }

    if (_otpExpirySeconds <= 0) {
      CustomToast.warning(
        context,
        'Your code has expired. Please request a new one.',
        title: 'Code Expired',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.verifyOTP(
        email: _emailController.text.trim(),
        otp: code,
      );
      if (!mounted) return;
      setState(() => _attemptsRemaining = null);
      CustomToast.success(
        context,
        'Code verified! Now set your new password.',
        title: 'Verified ✓',
      );
      _animateToStep(2);
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      if (e.isLocked) {
        setState(() {
          _lockoutMinutes = e.retryAfter ?? 30;
        });
        _showLockoutDialog();
      } else if (e.isExpired) {
        setState(() => _otpExpirySeconds = 0);
        CustomToast.warning(context, e.message, title: 'Code Expired');
      } else if (e.isInvalidOTP) {
        setState(() => _attemptsRemaining = e.attemptsRemaining);
        // Clear OTP fields on wrong code
        for (final c in _otpControllers) {
          c.clear();
        }
        if (_otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
        CustomToast.error(context, e.message, title: 'Wrong Code');
      } else {
        CustomToast.error(context, e.message, title: 'Verification Failed');
      }
    } on TimeoutException {
      if (!mounted) return;
      CustomToast.error(
        context,
        'Server is taking too long. Please try again.',
        title: 'Connection Timeout',
      );
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        title: 'Verification Failed',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── STEP 3: Reset Password ───
  Future<void> _handleResetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.isEmpty) {
      CustomToast.warning(
        context,
        'Please enter a new password.',
        title: 'Missing Password',
      );
      return;
    }

    // Client-side strength check
    final issues = _getPasswordIssues(newPass);
    if (issues.isNotEmpty) {
      CustomToast.warning(
        context,
        'Password must contain ${issues.join(", ")}.',
        title: 'Weak Password',
      );
      return;
    }

    if (newPass != confirmPass) {
      CustomToast.error(
        context,
        'Passwords do not match. Please try again.',
        title: 'Mismatch',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.resetPassword(
        email: _emailController.text.trim(),
        otp: _otpCode,
        newPassword: newPass,
      );
      if (!mounted) return;
      _animateToStep(3);
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      if (e.isWeakPassword) {
        CustomToast.warning(context, e.message, title: 'Weak Password');
      } else if (e.isSamePassword) {
        CustomToast.warning(context, e.message, title: 'Same Password');
      } else if (e.isLocked) {
        setState(() {
          _lockoutMinutes = e.retryAfter ?? 30;
        });
        _showLockoutDialog();
      } else if (e.isExpired) {
        CustomToast.warning(context, e.message, title: 'Code Expired');
        _animateToStep(0);
      } else {
        CustomToast.error(context, e.message, title: 'Reset Failed');
      }
    } on TimeoutException {
      if (!mounted) return;
      CustomToast.error(
        context,
        'Server is taking too long. Please try again.',
        title: 'Connection Timeout',
      );
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        title: 'Reset Failed',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleResendOTP() async {
    if (_resendCooldown > 0) return;
    setState(() => _loading = true);
    try {
      final result = await _authService.requestPasswordReset(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      final expiresIn = (result['expiresIn'] as int?) ?? 10;
      CustomToast.success(
        context,
        'A new code has been sent to your email.',
        title: 'Code Resent',
      );
      _startResendCooldown();
      _startOTPExpiryTimer(expiresIn);
      setState(() => _attemptsRemaining = null);
      // Clear old OTP
      for (final c in _otpControllers) {
        c.clear();
      }
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      if (e.isRateLimited) {
        CustomToast.warning(context, e.message, title: 'Too Many Requests');
      } else if (e.isLocked) {
        setState(() {
          _lockoutMinutes = e.retryAfter ?? 30;
        });
        _showLockoutDialog();
      } else {
        CustomToast.info(
          context,
          'A new code has been sent if the account exists.',
          title: 'Code Resent',
        );
        _startResendCooldown();
        _startOTPExpiryTimer(10);
      }
    } catch (_) {
      if (!mounted) return;
      CustomToast.info(
        context,
        'A new code has been sent if the account exists.',
        title: 'Code Resent',
      );
      _startResendCooldown();
      _startOTPExpiryTimer(10);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Lockout dialog ───
  void _showLockoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dangerRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_rounded, color: dangerRed, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Account Temporarily Locked',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: neutralColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Too many failed verification attempts. For security, password reset is locked for $_lockoutMinutes minutes.\n\nPlease try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: neutralColor.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Password validation helpers ───
  List<String> _getPasswordIssues(String password) {
    final issues = <String>[];
    if (password.length < 8) issues.add('at least 8 characters');
    if (!RegExp(r'[A-Z]').hasMatch(password)) issues.add('an uppercase letter');
    if (!RegExp(r'[a-z]').hasMatch(password)) issues.add('a lowercase letter');
    if (!RegExp(r'[0-9]').hasMatch(password)) issues.add('a number');
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      issues.add('a special character');
    }
    return issues;
  }

  // ─────────────────────── BUILD ───────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentStep < 3
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: primaryColor,
                ),
                onPressed: () {
                  if (_currentStep == 0) {
                    Navigator.pop(context);
                  } else {
                    _animateToStep(_currentStep - 1);
                  }
                },
              ),
              title: Text(
                _currentStep == 0
                    ? 'Forgot Password'
                    : _currentStep == 1
                    ? 'Verify Code'
                    : 'New Password',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: _buildCurrentStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOTPStep();
      case 2:
        return _buildNewPasswordStep();
      case 3:
        return _buildSuccessStep();
      default:
        return const SizedBox();
    }
  }

  // ─── Step Indicator ───
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        final isCurrent = index == _currentStep;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 32 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? primaryColor : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            if (index < 2) const SizedBox(width: 8),
          ],
        );
      }),
    );
  }

  // ─── STEP 0: Email Input ───
  Widget _buildEmailStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildStepIndicator(),
        const SizedBox(height: 40),
        // Icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: inputBg, shape: BoxShape.circle),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          "Reset your password",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter the email address associated with your account and we'll send you a reset code.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: neutralColor.withOpacity(0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              color: neutralColor.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: primaryColor.withOpacity(0.7),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: 'Send Reset Code',
          onPressed: _handleSendOTP,
          icon: Icons.send_rounded,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Back to Login',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: primaryColor.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  // ─── STEP 1: OTP Input ───
  Widget _buildOTPStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildStepIndicator(),
        const SizedBox(height: 40),
        // Icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B),
                  const Color(0xFFF59E0B).withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.pin_rounded, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          "Enter verification code",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: neutralColor.withOpacity(0.6),
              height: 1.5,
            ),
            children: [
              const TextSpan(text: "We've sent a 6-digit code to\n"),
              TextSpan(
                text: _emailController.text.trim(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── OTP Expiry Countdown ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _otpExpirySeconds <= 60
                ? dangerRed.withOpacity(0.08)
                : inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _otpExpirySeconds <= 60
                  ? dangerRed.withOpacity(0.3)
                  : primaryColor.withOpacity(0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: _otpExpirySeconds <= 60
                    ? dangerRed
                    : primaryColor.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                _otpExpirySeconds > 0
                    ? 'Code expires in $_formattedExpiry'
                    : 'Code expired',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _otpExpirySeconds <= 60
                      ? dangerRed
                      : primaryColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),

        // ── Attempts Remaining Warning ──
        if (_attemptsRemaining != null && _attemptsRemaining! <= 3) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: dangerRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: dangerRed),
                const SizedBox(width: 6),
                Text(
                  '$_attemptsRemaining attempt${_attemptsRemaining != 1 ? 's' : ''} remaining',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: dangerRed,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        // OTP Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              width: 48,
              height: 56,
              margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: _otpControllers[index].text.isNotEmpty
                      ? inputBg
                      : Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: primaryColor.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _otpControllers[index].text.isNotEmpty
                          ? primaryColor
                          : const Color(0xFFD1D5DB),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                onChanged: (val) {
                  setState(() {}); // rebuild to update border color
                  if (val.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  }
                  if (val.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                  // Auto-verify when all 6 digits entered
                  if (_otpCode.length == 6) {
                    _handleVerifyOTP();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        _buildPrimaryButton(
          label: 'Verify Code',
          onPressed: _handleVerifyOTP,
          icon: Icons.verified_rounded,
        ),
        const SizedBox(height: 16),
        // Resend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive the code? ",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: neutralColor.withOpacity(0.6),
              ),
            ),
            GestureDetector(
              onTap: _resendCooldown > 0 ? null : _handleResendOTP,
              child: Text(
                _resendCooldown > 0
                    ? 'Resend in ${_resendCooldown}s'
                    : 'Resend',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _resendCooldown > 0
                      ? neutralColor.withOpacity(0.4)
                      : primaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── STEP 2: New Password ───
  Widget _buildNewPasswordStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildStepIndicator(),
        const SizedBox(height: 40),
        // Icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [successGreen, successGreen.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: successGreen.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          "Create new password",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your new password must meet all the requirements below.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: neutralColor.withOpacity(0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        // New password
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'New password',
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              color: neutralColor.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: primaryColor.withOpacity(0.7),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? Icons.visibility_off : Icons.visibility,
                color: primaryColor.withOpacity(0.6),
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Confirm password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Confirm new password',
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              color: neutralColor.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.lock_person_outlined,
              color: primaryColor.withOpacity(0.7),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: primaryColor.withOpacity(0.6),
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Password strength indicator + requirements checklist
        _buildPasswordStrength(),
        _buildPasswordRequirements(),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: 'Reset Password',
          onPressed: _handleResetPassword,
          icon: Icons.check_circle_rounded,
        ),
      ],
    );
  }

  // ─── Password Strength Indicator ───
  Widget _buildPasswordStrength() {
    final password = _newPasswordController.text;
    if (password.isEmpty) return const SizedBox();

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    final labels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'];
    final colors = [
      Colors.red,
      Colors.orange,
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      primaryColor,
    ];

    final index = ((strength - 1) * 4 ~/ 5).clamp(0, 4);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Row(
            children: List.generate(5, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < strength
                        ? colors[index]
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              labels[index],
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors[index],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Password Requirements Checklist ───
  Widget _buildPasswordRequirements() {
    final password = _newPasswordController.text;
    if (password.isEmpty) return const SizedBox();

    final requirements = [
      _PasswordReq('At least 8 characters', password.length >= 8),
      _PasswordReq(
        'An uppercase letter (A-Z)',
        RegExp(r'[A-Z]').hasMatch(password),
      ),
      _PasswordReq(
        'A lowercase letter (a-z)',
        RegExp(r'[a-z]').hasMatch(password),
      ),
      _PasswordReq('A number (0-9)', RegExp(r'[0-9]').hasMatch(password)),
      _PasswordReq(
        'A special character (!@#\$...)',
        RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password),
      ),
    ];

    final confirmPass = _confirmPasswordController.text;
    final showMatch = confirmPass.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password Requirements',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: neutralColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 10),
            ...requirements.map(
              (req) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        req.met
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        key: ValueKey(req.met),
                        size: 18,
                        color: req.met
                            ? successGreen
                            : neutralColor.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      req.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: req.met
                            ? successGreen
                            : neutralColor.withOpacity(0.5),
                        fontWeight: req.met ? FontWeight.w500 : FontWeight.w400,
                        decoration: req.met
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showMatch) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      password == confirmPass
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      key: ValueKey(password == confirmPass),
                      size: 18,
                      color: password == confirmPass
                          ? successGreen
                          : neutralColor.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Passwords match',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: password == confirmPass
                          ? successGreen
                          : neutralColor.withOpacity(0.5),
                      fontWeight: password == confirmPass
                          ? FontWeight.w500
                          : FontWeight.w400,
                      decoration: password == confirmPass
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── STEP 3: Success ───
  Widget _buildSuccessStep() {
    return Column(
      children: [
        const SizedBox(height: 60),
        // Animated check
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [successGreen, successGreen.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: successGreen.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          "Password Reset\nSuccessful!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Your password has been reset successfully.\nYou can now log in with your new password.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: neutralColor.withOpacity(0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        _buildPrimaryButton(
          label: 'Back to Login',
          onPressed: () => Navigator.pop(context),
          icon: Icons.login_rounded,
        ),
      ],
    );
  }

  // ─── Reusable Primary Button ───
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Simple data class for password requirement items
class _PasswordReq {
  final String label;
  final bool met;
  const _PasswordReq(this.label, this.met);
}
