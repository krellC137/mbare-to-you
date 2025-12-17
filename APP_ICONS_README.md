# App Icons Setup Guide

I've created three unique icon designs for your apps. Since I cannot generate PNG files directly, please follow these steps to complete the icon setup:

## Icon Designs Created

### 1. Customer App Icon 🛒
- **Theme**: Purple gradient (#667eea → #764ba2)
- **Design**: Shopping cart icon on rounded square background
- **HTML Preview**: [apps/customer_app/assets/icons/app_icon.html](apps/customer_app/assets/icons/app_icon.html)

### 2. Vendor App Icon 🏪
- **Theme**: Pink gradient (#f093fb → #f5576c)
- **Design**: Storefront with awning on rounded square background
- **HTML Preview**: [apps/vendor_app/assets/icons/app_icon.html](apps/vendor_app/assets/icons/app_icon.html)

### 3. Driver App Icon 🚚
- **Theme**: Blue gradient (#4facfe → #00f2fe)
- **Design**: Delivery truck on rounded square background
- **HTML Preview**: [apps/driver_app/assets/icons/app_icon.html](apps/driver_app/assets/icons/app_icon.html)

## Quick Setup Steps

### Option 1: Use Online Icon Generator (Recommended - Fastest)

1. Open each HTML file in your browser
2. Take a screenshot of the icon (make sure it's 512x512 pixels or larger)
3. Use an online tool like:
   - https://icon.kitchen/ (Upload your screenshot, generates all sizes automatically)
   - https://appicon.co/ (Similar, generates iOS and Android icons)
   - https://www.appicon.build/ (Another good option)

4. Download the generated icons and place them in the respective app folders

### Option 2: Manual Screenshot + flutter_launcher_icons Package

1. **Generate Screenshots**:
   - Open each HTML file in your browser
   - Use browser dev tools to set viewport to exactly 512x512
   - Take high-quality screenshot
   - Save as PNG in the respective app's `assets/icons/` folder as `app_icon.png`

2. **Install Dependencies**:
   ```bash
   cd apps/customer_app
   flutter pub get
   ```

3. **Generate Icons**:
   ```bash
   dart run flutter_launcher_icons
   ```

4. **Repeat for other apps**:
   - Add the same configuration to `vendor_app/pubspec.yaml` and `driver_app/pubspec.yaml`
   - Change the colors to match each app's theme
   - Run `flutter pub get` and `dart run flutter_launcher_icons` for each

### Option 3: Use a Design Tool

1. Open Figma, Adobe XD, Sketch, or Canva
2. Create a 1024x1024 artboard
3. Recreate the designs based on the HTML previews:

   **Customer App**:
   - Background: Purple gradient (#667eea → #764ba2), 22.5% rounded corners
   - White shopping cart icon in center

   **Vendor App**:
   - Background: Pink gradient (#f093fb → #f5576c), 22.5% rounded corners
   - White storefront with striped awning

   **Driver App**:
   - Background: Blue gradient (#4facfe → #00f2fe), 22.5% rounded corners
   - White delivery truck icon

4. Export as PNG (1024x1024)
5. Use one of the online generators mentioned above OR flutter_launcher_icons

## Flutter Launcher Icons Configuration

I've already added `flutter_launcher_icons` to the customer app's `pubspec.yaml`.

### For Vendor App and Driver App:

Add this to their `pubspec.yaml` files:

**Vendor App** (Pink theme):
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#f093fb"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
```

**Driver App** (Blue theme):
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#4facfe"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
```

## Testing the Icons

After generating the icons:

1. Clean and rebuild each app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. Check the app icon on your device's home screen

3. Verify all three apps have distinct, professional icons

## Icon Files Created

- ✅ `apps/customer_app/assets/icons/app_icon.html` - Purple shopping cart design
- ✅ `apps/vendor_app/assets/icons/app_icon.html` - Pink storefront design
- ✅ `apps/driver_app/assets/icons/app_icon.html` - Blue delivery truck design
- ✅ `apps/customer_app/lib/core/widgets/app_icon_painter.dart` - Flutter painters (for reference)

## Next Steps

1. Choose one of the three options above to generate PNG icon files
2. Place the generated `app_icon.png` (512x512 or 1024x1024) in each app's `assets/icons/` folder
3. Run `flutter pub get` in each app directory
4. Run `dart run flutter_launcher_icons` in each app directory
5. The icons will be automatically placed in all required Android and iOS folders

That's it! You'll have three distinct, professional app icons for your marketplace.
