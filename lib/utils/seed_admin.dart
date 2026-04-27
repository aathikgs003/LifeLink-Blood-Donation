import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  final String email = 'admin@lifelink.com';
  final String password = 'AdminPassword123!';

  try {
    print('👤 Creating Admin Auth account...');
    UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _updateFirestore(credential.user!.uid, email);
    print('✅ SUCCESS: New Admin created!');
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      print('ℹ️ User already exists in Auth. Looking up ID...');
      // We can sign in to get the UID for the Firestore update
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      await _updateFirestore(cred.user!.uid, email);
      print('✅ SUCCESS: Existing user promoted to Admin!');
    } else {
      print('❌ AUTH ERROR: ${e.toString()}');
    }
  } catch (e) {
    print('❌ ERROR: ${e.toString()}');
  }
}

Future<void> _updateFirestore(String uid, String email) async {
  print('📂 Setting Admin role in Firestore for $email...');
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'userId': uid,
    'email': email,
    'role': 'admin',
    'lastLogin': FieldValue.serverTimestamp(),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'metadata': {
      'type': 'super_admin',
      'isSeeded': true,
    }
  }, SetOptions(merge: true));
}
