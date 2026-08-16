import 'package:flutter/material.dart';

enum AuthMode { email, phone }

extension AuthModeExtension on AuthMode {
  String get heading {
    switch (this) {
      case AuthMode.email:
        return 'Continue with Email';
      case AuthMode.phone:
        return 'Continue with Phone';
    }
  }

  String get toggleText {
    switch (this) {
      case AuthMode.email:
        return 'Continue with Phone';
      case AuthMode.phone:
        return 'Continue with Email';
    }
  }

  IconData get toggleIcon {
    switch (this) {
      case AuthMode.email:
        return Icons.phone;
      case AuthMode.phone:
        return Icons.email;
    }
  }
}
