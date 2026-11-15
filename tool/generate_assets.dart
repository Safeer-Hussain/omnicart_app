import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

void main() {
  final iconDir = Directory('assets/icons');
  final imageDir = Directory('assets/images');
  if (!iconDir.existsSync()) iconDir.createSync(recursive: true);
  if (!imageDir.existsSync()) imageDir.createSync(recursive: true);

  generateAppIcon('assets/icons/app_icon.png');
  generateCategoryBanner(
    'assets/images/tech_audio.png',
    'FLAGSHIP TECH & AUDIO',
    0xFF0D1B2A,
    0xFF00E5FF,
    0xFF1E88E5,
  );
  generateCategoryBanner(
    'assets/images/smart_home.png',
    'SMART HOME ECOSYSTEM',
    0xFF141E28,
    0xFF00E676,
    0xFF00B0FF,
  );
  generateCategoryBanner(
    'assets/images/artisan_grocery.png',
    'ARTISAN GROCERY & COFFEE',
    0xFF231709,
    0xFFFFB300,
    0xFFFF7043,
  );
  generateCategoryBanner(
    'assets/images/ergonomic_workspace.png',
    'ERGONOMIC WORKSPACE',
    0xFF151D24,
    0xFF7C4DFF,
    0xFF536DFE,
  );
  generateCategoryBanner(
    'assets/images/performance_apparel.png',
    'PERFORMANCE APPAREL',
    0xFF1C1A27,
    0xFFFF3D00,
    0xFFFF6E40,
  );
  generateBadge(
    'assets/images/courier_badge.png',
    'EXPRESS 15-MIN COURIER',
    0xFF00E676,
  );
  generateBadge(
    'assets/images/darkstore_hub.png',
    'DARK-STORE FULFILLMENT',
    0xFF00B0FF,
  );

  stdout.writeln(
    'Successfully generated assets in assets/icons/ and assets/images/',
  );
}

void generateAppIcon(String path) {
  const size = 512;
  final image = img.Image(width: size, height: size);

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x - size / 2;
      final dy = y - size / 2;
      final dist = sqrt(dx * dx + dy * dy);
      final factor = (dist / (size / 1.4)).clamp(0.0, 1.0);
      final r = (15 * (1 - factor * 0.5)).toInt();
      final g = (18 * (1 - factor * 0.5)).toInt();
      final b = (28 * (1 - factor * 0.5)).toInt();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  const cx = 256.0;
  const cy = 256.0;
  const s = 110.0;

  drawPolygon(
    image,
    [
      Point(cx, cy - s),
      Point(cx + s * 0.866, cy - s * 0.5),
      Point(cx, cy),
      Point(cx - s * 0.866, cy - s * 0.5),
    ],
    0xFF00E5FF,
    0xFF0091EA,
  );

  drawPolygon(
    image,
    [
      Point(cx - s * 0.866, cy - s * 0.5),
      Point(cx, cy),
      Point(cx, cy + s),
      Point(cx - s * 0.866, cy + s * 0.5),
    ],
    0xFF00E676,
    0xFF00B248,
  );

  drawPolygon(
    image,
    [
      Point(cx, cy),
      Point(cx + s * 0.866, cy - s * 0.5),
      Point(cx + s * 0.866, cy + s * 0.5),
      Point(cx, cy + s),
    ],
    0xFFFF5722,
    0xFFD84315,
  );

  for (double a = 0; a < 2 * pi; a += 0.01) {
    if ((a > 0.4 && a < 2.5) || (a > 3.5 && a < 5.6)) {
      final rx = (cx + 175 * cos(a)).toInt();
      final ry = (cy + 175 * sin(a) * 0.6).toInt();
      for (int i = -3; i <= 3; i++) {
        for (int j = -3; j <= 3; j++) {
          if (rx + i >= 0 && rx + i < size && ry + j >= 0 && ry + j < size) {
            final alpha = ((4 - max(i.abs(), j.abs())) / 4.0 * 200).toInt();
            image.setPixelRgba(rx + i, ry + j, 0, 230, 118, alpha);
          }
        }
      }
    }
  }

  final pngBytes = img.encodePng(image);
  File(path).writeAsBytesSync(pngBytes);
}

void drawPolygon(
  img.Image image,
  List<Point<double>> pts,
  int color1,
  int color2,
) {
  fillTri(image, pts[0], pts[1], pts[2], color1);
  fillTri(image, pts[0], pts[2], pts[3], color2);
}

