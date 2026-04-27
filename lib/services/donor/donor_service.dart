import '../../models/donor/donor_model.dart';
import '../../repositories/donor_repository.dart';
import '../../models/enums.dart';

class DonorService {
  final DonorRepository _donorRepository;

  DonorService(this._donorRepository);

  Future<DonorModel?> getDonorProfile(String userId) async {
    return await _donorRepository.getDonorByUserId(userId);
  }

  Future<void> createDonorProfile(DonorModel donor) async {
    await _donorRepository.createDonor(donor);
  }

  Future<void> updateDonorProfile(DonorModel donor) async {
    await _donorRepository.updateDonor(donor);
  }

  Future<void> updateAvailability(String donorId, bool available) async {
    final donor = await _donorRepository.getDonorById(donorId);
    if (donor != null) {
      final updatedDonor = donor.copyWith(
        isAvailable: available,
        updatedAt: DateTime.now(),
      );
      await _donorRepository.updateDonor(updatedDonor);
    }
  }

  bool isEligibleToDonate(DonorModel donor) {
    if (donor.lastDonationDate == null) return true;
    final nextEligible = donor.lastDonationDate!.add(const Duration(days: 90));
    return DateTime.now().isAfter(nextEligible);
  }

  Future<List<DonorModel>> searchDonors({
    BloodGroup? bloodGroup,
    String? city,
  }) async {
    return await _donorRepository.searchDonors(
      bloodGroup: bloodGroup,
      city: city,
      availableOnly: true,
      verifiedOnly: true,
    );
  }
}
