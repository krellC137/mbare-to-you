import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

/// Run this to seed platform settings
/// flutter run -t lib/seed_platform_settings.dart -d chrome
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SeedApp());
}

class SeedApp extends StatelessWidget {
  const SeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seed Platform Settings',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SeedScreen(),
    );
  }
}

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  Future<void> _seedPlatformSettings() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      // Sign in with admin credentials
      print('Authenticating...');
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('Authenticated as: ${userCredential.user?.email}');

      // Verify user has admin role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found. Please create a user profile first.');
      }

      final userData = userDoc.data();
      if (userData?['role'] != 'admin') {
        throw Exception('You must be an admin to seed platform settings. Current role: ${userData?['role']}');
      }

      print('Creating platform settings...');

      // Create platform settings document
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('platform_settings')
          .set({
        'id': 'platform_settings',
        'deliveryFeePercentage': 10.0,
        'platformFeePercentage': 5.0,
        'minimumOrderAmount': 0.0,
        'baseDeliveryFee': 5.0,
        'isDeliveryFeePercentageBased': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userCredential.user!.email,
      });

      setState(() {
        _isSuccess = true;
        _message = '''✅ Platform settings created successfully!

Settings:
• Delivery Fee: 10% of order total
• Platform Fee: 5% commission
• Base Delivery Fee: \$5.00
• Minimum Order: \$0.00

You can now close this window.''';
      });

      print('✅ Platform settings created successfully!');
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = '❌ Error: $e';
      });
      print('❌ Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Platform Settings'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Admin Authentication Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in with your admin account to seed platform settings',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Admin Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                enabled: !_isLoading,
                onSubmitted: (_) => _seedPlatformSettings(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _seedPlatformSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Seed Platform Settings', style: TextStyle(fontSize: 16)),
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                    border: Border.all(
                      color: _isSuccess ? Colors.green : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
