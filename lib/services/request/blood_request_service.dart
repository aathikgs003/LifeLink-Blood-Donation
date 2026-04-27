import '../../models/request/blood_request_model.dart';
import '../../models/notification/notification_model.dart';
import '../../models/donor/donor_model.dart';
import '../../repositories/donor_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/request_repository.dart';
import '../../models/enums.dart';

class RequestService {
  final RequestRepository _requestRepository;
  final DonorRepository _donorRepository;
  final NotificationRepository _notificationRepository;

  RequestService(
    this._requestRepository,
    this._donorRepository,
    this._notificationRepository,
  );

  Future<void> createRequest(BloodRequestModel request) async {
    final now = DateTime.now();
    final matchedDonors = await _findMatchingDonors(request);
    final enrichedRequest = request.copyWith(
      matchedDonors: matchedDonors.map((donor) => _buildMatchedDonorEntry(donor, now)).toList(),
      notificationBroadcastAt: matchedDonors.isEmpty ? request.notificationBroadcastAt : now,
      updatedAt: now,
      metadata: {
        ...request.metadata,
        'matchedDonorCount': matchedDonors.length,
      },
    );

    await _requestRepository.createRequest(enrichedRequest);
    await _notifyMatchedDonors(enrichedRequest, matchedDonors, now);
  }

  Future<void> updateRequest(BloodRequestModel request) async {
    await _requestRepository.updateRequest(request);
  }

  Future<void> cancelRequest(String requestId) async {
    final request = await _requestRepository.getRequestById(requestId);
    if (request != null) {
      final now = DateTime.now();
      final updatedRequest = request.copyWith(
        status: RequestStatus.cancelled,
        isActive: false,
        updatedAt: now,
      );
      await _requestRepository.updateRequest(updatedRequest);
      await _notifyRequestClosed(
        updatedRequest,
        now,
        notificationType: NotificationType.requestCancelled,
        title: 'Blood request cancelled',
        body:
            'The request for ${updatedRequest.patientName} has been cancelled. You do not need to respond now.',
      );
    }
  }

  Future<void> completeRequest(String requestId) async {
    final request = await _requestRepository.getRequestById(requestId);
    if (request != null) {
      final now = DateTime.now();
      final updatedRequest = request.copyWith(
        status: RequestStatus.completed,
        isActive: false,
        completedAt: now,
        updatedAt: now,
      );
      await _requestRepository.updateRequest(updatedRequest);
      await _markAcceptedDonorDonationAsCompleted(
        request: updatedRequest,
        completedAt: now,
      );
      await _notifyRequestClosed(
        updatedRequest,
        now,
        notificationType: NotificationType.requestCompleted,
        title: 'Receiver got the blood',
        body:
            '${updatedRequest.patientName} has received the required blood. Thank you for being available to help.',
      );
    }
  }

  Future<bool> donorAcceptRequest(String requestId, String donorUserId) async {
    final donor = await _donorRepository.getDonorByUserId(donorUserId);

    if (donor == null) {
      return false;
    }
    final now = DateTime.now();
    final acceptedEntry = _buildAcceptedDonorEntry(donor, now);

    final updatedRequest = await _requestRepository.acceptRequestByDonor(
      requestId: requestId,
      donorUserId: donorUserId,
      acceptedDonorEntry: acceptedEntry,
      acceptedAt: now,
    );
    if (updatedRequest == null) {
      return false;
    }

    await _notificationRepository.hideRequestNotificationsForOtherDonors(
      requestId: requestId,
      acceptedDonorUserId: donorUserId,
    );

    await _recordDonationForDonor(
      donor: donor,
      request: updatedRequest,
      donatedAt: now,
    );

    await _notifyRequesterOfAcceptedDonor(updatedRequest, donor, now);
    await _notifyRequestClosed(
      updatedRequest,
      now,
      notificationType: NotificationType.requestAccepted,
      title: 'Request accepted by another donor',
      body:
          '${updatedRequest.patientName} has already been matched with a donor. This request is now closed for other donors.',
      excludeRecipientIds: {donor.userId},
    );
    return true;
  }

