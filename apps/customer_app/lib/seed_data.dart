// Run this file to seed your Firebase with test data
// Usage: dart run lib/seed_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  print('🌱 Starting Firebase seed script...\n');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  // IMPORTANT: Get your user ID from Firebase Console
  // Go to Authentication -> Users tab and copy your UID
  print(
    '⚠️  BEFORE RUNNING: Update YOUR_USER_UID_HERE with your actual user UID!',
  );
  print('   Go to Firebase Console -> Authentication -> Users');
  print('   Copy your user UID and replace it in this file\n');

  const String yourUserId = 'Bde4FnnI7Ohl5mt1dz0sN1gPCIl2';

  if (yourUserId == 'YOUR_USER_UID_HERE') {
    print(
      '❌ Error: Please update yourUserId with your actual user UID from Firebase Console',
    );
    print('   1. Go to https://console.firebase.google.com/');
    print('   2. Select MbareToYou project');
    print('   3. Click Authentication -> Users');
    print('   4. Copy the User UID');
    print('   5. Replace YOUR_USER_UID_HERE in this file');
    return;
  }

  print('✅ Firebase initialized\n');

  // Seed Vendors
  print('📦 Seeding vendors...');
  final vendors = await seedVendors(firestore, yourUserId);
  print('✅ Created ${vendors.length} vendors\n');

  // Seed Products
  print('📦 Seeding products...');
  final productCount = await seedProducts(firestore, vendors);
  print('✅ Created $productCount products\n');

  print('🎉 Seed complete! Your Firebase is ready to use.');
  print('\nNext steps:');
  print('1. Restart your Flutter app (press R in terminal)');
  print('2. You should see vendors and products on the home screen!');
}

