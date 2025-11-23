import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/habitacion.dart';
import 'firestore_storage_service.dart';

class HabitacionService extends ChangeNotifier {
  List<Habitacion> _habitaciones = [];
  bool _isLoading = true;
  StreamSubscription? _subscription;

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
        if (data.isNotEmpty) {
          _habitaciones = data.map((json) => Habitacion.fromJson(json)).toList();
          print('🔄 Habitaciones actualizadas desde Firestore: ${_habitaciones.length}');
        } else if (_habitaciones.isEmpty) {
          // Solo inicializar si no hay datos
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
    _habitaciones.add(habitacion);
    await _guardarDatos();
    notifyListeners();
  }

  Future<void> actualizarHabitacion(String id, Habitacion habitacionActualizada) async {
    final index = _habitaciones.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habitaciones[index] = habitacionActualizada;
      await _guardarDatos();
      notifyListeners();
    }
  }

  Future<void> toggleActiva(String id) async {
    final index = _habitaciones.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habitaciones[index] = _habitaciones[index].copyWith(
        activa: !_habitaciones[index].activa,
      );
      await _guardarDatos();
      notifyListeners();
    }
  }

  Future<void> eliminarHabitacion(String id) async {
    _habitaciones.removeWhere((h) => h.id == id);
    await _guardarDatos();
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