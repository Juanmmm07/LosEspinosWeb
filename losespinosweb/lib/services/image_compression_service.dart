import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'dart:convert';

/// Servicio para comprimir imágenes antes de guardarlas en Firestore
/// Esto permite almacenar imágenes GRATIS sin usar Firebase Storage
class ImageCompressionService {
  
  /// Comprime una imagen a un tamaño máximo especificado (default 300KB)
  /// Mantiene una calidad aceptable y convierte a base64
  static Future<String> comprimirYConvertirABase64(
    Uint8List bytes, {
    int maxKB = 300,
    int maxAncho = 1200,
  }) async {
    try {
      // Decodificar la imagen original
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }
      
      // Redimensionar si es muy grande
      if (image.width > maxAncho) {
        image = img.copyResize(image, width: maxAncho);
        print('📐 Imagen redimensionada a ${image.width}x${image.height}');
      }
      
      // Comprimir con calidad progresiva hasta alcanzar el tamaño deseado
      int quality = 85;
      Uint8List compressed = Uint8List.fromList(
        img.encodeJpg(image, quality: quality)
      );
      
      final maxBytes = maxKB * 1024;
      
      // Reducir calidad gradualmente hasta cumplir el límite
      while (compressed.length > maxBytes && quality > 20) {
        quality -= 5;
        compressed = Uint8List.fromList(
          img.encodeJpg(image, quality: quality)
        );
      }
      
      // Si aún es muy grande, reducir más el tamaño
      if (compressed.length > maxBytes && image.width > 800) {
        image = img.copyResize(image, width: 800);
        quality = 70;
        compressed = Uint8List.fromList(
          img.encodeJpg(image, quality: quality)
        );
      }
      
      final tamanoFinalKB = (compressed.length / 1024).toStringAsFixed(2);
      print('✅ Imagen comprimida: $tamanoFinalKB KB (calidad: $quality%)');
      
      // Convertir a base64 con prefijo data URI
      final base64String = 'data:image/jpeg;base64,${base64Encode(compressed)}';
      
      return base64String;
      
    } catch (e) {
      print('❌ Error al comprimir imagen: $e');
      rethrow;
    }
  }
  
  /// Comprime múltiples imágenes en paralelo
  static Future<List<String>> comprimirMultiples(
    List<Uint8List> imagenes, {
    int maxKB = 300,
  }) async {
    final List<String> resultado = [];
    
    for (var bytes in imagenes) {
      try {
        final comprimida = await comprimirYConvertirABase64(bytes, maxKB: maxKB);
        resultado.add(comprimida);
      } catch (e) {
        print('⚠️ Error al comprimir una imagen: $e');
        // Continuar con las demás
      }
    }
    
    return resultado;
  }
  
  /// Obtiene el tamaño real de una imagen base64 en KB
  static double getTamanoBase64KB(String base64String) {
    try {
      // Remover el prefijo data:image/...;base64,
      final sinPrefijo = base64String.contains(',') 
          ? base64String.split(',').last 
          : base64String;
      
      // Base64 usa 4 caracteres para representar 3 bytes
      // Tamaño real = (longitud * 3) / 4
      return (sinPrefijo.length * 0.75) / 1024;
    } catch (e) {
      return 0;
    }
  }
  
  /// Valida que una imagen base64 no exceda el límite especificado
  static bool validarTamano(String base64String, {double maxKB = 300}) {
    return getTamanoBase64KB(base64String) <= maxKB;
  }
  
  /// Obtiene información detallada de una imagen base64
  static Map<String, dynamic> getInfoImagen(String base64String) {
    try {
      final sinPrefijo = base64String.split(',').last;
      final bytes = base64Decode(sinPrefijo);
      final image = img.decodeImage(bytes);
      
      return {
        'tamanoKB': getTamanoBase64KB(base64String),
        'ancho': image?.width ?? 0,
        'alto': image?.height ?? 0,
        'formato': 'JPEG',
        'esValida': image != null,
      };
    } catch (e) {
      return {
        'tamanoKB': getTamanoBase64KB(base64String),
        'error': e.toString(),
        'esValida': false,
      };
    }
  }
  
  /// Convierte una imagen base64 de vuelta a Uint8List (para preview)
  static Uint8List base64ToUint8List(String base64String) {
    final sinPrefijo = base64String.contains(',')
        ? base64String.split(',').last
        : base64String;
    return base64Decode(sinPrefijo);
  }

  /// Obtiene el tamaño total de múltiples imágenes en MB
  static double getTamanoTotalMB(List<String> imagenes) {
    double totalKB = 0;
    for (var img in imagenes) {
      totalKB += getTamanoBase64KB(img);
    }
    return totalKB / 1024;
  }

  /// Valida que un conjunto de imágenes no exceda el límite total
  static bool validarConjunto(List<String> imagenes, {double maxTotalMB = 1.0}) {
    return getTamanoTotalMB(imagenes) <= maxTotalMB;
  }
}