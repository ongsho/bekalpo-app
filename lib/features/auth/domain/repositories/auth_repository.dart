import '../../data/models/auth_response.dart';
import '../../data/models/signin_response.dart';
import '../../data/models/otp_response.dart';

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
  Future<OtpResponse> sendOtp(String type, String identifier);
  Future<OtpResponse> setPasswordByEmail(
    String email,
    String otp,
    String password,
    String confirmedPassword,
  );
  Future<OtpResponse> setPasswordByPhone(
    String phone,
    String otp,
    String password,
    String confirmedPassword,
  );
}
