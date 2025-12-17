# 🚀 Running the MbareToYou Customer App

## Quick Start

### Step 1: Navigate to Customer App Directory
```bash
cd apps/customer_app
```

### Step 2: Get Dependencies
```bash
flutter pub get
```

### Step 3: Run the App
```bash
flutter run
```

---

## Detailed Instructions

### Prerequisites
Before running the app, ensure you have:

1. ✅ **Flutter SDK installed** (3.0+)
   ```bash
   flutter doctor
   ```

2. ✅ **A connected device or emulator**
   - Android: Android Studio emulator or physical device
   - iOS: Xcode simulator or physical device (Mac only)
   - Check with: `flutter devices`

3. ✅ **Firebase configured**
   - The app uses Firebase for authentication and data
   - Firebase is already configured in `firebase_options.dart`

---

## Running the App

### Method 1: Command Line (Simplest)

From the **root directory** (`mbare_to_you`):

```bash
# Navigate to customer app
cd apps/customer_app

# Get all dependencies
flutter pub get

# Run on default device
flutter run

# OR run on specific device
flutter run -d <device_id>

# OR run in release mode (faster)
flutter run --release
```

### Method 2: VS Code

1. **Open the customer app folder**:
   - File → Open Folder
   - Navigate to `mbare_to_you/apps/customer_app`
   - Click "Select Folder"

2. **Open main.dart**:
   - Navigate to `lib/main.dart`

3. **Select your device**:
   - Click on the device selector in the bottom right
   - Choose your emulator or connected device

4. **Run the app**:
   - Press **F5** (Start Debugging)
   - Or press **Ctrl+F5** (Run Without Debugging)
   - Or click the **Play button** in the top right

### Method 3: Android Studio

1. **Open the customer app**:
   - File → Open
   - Select `mbare_to_you/apps/customer_app`

2. **Sync dependencies**:
   - Wait for Gradle sync to complete
   - Or click "Get Dependencies" if prompted

3. **Select device**:
   - Use the device dropdown in the toolbar

4. **Run**:
   - Click the green play button
   - Or use Run → Run 'main.dart'

---

## Troubleshooting

### Problem: "Multiple main.dart files found"
**Solution**: Make sure you're running from `apps/customer_app/`, not the root directory.

### Problem: "Package not found" errors
**Solution**:
```bash
cd apps/customer_app
flutter clean
flutter pub get
```

### Problem: Firebase initialization errors
**Solution**: Make sure `firebase_options.dart` exists in the customer_app:
```bash
ls apps/customer_app/lib/firebase_options.dart
```

### Problem: Build errors with analyzer_plugin
**Solution**: This is a known issue with code generation. The app will still run fine. To suppress warnings:
```bash
# Just run the app - code generation is not required for running
flutter run
```

### Problem: No devices found
**Solution**:
```bash
# Check connected devices
flutter devices

# Start an emulator
flutter emulators
flutter emulators --launch <emulator_id>
```

---

## Testing the App

### Test Accounts (if you have test data in Firebase)
- **Email**: test@example.com
- **Password**: Test123!

### Features to Test
1. ✅ **Login** - Authentication flow
2. ✅ **Browse Vendors** - See vendor cards on home page
3. ✅ **View Products** - Tap a vendor to see their products
4. ✅ **Add to Cart** - Add products and see cart badge update
5. ✅ **Shopping Cart** - View/edit cart items
6. ✅ **Checkout** - Enter delivery address and place order
7. ✅ **My Orders** - Tap "My Orders" on home page
8. ✅ **Order Details** - Tap an order to see tracking timeline

---

## Hot Reload & Hot Restart

While the app is running:

- **Hot Reload**: Press `r` in terminal (or save in VS Code)
  - Fast refresh for UI changes

- **Hot Restart**: Press `R` in terminal
  - Restarts the app but keeps the process running

- **Full Restart**: Press `Ctrl+C` then `flutter run` again
  - Complete restart of the app

---

## Running Other Apps in the Monorepo

### Vendor App (when implemented)
```bash
cd apps/vendor_app
flutter pub get
flutter run
```

### Driver App (when implemented)
```bash
cd apps/driver_app
flutter pub get
flutter run
```

---

## Build for Production

### Android APK
```bash
cd apps/customer_app
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)
```bash
cd apps/customer_app
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (Mac only)
```bash
cd apps/customer_app
flutter build ios --release
# Then open in Xcode to archive and upload
```

---

## Project Structure

```
mbare_to_you/
├── apps/
│   └── customer_app/          ← RUN THIS APP
│       ├── lib/
│       │   ├── main.dart      ← Entry point
│       │   ├── core/
│       │   └── features/
│       └── pubspec.yaml
├── packages/
│   ├── mbare_core/            ← Shared models
│   ├── mbare_data/            ← Data layer
│   └── mbare_ui/              ← UI components
└── melos.yaml                 ← Monorepo config
```

---

## Next Steps

After the app is running:

1. **Test the complete flow**: Login → Browse → Cart → Checkout → Orders
2. **Check Firebase Console**: Verify orders are being created
3. **Test on multiple devices**: Android and iOS if possible
4. **Review the code**: Explore the features we built

---

## Need Help?

- Check `flutter doctor` for environment issues
- Read error messages carefully - they usually point to the problem
- Make sure you're in the `apps/customer_app` directory
- Ensure all dependencies are installed with `flutter pub get`

Happy coding! 🎉
