import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/habitacion.dart';
import 'firestore_storage_service.dart';

class HabitacionService extends ChangeNotifier {
  List<Habitacion> _habitaciones = [];
  bool _isLoading = true;
  StreamSubscription? _subscription;
  
  // ✅ NUEVO: Flag para prevenir conflictos durante actualizaciones
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

  // Escuchar cambios en tiempo real desde Firestore
  void _iniciarEscucha() {
    _subscription = FirestoreStorageService.habitacionesStream().listen(
      (data) {
        // ✅ CLAVE: No actualizar desde el stream si estamos en medio de una actualización
        if (_isUpdating) {
          print('⏸️ Actualizando... ignorando cambios del stream temporalmente');
          return;
        }
        
        if (data.isNotEmpty) {
          _habitaciones = data.map((json) => Habitacion.fromJson(json)).toList();
          print('📄 Habitaciones actualizadas desde Firestore: ${_habitaciones.length}');
        } else if (_habitaciones.isEmpty) {
          _inicializarDatos();
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        print('❌ Error en stream de habitaciones: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _inicializarDatos() async {
    print('🆕 Inicializando habitaciones por primera vez...');
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
    
    // ✅ Esperar un poco antes de permitir actualizaciones del stream
    await Future.delayed(const Duration(milliseconds: 500));
    _isUpdating = false;
    notifyListeners();
  }

  // ✅ MÉTODO CORREGIDO - Este era el problema principal
  Future<void> actualizarHabitacion(String id, Habitacion habitacionActualizada) async {
    final index = _habitaciones.indexWhere((h) => h.id == id);
    if (index != -1) {
      // ✅ Activar flag para ignorar cambios del stream
      _isUpdating = true;
      
      // Actualizar en la lista local
      _habitaciones[index] = habitacionActualizada;
      
      print('🔄 Actualizando habitación $id en Firestore...');
      
      // Guardar en Firestore
      await FirestoreStorageService.actualizarHabitacion(
        id, 
        habitacionActualizada.toJson()
      );
      
      print('✅ Habitación $id actualizada correctamente');
      
      // ✅ Esperar un poco más para asegurar que Firestore procese el cambio
      await Future.delayed(const Duration(milliseconds: 800));
      
      // ✅ Desactivar flag
      _isUpdating = false;
      
      notifyListeners();
    }
  }

  Future<void> toggleActiva(String id) async {
    final index = _habitaciones.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habitacionActualizada = _habitaciones[index].copyWith(
        activa: !_habitaciones[index].activa,
      );
      
      await actualizarHabitacion(id, habitacionActualizada);
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
        descripcion:
            'Habitación acogedora con cama matrimonial king size, perfecta para parejas que buscan intimidad y confort en medio de la naturaleza.',
        precioBase: 75000,
        capacidad: 2,
        imagenes: [
          'assets/images/glamping_1.jpg',
          'assets/images/glamping_2.jpg',
        ],
        activa: true,
        comodidades: ['Wi-Fi', 'Baño privado', 'Terraza', 'Desayuno incluido'],
        categoria: 'Habitación Premium',
      ),
      Habitacion(
        id: 'hab2',
        nombre: 'Camas de Dos Pisos',
        descripcion:
            'Espaciosa habitación con camas literas de dos pisos, ideal para familias o grupos de amigos. Ambiente acogedor con todas las comodidades.',
        precioBase: 100000,
        capacidad: 4,
        imagenes: [
          'assets/images/glamping_2.jpg',
          'assets/images/glamping_3.jpg',
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
        descripcion:
            'Experiencia auténtica de camping en zona designada con acceso a baños y duchas. Disfruta de la naturaleza bajo las estrellas.',
        precioBase: 20000,
        capacidad: 6,
        imagenes: [
          'assets/images/glamping_3.jpg',
          'assets/images/glamping_1.jpg',
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