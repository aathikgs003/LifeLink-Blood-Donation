import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  CollectionReference get _users => _firestore.collection('users');

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _users.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.userId).set(user.toJson());
  }

  Future<void> updateUser(UserModel user) async {
    await _users.doc(user.userId).update(user.toJson());
  }

  Future<void> updateFCMToken(String userId, String token) async {
    await _users.doc(userId).update({'fcmToken': token});
  }

  Future<void> deleteUser(String userId) async {
    await _users.doc(userId).delete();
  }

  Stream<UserModel?> watchUser(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
