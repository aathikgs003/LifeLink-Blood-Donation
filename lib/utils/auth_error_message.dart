import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'user-not-found':
      case 'wrong-password':
        return 'Wrong email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'An unknown authentication error occurred.';
    }
  }

  final message = error.toString().trim();
  if (message.isEmpty) {
    return 'An unknown authentication error occurred.';
  }

  return message
      .replaceFirst(RegExp(r'^(Exception|FirebaseException|FirebaseAuthException):\s*'), '')
      .replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '')
      .trim();
}
