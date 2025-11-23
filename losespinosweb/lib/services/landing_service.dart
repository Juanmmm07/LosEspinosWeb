import 'package:flutter/foundation.dart';
import 'dart:async';
import 'firestore_storage_service.dart';

class LandingService extends ChangeNotifier {
  List<Map<String, String>> _slides = [];
  StreamSubscription? _subscription;

  LandingService() {
    _iniciarEscucha();
  }

  List<Map<String, String>> get slides => List.unmodifiable(_slides);

  // Escuchar cambios en tiempo real desde Firestore
  void _iniciarEscucha() {
    _subscription = FirestoreStorageService.landingStream().listen(
      (data) {
        if (data.isNotEmpty) {
          _slides = data;
          print('🔄 Landing actualizado desde Firestore: ${_slides.length} slides');
        } else if (_slides.isEmpty) {
          _inicializarDatos();
        }
        notifyListeners();
      },
      onError: (e) {
        print('❌ Error en stream de landing: $e');
        notifyListeners();
      },
    );
  }

  Future<void> _inicializarDatos() async {
    print('🆕 Inicializando landing por primera vez...');
    _slides = _slidesIniciales();
    await _guardarDatos();
  }

  Future<void> _guardarDatos() async {
    await FirestoreStorageService.guardarLanding(_slides);
  }

  Future<void> agregarSlide(Map<String, String> slide) async {
    _slides.add(slide);
    await _guardarDatos();
    notifyListeners();
  }

  Future<void> actualizarSlide(int index, Map<String, String> slide) async {
    if (index >= 0 && index < _slides.length) {
      _slides[index] = slide;
      await _guardarDatos();
      notifyListeners();
    }
  }

  Future<void> eliminarSlide(int index) async {
    if (_slides.length > 1 && index >= 0 && index < _slides.length) {
      _slides.removeAt(index);
      await _guardarDatos();
      notifyListeners();
    }
  }

  Future<void> reordenarSlides(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final slide = _slides.removeAt(oldIndex);
    _slides.insert(newIndex, slide);
    await _guardarDatos();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<Map<String, String>> _slidesIniciales() {
    return [
      {
        'image': 'assets/images/glamping_1.jpg',
        'title': 'Bienvenido a Los Espinos',
        'subtitle': 'Tu refugio natural en el corazón de la montaña',
      },
      {
        'image': 'assets/images/glamping_2.jpg',
        'title': 'Experiencias Únicas',
        'subtitle': 'Naturaleza, confort y aventura en un solo lugar',
      },
      {
        'image': 'assets/images/glamping_3.jpg',
        'title': 'Desconéctate del Mundo',
        'subtitle': 'Vive momentos inolvidables con los tuyos',
      },
    ];
  }
}