void fillTri(
  img.Image image,
  Point<double> p1,
  Point<double> p2,
  Point<double> p3,
  int hexColor,
) {
  final minX = max(0, min(p1.x, min(p2.x, p3.x)).floor());
  final maxX = min(image.width - 1, max(p1.x, max(p2.x, p3.x)).ceil());
  final minY = max(0, min(p1.y, min(p2.y, p3.y)).floor());
  final maxY = min(image.height - 1, max(p1.y, max(p2.y, p3.y)).ceil());

  final r = (hexColor >> 16) & 0xFF;
  final g = (hexColor >> 8) & 0xFF;
  final b = hexColor & 0xFF;

  double edgeFunction(Point<double> a, Point<double> b, double px, double py) {
    return (px - a.x) * (b.y - a.y) - (py - a.y) * (b.x - a.x);
  }

  final area = edgeFunction(p1, p2, p3.x, p3.y);
  if (area == 0) return;

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final w0 = edgeFunction(p2, p3, x.toDouble(), y.toDouble());
      final w1 = edgeFunction(p3, p1, x.toDouble(), y.toDouble());
      final w2 = edgeFunction(p1, p2, x.toDouble(), y.toDouble());

      if ((area > 0 && w0 >= 0 && w1 >= 0 && w2 >= 0) ||
          (area < 0 && w0 <= 0 && w1 <= 0 && w2 <= 0)) {
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }
}

void generateCategoryBanner(
  String path,
  String label,
  int bgHex,
  int accentHex,
  int secondaryHex,
) {
  const width = 600;
  const height = 400;
  final image = img.Image(width: width, height: height);

  final bgR = (bgHex >> 16) & 0xFF;
  final bgG = (bgHex >> 8) & 0xFF;
  final bgB = bgHex & 0xFF;

  final acR = (accentHex >> 16) & 0xFF;
  final acG = (accentHex >> 8) & 0xFF;
  final acB = accentHex & 0xFF;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final f = (x + y) / (width + height);
      final r = (bgR * (1 - f * 0.4)).toInt();
      final g = (bgG * (1 - f * 0.4)).toInt();
      final b = (bgB * (1 - f * 0.4)).toInt();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  for (var i = 0; i < 6; i++) {
    final yPos = 80 + i * 50;
    for (var x = 50; x < width - 50; x++) {
      final wave = (sin((x + i * 40) * 0.03) * 20).toInt();
      final py = yPos + wave;
      if (py >= 0 && py < height) {
        image.setPixelRgba(x, py, acR, acG, acB, 180);
        if (py + 1 < height) image.setPixelRgba(x, py + 1, acR, acG, acB, 140);
      }
    }
  }

  for (var r = 80; r > 0; r--) {
    final alpha = (255 * (1 - r / 80)).toInt();
    for (double a = 0; a < 2 * pi; a += 0.02) {
      final px = (width ~/ 2 + r * cos(a)).toInt();
      final py = (height ~/ 2 + r * sin(a)).toInt();
      if (px >= 0 && px < width && py >= 0 && py < height) {
        image.setPixelRgba(px, py, acR, acG, acB, (alpha * 0.3).toInt());
      }
    }
  }

  File(path).writeAsBytesSync(img.encodePng(image));
}

void generateBadge(String path, String label, int accentHex) {
  const width = 400;
  const height = 400;
  final image = img.Image(width: width, height: height);

  final acR = (accentHex >> 16) & 0xFF;
  final acG = (accentHex >> 8) & 0xFF;
  final acB = accentHex & 0xFF;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(x, y, 16, 22, 30, 255);
    }
  }

  for (var y = 40; y < height - 40; y++) {
    for (var x = 40; x < width - 40; x++) {
      final dx = (x - width / 2).abs();
      final dy = (y - height / 2).abs();
      if (dx * 1.5 + dy < 200) {
        image.setPixelRgba(x, y, 24, 34, 48, 255);
      }
    }
  }

  for (double a = 0; a < 2 * pi; a += 0.01) {
    final px = (width ~/ 2 + 100 * cos(a)).toInt();
    final py = (height ~/ 2 + 100 * sin(a)).toInt();
    for (var i = -2; i <= 2; i++) {
      for (var j = -2; j <= 2; j++) {
        image.setPixelRgba(px + i, py + j, acR, acG, acB, 220);
      }
    }
  }

  File(path).writeAsBytesSync(img.encodePng(image));
}
