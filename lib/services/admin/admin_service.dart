import '../../repositories/admin_repository.dart';
import '../../models/user/user_model.dart';
import '../../models/donor/donor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final AdminRepository _adminRepository;

  AdminService(this._adminRepository);

  Future<List<UserModel>> fetchAllUsers() {
    return _adminRepository.getAllUsers();
  }

  Future<UsersPageResult> fetchUsersPage({
    required int pageSize,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc,
    String role = 'all',
    String status = 'all',
    String profile = 'all',
    String city = '',
    String bloodGroup = 'all',
  }) {
    return _adminRepository.getUsersPage(
      pageSize: pageSize,
      startAfterDoc: startAfterDoc,
      role: role,
      status: status,
      profile: profile,
      city: city,
      bloodGroup: bloodGroup,
    );
  }

  Future<List<DonorModel>> fetchPendingDonors() {
    return _adminRepository.getPendingVerifications();
  }

  Future<void> verifyDonor(String donorId) {
    return _adminRepository.updateVerificationStatus(donorId, true);
  }

  Future<void> rejectDonor(String donorId) {
    return _adminRepository.updateVerificationStatus(donorId, false);
  }

  Future<void> promoteToAdmin(String userId) {
    return _adminRepository.updateUserRole(userId, 'admin');
  }
}
