import 'package:lifelink_blood/models/user/user_model.dart';
import 'package:lifelink_blood/repositories/user_repository.dart';

class UserService {
  final UserRepository _userRepository;

  UserService(this._userRepository);

  Future<void> updateUserProfile(
    String userId, {
    String? fullName,
    String? phone,
    String? profileImageUrl,
    bool? profileCompleted,
    Map<String, String>? metadata,
  }) async {
    final user = await _userRepository.getUserById(userId);
    if (user != null) {
      final updatedUser = user.copyWith(
        fullName: fullName ?? user.fullName,
        phone: phone ?? user.phone,
        profileImageUrl: profileImageUrl ?? user.profileImageUrl,
        profileCompleted: profileCompleted ?? user.profileCompleted,
        metadata:
            metadata != null ? {...user.metadata, ...metadata} : user.metadata,
        updatedAt: DateTime.now(),
      );
      await _userRepository.updateUser(updatedUser);
    }
  }

  Future<UserModel?> getUser(String userId) async {
    return await _userRepository.getUserById(userId);
  }
}
