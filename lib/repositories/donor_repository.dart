import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donor/donor_model.dart';
import '../models/enums.dart';

class DonorRepository {
  final FirebaseFirestore _firestore;

  DonorRepository(this._firestore);

  CollectionReference get _donors => _firestore.collection('donors');

  Future<DonorModel?> getDonorById(String donorId) async {
    final doc = await _donors.doc(donorId).get();
    if (doc.exists) {
      return DonorModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<DonorModel?> getDonorByUserId(String userId) async {
    final query = await _donors.where('userId', isEqualTo: userId).limit(1).get();
    if (query.docs.isNotEmpty) {
      return DonorModel.fromJson(query.docs.first.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> createDonor(DonorModel donor) async {
    await _donors.doc(donor.donorId).set(donor.toJson());
  }

  Future<void> updateDonor(DonorModel donor) async {
    await _donors.doc(donor.donorId).update(donor.toJson());
  }

  Future<void> updateFcmTokenByUserId(String userId, String token) async {
    final donorSnapshot = await _donors
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (donorSnapshot.docs.isEmpty) {
      return;
    }

    await donorSnapshot.docs.first.reference.update({
      'fcmToken': token,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<DonorModel>> searchDonors({
    BloodGroup? bloodGroup,
    List<BloodGroup>? bloodGroups,
    String? city,
    bool? availableOnly,
    bool? verifiedOnly,
    bool? activeOnly,
  }) async {
    Query query = _donors;
    
    final normalizedBloodGroups = bloodGroups ?? (bloodGroup != null ? [bloodGroup] : null);
    if (normalizedBloodGroups != null && normalizedBloodGroups.isNotEmpty) {
      if (normalizedBloodGroups.length == 1) {
        query = query.where('bloodGroup', isEqualTo: normalizedBloodGroups.first.name);
      } else {
        query = query.where(
          'bloodGroup',
          whereIn: normalizedBloodGroups.map((group) => group.name).toList(),
        );
      }
    } else if (bloodGroup != null) {
      query = query.where('bloodGroup', isEqualTo: bloodGroup.name);
    }
    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }
    if (availableOnly == true) {
      query = query.where('isAvailable', isEqualTo: true);
    }
    if (verifiedOnly == true) {
      query = query.where('verified', isEqualTo: true);
    }
    if (activeOnly == true) {
      query = query.where('isActive', isEqualTo: true);
    }

    final docs = await query.get();
    return docs.docs
        .map((doc) => DonorModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<DonorModel?> watchDonor(String donorId) {
    return _donors.doc(donorId).snapshots().map((doc) {
      if (doc.exists) {
        return DonorModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Stream<DonorModel?> watchDonorByUserId(String userId) {
    return _donors
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((query) {
      if (query.docs.isEmpty) {
        return null;
      }
      return DonorModel.fromJson(query.docs.first.data() as Map<String, dynamic>);
    });
  }
}
