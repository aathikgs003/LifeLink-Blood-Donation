import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> verifyEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'user-not-found':
      case 'wrong-password':
        return Exception('Wrong credentials or account not found.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many login attempts. Please try again later.');
      case 'network-request-failed':
        return Exception(
          'Network error. Please check your internet connection.',
        );
      case 'operation-not-allowed':
        return Exception('Email/password login is not enabled.');
      case 'email-already-in-use':
        return Exception('An account already exists for this email.');
      case 'invalid-email':
        return Exception('The email address is invalid.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      default:
        return Exception(
          e.message ?? 'An unknown authentication error occurred.',
        );
    }
  }
}
