# MbareToYou - Quick Reference Guide

## Project Overview

**MbareToYou** is a production-ready Flutter marketplace connecting Mbare Musika vendors with customers in Harare, Zimbabwe. Think "Uber Eats for vegetables."

### Key Info
- **Mono-repo:** Managed with Melos
- **State Management:** Riverpod 2.x
- **Backend:** Firebase (Auth, Firestore, Functions, Storage)
- **Architecture:** Clean Architecture (Presentation → Providers → Domain → Data)

---

## Melos Commands

```bash
# Bootstrap workspace (first time setup)
melos bootstrap

# Run code generation (Freezed, Riverpod, JSON)
melos run codegen

# Watch mode for code generation
melos run codegen:watch

# Run all tests
melos run test

# Run only unit tests
melos run test:unit

# Run only widget tests
melos run test:widget

# Analyze all packages
melos run analyze

# Format all code
melos run format

# Clean all packages
melos run clean

# Get dependencies for all packages
melos run get

# Build Android APK
melos run build:apk

# Build iOS (no codesign)
melos run build:ios
```

---

## Package Structure

### mbare_core
**Core domain logic, models, and utilities**

```dart
// Import everything
import 'package:mbare_core/mbare_core.dart';

// Available Models
UserModel, VendorModel, ProductModel, OrderModel, CartItemModel, AddressModel

// Failures & Exceptions
ServerFailure, NetworkFailure, AuthFailure, ValidationFailure
ServerException, NetworkException, AuthException

// Result Type (FPDart Either)
Result<T> = Either<Failure, T>
success<T>(value), failure<T>(failure)

// Validators
Validators.validateEmail(email)
Validators.validatePassword(password)
Validators.validatePhone(phone)

// Extensions
'hello'.capitalize() // 'Hello'
'test@email.com'.isValidEmail // true
DateTime.now().toRelativeTime() // 'Just now'

// Constants
AppConstants.roleCustomer
AppConstants.orderStatusPending
AppConstants.paymentMethodEcocash
```

### mbare_ui
**Shared UI components and theme**

```dart
import 'package:mbare_ui/mbare_ui.dart';

// Theme
AppTheme.light()
AppColors.primary
AppTextStyles.headline1
AppSpacing.medium

// Widgets
LoadingIndicator()
ErrorView(message: 'Error')
EmptyState(message: 'No items')

// Buttons
PrimaryButton(onPressed: () {}, child: Text('Submit'))
SecondaryButton(onPressed: () {}, child: Text('Cancel'))

// Inputs
AppTextField(label: 'Email', validator: Validators.validateEmail)
```

### mbare_services
**Firebase and API services**

```dart
import 'package:mbare_services/mbare_services.dart';

// Firebase Auth
FirebaseAuthService.signIn(email, password)
FirebaseAuthService.signUp(email, password)
FirebaseAuthService.signOut()

// Firestore
FirestoreService.getCollection('vendors')
FirestoreService.getDocument('vendors', vendorId)

// Storage
StorageService.uploadImage(file, path)
```

### mbare_data
**Repositories and data sources with Riverpod**

```dart
import 'package:mbare_data/mbare_data.dart';

// Repositories
AuthRepository, UserRepository, VendorRepository, ProductRepository, OrderRepository

// Providers (example usage)
final authStateProvider = ...
final userProvider = ...
```

---

## Code Generation Workflow

### 1. Create a Model with Freezed

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_model.freezed.dart';
part 'my_model.g.dart';

@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
    @Default(0) int count,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}
```

### 2. Create a Riverpod Provider

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_provider.g.dart';

@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  int build() => 0;

  void increment() => state++;
}

// Usage in widget
final count = ref.watch(myNotifierProvider);
```

### 3. Run Code Generation

```bash
# Single package
cd packages/mbare_core
flutter pub run build_runner build --delete-conflicting-outputs

# All packages at once
melos run codegen
```

---

## Firebase Setup

### 1. Create Firebase Project
1. Go to https://console.firebase.google.com
2. Create a new project: "MbareToYou"
3. Enable these services:
   - Authentication (Email/Password)
   - Firestore Database
   - Storage
   - Cloud Functions
   - Cloud Messaging (FCM)

### 2. Add Android App
1. Package name: `com.mbaretoyou.customer_app`
2. Download `google-services.json`
3. Place in: `apps/customer_app/android/app/`

### 3. Add iOS App
1. Bundle ID: `com.mbaretoyou.customerApp`
2. Download `GoogleService-Info.plist`
3. Place in: `apps/customer_app/ios/Runner/`

### 4. Enable Authentication
```
Firebase Console → Authentication → Sign-in method
Enable: Email/Password
```

