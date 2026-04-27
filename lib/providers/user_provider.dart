import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user/user_model.dart';
import 'service_providers.dart';

class UserNotifier extends StateNotifier<UserModel?> {
  final Ref _ref;

  UserNotifier(this._ref) : super(null) {
    _ref.listen(currentUserStreamProvider, (previous, next) {
      next.whenData((user) => state = user);
    });
    _init();
  }

  Future<void> _init() async {
    final user = await _ref.read(authServiceProvider).getCurrentUser();
    if (user != state) {
      state = user;
    }
  }

  void setUser(UserModel? user) => state = user;

  Future<void> refreshUser() async {
    final user = await _ref.read(authServiceProvider).getCurrentUser();
    state = user;
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier(ref);
});

final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.asyncMap((firebaseUser) async {
    if (firebaseUser == null) return null;
    return await authService.getCurrentUser();
  });
});
