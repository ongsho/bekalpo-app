import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/auth_mode.dart';
import '../../data/repositories/auth_repository.dart';
import 'email_signin_screen.dart';
import 'set_password_screen.dart';
import 'phone_signup_screen.dart';
import 'phone_signin_screen.dart';
import 'otp_verification_screen.dart';

class AuthEntryScreen extends ConsumerStatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  ConsumerState<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends ConsumerState<AuthEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  AuthMode _authMode = AuthMode.phone;
  String _countryCode = '+880';
  bool _isLoading = false;
  String? _errorMessage;

  // Google Sign-In
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Cached Google account (for One-Tap)
  GoogleSignInAccount? _cachedGoogleAccount;

  @override
  void initState() {
    super.initState();
    _loadCachedGoogleAccount();
    // Auto focus phone input field when phone mode is default
    if (_authMode == AuthMode.phone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _phoneFocusNode.requestFocus();
      });
    }
  }

  Future<void> _loadCachedGoogleAccount() async {
    final account = await _googleSignIn.signInSilently();
    if (mounted) {
      setState(() {
        _cachedGoogleAccount = account;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.email ? AuthMode.phone : AuthMode.email;
      _errorMessage = null;
      // Clear the inactive mode's input
      if (_authMode == AuthMode.email) {
        _phoneController.clear();
        _phoneFocusNode.unfocus();
      } else {
        _emailController.clear();
        // Auto focus phone field when switching to phone mode
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _phoneFocusNode.requestFocus();
        });
      }
    });
  }

  bool _isInputValid() {
    if (_authMode == AuthMode.email) {
      return _isValidEmail(_emailController.text.trim());
    } else {
      return _isValidPhone(_phoneController.text.trim());
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Accept both formats: 01967569642 (11 digits with leading 0) or 1967569642 (10 digits without leading 0)
    final phoneWithZero = RegExp(r'^0[0-9]{10}$'); // 0 followed by 10 digits
    final phoneWithoutZero = RegExp(r'^[0-9]{10}$'); // exactly 10 digits
    return phoneWithZero.hasMatch(phone) || phoneWithoutZero.hasMatch(phone);
  }

  String? _getPhoneErrorMessage(String phone) {
    if (phone.isEmpty) {
      return 'Please enter your phone number';
    }

    // Check if it contains any non-digit characters (except leading +)
    final cleanPhone = phone.replaceAll('+', '');
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return 'Phone number can only contain digits';
    }

    // Check length and format
    final phoneWithZero = RegExp(r'^0[0-9]{10}$');
    final phoneWithoutZero = RegExp(r'^[0-9]{10}$');

    if (phoneWithZero.hasMatch(phone)) {
      return null; // Valid format: 01967569642
    }

    if (phoneWithoutZero.hasMatch(phone)) {
      return null; // Valid format: 1967569642
    }

    // Provide specific error message based on the issue
    if (phone.startsWith('+880') || phone.startsWith('880')) {
      return 'Please enter number without country code (e.g., 01967569642)';
    }

    if (phone.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (phone.length > 11) {
      return 'Phone number cannot exceed 11 digits';
    }

    return 'Invalid phone format. Use 01967569642 or 1967569642';
  }

  // Format phone number for backend: always send clean number starting with 0
  String _formatPhoneNumberForBackend(String phoneNumber) {
    // Remove any existing country code prefix if present
    if (phoneNumber.startsWith('+880')) {
      phoneNumber = phoneNumber.substring(4);
    } else if (phoneNumber.startsWith('880')) {
      phoneNumber = phoneNumber.substring(3);
    }
    // Ensure number starts with 0
    if (!phoneNumber.startsWith('0')) {
      phoneNumber = '0$phoneNumber';
    }
    return phoneNumber;
  }

  String _extractErrorMessage(String error) {
    // Clean up exception messages
    if (error.contains('Failed to check email:')) {
      return error.replaceFirst('Failed to check email: ', '');
    } else if (error.contains('Failed to check phone:')) {
      return error.replaceFirst('Failed to check phone: ', '');
    } else if (error.contains('Failed to sign in with Google:')) {
      return error.replaceFirst('Failed to sign in with Google: ', '');
    }
    return error;
  }

  Future<void> _handleContinue() async {
    // Validate phone number format before proceeding
    if (_authMode == AuthMode.phone) {
      final phoneInput = _phoneController.text.trim();
      final phoneError = _getPhoneErrorMessage(phoneInput);
      if (phoneError != null) {
        setState(() {
          _errorMessage = phoneError;
        });
        return;
      }
    }

    if (!_isInputValid()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = AuthRepositoryImpl();

      if (_authMode == AuthMode.email) {
        final email = _emailController.text.trim();
        final response = await authRepository.checkEmail(email);

        if (!mounted) return;

        if (response.requiresSignup) {
          // Navigate to signup flow
          _navigateToSignup(email: email);
        } else if (response.requiresSignin) {
          // Navigate to signin flow
          _navigateToSignin(email: email);
        } else if (response.requiresSetPassword) {
          // Navigate to set password flow (Google user without password)
          _navigateToSetPassword(email: email);
        }
      } else {
        // Format phone number: ensure it starts with 0, send clean number without country code prefix
        final phoneNumber = _formatPhoneNumberForBackend(
          _phoneController.text.trim(),
        );
        final response = await authRepository.checkPhone(phoneNumber);

        if (!mounted) return;

        if (response.requiresPhoneSignup) {
          // Navigate to phone signup flow
          _navigateToPhoneSignup(phone: phoneNumber);
        } else if (response.requiresPhoneVerify) {
          // Navigate to OTP verification flow
          _navigateToPhoneVerify(phone: phoneNumber);
        } else if (response.requiresPhoneSignin) {
          // Navigate to phone signin flow
          _navigateToPhoneSignin(phone: phoneNumber);
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication authentication =
          await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      final authRepository = AuthRepositoryImpl();
      final response = await authRepository.signInWithGoogle(idToken);

      if (response.status) {
        // Handle successful Google sign-in
        if (mounted) {
          _handleAuthSuccess(response);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _extractErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  void _handleAuthSuccess(dynamic response) {
    // Store token and update auth state
    // TODO: Extract user data from response and update auth state
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Authentication successful')));
  }

  void _navigateToSignup({required String email}) {
    // TODO: Implement navigation to email signup screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Navigate to email signup: $email (New user - email doesn\'t exist)',
        ),
      ),
    );
  }

  void _navigateToSignin({required String email}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EmailSigninScreen(email: email)),
    );
  }

  void _navigateToPhoneSignup({required String phone}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PhoneSignupScreen(phone: _formatPhoneForDisplay(phone)),
      ),
    );
  }

  void _navigateToPhoneVerify({required String phone}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OtpVerificationScreen(phone: _formatPhoneForDisplay(phone)),
      ),
    );
  }

  void _navigateToPhoneSignin({required String phone}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PhoneSigninScreen(phone: _formatPhoneForDisplay(phone)),
      ),
    );
  }

  // Format phone number for display (add country code)
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

  void _navigateToSetPassword({required String email}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SetPasswordScreen(email: email)),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
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
                // Heading
                Text(
                  _authMode.heading,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Input field based on mode
                if (_authMode == AuthMode.email)
                  _EmailInputField(
                    controller: _emailController,
                    errorMessage: _errorMessage,
                    onChanged: () => setState(() {}),
                  )
                else
                  _PhoneInputField(
                    phoneController: _phoneController,
                    phoneFocusNode: _phoneFocusNode,
                    countryCode: _countryCode,
                    onCountryCodeChanged: (code) {
                      setState(() {
                        _countryCode = code;
                      });
                    },
                    errorMessage: _errorMessage,
                    onChanged: () {
                      setState(() {
                        // Clear error when user starts typing
                        _errorMessage = null;
                      });
                    },
                  ),

                const SizedBox(height: 24),

                // Error message display
                if (_errorMessage != null && _authMode == AuthMode.phone)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),

                // Continue button
                ElevatedButton(
                  onPressed: _isInputValid() && !_isLoading
                      ? _handleContinue
                      : null,
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
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor)),
                  ],
                ),

                const SizedBox(height: 24),

                // Google One-Tap suggestion chip
                if (_cachedGoogleAccount != null)
                  _GoogleOneTapChip(
                    account: _cachedGoogleAccount!,
                    onTap: _handleGoogleSignIn,
                  ),

                const SizedBox(height: 16),

                // Mode switch button
                TextButton.icon(
                  onPressed: _toggleAuthMode,
                  icon: Icon(
                    _authMode.toggleIcon,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    _authMode.toggleText,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Footer
                _Footer(
                  onTermsTap: () => _launchUrl('https://bekalpo.com/tos'),
                  onPrivacyTap: () =>
                      _launchUrl('https://bekalpo.com/privacy-policy'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorMessage;
  final VoidCallback onChanged;

  const _EmailInputField({
    required this.controller,
    this.errorMessage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surface,
        prefixIcon: Icon(
          Icons.email_outlined,
          color: theme.colorScheme.primary,
        ),
        hintText: 'info@gmail.com',
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorText: errorMessage,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }
}

class _PhoneInputField extends StatelessWidget {
  final TextEditingController phoneController;
  final FocusNode phoneFocusNode;
  final String countryCode;
  final Function(String) onCountryCodeChanged;
  final String? errorMessage;
  final VoidCallback onChanged;

  const _PhoneInputField({
    required this.phoneController,
    required this.phoneFocusNode,
    required this.countryCode,
    required this.onCountryCodeChanged,
    this.errorMessage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Country code picker
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CountryCodePicker(
            onChanged: (country) {
              onCountryCodeChanged(country.dialCode!);
            },
            initialSelection: 'BD',
            favorite: const ['+880', 'BD'],
            showCountryOnly: false,
            showOnlyCountryWhenClosed: false,
            alignLeft: false,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 12),
        // Phone number input
        Expanded(
          child: TextFormField(
            controller: phoneController,
            focusNode: phoneFocusNode,
            autofocus: true,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              hintText: '01900000000',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorText: errorMessage,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleOneTapChip extends StatelessWidget {
  final GoogleSignInAccount account;
  final VoidCallback onTap;

  const _GoogleOneTapChip({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundImage: account.photoUrl != null
                  ? NetworkImage(account.photoUrl!)
                  : null,
              child: account.photoUrl == null
                  ? Icon(
                      Icons.person,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name and email
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account.displayName ?? 'User',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  account.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Google icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Text(
                'G',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const _Footer({required this.onTermsTap, required this.onPrivacyTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          height: 1.5,
        ),
        children: [
          const TextSpan(
            text: 'By signing up for an account you agree to our ',
          ),
          WidgetSpan(
            child: GestureDetector(
              onTap: onTermsTap,
              child: Text(
                'Terms of Service',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            child: GestureDetector(
              onTap: onPrivacyTap,
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
