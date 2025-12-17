# App Icon Generation Instructions

I've created three unique HTML-based icon designs:

## Icons Created:
1. **Customer App** - Purple gradient with shopping cart (Purple/Violet theme)
   - Location: `apps/customer_app/assets/icons/app_icon.html`
   - Colors: #667eea to #764ba2

2. **Vendor App** - Pink gradient with storefront (Pink/Red theme)
   - Location: `apps/vendor_app/assets/icons/app_icon.html`
   - Colors: #f093fb to #f5576c

3. **Driver App** - Blue gradient with delivery truck (Blue/Cyan theme)
   - Location: `apps/driver_app/assets/icons/app_icon.html`
   - Colors: #4facfe to #00f2fe

## To Generate Icons:

### Method 1: Screenshot Approach
1. Open each HTML file in a browser
2. Take a screenshot of the icon (512x512px)
3. Save as PNG in the respective app's assets/icons/ folder

### Method 2: Using flutter_launcher_icons Package (Recommended)
1. Add `flutter_launcher_icons` to each app's pubspec.yaml
2. Configure icon paths
3. Run `dart run flutter_launcher_icons`

I'll now configure the flutter_launcher_icons package for automatic generation.
