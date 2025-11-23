import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/comentario.dart';
import 'firestore_storage_service.dart';

class ComentarioService extends ChangeNotifier {
  List<Comentario> _comentarios = [];
  StreamSubscription? _subscription;

  ComentarioService() {
    _iniciarEscucha();
  }

  List<Comentario> get todosLosComentarios => _comentarios;
  List<Comentario> get comentariosAprobados =>
      _comentarios.where((c) => c.aprobado).toList();
  List<Comentario> get comentariosPendientes =>
      _comentarios.where((c) => !c.aprobado).toList();

  void _iniciarEscucha() {
    _subscription = FirestoreStorageService.comentariosStream().listen(
      (data) {
        if (data.isNotEmpty) {
          _comentarios = data.map((json) => Comentario.fromJson(json)).toList();
          print('📄 Comentarios actualizados desde Firestore: ${_comentarios.length}');
        } else if (_comentarios.isEmpty) {
          _inicializarDatos();
        }
        notifyListeners();
      },
      onError: (e) {
        print('❌ Error en stream de comentarios: $e');
        notifyListeners();
      },
    );
  }

  Future<void> _inicializarDatos() async {
    print('🆕 Inicializando comentarios por primera vez...');
    _comentarios = _comentariosIniciales();
    await _guardarDatos();
  }

  Future<void> _guardarDatos() async {
    final jsonList = _comentarios.map((c) => c.toJson()).toList();
    await FirestoreStorageService.guardarComentarios(jsonList);
  }

  Future<void> agregarComentario(Comentario comentario) async {
    _comentarios.add(comentario);
    await _guardarDatos();
    notifyListeners();
  }

  Future<void> aprobarComentario(String id) async {
    final index = _comentarios.indexWhere((c) => c.id == id);
    if (index != -1) {
      _comentarios[index] = _comentarios[index].copyWith(aprobado: true);
      await _guardarDatos();
      notifyListeners();
    }
  }

  Future<void> rechazarComentario(String id) async {
    _comentarios.removeWhere((c) => c.id == id);
    await _guardarDatos();
    notifyListeners();
  }

  Future<void> eliminarComentario(String id) async {
    _comentarios.removeWhere((c) => c.id == id);
    await _guardarDatos();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<Comentario> _comentariosIniciales() {
    return [
      Comentario(
        id: 'com1',
        odId: 'user1',  // ← Cambiado de userId a odId
        userName: 'María García',
        texto: '¡Increíble experiencia! El lugar es hermoso y la atención excelente.',
        calificacion: 5.0,
        fecha: DateTime.now().subtract(const Duration(days: 5)),
        aprobado: true,
      ),
      Comentario(
        id: 'com2',
        odId: 'user2',  // ← Cambiado de userId a odId
        userName: 'Carlos Rodríguez',
        texto: 'Perfecto para desconectarse. La naturaleza y el silencio son de primera.',
        calificacion: 5.0,
        fecha: DateTime.now().subtract(const Duration(days: 10)),
        aprobado: true,
      ),
      Comentario(
        id: 'com3',
        odId: 'user3',  // ← Cambiado de userId a odId
        userName: 'Ana Martínez',
        texto: 'Un lugar mágico. Las habitaciones son cómodas. ¡Muy recomendado!',
        calificacion: 4.5,
        fecha: DateTime.now().subtract(const Duration(days: 15)),
        aprobado: true,
      ),
    ];
  }
}