import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreStorageService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===================== HABITACIONES =====================
  static Future<void> guardarHabitaciones(
      List<Map<String, dynamic>> habitaciones) async {
    try {
      print('💾 Guardando ${habitaciones.length} habitaciones en Firestore...');
      final batch = _db.batch();
      final collection = _db.collection('habitaciones');

      final existentes = await collection.get();
      for (var doc in existentes.docs) {
        batch.delete(doc.reference);
      }

      for (var habitacion in habitaciones) {
        final docRef = collection.doc(habitacion['id']);
        if (habitacion['imagenes'] != null) {
          print(
              '🖼️ Hab ${habitacion['id']}: ${(habitacion['imagenes'] as List).length} imágenes');
        }
        batch.set(docRef, habitacion, SetOptions(merge: false));
      }

      await batch.commit();
      print('✅ Habitaciones guardadas en Firestore');
    } catch (e) {
      print('❌ Error al guardar habitaciones: $e');
      rethrow;
    }
  }

  static Future<void> actualizarHabitacion(
      String id, Map<String, dynamic> habitacionData) async {
    try {
      print('📝 Actualizando habitación $id en Firestore...');

      if (habitacionData['imagenes'] != null) {
        final imagenes = habitacionData['imagenes'] as List;
        print('🖼️ Total imágenes a guardar: ${imagenes.length}');
      }

      await _db
          .collection('habitaciones')
          .doc(id)
          .set(habitacionData, SetOptions(merge: false));
      print('✅ Habitación $id actualizada en Firestore');

      await Future.delayed(const Duration(milliseconds: 500));
      final doc = await _db.collection('habitaciones').doc(id).get();
      if (doc.exists) {
        final data = doc.data();
        final imagenesGuardadas = (data?['imagenes'] as List?)?.length ?? 0;
        print(
            '🔍 Verificación exitosa: $imagenesGuardadas imágenes en Firestore');
      }
    } catch (e) {
      print('❌ Error al actualizar habitación: $e');
      rethrow;
    }
  }

  static Stream<List<Map<String, dynamic>>> habitacionesStream() {
    return _db.collection('habitaciones').snapshots().map((snapshot) {
      final habitaciones = snapshot.docs.map((doc) => doc.data()).toList();
      return habitaciones;
    });
  }

  // ===================== LANDING/SLIDES =====================
  static Future<void> guardarLanding(List<Map<String, String>> slides) async {
    try {
      print('💾 Guardando ${slides.length} slides en Firestore...');
      await _db.collection('config').doc('landing').set({
        'slides': slides,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));
      print('✅ Landing guardado en Firestore');
    } catch (e) {
      print('❌ Error al guardar landing: $e');
      rethrow;
    }
  }

  static Stream<List<Map<String, String>>> landingStream() {
    return _db.collection('config').doc('landing').snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return <Map<String, String>>[];
      final slides = doc.data()!['slides'] as List<dynamic>?;
      if (slides == null) return <Map<String, String>>[];
      return slides.map((s) => Map<String, String>.from(s)).toList();
    });
  }

  // ===================== COMENTARIOS =====================
  static Future<void> guardarComentarios(
      List<Map<String, dynamic>> comentarios) async {
    try {
      final batch = _db.batch();
      final collection = _db.collection('comentarios');

      final existentes = await collection.get();
      for (var doc in existentes.docs) {
        batch.delete(doc.reference);
      }

      for (var comentario in comentarios) {
        final docRef = collection.doc(comentario['id']);
        batch.set(docRef, comentario);
      }

      await batch.commit();
      print('✅ Comentarios guardados en Firestore');
    } catch (e) {
      print('❌ Error al guardar comentarios: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> comentariosStream() {
    return _db
        .collection('comentarios')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ===================== RESERVAS =====================
  static Future<void> guardarReserva(Map<String, dynamic> reserva) async {
    try {
      await _db.collection('reservas').doc(reserva['id']).set(reserva);
      print('✅ Reserva guardada: ${reserva['id']}');
    } catch (e) {
      print('❌ Error al guardar reserva: $e');
    }
  }

  static Future<void> actualizarReserva(
      String id, Map<String, dynamic> data) async {
    try {
      await _db.collection('reservas').doc(id).update(data);
      print('✅ Reserva actualizada: $id');
    } catch (e) {
      print('❌ Error al actualizar reserva: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> reservasStream() {
    return _db
        .collection('reservas')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
