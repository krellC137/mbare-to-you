import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

/// Run this to seed admin user
/// flutter run -t lib/seed_admin.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await seedAdminUser();
}

Future<void> seedAdminUser() async {
  const email = 'admin@mbaretoyou.com';
  const password = 'Admin123!';
  const displayName = 'System Admin';

  try {
    print('Creating admin user...');

    // Create auth user
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final uid = userCredential.user!.uid;
    print('Auth user created with UID: $uid');

    // Update display name
    await userCredential.user!.updateDisplayName(displayName);

    // Create Firestore document
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'id': uid,
      'email': email,
      'displayName': displayName,
      'role': 'admin',
      'isActive': true,
      'isEmailVerified': true,
      'isPhoneVerified': false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    print('✅ Admin user created successfully!');
    print('Email: $email');
    print('Password: $password');
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      print('⚠️ Admin user already exists');
      print('Email: $email');
      print('Password: $password');
    } else {
      print('❌ Error: ${e.message}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  // Exit after seeding
  print('\nDone! You can now close this window.');
}
