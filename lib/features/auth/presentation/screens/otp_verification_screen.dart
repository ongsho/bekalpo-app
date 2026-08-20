import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../data/repositories/auth_repository.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phone;
  final bool isSignup;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    this.isSignup = false,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with CodeAutoFill {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void codeUpdated() {
    if (code != null) {
      _otpController.text = code!;
      // Auto-submit when OTP is detected (6 digits)
      if (code!.length == 6) {
        _handleVerify();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    listenForCode();
    // Listen for clipboard changes
    _listenForClipboard();
  }

  void _listenForClipboard() {
    // Check clipboard periodically for OTP
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        final text = clipboardData!.text!;
        // Extract 6-digit OTP from clipboard text
        final otp = _extractOtpFromText(text);
        if (otp != null && otp.length == 6) {
          _otpController.text = otp;
          _handleVerify();
          return false; // Stop listening after successful OTP detection
        }
      }
      return true; // Continue listening
    });
  }

  String? _extractOtpFromText(String text) {
    // Extract 6-digit number from text (works for both English and Bengali SMS)
    final regex = RegExp(r'\b\d{6}\b');
    final match = regex.firstMatch(text);
    return match?.group(0);
  }

  @override
  void dispose() {
    _otpController.dispose();
    cancel();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Format phone number for backend: ensure it starts with 0
      String phoneNumber = widget.phone;
      if (phoneNumber.startsWith('+880')) {
        phoneNumber = phoneNumber.substring(4);
      } else if (phoneNumber.startsWith('880')) {
        phoneNumber = phoneNumber.substring(3);
      }
      if (!phoneNumber.startsWith('0')) {
        phoneNumber = '0$phoneNumber';
      }

      final authRepository = AuthRepositoryImpl();
      final response = await authRepository.verifyPhone(
        phoneNumber,
        _otpController.text.trim(),
      );

      if (response.isSuccess) {
        // Update auth state (will save to shared preferences automatically)
        ref
            .read(authProvider.notifier)
            .login(
              userName: response.user.name,
              userEmail: response.user.email,
              userPhone: response.user.phone,
              token: response.token,
              avatar: response.user.avatar,
            );

        if (mounted) {
          // Navigate back to profile or home
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _extractErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _extractErrorMessage(String error) {
    if (error.contains('Failed to verify phone:')) {
      return error.replaceFirst('Failed to verify phone: ', '');
    }
    return error;
  }

  String _formatPhoneForDisplay(String phone) {
    // Ensure phone starts with 0 for consistency
    String formattedPhone = phone;
    if (formattedPhone.startsWith('+880')) {
      formattedPhone = formattedPhone.substring(4);
    } else if (formattedPhone.startsWith('880')) {
      formattedPhone = formattedPhone.substring(3);
    }
    if (!formattedPhone.startsWith('0')) {
      formattedPhone = '0$formattedPhone';
    }
    // Display as +88001XXXXXXXXX
    return '+880${formattedPhone.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verify Phone',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Illustration or icon
                Icon(
                  Icons.sms_outlined,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Verification Code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Enter the 6-digit code sent to\n${_formatPhoneForDisplay(widget.phone)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // OTP input field with auto-fill support
                PinFieldAutoFill(
                  controller: _otpController,
                  codeLength: 6,
                  onCodeChanged: (code) {
                    if (code != null && code.length == 6) {
                      _handleVerify();
                    }
                  },
                  decoration: BoxLooseDecoration(
                    strokeColorBuilder: PinListenColorBuilder(
                      theme.colorScheme.primary,
                      theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    bgColorBuilder: FixedColorBuilder(
                      theme.colorScheme.surface,
                    ),
                    radius: const Radius.circular(12),
                  ),
                  cursor: Cursor(
                    color: theme.colorScheme.primary,
                    width: 2,
                    height: 24,
                    enabled: true,
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 24),

                // Verify button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand500,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.brand200,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Resend code link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Implement resend OTP
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Resend OTP - TODO')),
                        );
                      },
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
