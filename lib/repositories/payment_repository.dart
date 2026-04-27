import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepository(this._firestore);

  CollectionReference get _payments => _firestore.collection('payments');

  Future<void> createPayment(PaymentModel payment) async {
    await _payments.doc(payment.paymentId).set(payment.toJson());
  }

  Future<void> updatePayment(PaymentModel payment) async {
    await _payments.doc(payment.paymentId).update(payment.toJson());
  }

  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final doc = await _payments.doc(paymentId).get();
    if (doc.exists) {
      return PaymentModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<PaymentModel>> getPaymentsByUser(String userId) async {
    final docs = await _payments
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return docs.docs
        .map((doc) => PaymentModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<List<PaymentModel>> watchPayments(String userId) {
    return _payments
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }
}