Future<List<String>> seedVendors(
  FirebaseFirestore firestore,
  String ownerId,
) async {
  final vendorIds = <String>[];

  // Vendor 1: Fresh Produce
  final vendor1Ref = firestore.collection('vendors').doc();
  await vendor1Ref.set({
    'id': vendor1Ref.id,
    'name': 'Fresh Produce by Mai Chipo',
    'description': 'Fresh vegetables and fruits daily from Mbare Market',
    'ownerId': ownerId,
    'marketSection': 'Section A - Vegetables',
    'categories': ['Vegetables', 'Fruits'],
    'isApproved': true,
    'isActive': true,
    'rating': 4.5,
    'reviewCount': 24,
    'logoUrl': '',
    'address': 'Mbare Musika, Section A, Stall 15',
    'phone': '+263 77 123 4567',
    'email': 'chipo@mbaretoyou.com',
    'deliveryFee': 2.5,
    'minimumOrder': 5.0,
    'isDeliveryAvailable': true,
    'businessHours': {
      'monday': '06:00-18:00',
      'tuesday': '06:00-18:00',
      'wednesday': '06:00-18:00',
      'thursday': '06:00-18:00',
      'friday': '06:00-18:00',
      'saturday': '06:00-16:00',
      'sunday': 'CLOSED',
    },
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  vendorIds.add(vendor1Ref.id);
  print('  ✓ Created vendor: Fresh Produce by Mai Chipo (${vendor1Ref.id})');

  // Vendor 2: Musika Meats
  final vendor2Ref = firestore.collection('vendors').doc();
  await vendor2Ref.set({
    'id': vendor2Ref.id,
    'name': 'Musika Meats',
    'description': 'Premium quality meat and poultry from trusted suppliers',
    'ownerId': ownerId,
    'marketSection': 'Section B - Meat',
    'categories': ['Meat', 'Poultry'],
    'isApproved': true,
    'isActive': true,
    'rating': 4.7,
    'reviewCount': 18,
    'logoUrl': '',
    'address': 'Mbare Musika, Section B, Stall 8',
    'phone': '+263 77 234 5678',
    'email': 'meats@mbaretoyou.com',
    'deliveryFee': 3.0,
    'minimumOrder': 10.0,
    'isDeliveryAvailable': true,
    'businessHours': {
      'monday': '06:00-18:00',
      'tuesday': '06:00-18:00',
      'wednesday': '06:00-18:00',
      'thursday': '06:00-18:00',
      'friday': '06:00-18:00',
      'saturday': '06:00-16:00',
      'sunday': 'CLOSED',
    },
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  vendorIds.add(vendor2Ref.id);
  print('  ✓ Created vendor: Musika Meats (${vendor2Ref.id})');

  return vendorIds;
}

Future<int> seedProducts(
  FirebaseFirestore firestore,
  List<String> vendorIds,
) async {
  var count = 0;

  // Products for Vendor 1 (Fresh Produce)
  final vendor1Products = [
    {
      'name': 'Fresh Tomatoes',
      'description': 'Locally grown red ripe tomatoes',
      'category': 'Vegetables',
      'price': 2.5,
      'unit': 'kg',
      'stock': 50,
    },
    {
      'name': 'Red Onions',
      'description': 'Fresh red onions',
      'category': 'Vegetables',
      'price': 1.8,
      'unit': 'kg',
      'stock': 100,
    },
    {
      'name': 'Fresh Cabbage',
      'description': 'Green cabbage heads',
      'category': 'Vegetables',
      'price': 1.2,
      'unit': 'head',
      'stock': 30,
    },
    {
      'name': 'Potatoes',
      'description': 'Fresh potatoes',
      'category': 'Vegetables',
      'price': 2.0,
      'unit': 'kg',
      'stock': 80,
    },
    {
      'name': 'Carrots',
      'description': 'Fresh orange carrots',
      'category': 'Vegetables',
      'price': 1.5,
      'unit': 'kg',
      'stock': 45,
    },
    {
      'name': 'Sweet Peppers',
      'description': 'Colorful bell peppers',
      'category': 'Vegetables',
      'price': 3.0,
      'unit': 'kg',
      'stock': 25,
    },
    {
      'name': 'Bananas',
      'description': 'Ripe yellow bananas',
      'category': 'Fruits',
      'price': 2.0,
      'unit': 'dozen',
      'stock': 40,
    },
    {
      'name': 'Oranges',
      'description': 'Juicy sweet oranges',
      'category': 'Fruits',
      'price': 3.5,
      'unit': 'kg',
      'stock': 35,
    },
  ];

  for (final product in vendor1Products) {
    final productRef = firestore.collection('products').doc();
    await productRef.set({
      'id': productRef.id,
      'vendorId': vendorIds[0],
      'name': product['name'],
      'description': product['description'],
      'category': product['category'],
      'price': product['price'],
      'unit': product['unit'],
      'stock': product['stock'],
      'isAvailable': true,
      'imageUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    count++;
    print('  ✓ Created product: ${product['name']}');
  }

  // Products for Vendor 2 (Musika Meats)
  final vendor2Products = [
    {
      'name': 'Whole Chicken',
      'description': 'Fresh whole chicken',
      'category': 'Poultry',
      'price': 8.5,
      'unit': 'kg',
      'stock': 20,
    },
    {
      'name': 'Chicken Pieces',
      'description': 'Fresh chicken cuts',
      'category': 'Poultry',
      'price': 9.0,
      'unit': 'kg',
      'stock': 15,
    },
    {
      'name': 'Beef Steak',
      'description': 'Premium beef steak',
      'category': 'Meat',
      'price': 12.0,
      'unit': 'kg',
      'stock': 10,
    },
    {
      'name': 'Beef Mince',
      'description': 'Fresh ground beef',
      'category': 'Meat',
      'price': 10.0,
      'unit': 'kg',
      'stock': 25,
    },
    {
      'name': 'Pork Chops',
      'description': 'Fresh pork chops',
      'category': 'Meat',
      'price': 10.5,
      'unit': 'kg',
      'stock': 12,
    },
  ];

  for (final product in vendor2Products) {
    final productRef = firestore.collection('products').doc();
    await productRef.set({
      'id': productRef.id,
      'vendorId': vendorIds[1],
      'name': product['name'],
      'description': product['description'],
      'category': product['category'],
      'price': product['price'],
      'unit': product['unit'],
      'stock': product['stock'],
      'isAvailable': true,
      'imageUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    count++;
    print('  ✓ Created product: ${product['name']}');
  }

  return count;
}
