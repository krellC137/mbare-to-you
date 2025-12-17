# Generate Icons on Windows (PowerShell)

## Important Note
The icons are configured, but you need to provide the PNG files first!

## Step 1: Create Icon PNG Files

You have three options:

### Option A: Use Online Tool (Fastest & Easiest)
1. Open each HTML file in your browser:
   - `apps/customer_app/assets/icons/app_icon.html` (Purple cart)
   - `apps/vendor_app/assets/icons/app_icon.html` (Pink store)
   - `apps/driver_app/assets/icons/app_icon.html` (Blue truck)

2. Take a screenshot or use browser dev tools to capture at 512x512 or larger

3. Go to https://icon.kitchen/ or https://appicon.co/
   - Upload each screenshot
   - Download the generated Android/iOS icons
   - Extract to each app's android/ios folders

### Option B: Use Design Tool
1. Open Figma, Canva, or any design tool
2. Create 1024x1024 canvas
3. Recreate the designs from the HTML files:
   - **Customer**: Purple gradient (#667eea → #764ba2) with white cart
   - **Vendor**: Pink gradient (#f093fb → #f5576c) with white storefront
   - **Driver**: Blue gradient (#4facfe → #00f2fe) with white truck
4. Export as PNG
5. Save as `app_icon.png` in each app's `assets/icons/` folder

### Option C: Manual Screenshot
1. Open HTML files in Chrome/Edge
2. Press F12 for dev tools
3. Click "Toggle device toolbar" (Ctrl+Shift+M)
4. Set dimensions to 512x512
5. Screenshot and save as `app_icon.png`

## Step 2: Run Icon Generator (PowerShell Commands)

Once you have the PNG files in place:

```powershell
# Customer App
cd apps\customer_app
flutter pub get
dart run flutter_launcher_icons
cd ..\..

# Vendor App
cd apps\vendor_app
flutter pub get
dart run flutter_launcher_icons
cd ..\..

# Driver App
cd apps\driver_app
flutter pub get
dart run flutter_launcher_icons
cd ..\..
```

## Step 3: Verify Icons

```powershell
# Rebuild each app
cd apps\customer_app
flutter clean
flutter run
```

Check the home screen icon!

## Current Status
✅ flutter_launcher_icons package installed
✅ Configuration added to all three pubspec.yaml files
❌ PNG icon files needed (you need to create these)

Once you have the PNG files, the icon generator will automatically create all required sizes for Android and iOS!
