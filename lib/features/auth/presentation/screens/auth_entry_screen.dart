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

class AuthEntryScreen extends ConsumerStatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  ConsumerState<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends ConsumerState<AuthEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  AuthMode _authMode = AuthMode.email;
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
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.email ? AuthMode.phone : AuthMode.email;
      _errorMessage = null;
      // Clear the inactive mode's input
      if (_authMode == AuthMode.email) {
        _phoneController.clear();
      } else {
        _emailController.clear();
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
    // Basic validation - at least 10 digits for most countries
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
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
        final phone = '$_countryCode${_phoneController.text.trim()}';
        final response = await authRepository.checkPhone(phone);

        if (!mounted) return;

        if (response.requiresSignup) {
          // Navigate to phone signup flow
          _navigateToPhoneSignup(phone: phone);
        } else if (response.requiresSignin) {
          // Navigate to phone signin flow
          _navigateToPhoneSignin(phone: phone);
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
    // TODO: Implement navigation to phone signup screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navigate to phone signup: $phone')));
  }

  void _navigateToPhoneSignin({required String phone}) {
    // TODO: Implement navigation to phone signin screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navigate to phone signin: $phone')));
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
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Heading
                Text(
                  _authMode.heading,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
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
                    countryCode: _countryCode,
                    onCountryCodeChanged: (code) {
                      setState(() {
                        _countryCode = code;
                      });
                    },
                    errorMessage: _errorMessage,
                    onChanged: () => setState(() {}),
                  ),

                const SizedBox(height: 24),

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
                    const Expanded(
                      child: Divider(color: AppColors.surfaceBorder),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.surfaceBorder),
                    ),
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
                  icon: Icon(_authMode.toggleIcon, color: AppColors.brand500),
                  label: Text(
                    _authMode.toggleText,
                    style: const TextStyle(
                      color: AppColors.brand500,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Footer
                _Footer(
                  onTermsTap: () => _launchUrl('https://bekalpo.com/terms'),
                  onPrivacyTap: () => _launchUrl('https://bekalpo.com/privacy'),
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
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.brand25,
        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.brand500),
        hintText: 'info@gmail.com',
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
  final String countryCode;
  final Function(String) onCountryCodeChanged;
  final String? errorMessage;
  final VoidCallback onChanged;

  const _PhoneInputField({
    required this.phoneController,
    required this.countryCode,
    required this.onCountryCodeChanged,
    this.errorMessage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Country code picker
        Container(
          decoration: BoxDecoration(
            color: AppColors.brand25,
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
            keyboardType: TextInputType.phone,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.brand25,
              hintText: '1900000000',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              errorText: errorMessage,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              final phoneRegex = RegExp(r'^[0-9]{10,15}$');
              if (!phoneRegex.hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.brand25,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.brand100),
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
                  ? const Icon(Icons.person, size: 20)
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  account.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Google icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
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
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textGray,
          height: 1.5,
        ),
        children: [
          const TextSpan(
            text: 'By signing up for an account you agree to our ',
          ),
          WidgetSpan(
            child: GestureDetector(
              onTap: onTermsTap,
              child: const Text(
                'Terms of Service',
                style: TextStyle(
                  color: AppColors.brand500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            child: GestureDetector(
              onTap: onPrivacyTap,
              child: const Text(
                'Privacy Policy',
                style: TextStyle(
                  color: AppColors.brand500,
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
