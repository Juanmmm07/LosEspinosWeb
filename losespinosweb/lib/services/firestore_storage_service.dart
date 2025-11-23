import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreStorageService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===================== HABITACIONES =====================
  static Future<void> guardarHabitaciones(List<Map<String, dynamic>> habitaciones) async {
    try {
      final batch = _db.batch();
      final collection = _db.collection('habitaciones');
      
      // Primero eliminar todas las existentes
      final existentes = await collection.get();
      for (var doc in existentes.docs) {
        batch.delete(doc.reference);
      }
      
      // Luego agregar las nuevas
      for (var habitacion in habitaciones) {
        final docRef = collection.doc(habitacion['id']);
        batch.set(docRef, habitacion);
      }
      
      await batch.commit();
      print('✅ Habitaciones guardadas en Firestore');
    } catch (e) {
      print('❌ Error al guardar habitaciones: $e');
    }
  }

  static Future<List<Map<String, dynamic>>?> cargarHabitaciones() async {
    try {
      final snapshot = await _db.collection('habitaciones').get();
      if (snapshot.docs.isEmpty) return null;
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error al cargar habitaciones: $e');
      return null;
    }
  }

  static Stream<List<Map<String, dynamic>>> habitacionesStream() {
    return _db.collection('habitaciones').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  // ===================== LANDING/SLIDES =====================
  static Future<void> guardarLanding(List<Map<String, String>> slides) async {
    try {
      await _db.collection('config').doc('landing').set({
        'slides': slides,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Landing guardado en Firestore');
    } catch (e) {
      print('❌ Error al guardar landing: $e');
    }
  }

  static Future<List<Map<String, String>>?> cargarLanding() async {
    try {
      final doc = await _db.collection('config').doc('landing').get();
      if (!doc.exists || doc.data() == null) return null;
      
      final data = doc.data()!;
      final slides = data['slides'] as List<dynamic>?;
      if (slides == null) return null;
      
      return slides.map((s) => Map<String, String>.from(s)).toList();
    } catch (e) {
      print('❌ Error al cargar landing: $e');
      return null;
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
  static Future<void> guardarComentarios(List<Map<String, dynamic>> comentarios) async {
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

  static Future<List<Map<String, dynamic>>?> cargarComentarios() async {
    try {
      final snapshot = await _db.collection('comentarios')
          .orderBy('fecha', descending: true)
          .get();
      if (snapshot.docs.isEmpty) return null;
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error al cargar comentarios: $e');
      return null;
    }
  }

  static Stream<List<Map<String, dynamic>>> comentariosStream() {
    return _db.collection('comentarios')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ===================== RESERVAS =====================
  static Future<void> guardarReservas(List<Map<String, dynamic>> reservas) async {
    try {
      final batch = _db.batch();
      final collection = _db.collection('reservas');
      
      final existentes = await collection.get();
      for (var doc in existentes.docs) {
        batch.delete(doc.reference);
      }
      
      for (var reserva in reservas) {
        final docRef = collection.doc(reserva['id']);
        batch.set(docRef, reserva);
      }
      
      await batch.commit();
      print('✅ Reservas guardadas en Firestore');
    } catch (e) {
      print('❌ Error al guardar reservas: $e');
    }
  }

  static Future<void> guardarReserva(Map<String, dynamic> reserva) async {
    try {
      await _db.collection('reservas').doc(reserva['id']).set(reserva);
      print('✅ Reserva guardada: ${reserva['id']}');
    } catch (e) {
      print('❌ Error al guardar reserva: $e');
    }
  }

  static Future<void> actualizarReserva(String id, Map<String, dynamic> data) async {
    try {
      await _db.collection('reservas').doc(id).update(data);
      print('✅ Reserva actualizada: $id');
    } catch (e) {
      print('❌ Error al actualizar reserva: $e');
    }
  }

  static Future<List<Map<String, dynamic>>?> cargarReservas() async {
    try {
      final snapshot = await _db.collection('reservas')
          .orderBy('fechaCreacion', descending: true)
          .get();
      if (snapshot.docs.isEmpty) return null;
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error al cargar reservas: $e');
      return null;
    }
  }

  static Stream<List<Map<String, dynamic>>> reservasStream() {
    return _db.collection('reservas')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Reservas por usuario
  static Stream<List<Map<String, dynamic>>> reservasUsuarioStream(String odId) {
    return _db.collection('reservas')
        .where('userId', isEqualTo: odId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}