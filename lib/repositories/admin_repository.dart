import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user/user_model.dart';
import '../models/donor/donor_model.dart';

class UsersPageResult {
  final List<UserModel> users;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  UsersPageResult({
    required this.users,
    required this.lastDoc,
    required this.hasMore,
  });
}

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository(this._firestore);

  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _donors => _firestore.collection('donors');

  Future<List<UserModel>> getAllUsers() async {
    final docs = await _users.orderBy('createdAt', descending: true).get();
    return docs.docs
        .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<UsersPageResult> getUsersPage({
    required int pageSize,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc,
    String role = 'all',
    String status = 'all',
    String profile = 'all',
    String city = '',
    String bloodGroup = 'all',
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection('users').orderBy('createdAt', descending: true);

    if (role != 'all') {
      query = query.where('role', isEqualTo: role);
    }
    if (status == 'active') {
      query = query.where('isActive', isEqualTo: true);
    } else if (status == 'inactive') {
      query = query.where('isActive', isEqualTo: false);
    }
    if (profile == 'complete') {
      query = query.where('profileCompleted', isEqualTo: true);
    } else if (profile == 'incomplete') {
      query = query.where('profileCompleted', isEqualTo: false);
    }

    final normalizedCity = city.trim();
    if (normalizedCity.isNotEmpty) {
      query = query.where('metadata.city', isEqualTo: normalizedCity);
    }
    if (bloodGroup != 'all') {
      query = query.where('metadata.bloodGroup', isEqualTo: bloodGroup);
    }

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final snapshot = await query.limit(pageSize).get();
    final docs = snapshot.docs;

    return UsersPageResult(
      users: docs.map((doc) => UserModel.fromJson(doc.data())).toList(),
      lastDoc: docs.isEmpty ? null : docs.last,
      hasMore: docs.length == pageSize,
    );
  }

  Future<List<DonorModel>> getPendingVerifications() async {
    final docs = await _donors.where('isVerified', isEqualTo: false).get();
    return docs.docs
        .map((doc) => DonorModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateVerificationStatus(String donorId, bool status) async {
    await _donors.doc(donorId).update({'isVerified': status});
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _users.doc(userId).update({'role': role});
  }
}
