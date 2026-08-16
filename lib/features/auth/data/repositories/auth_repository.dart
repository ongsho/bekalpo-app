import '../../../../core/network/api_service.dart';
import '../models/auth_response.dart';
import '../models/signin_response.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<AuthResponse> checkEmail(String email) async {
    try {
      final response = await ApiService.post(
        'auth/email',
        data: {'email': email},
      );
      final authResponse = AuthResponse.fromJson(response);

      if (!authResponse.status && authResponse.errors != null) {
        throw _extractErrorMessage(authResponse.errors);
      }

      return authResponse;
    } catch (e) {
      throw Exception('Failed to check email: $e');
    }
  }

  @override
  Future<AuthResponse> checkPhone(String phone) async {
    try {
      final response = await ApiService.post(
        'auth/phone',
        data: {'phone': phone},
      );
      final authResponse = AuthResponse.fromJson(response);

      if (!authResponse.status && authResponse.errors != null) {
        throw _extractErrorMessage(authResponse.errors);
      }

      return authResponse;
    } catch (e) {
      throw Exception('Failed to check phone: $e');
    }
  }

  @override
  Future<AuthResponse> signInWithGoogle(String idToken) async {
    try {
      final response = await ApiService.post(
        'auth/signin/google',
        data: {'id_token': idToken},
      );
      final authResponse = AuthResponse.fromJson(response);

      if (!authResponse.status && authResponse.errors != null) {
        throw _extractErrorMessage(authResponse.errors);
      }

      return authResponse;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  String _extractErrorMessage(Map<String, dynamic>? errors) {
    if (errors == null) return 'An error occurred';

    // Extract first error message from errors object
    final firstKey = errors.keys.first;
    final firstError = errors[firstKey];

    if (firstError is List && firstError.isNotEmpty) {
      return firstError[0].toString();
    } else if (firstError is String) {
      return firstError;
    }

    return 'An error occurred';
  }

  @override
  Future<SigninResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await ApiService.post(
        'auth/signin/email',
        data: {'email': email, 'password': password},
      );
      final signinResponse = SigninResponse.fromJson(response);

      if (!signinResponse.isSuccess) {
        throw Exception('Signin failed');
      }

      return signinResponse;
    } catch (e) {
      throw Exception('Failed to sign in with email: $e');
    }
  }

  @override
  Future<SigninResponse> signInWithPhone(String phone, String password) async {
    try {
      final response = await ApiService.post(
        'auth/signin/phone',
        data: {'phone': phone, 'password': password},
      );
      final signinResponse = SigninResponse.fromJson(response);

      if (!signinResponse.isSuccess) {
        throw Exception('Signin failed');
      }

      return signinResponse;
    } catch (e) {
      throw Exception('Failed to sign in with phone: $e');
    }
  }

  @override
  Future<AuthResponse> signupWithPhone(
    String name,
    String phone,
    String password,
  ) async {
    try {
      final response = await ApiService.post(
        'auth/signup/phone',
        data: {'name': name, 'phone': phone, 'password': password},
      );
      final authResponse = AuthResponse.fromJson(response);

      if (!authResponse.status && authResponse.errors != null) {
        throw _extractErrorMessage(authResponse.errors);
      }

      return authResponse;
    } catch (e) {
      throw Exception('Failed to signup with phone: $e');
    }
  }

  @override
  Future<SigninResponse> verifyPhone(String phone, String otp) async {
    try {
      final response = await ApiService.post(
        'auth/verify/phone',
        data: {'phone': phone, 'otp': otp},
      );
      final signinResponse = SigninResponse.fromJson(response);

      if (!signinResponse.isSuccess) {
        throw Exception('Verification failed');
      }

      return signinResponse;
    } catch (e) {
      throw Exception('Failed to verify phone: $e');
    }
  }
}
