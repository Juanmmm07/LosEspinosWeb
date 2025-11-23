import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Selecciona una imagen desde la galería o cámara
  /// Retorna los bytes de la imagen y el nombre del archivo
  static Future<Map<String, dynamic>?> seleccionarImagen({
    bool desdeGaleria = true,
  }) async {
    try {
      if (kIsWeb) {
        return await _seleccionarImagenWeb();
      } else {
        return await _seleccionarImagenMobile(desdeGaleria);
      }
    } catch (e) {
      print('❌ Error al seleccionar imagen: $e');
      return null;
    }
  }

  /// Selección de imagen para WEB
  static Future<Map<String, dynamic>?> _seleccionarImagenWeb() async {
    final completer = html.FileUploadInputElement();
    completer.accept = 'image/*';
    completer.click();

    await completer.onChange.first;

    if (completer.files == null || completer.files!.isEmpty) {
      return null;
    }

    final file = completer.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final bytes = reader.result as Uint8List;
    return {
      'bytes': bytes,
      'nombre': file.name,
      'tipo': file.type,
    };
  }

  /// Selección de imagen para MOBILE
  static Future<Map<String, dynamic>?> _seleccionarImagenMobile(
      bool desdeGaleria) async {
    final XFile? imagen = await _picker.pickImage(
      source: desdeGaleria ? ImageSource.gallery : ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (imagen == null) return null;

    final bytes = await imagen.readAsBytes();
    return {
      'bytes': bytes,
      'nombre': imagen.name,
      'tipo': 'image/jpeg',
    };
  }

  /// Sube una imagen a Firebase Storage
  /// [carpeta] puede ser 'habitaciones', 'landing', 'comentarios'
  /// Retorna la URL de descarga
  static Future<String?> subirImagen({
    required Uint8List bytes,
    required String nombreArchivo,
    required String carpeta,
  }) async {
    try {
      final String nombreUnico =
          '${DateTime.now().millisecondsSinceEpoch}_$nombreArchivo';
      final Reference ref = _storage.ref().child('$carpeta/$nombreUnico');

      // Subir archivo
      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Esperar a que termine
      final TaskSnapshot snapshot = await uploadTask;

      // Obtener URL de descarga
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Imagen subida: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      return null;
    }
  }

  /// Elimina una imagen de Firebase Storage
  static Future<bool> eliminarImagen(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
      print('✅ Imagen eliminada');
      return true;
    } catch (e) {
      print('❌ Error al eliminar imagen: $e');
      return false;
    }
  }

  /// Selecciona múltiples imágenes (solo web por ahora)
  static Future<List<Map<String, dynamic>>> seleccionarMultiplesImagenes() async {
    List<Map<String, dynamic>> imagenes = [];

    if (kIsWeb) {
      final completer = html.FileUploadInputElement();
      completer.accept = 'image/*';
      completer.multiple = true;
      completer.click();

      await completer.onChange.first;

      if (completer.files == null || completer.files!.isEmpty) {
        return [];
      }

      for (var file in completer.files!) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;

        final bytes = reader.result as Uint8List;
        imagenes.add({
          'bytes': bytes,
          'nombre': file.name,
          'tipo': file.type,
        });
      }
    } else {
      final List<XFile> imgs = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      for (var img in imgs) {
        final bytes = await img.readAsBytes();
        imagenes.add({
          'bytes': bytes,
          'nombre': img.name,
          'tipo': 'image/jpeg',
        });
      }
    }

    return imagenes;
  }
}