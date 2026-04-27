import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/user/user_model.dart';
import '../../models/enums.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';

class AuthService {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthService(this._authRepository, this._userRepository);

  Stream<firebase_auth.User?> get authStateChanges =>
      _authRepository.authStateChanges;

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser != null) {
      return await _userRepository.getUserById(firebaseUser.uid);
    }
    return null;
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final credential = await _authRepository.signIn(email, password);
      if (credential.user != null) {
        final user = await _userRepository.getUserById(credential.user!.uid);
        if (user != null) {
          // Update last login
          final updatedUser = user.copyWith(
              lastLogin: DateTime.now(), updatedAt: DateTime.now());
          await _userRepository.updateUser(updatedUser);
          return updatedUser;
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signUp(
      String email, String password, UserRole role) async {
    try {
      final credential = await _authRepository.signUp(email, password);
      if (credential.user != null) {
        final newUser = UserModel(
          userId: credential.user!.uid,
          email: email,
          role: role,
          emailVerified: true, // Auto-verify email
          lastLogin: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          metadata: {
            'platform': 'android', // For demonstration
            'appVersion': '1.0.0',
          },
        );
        await _userRepository.createUser(newUser);
        return newUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }

  Future<void> verifyEmail() async {
    await _authRepository.verifyEmail();
  }
}
