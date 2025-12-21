// lib/utils/image_converter.dart

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Convertit une frame YUV420_888 de CameraImage en format img.Image (RGB).
img.Image? convertYUV420ToImage(CameraImage image) {
  if (image.format.group != ImageFormatGroup.yuv420) {
    return null; // Format non supporté
  }

  // Obtenez les buffers YUV
  final planeY = image.planes[0];
  final planeU = image.planes[1];
  final planeV = image.planes[2];

  final yuvBytes = Uint8List(image.width * image.height * 3 ~/ 2);
  final outputRgb = img.Image(width: image.width, height: image.height); 

  // Implémentation brute (très lente en Dart pur, mais simple pour l'exemple)
  // Une implémentation rapide utiliserait FFI ou des fonctions natives optimisées
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      // 1. Lire Y, U, V
      final int yVal = planeY.bytes[y * planeY.bytesPerRow + x * planeY.bytesPerPixel!];
      
      // Les plans U et V sont sous-échantillonnés (divisés par 2)
      final int uvX = (x / 2).floor();
      final int uvY = (y / 2).floor();
      
      // Calcul des indices U et V
      final int uIndex = uvY * planeU.bytesPerRow + uvX * planeU.bytesPerPixel!;
      final int vIndex = uvY * planeV.bytesPerRow + uvX * planeV.bytesPerPixel!;

      final int uVal = planeU.bytes[uIndex];
      final int vVal = planeV.bytes[vIndex];

      // 2. Conversion YUV vers RGB (Approximation : YCbCr)
      final int r = (yVal + 1.402 * (vVal - 128)).clamp(0, 255).toInt();
      final int g = (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128)).clamp(0, 255).toInt();
      final int b = (yVal + 1.772 * (uVal - 128)).clamp(0, 255).toInt();
      
      // 3. Écrire le pixel RGB
      outputRgb.setPixelRgb(x, y, r, g, b);
    }
  }

  return outputRgb;
}