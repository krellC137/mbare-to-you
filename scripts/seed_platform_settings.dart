/// Script to seed platform settings in Firestore
///
/// Run this script with:
/// dart run scripts/seed_platform_settings.dart
///
/// Or from admin_web app:
/// cd apps/admin_web
/// flutter run -t lib/seed_platform_settings.dart -d chrome

import 'dart:io';

void main() {
  print('''
╔════════════════════════════════════════════════════════════════╗
║         MbareToYou Platform Settings Setup Instructions        ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  To initialize platform settings, follow these steps:          ║
║                                                                ║
║  1. Go to Firebase Console (https://console.firebase.google.com)║
║  2. Select your project: mbaretoyou                            ║
║                                                                ║
║  STEP 1: Create Platform Settings Document                     ║
║  ──────────────────────────────────────                         ║
║  • Go to: Firestore Database > settings collection             ║
║  • Click "Add document"                                        ║
║  • Document ID: platform_settings                              ║
║  • Add these fields:                                           ║
║                                                                ║
║    id: "platform_settings"                                     ║
║    deliveryFeePercentage: 10.0                                 ║
║    platformFeePercentage: 5.0                                  ║
║    minimumOrderAmount: 0.0                                     ║
║    baseDeliveryFee: 5.0                                        ║
║    isDeliveryFeePercentageBased: true                          ║
║    updatedAt: [timestamp - now]                                ║
║    updatedBy: "system"                                         ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

JSON format for Firestore document:

{
  "id": "platform_settings",
  "deliveryFeePercentage": 10.0,
  "platformFeePercentage": 5.0,
  "minimumOrderAmount": 0.0,
  "baseDeliveryFee": 5.0,
  "isDeliveryFeePercentageBased": true,
  "updatedAt": "<TIMESTAMP>",
  "updatedBy": "system"
}

Press Enter to exit...
''');

  stdin.readLineSync();
}
