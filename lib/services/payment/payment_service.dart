import '../../models/payment/payment_model.dart';
import '../../repositories/payment_repository.dart';

class PaymentService {
  final PaymentRepository _paymentRepository;

  PaymentService(this._paymentRepository);

  Future<void> initiatePayment(PaymentModel payment) async {
    await _paymentRepository.createPayment(payment);
    // Integration with Razorpay will be handled in UI/Specific Service
  }

  Future<void> completePayment(String paymentId, String razorpayPaymentId,
      String razorpaySignature) async {
    final payment = await _paymentRepository.getPaymentById(paymentId);
    if (payment != null) {
      final updatedPayment = payment.copyWith(
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
        status: 'success',
        completedAt: DateTime.now(),
      );
      await _paymentRepository.updatePayment(updatedPayment);
    }
  }

  Future<List<PaymentModel>> getMyPayments(String userId) {
    return _paymentRepository.getPaymentsByUser(userId);
  }

  Future<bool> processDonation({
    required String userId,
    required double amount,
    required String email,
    required String phone,
  }) async {
    // Save to Firestore first
    final payment = PaymentModel(
      paymentId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      amount: amount,
      currency: 'INR',
      status: 'pending',
      type: 'donation',
      description: 'Platform Donation',
      createdAt: DateTime.now(),
    );
    await _paymentRepository.createPayment(payment);

    // Simulation of payment success
    await Future.delayed(const Duration(seconds: 1));
    await _paymentRepository.updatePayment(
      payment.copyWith(
        status: 'success',
        completedAt: DateTime.now(),
      ),
    );
    return true;
  }
}
