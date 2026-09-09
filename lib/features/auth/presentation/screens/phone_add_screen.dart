import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/models/contact.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/api_client_provider.dart';

class PhoneAddScreen extends ConsumerStatefulWidget {
  const PhoneAddScreen({super.key});

  @override
  ConsumerState<PhoneAddScreen> createState() => _PhoneAddScreenState();
}

class _PhoneAddScreenState extends ConsumerState<PhoneAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingPhone = false;
  bool _showOtpScreen = false;
  String? _errorMessage;
  String? _phoneNumber;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Normalize phone number for backend (keep 0 prefix)
  /// User enters: 01967569642
  /// App sends: 01967569642
  String _normalizePhoneNumber(String phone) {
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure it starts with 0 for Bangladesh
    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }

    return digits;
  }

  Future<void> _checkPhoneExists() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 11) {
      return;
    }

    setState(() {
      _isCheckingPhone = true;
      _errorMessage = null;
    });

    try {
      // Normalize phone number (keep 0 prefix)
      final normalizedPhone = _normalizePhoneNumber(phone);

      print('PhoneAddScreen: Checking phone: $normalizedPhone');

      // Use the existing ApiClient which has auth interceptors
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        'phones/check',
        data: {'phone': normalizedPhone},
      );

      if (response.data['status'] == false) {
        // Phone does not exist, good to proceed
        setState(() {
          _phoneNumber = normalizedPhone;
          _isCheckingPhone = false;
        });
        print('PhoneAddScreen: Phone is available: $normalizedPhone');
      } else {
        // Phone exists
        setState(() {
          _errorMessage = 'Phone number already exists';
          _isCheckingPhone = false;
        });
        print('PhoneAddScreen: Phone already exists: $normalizedPhone');
      }
    } on DioException catch (e) {
      print(
        'PhoneAddScreen: DioException checking phone: ${e.type} - ${e.message}',
      );
      print('PhoneAddScreen: Response status: ${e.response?.statusCode}');

      String userMessage = 'Error checking phone number';

      if (e.type == DioExceptionType.badResponse) {
        if (e.response?.statusCode == 401) {
          userMessage = 'Authentication required. Please login again.';
        } else if (e.response?.statusCode == 422) {
          userMessage = 'Invalid phone number format';
        } else if (e.response?.statusCode == 429) {
          userMessage = 'Too many requests. Please try again later.';
        } else {
          userMessage = 'Server error. Please try again.';
        }
      } else if (e.type == DioExceptionType.connectionError) {
        userMessage = 'No internet connection';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        userMessage = 'Connection timeout. Please check your internet.';
      }

      setState(() {
        _errorMessage = userMessage;
        _isCheckingPhone = false;
      });
    } catch (e) {
      print('PhoneAddScreen: Unexpected error checking phone: $e');
      setState(() {
        _errorMessage = 'Unexpected error occurred';
        _isCheckingPhone = false;
      });
    }
  }

  Future<void> _handleAddPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 11) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Normalize phone number (keep 0 prefix as per API spec)
      final normalizedPhone = _normalizePhoneNumber(phone);

      print('PhoneAddScreen: Checking phone: $normalizedPhone');

      // Step 1: Check if phone exists
      final apiClient = ref.read(apiClientProvider);
      final checkResponse = await apiClient.post(
        'phones/check',
        data: {'phone': normalizedPhone},
      );

      if (checkResponse.data['status'] != false) {
        // Phone exists
        setState(() {
          _errorMessage = 'Phone number already exists';
          _isLoading = false;
        });
        print('PhoneAddScreen: Phone already exists: $normalizedPhone');
        return;
      }

      // Phone is available, proceed with adding
      print('PhoneAddScreen: Phone is available, adding: $normalizedPhone');
      _phoneNumber = normalizedPhone;

      // Step 2: Add phone
      final response = await apiClient.post(
        'phones',
        data: {'phone': _phoneNumber},
      );

      if (response.data['status'] == 'success' &&
          response.data['action'] == 'otp_send') {
        // Send OTP
        await _sendOtp();
      } else {
        setState(() {
          _errorMessage = 'Failed to add phone';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      print(
        'PhoneAddScreen: DioException adding phone: ${e.type} - ${e.message}',
      );
      print('PhoneAddScreen: Response status: ${e.response?.statusCode}');

      String userMessage = 'Error adding phone number';

      if (e.type == DioExceptionType.badResponse) {
        if (e.response?.statusCode == 401) {
          userMessage = 'Authentication required. Please login again.';
        } else if (e.response?.statusCode == 422) {
          userMessage = 'Invalid phone number format';
        } else {
          userMessage = 'Server error. Please try again.';
        }
      } else if (e.type == DioExceptionType.connectionError) {
        userMessage = 'No internet connection';
      }

      setState(() {
        _errorMessage = userMessage;
        _isLoading = false;
      });
    } catch (e) {
      print('PhoneAddScreen: Unexpected error adding phone: $e');
      setState(() {
        _errorMessage = 'Unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendOtp() async {
    try {
      print('PhoneAddScreen: Sending OTP to: $_phoneNumber');

      // Use the existing ApiClient which has auth interceptors
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        'phones/otp',
        data: {'phone': _phoneNumber},
      );

      if (response.data['status'] == 'success' &&
          response.data['action'] == 'otp') {
        // Show OTP screen
        setState(() {
          _showOtpScreen = true;
          _isLoading = false;
        });
        print('PhoneAddScreen: OTP sent successfully');
      } else {
        setState(() {
          _errorMessage = 'Failed to send OTP';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      print(
        'PhoneAddScreen: DioException sending OTP: ${e.type} - ${e.message}',
      );

      String userMessage = 'Error sending OTP';

      if (e.type == DioExceptionType.badResponse) {
        if (e.response?.statusCode == 401) {
          userMessage = 'Authentication required. Please login again.';
        } else if (e.response?.statusCode == 429) {
          userMessage = 'Too many OTP requests. Please wait.';
        } else {
          userMessage = 'Server error. Please try again.';
        }
      } else if (e.type == DioExceptionType.connectionError) {
        userMessage = 'No internet connection';
      }

      setState(() {
        _errorMessage = userMessage;
        _isLoading = false;
      });
    } catch (e) {
      print('PhoneAddScreen: Unexpected error sending OTP: $e');
      setState(() {
        _errorMessage = 'Unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 4) {
      setState(() {
        _errorMessage = 'Please enter valid OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('PhoneAddScreen: Verifying OTP for: $_phoneNumber');

      // Use the existing ApiClient which has auth interceptors
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        'phones/verify',
        data: {'otp': otp, 'phone': _phoneNumber},
      );

      if (response.data['status'] == 'success') {
        // Phone verified successfully
        print('PhoneAddScreen: Phone verified successfully');

        // Update auth state and navigate back
        await ref.read(authProvider.notifier).refreshUser();

        if (mounted) {
          Navigator.of(context).pop(); // Go back to post-add screen
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid OTP';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      print(
        'PhoneAddScreen: DioException verifying OTP: ${e.type} - ${e.message}',
      );

      String userMessage = 'Error verifying OTP';

      if (e.type == DioExceptionType.badResponse) {
        if (e.response?.statusCode == 401) {
          userMessage = 'Authentication required. Please login again.';
        } else if (e.response?.statusCode == 422) {
          userMessage = 'Invalid or expired OTP';
        } else {
          userMessage = 'Server error. Please try again.';
        }
      } else if (e.type == DioExceptionType.connectionError) {
        userMessage = 'No internet connection';
      }

      setState(() {
        _errorMessage = userMessage;
        _isLoading = false;
      });
    } catch (e) {
      print('PhoneAddScreen: Unexpected error verifying OTP: $e');
      setState(() {
        _errorMessage = 'Unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final existingContacts = authState.userContacts ?? [];

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
          'Add Phone Number',
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
                // Existing contacts section
                if (existingContacts.isNotEmpty) ...[
                  Text(
                    'Your Phone Numbers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...existingContacts.map(
                    (contact) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          Icons.phone,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(contact.value ?? ''),
                        subtitle: Text(contact.type ?? 'Personal'),
                        trailing: contact.isPrimary == true
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Primary',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.star_border),
                                onPressed: () {
                                  // TODO: Set as primary
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                ],

                // Phone input screen
                if (!_showOtpScreen) ...[
                  Text(
                    'Add New Phone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phone input
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      if (value.length >= 11) {
                        _checkPhoneExists();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '017XXXXXXXXX',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      suffixIcon: _isCheckingPhone
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _phoneNumber != null
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      if (value.length < 11) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

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

                  // Add button
                  Material(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _isLoading ? null : _handleAddPhone,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        alignment: Alignment.center,
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
                                'Add & Verify Phone',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Helper text
                  Text(
                    'We will send a verification code to this number',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // OTP verification screen
                if (_showOtpScreen) ...[
                  Text(
                    'Verify Phone Number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code sent to $_phoneNumber',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // OTP input
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '------',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 24),

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

                  // Verify button
                  Material(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _isLoading ? null : _verifyOtp,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        alignment: Alignment.center,
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
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resend OTP link
                  TextButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
