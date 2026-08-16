import '../../data/models/auth_response.dart';
import '../../data/models/signin_response.dart';

abstract class AuthRepository {
  Future<AuthResponse> checkEmail(String email);
  Future<AuthResponse> checkPhone(String phone);
  Future<AuthResponse> signInWithGoogle(String idToken);
  Future<SigninResponse> signInWithEmail(String email, String password);
  Future<SigninResponse> signInWithPhone(String phone, String password);
  Future<AuthResponse> signupWithPhone(
    String name,
    String phone,
    String password,
  );
  Future<SigninResponse> verifyPhone(String phone, String otp);
}