  Future<void> _recordDonationForDonor({
    required DonorModel donor,
    required BloodRequestModel request,
    required DateTime donatedAt,
  }) async {
    final existingHistory = List<Map<String, dynamic>>.from(donor.donationHistory);
    final alreadyRecorded = existingHistory.any(
      (entry) => entry['requestId']?.toString() == request.requestId,
    );

    if (alreadyRecorded) {
      return;
    }

    final donationEntry = <String, dynamic>{
      'requestId': request.requestId,
      'donationId': '${request.requestId}_${donor.userId}',
      'date': donatedAt.toIso8601String(),
      'donatedAt': donatedAt.toIso8601String(),
      'hospitalName': request.hospitalName,
      'location': request.city,
      'units': request.unitsRequired,
      'status': 'Accepted',
      'donationType': 'Emergency Donation',
      'bloodGroup': donor.bloodGroup.name,
      'patientName': request.patientName,
    };

    final updatedHistory = [donationEntry, ...existingHistory];
    final updatedDonor = donor.copyWith(
      donationCount: donor.donationCount + 1,
      lastDonationDate: donatedAt,
      nextEligibleDonationDate: donatedAt.add(const Duration(days: 90)),
      donationHistory: updatedHistory,
      updatedAt: donatedAt,
    );

    await _donorRepository.updateDonor(updatedDonor);
  }

  Future<void> _markAcceptedDonorDonationAsCompleted({
    required BloodRequestModel request,
    required DateTime completedAt,
  }) async {
    String? acceptedDonorUserId;
    for (final donor in request.acceptedDonors) {
      final userId = donor['userId']?.toString() ?? donor['donorUserId']?.toString();
      if (userId != null && userId.isNotEmpty) {
        acceptedDonorUserId = userId;
        break;
      }
    }

    if (acceptedDonorUserId == null) {
      return;
    }

    final donor = await _donorRepository.getDonorByUserId(acceptedDonorUserId);
    if (donor == null) {
      return;
    }

    final updatedHistory = donor.donationHistory.map((entry) {
      if (entry['requestId']?.toString() != request.requestId) {
        return entry;
      }

      return {
        ...entry,
        'status': 'Completed',
        'completedAt': completedAt.toIso8601String(),
      };
    }).toList();

    final updatedDonor = donor.copyWith(
      donationHistory: updatedHistory,
      updatedAt: completedAt,
    );

    await _donorRepository.updateDonor(updatedDonor);
  }

  Future<List<BloodRequestModel>> getMyRequests(String userId) async {
    return await _requestRepository.getRequestsByUser(userId);
  }

  Future<BloodRequestModel?> getRequestById(String requestId) {
    return _requestRepository.getRequestById(requestId);
  }

  Stream<List<BloodRequestModel>> watchActiveRequests({String? city}) {
    return _requestRepository.watchActiveRequests(city: city);
  }

  Stream<List<BloodRequestModel>> watchRequestsByUser(String userId) {
    return _requestRepository.watchRequestsByUser(userId);
  }

  Stream<BloodRequestModel?> watchRequest(String requestId) {
    return _requestRepository.watchRequest(requestId);
  }

  Future<List<DonorModel>> _findMatchingDonors(BloodRequestModel request) async {
    final donors = await _donorRepository.searchDonors(
      bloodGroups: request.bloodGroupRequired.compatibleDonors,
      availableOnly: true,
      verifiedOnly: true,
      activeOnly: true,
    );

    return donors
        .where((donor) => donor.userId != request.userId)
        .where((donor) => donor.notificationPreferences['emergencyAlerts'] != false)
        .toList();
  }

  Map<String, dynamic> _buildMatchedDonorEntry(DonorModel donor, DateTime now) {
    return {
      'donorId': donor.donorId,
      'userId': donor.userId,
      'name': donor.name,
      'phone': donor.phone,
      'bloodGroup': donor.bloodGroup.name,
      'city': donor.city,
      'status': DonorMatchStatus.invited.name,
      'notifiedAt': now.toIso8601String(),
    };
  }

