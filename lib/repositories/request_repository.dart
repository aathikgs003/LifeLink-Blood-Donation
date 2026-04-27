import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request/blood_request_model.dart';
import '../models/enums.dart';

class RequestRepository {
  final FirebaseFirestore _firestore;

  RequestRepository(this._firestore);

  CollectionReference get _requests => _firestore.collection('requests');

  bool _isTerminalStatus(RequestStatus status) {
    return status == RequestStatus.accepted ||
        status == RequestStatus.completed ||
        status == RequestStatus.cancelled ||
        status == RequestStatus.expired;
  }

  List<BloodRequestModel> _filterAndSortActiveRequests(
    List<BloodRequestModel> requests, {
    String? city,
  }) {
    final normalizedCity = city?.trim().toLowerCase();

    final filteredRequests = requests.where((request) {
      final isActiveRequest = request.isActive &&
          request.status != RequestStatus.accepted &&
          request.status != RequestStatus.completed &&
          request.status != RequestStatus.cancelled &&
          request.status != RequestStatus.expired;
      if (!isActiveRequest) {
        return false;
      }

      if (normalizedCity == null || normalizedCity.isEmpty) {
        return true;
      }

      return request.city.trim().toLowerCase() == normalizedCity;
    }).toList();

    filteredRequests.sort(
      (left, right) => right.createdAt.compareTo(left.createdAt),
    );

    return filteredRequests;
  }

  Future<BloodRequestModel?> getRequestById(String requestId) async {
    final doc = await _requests.doc(requestId).get();
    if (doc.exists) {
      return BloodRequestModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> createRequest(BloodRequestModel request) async {
    await _requests.doc(request.requestId).set(request.toJson());
  }

  Future<void> updateRequest(BloodRequestModel request) async {
    await _requests.doc(request.requestId).update(request.toJson());
  }

  Future<BloodRequestModel?> acceptRequestByDonor({
    required String requestId,
    required String donorUserId,
    required Map<String, dynamic> acceptedDonorEntry,
    required DateTime acceptedAt,
  }) {
    return _firestore.runTransaction((transaction) async {
      final requestRef = _requests.doc(requestId);
      final requestSnapshot = await transaction.get(requestRef);

      if (!requestSnapshot.exists) {
        return null;
      }

      final request = BloodRequestModel.fromJson(
        requestSnapshot.data() as Map<String, dynamic>,
      );

      final alreadyAcceptedByCurrentDonor = request.acceptedDonors.any(
        (acceptedDonor) =>
            acceptedDonor['userId']?.toString() == donorUserId ||
            acceptedDonor['donorUserId']?.toString() == donorUserId,
      );
      if (alreadyAcceptedByCurrentDonor) {
        return request;
      }

      if (!request.isActive || _isTerminalStatus(request.status)) {
        return null;
      }

      final updatedMatchedDonors = request.matchedDonors.map((matchedDonor) {
        final matchedUserId = matchedDonor['userId']?.toString();
        if (matchedUserId == donorUserId) {
          return {
            ...matchedDonor,
            'status': DonorMatchStatus.accepted.name,
            'respondedAt': acceptedAt.toIso8601String(),
          };
        }

        if (matchedDonor['status'] == DonorMatchStatus.invited.name) {
          return {
            ...matchedDonor,
            'status': DonorMatchStatus.noResponse.name,
            'closedAt': acceptedAt.toIso8601String(),
          };
        }
        return matchedDonor;
      }).toList();

      final updatedRequest = request.copyWith(
        acceptedDonors: [...request.acceptedDonors, acceptedDonorEntry],
        matchedDonors: updatedMatchedDonors,
        status: RequestStatus.accepted,
        isActive: false,
        updatedAt: acceptedAt,
        metadata: {
          ...request.metadata,
          'acceptedByDonorUserId': donorUserId,
          'acceptedAt': acceptedAt.toIso8601String(),
        },
      );

      transaction.update(requestRef, updatedRequest.toJson());
      return updatedRequest;
    });
  }

  Future<List<BloodRequestModel>> getRequestsByUser(String userId) async {
    final docs = await _requests
        .where('userId', isEqualTo: userId)
        .get();
    final requests = docs.docs
        .map((doc) => BloodRequestModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    requests.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return requests;
  }

  Future<List<BloodRequestModel>> getActiveRequests() async {
    final docs = await _requests
      .where('isActive', isEqualTo: true)
        .get();
    final requests = docs.docs
        .map((doc) => BloodRequestModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    return _filterAndSortActiveRequests(requests);
  }

  Stream<List<BloodRequestModel>> watchActiveRequests({String? city}) {
    return _requests
      .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList())
      .map((requests) => _filterAndSortActiveRequests(requests, city: city));
  }

  Stream<BloodRequestModel?> watchRequest(String requestId) {
    return _requests.doc(requestId).snapshots().map((doc) {
      if (doc.exists) {
        return BloodRequestModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Stream<List<BloodRequestModel>> watchRequestsByUser(String userId) {
    return _requests
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList())
        .map((requests) {
          requests.sort((left, right) => right.createdAt.compareTo(left.createdAt));
          return requests;
        });
  }
}
