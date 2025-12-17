# Vendor App Icon

## What You Need to Do

Place a PNG icon file named `app_icon.png` in this directory.

## Icon Design Specifications

- **Theme**: Pink Storefront
- **Background**: Linear gradient 135° from #f093fb to #f5576c
- **Icon**: White storefront with striped awning
- **Size**: 1024x1024 pixels (or at least 512x512)
- **Corner Radius**: 22.5% of width (rounded square)

## Preview

Open `app_icon.html` in your browser to see the design.

## Quick Ways to Create This Icon

1. **Fastest**: Use https://icon.kitchen/ or https://appicon.co/
   - Upload a screenshot of app_icon.html
   - Download generated icons

2. **Canva/Figma**:
   - Create 1024x1024 design
   - Pink gradient background
   - Add white store/shop icon from library
   - Round corners
   - Export as PNG

3. **AI Generator**: Use Brandmark, Looka, or similar
   - Describe: "pink gradient storefront app icon"
   - Download and save here

Once you have the file, run:
```bash
cd apps/vendor_app
dart run flutter_launcher_icons
```

This will automatically generate all required Android and iOS icon sizes!