  Map<String, dynamic> _buildAcceptedDonorEntry(DonorModel donor, DateTime now) {
    return {
      'donorId': donor.donorId,
      'userId': donor.userId,
      'donorUserId': donor.userId,
      'name': donor.name,
      'donorName': donor.name,
      'phone': donor.phone,
      'bloodGroup': donor.bloodGroup.name,
      'city': donor.city,
      'status': DonorMatchStatus.accepted.name,
      'acceptedAt': now.toIso8601String(),
    };
  }

  Future<void> _notifyMatchedDonors(
    BloodRequestModel request,
    List<DonorModel> donors,
    DateTime now,
  ) async {
    for (final donor in donors) {
      final notification = NotificationModel(
        notificationId: _notificationId(request.requestId, donor.userId, 'match'),
        recipientId: donor.userId,
        requestId: request.requestId,
        type: NotificationType.bloodRequest.name,
        title: '${request.bloodGroupRequired.displayName} blood needed',
        body:
            '${request.patientName} needs blood at ${request.hospitalName}, ${request.city}. Please respond if you can donate.',
        data: {
          'requestId': request.requestId,
          'patientName': request.patientName,
          'hospitalName': request.hospitalName,
          'city': request.city,
          'urgencyLevel': request.urgencyLevel.name,
          'contactNumber': request.contactNumber,
          'requesterUserId': request.userId,
          'bloodGroupRequired': request.bloodGroupRequired.name,
          'unitsRequired': request.unitsRequired,
        },
        priority: request.urgencyLevel == UrgencyLevel.critical ? 'high' : 'normal',
        sentAt: now,
        expiresAt: request.expiresAt,
      );
      await _notificationRepository.createNotification(notification);
    }
  }

  Future<void> _notifyRequestClosed(
    BloodRequestModel request,
    DateTime now, {
    required NotificationType notificationType,
    required String title,
    required String body,
    Set<String> excludeRecipientIds = const {},
  }) async {
    final recipientIds = <String>{
      ...request.matchedDonors
          .map((donor) => donor['userId']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty),
      ...request.acceptedDonors
          .map((donor) => donor['userId']?.toString() ?? donor['donorUserId']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty),
    }.difference(excludeRecipientIds);

    for (final recipientId in recipientIds) {
      final notification = NotificationModel(
        notificationId: _notificationId(request.requestId, recipientId, notificationType.name),
        recipientId: recipientId,
        requestId: request.requestId,
        type: notificationType.name,
        title: title,
        body: body,
        data: {
          'requestId': request.requestId,
          'status': request.status.name,
          'patientName': request.patientName,
          'bloodGroupRequired': request.bloodGroupRequired.name,
        },
        priority: 'normal',
        sentAt: now,
        expiresAt: now.add(const Duration(days: 30)),
      );
      await _notificationRepository.createNotification(notification);
    }
  }

  Future<void> _notifyRequesterOfAcceptedDonor(
    BloodRequestModel request,
    DonorModel donor,
    DateTime now,
  ) async {
    final notification = NotificationModel(
      notificationId: _notificationId(
        request.requestId,
        request.userId,
        '${NotificationType.donorAccepted.name}_${donor.userId}',
      ),
      recipientId: request.userId,
      requestId: request.requestId,
      type: NotificationType.donorAccepted.name,
      title: 'A donor accepted your request',
      body:
          '${donor.name} has agreed to donate for ${request.patientName}. The request has been closed for other donors.',
      data: {
        'requestId': request.requestId,
        'donorUserId': donor.userId,
        'donorName': donor.name,
        'donorPhone': donor.phone,
        'status': RequestStatus.accepted.name,
      },
      priority: 'high',
      sentAt: now,
      expiresAt: now.add(const Duration(days: 30)),
    );

    await _notificationRepository.createNotification(notification);
  }

  String _notificationId(String requestId, String recipientId, String suffix) {
    return '${requestId}_${recipientId}_$suffix';
  }
}
