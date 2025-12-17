import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Custom painter for Customer App icon - Shopping Cart
class CustomerAppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background gradient
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    );
    paint.shader = gradient.createShader(rect);

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * 0.225),
    );
    canvas.drawRRect(rrect, paint);

    // Reset shader
    paint.shader = null;
    paint.color = Colors.white;

    // Shopping cart
    final cartScale = size.width / 512;
    final cartCenterX = size.width / 2;
    final cartCenterY = size.height / 2;

    // Cart body
    final cartBodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cartCenterX, cartCenterY + 25 * cartScale),
        width: 220 * cartScale,
        height: 140 * cartScale,
      ),
      Radius.circular(20 * cartScale),
    );
    canvas.drawRRect(cartBodyRect, paint);

    // Cart handle (arc)
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 25 * cartScale;
    final handleRect = Rect.fromCenter(
      center: Offset(cartCenterX, cartCenterY - 25 * cartScale),
      width: 180 * cartScale,
      height: 100 * cartScale,
    );
    canvas.drawArc(handleRect, 3.14159, 3.14159, false, paint);

    // Wheels
    paint.style = PaintingStyle.fill;
    final wheelRadius = 25 * cartScale;
    canvas.drawCircle(
      Offset(cartCenterX - 70 * cartScale, cartCenterY + 120 * cartScale),
      wheelRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(cartCenterX + 70 * cartScale, cartCenterY + 120 * cartScale),
      wheelRadius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for Vendor App icon - Storefront
class VendorAppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background gradient
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
    );
    paint.shader = gradient.createShader(rect);

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * 0.225),
    );
    canvas.drawRRect(rrect, paint);

    // Reset shader
    paint.shader = null;
    paint.color = Colors.white;

    final scale = size.width / 512;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Awning
    final awningRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - 80 * scale),
        width: 320 * scale,
        height: 80 * scale,
      ),
      Radius.circular(15 * scale),
    );
    canvas.drawRRect(awningRect, paint);

    // Awning stripes
    paint.color = Color(0x4Df5576c);
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          centerX - 160 * scale,
          centerY - 120 * scale + (i * 32 * scale),
          320 * scale,
          16 * scale,
        ),
        paint,
      );
    }

    // Building
    paint.color = Colors.white;
    final buildingRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 20 * scale),
        width: 320 * scale,
        height: 200 * scale,
      ),
      Radius.circular(15 * scale),
    );
    canvas.drawRRect(buildingRect, paint);

    // Windows
    paint.color = Color(0x26f5576c);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX - 100 * scale, centerY - 40 * scale),
          width: 60 * scale,
          height: 60 * scale,
        ),
        Radius.circular(8 * scale),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX + 100 * scale, centerY - 40 * scale),
          width: 60 * scale,
          height: 60 * scale,
        ),
        Radius.circular(8 * scale),
      ),
      paint,
    );

    // Door
    paint.color = Color(0x33f5576c);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY + 50 * scale),
          width: 100 * scale,
          height: 140 * scale,
        ),
        Radius.circular(10 * scale),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for Driver App icon - Delivery Truck
class DriverAppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background gradient
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    );
    paint.shader = gradient.createShader(rect);

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * 0.225),
    );
    canvas.drawRRect(rrect, paint);

    // Reset shader
    paint.shader = null;
    paint.color = Colors.white;

    final scale = size.width / 512;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Cabin
    final cabinRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX - 70 * scale, centerY - 10 * scale),
        width: 100 * scale,
        height: 120 * scale,
      ),
      Radius.circular(15 * scale),
    );
    canvas.drawRRect(cabinRect, paint);

    // Cabin window
    paint.color = Color(0x4D4facfe);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX - 70 * scale, centerY - 25 * scale),
          width: 70 * scale,
          height: 60 * scale,
        ),
        Radius.circular(10 * scale),
      ),
      paint,
    );

    // Cargo
    paint.color = Colors.white;
    final cargoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX + 70 * scale, centerY - 10 * scale),
        width: 200 * scale,
        height: 140 * scale,
      ),
      Radius.circular(15 * scale),
    );
    canvas.drawRRect(cargoRect, paint);

    // Cargo door
    paint.color = Color(0x264facfe);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX + 70 * scale, centerY - 10 * scale),
          width: 160 * scale,
          height: 100 * scale,
        ),
        Radius.circular(10 * scale),
      ),
      paint,
    );

    // Wheels
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;

    // Front wheel
    canvas.drawCircle(
      Offset(centerX - 70 * scale, centerY + 80 * scale),
      30 * scale,
      paint,
    );

    // Back wheel
    canvas.drawCircle(
      Offset(centerX + 90 * scale, centerY + 80 * scale),
      30 * scale,
      paint,
    );

    // Wheel borders
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 8 * scale;
    paint.color = Color(0x4D4facfe);

    canvas.drawCircle(
      Offset(centerX - 70 * scale, centerY + 80 * scale),
      30 * scale,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX + 90 * scale, centerY + 80 * scale),
      30 * scale,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
