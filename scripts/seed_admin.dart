/// Script to seed admin user in Firebase
///
/// Run this script with:
/// dart run scripts/seed_admin.dart
///
/// Or create the admin user manually in Firebase Console:
/// 1. Go to Firebase Console > Authentication > Users
/// 2. Add user with email: admin@mbaretoyou.com, password: Admin123!
/// 3. Go to Firestore > users collection
/// 4. Add document with the user's UID containing the admin data below

import 'dart:io';

void main() {
  print('''
╔════════════════════════════════════════════════════════════════╗
║           MbareToYou Admin User Setup Instructions             ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  To create an admin user, follow these steps:                  ║
║                                                                ║
║  1. Go to Firebase Console (https://console.firebase.google.com)║
║  2. Select your project                                        ║
║                                                                ║
║  STEP 1: Create Authentication User                            ║
║  ─────────────────────────────────────                         ║
║  • Go to: Authentication > Users > Add user                    ║
║  • Email: admin@mbaretoyou.com                                  ║
║  • Password: Admin123!                                          ║
║  • Copy the generated UID                                       ║
║                                                                ║
║  STEP 2: Create Firestore User Document                        ║
║  ─────────────────────────────────────                         ║
║  • Go to: Firestore Database > users collection                ║
║  • Click "Add document"                                        ║
║  • Document ID: [paste the UID from Step 1]                    ║
║  • Add these fields:                                           ║
║                                                                ║
║    id: [same UID]                                              ║
║    email: "admin@mbaretoyou.com"                                ║
║    displayName: "System Admin"                                  ║
║    role: "admin"                                                ║
║    isActive: true                                               ║
║    isEmailVerified: true                                        ║
║    isPhoneVerified: false                                       ║
║    createdAt: [timestamp - now]                                 ║
║    updatedAt: [timestamp - now]                                 ║
║                                                                ║
║  ADMIN CREDENTIALS:                                             ║
║  ──────────────────                                             ║
║  Email:    admin@mbaretoyou.com                                  ║
║  Password: Admin123!                                             ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

JSON format for Firestore document:

{
  "id": "<UID_FROM_AUTH>",
  "email": "admin@mbaretoyou.com",
  "displayName": "System Admin",
  "role": "admin",
  "isActive": true,
  "isEmailVerified": true,
  "isPhoneVerified": false,
  "createdAt": "<TIMESTAMP>",
  "updatedAt": "<TIMESTAMP>"
}

Press Enter to exit...
''');

  stdin.readLineSync();
}
