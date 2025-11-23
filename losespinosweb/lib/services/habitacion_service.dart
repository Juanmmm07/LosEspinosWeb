import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/habitacion.dart';
import 'firestore_storage_service.dart';

class HabitacionService extends ChangeNotifier {
  List<Habitacion> _habitaciones = [];
  bool _isLoading = true;
  StreamSubscription? _subscription;
  bool _isUpdating = false;

  HabitacionService() {
    _iniciarEscucha();
  }

  List<Habitacion> get todasLasHabitaciones => _habitaciones;
  List<Habitacion> get habitacionesActivas =>
      _habitaciones.where((h) => h.activa).toList();
  bool get isLoading => _isLoading;

  Habitacion? getHabitacionByNombre(String nombre) {
    try {
      return _habitaciones.firstWhere((h) => h.nombre == nombre);
    } catch (e) {
      return null;
    }
  }

  void _iniciarEscucha() {
    _subscription = FirestoreStorageService.habitacionesStream().listen(
      (data) {
        if (_isUpdating) {
          print('⏸️ Actualizando... ignorando cambios del stream');
          return;
        }

        if (data.isNotEmpty) {
          _habitaciones =
              data.map((json) => Habitacion.fromJson(json)).toList();
          print('📄 Habitaciones actualizadas: ${_habitaciones.length}');
        } else if (_habitaciones.isEmpty) {
          _inicializarDatos();
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        print('❌ Error en stream: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _inicializarDatos() async {
    print('🆕 Inicializando habitaciones...');
    _habitaciones = _habitacionesIniciales();
    await _guardarDatos();
  }

  Future<void> _guardarDatos() async {
    final jsonList = _habitaciones.map((h) => h.toJson()).toList();
    await FirestoreStorageService.guardarHabitaciones(jsonList);
  }

  Future<void> agregarHabitacion(Habitacion habitacion) async {
    _isUpdating = true;
    _habitaciones.add(habitacion);
    await _guardarDatos();
    await Future.delayed(const Duration(milliseconds: 500));
    _isUpdating = false;
    notifyListeners();
  }

  Future<void> actualizarHabitacion(
      String id, Habitacion habitacionActualizada) async {
    final index = _habitaciones.indexWhere((h) => h.id == id);
    if (index != -1) {
      _isUpdating = true;

      print('📝 Actualizando habitación $id...');
      print('🖼️ Imágenes totales: ${habitacionActualizada.imagenes.length}');

      // Validar que todas las imágenes sean válidas
      final imagenesValidas = habitacionActualizada.imagenes.where((img) {
        return img.isNotEmpty &&
            (img.startsWith('data:image') ||
                img.startsWith('assets/') ||
                img.startsWith('http'));
      }).toList();

      print('✅ Imágenes válidas: ${imagenesValidas.length}');

      // Actualizar con imágenes válidas
      final habitacionConImagenesValidas = habitacionActualizada.copyWith(
        imagenes: imagenesValidas,
      );

      _habitaciones[index] = habitacionConImagenesValidas;

      // Convertir a JSON y validar
      final jsonData = habitacionConImagenesValidas.toJson();
      print(
          '📦 JSON imagenes length: ${(jsonData['imagenes'] as List).length}');

      // Guardar en Firestore con retry
      bool guardadoExitoso = false;
      int intentos = 0;

      while (!guardadoExitoso && intentos < 3) {
        try {
          await FirestoreStorageService.actualizarHabitacion(id, jsonData);
          guardadoExitoso = true;
          print('✅ Habitación guardada exitosamente (intento ${intentos + 1})');
        } catch (e) {
          intentos++;
          print('⚠️ Error en intento $intentos: $e');
          if (intentos < 3) {
            await Future.delayed(Duration(milliseconds: 500 * intentos));
          } else {
            print('❌ Falló después de 3 intentos');
            rethrow;
          }
        }
      }

      // Esperar más tiempo para asegurar sincronización
      await Future.delayed(const Duration(milliseconds: 1500));

      _isUpdating = false;

      notifyListeners();
    } else {
      print('❌ Habitación con id $id no encontrada');
    }
  }

  Future<void> eliminarHabitacion(String id) async {
    _isUpdating = true;
    _habitaciones.removeWhere((h) => h.id == id);
    await _guardarDatos();
    await Future.delayed(const Duration(milliseconds: 500));
    _isUpdating = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<Habitacion> _habitacionesIniciales() {
    return [
      Habitacion(
        id: 'hab1',
        nombre: 'Cama Matrimonial',
        descripcion: 'Habitación acogedora con cama matrimonial king size.',
        precioBase: 75000,
        capacidad: 2,
        imagenes: [
          'assets/images/glamping_1.jpg',
          'assets/images/glamping_2.jpg'
        ],
        activa: true,
        comodidades: ['Wi-Fi', 'Baño privado', 'Terraza', 'Desayuno incluido'],
        categoria: 'Habitación Premium',
      ),
      Habitacion(
        id: 'hab2',
        nombre: 'Camas de Dos Pisos',
        descripcion: 'Espaciosa habitación con camas literas.',
        precioBase: 100000,
        capacidad: 4,
        imagenes: [
          'assets/images/glamping_2.jpg',
          'assets/images/glamping_3.jpg'
        ],
        activa: true,
        comodidades: [
          'Wi-Fi',
          'Baño compartido',
          'Zona de juegos',
          'Fogata',
          'Hamacas'
        ],
        categoria: 'Habitación Familiar',
      ),
      Habitacion(
        id: 'hab3',
        nombre: 'Zona de Camping',
        descripcion: 'Experiencia auténtica de camping.',
        precioBase: 20000,
        capacidad: 6,
        imagenes: [
          'assets/images/glamping_3.jpg',
          'assets/images/glamping_1.jpg'
        ],
        activa: true,
        comodidades: [
          'Zona de fogata',
          'Baños compartidos',
          'Área de parrilla',
          'Mesas de picnic'
        ],
        categoria: 'Camping',
      ),
    ];
  }
}