### 5. Create Firestore Database
```
Firebase Console → Firestore Database → Create database
Start in: Test mode (we'll add security rules later)
```

---

## Firestore Collections Structure

```
users/{userId}
  - email: string
  - role: string (customer|vendor|driver|admin)
  - displayName: string
  - phoneNumber: string
  - createdAt: timestamp

vendors/{vendorId}
  - ownerId: string (ref to users/{userId})
  - businessName: string
  - tableNumber: string
  - marketSection: string
  - isApproved: boolean
  - rating: number
  - totalOrders: number

vendors/{vendorId}/products/{productId}
  - name: string
  - category: string
  - price: number
  - images: array<string>
  - stockQuantity: number
  - isAvailable: boolean

orders/{orderId}
  - customerId: string
  - vendorId: string
  - driverId: string?
  - items: array<CartItem>
  - subtotal: number
  - deliveryFee: number
  - total: number
  - status: string
  - deliveryAddress: AddressModel
  - createdAt: timestamp
  - confirmedAt: timestamp?
  - deliveredAt: timestamp?
```

---

## Common Patterns

### 1. Repository Pattern with Result

```dart
class VendorRepository {
  Future<Result<List<VendorModel>>> getVendors() async {
    try {
      final snapshot = await _firestore.collection('vendors').get();
      final vendors = snapshot.docs
          .map((doc) => VendorModel.fromJson(doc.data()))
          .toList();
      return success(vendors);
    } on FirebaseException catch (e) {
      return failure(ServerFailure(message: e.message ?? 'Unknown error'));
    } catch (e) {
      return failure(UnknownFailure(message: e.toString()));
    }
  }
}
```

### 2. Riverpod Provider with AsyncValue

```dart
@riverpod
class VendorList extends _$VendorList {
  @override
  Future<List<VendorModel>> build() async {
    final result = await ref.read(vendorRepositoryProvider).getVendors();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (vendors) => vendors,
    );
  }
}

// In widget
ref.watch(vendorListProvider).when(
  data: (vendors) => ListView.builder(...),
  loading: () => LoadingIndicator(),
  error: (err, stack) => ErrorView(message: err.toString()),
);
```

### 3. Form Validation

```dart
final _formKey = GlobalKey<FormState>();

AppTextField(
  label: 'Email',
  validator: Validators.validateEmail,
  onSaved: (value) => _email = value!,
)

// On submit
if (_formKey.currentState!.validate()) {
  _formKey.currentState!.save();
  // Process form
}
```

---

## Testing

### Unit Test Example

```dart
void main() {
  group('ProductModel', () {
    test('should format price correctly', () {
      final product = ProductModel(
        id: '1',
        vendorId: 'v1',
        name: 'Tomato',
        category: 'Vegetables',
        price: 5.50,
      );

      expect(product.formattedPrice, '\$5.50');
    });
  });
}
```

### Widget Test Example

```dart
void main() {
  testWidgets('PrimaryButton shows label and calls onPressed', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PrimaryButton(
          onPressed: () => pressed = true,
          child: const Text('Click Me'),
        ),
      ),
    );

    expect(find.text('Click Me'), findsOneWidget);

    await tester.tap(find.byType(PrimaryButton));
    expect(pressed, isTrue);
  });
}
```

---

## Troubleshooting

### Code generation not working
```bash
# Clean and regenerate
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Melos commands not found
```bash
# Ensure Melos is activated
dart pub global activate melos

# Use full path
dart pub global run melos bootstrap
```

### Import errors after adding new file
```bash
# Run code generation
melos run codegen
```

### Firebase not initializing
- Check `google-services.json` is in `android/app/`
- Check `GoogleService-Info.plist` is in `ios/Runner/`
- Ensure `firebase_core` is initialized in `main.dart`:
  ```dart
  await Firebase.initializeApp();
  ```

---

## Useful Resources

- [Flutter Docs](https://docs.flutter.dev)
- [Riverpod Docs](https://riverpod.dev)
- [Freezed Package](https://pub.dev/packages/freezed)
- [Firebase Flutter](https://firebase.flutter.dev)
- [Melos](https://melos.invertase.dev)
- [FPDart (Either)](https://pub.dev/packages/fpdart)

---

## Key Files to Know

| File | Purpose |
|------|---------|
| `melos.yaml` | Mono-repo configuration |
| `analysis_options.yaml` | Linting rules |
| `pubspec.yaml` | Package dependencies |
| `lib/main.dart` | App entry point |
| `lib/app.dart` | Root MaterialApp with routing |
| `PROGRESS.md` | Detailed development progress |

---

*Last Updated: 2025-11-10*
