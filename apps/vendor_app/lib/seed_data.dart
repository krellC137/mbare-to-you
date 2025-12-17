// Run this file to seed your Firebase with vendor test data
// Usage: flutter run lib/seed_data.dart
// Or press the "Seed Data" button in the app's login page

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🌱 Starting Vendor App seed script...\n');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  // Vendor test credentials
  const vendorEmail = 'vendor@mbaretoyou.com';
  const vendorPassword = 'vendor123';
  const vendorName = 'Test Vendor Store';

  print('📧 Vendor Login Credentials:');
  print('   Email: $vendorEmail');
  print('   Password: $vendorPassword\n');

  // Create or get vendor user
  String vendorId;
  try {
    // Try to create new user
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: vendorEmail,
      password: vendorPassword,
    );
    vendorId = userCredential.user!.uid;
    await userCredential.user!.updateDisplayName(vendorName);
    print('✅ Created new vendor user: $vendorId');
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      // User exists, sign in to get UID
      final userCredential = await auth.signInWithEmailAndPassword(
        email: vendorEmail,
        password: vendorPassword,
      );
      vendorId = userCredential.user!.uid;
      print('✅ Using existing vendor user: $vendorId');
    } else {
      print('❌ Error creating user: ${e.message}');
      return;
    }
  }

  // Seed Vendor Profile
  print('\n📦 Seeding vendor profile...');
  await seedVendorProfile(firestore, vendorId, vendorName);
  print('✅ Vendor profile created\n');

  // Seed Products
  print('📦 Seeding products...');
  final productCount = await seedProducts(firestore, vendorId);
  print('✅ Created $productCount products\n');

  // Seed Orders
  print('📦 Seeding orders...');
  final orderCount = await seedOrders(firestore, vendorId);
  print('✅ Created $orderCount orders\n');

  print('🎉 Seed complete! Your vendor app is ready to test.');
  print('\n📱 Test the app:');
  print('   1. Run the vendor app');
  print('   2. Login with: $vendorEmail / $vendorPassword');
  print('   3. Dashboard should show stats and recent orders');
  print('   4. Products page should list products');
  print('   5. Orders page should show orders by status');
}

Future<void> seedVendorProfile(
  FirebaseFirestore firestore,
  String vendorId,
  String vendorName,
) async {
  await firestore.collection('vendors').doc(vendorId).set({
    'id': vendorId,
    'name': vendorName,
    'description': 'Fresh groceries and daily essentials',
    'ownerId': vendorId,
    'marketSection': 'Section A - General',
    'categories': ['Groceries', 'Vegetables', 'Fruits'],
    'isApproved': true,
    'isActive': true,
    'rating': 4.5,
    'reviewCount': 12,
    'logoUrl': '',
    'address': 'Mbare Musika, Section A, Stall 10',
    'phone': '+263 77 999 8888',
    'email': 'vendor@mbaretoyou.com',
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
  print('  ✓ Created vendor profile');
}

Future<int> seedProducts(
  FirebaseFirestore firestore,
  String vendorId,
) async {
  final products = [
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
      'name': 'Bananas',
      'description': 'Ripe yellow bananas',
      'category': 'Fruits',
      'price': 2.0,
      'unit': 'dozen',
      'stock': 40,
    },
  ];

  var count = 0;
  for (final product in products) {
    final productRef = firestore.collection('products').doc();
    await productRef.set({
      'id': productRef.id,
      'vendorId': vendorId,
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

Future<int> seedOrders(
  FirebaseFirestore firestore,
  String vendorId,
) async {
  final now = DateTime.now();

  final orders = [
    {
      'status': 'pending',
      'customerName': 'John Moyo',
      'customerPhone': '+263 77 111 2222',
      'items': [
        {'name': 'Fresh Tomatoes', 'quantity': 2, 'price': 2.5},
        {'name': 'Red Onions', 'quantity': 1, 'price': 1.8},
      ],
      'subtotal': 6.8,
      'deliveryFee': 2.5,
      'total': 9.3,
      'createdAt': now.subtract(const Duration(minutes: 15)),
    },
    {
      'status': 'confirmed',
      'customerName': 'Sarah Ncube',
      'customerPhone': '+263 77 333 4444',
      'items': [
        {'name': 'Potatoes', 'quantity': 3, 'price': 2.0},
        {'name': 'Fresh Cabbage', 'quantity': 2, 'price': 1.2},
      ],
      'subtotal': 8.4,
      'deliveryFee': 2.5,
      'total': 10.9,
      'createdAt': now.subtract(const Duration(hours: 1)),
    },
    {
      'status': 'preparing',
      'customerName': 'Peter Dube',
      'customerPhone': '+263 77 555 6666',
      'items': [
        {'name': 'Bananas', 'quantity': 2, 'price': 2.0},
        {'name': 'Fresh Tomatoes', 'quantity': 1, 'price': 2.5},
      ],
      'subtotal': 6.5,
      'deliveryFee': 2.5,
      'total': 9.0,
      'createdAt': now.subtract(const Duration(hours: 2)),
    },
    {
      'status': 'ready',
      'customerName': 'Mary Sibanda',
      'customerPhone': '+263 77 777 8888',
      'items': [
        {'name': 'Red Onions', 'quantity': 2, 'price': 1.8},
      ],
      'subtotal': 3.6,
      'deliveryFee': 2.5,
      'total': 6.1,
      'createdAt': now.subtract(const Duration(hours: 3)),
    },
    {
      'status': 'delivered',
      'customerName': 'David Choto',
      'customerPhone': '+263 77 999 0000',
      'items': [
        {'name': 'Potatoes', 'quantity': 5, 'price': 2.0},
        {'name': 'Fresh Cabbage', 'quantity': 1, 'price': 1.2},
        {'name': 'Bananas', 'quantity': 1, 'price': 2.0},
      ],
      'subtotal': 13.2,
      'deliveryFee': 2.5,
      'total': 15.7,
      'createdAt': now.subtract(const Duration(days: 1)),
    },
  ];

  var count = 0;
  for (final order in orders) {
    final orderRef = firestore.collection('orders').doc();
    final customerId = 'test-customer-${count + 1}';

    // Convert simple items to CartItemModel format
    final items = (order['items'] as List).map((item) => {
      'productId': 'product-${(item as Map)['name']}',
      'vendorId': vendorId,
      'productName': item['name'],
      'unitPrice': item['price'],
      'quantity': item['quantity'],
      'productImage': '',
    }).toList();

    await orderRef.set({
      'id': orderRef.id,
      'vendorId': vendorId,
      'customerId': customerId,
      'status': order['status'],
      'items': items,
      'subtotal': order['subtotal'],
      'deliveryFee': order['deliveryFee'],
      'total': order['total'],
      'deliveryAddress': {
        'userId': customerId,
        'street': '${123 + count} Test Street',
        'suburb': 'Mbare',
        'city': 'Harare',
        'country': 'Zimbabwe',
      },
      'customerNotes': '',
      'paymentMethod': 'cash',
      'paymentStatus': 'pending',
      'createdAt': (order['createdAt'] as DateTime).toIso8601String(),
    });
    count++;
    print('  ✓ Created order: ${order['status']} - ${order['customerName']}');
  }

  return count;
}
