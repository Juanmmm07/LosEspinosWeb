import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'firebase_options.dart';

import 'models/reserva.dart';

import 'services/firebase_auth_service.dart';
import 'services/habitacion_service.dart';
import 'services/landing_service.dart';
import 'services/comentario_service.dart';
import 'services/pago_service.dart';
import 'services/firestore_storage_service.dart';

import 'pages/landing_page.dart';
import 'pages/habitaciones_page.dart';
import 'pages/hacer_reserva_page.dart';
import 'pages/cuenta_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LosEspinosApp());
}

class LosEspinosApp extends StatefulWidget {
  const LosEspinosApp({super.key});

  @override
  State<LosEspinosApp> createState() => _LosEspinosAppState();
}

class _LosEspinosAppState extends State<LosEspinosApp> {
  int _paginaSeleccionada = 0;
  List<Reserva> _reservas = [];
  String? _tipoHabitacionSeleccionada;

  final FirebaseAuthService _authService = FirebaseAuthService();
  final HabitacionService _habitacionService = HabitacionService();
  final LandingService _landingService = LandingService();
  final ComentarioService _comentarioService = ComentarioService();
  final PagoService _pagoService = PagoService();

  bool _isLoading = true;
  StreamSubscription? _reservasSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    print('🚀 Iniciando servicios...');
    
    await _authService.initialize();
    print('✅ Auth inicializado');

    // Escuchar reservas en tiempo real desde Firestore
    _iniciarEscuchaReservas();
    print('✅ Escucha de reservas iniciada');

    _authService.addListener(_updateState);
    _habitacionService.addListener(_updateState);
    _landingService.addListener(_updateState);
    _comentarioService.addListener(_updateState);
    _pagoService.addListener(_updateState);

    setState(() => _isLoading = false);
    print('✅ Todos los servicios listos');
  }

  void _iniciarEscuchaReservas() {
    _reservasSubscription = FirestoreStorageService.reservasStream().listen(
      (data) {
        setState(() {
          _reservas = data.map((json) => Reserva.fromJson(json)).toList();
        });
        print('🔄 Reservas actualizadas: ${_reservas.length}');
      },
      onError: (e) {
        print('❌ Error en stream de reservas: $e');
      },
    );
  }

  @override
  void dispose() {
    _reservasSubscription?.cancel();
    _authService.removeListener(_updateState);
    _habitacionService.removeListener(_updateState);
    _landingService.removeListener(_updateState);
    _comentarioService.removeListener(_updateState);
    _pagoService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() => setState(() {});

  void _irAHacerReserva(String tipoHabitacion) {
    if (!_authService.isLoggedIn) {
      _mostrarDialogoLoginYRedirigir(tipoHabitacion);
    } else {
      setState(() {
        _tipoHabitacionSeleccionada = tipoHabitacion;
        _paginaSeleccionada = 2;
      });
    }
  }

  Future<void> _mostrarDialogoLoginYRedirigir(String tipoHabitacion) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_person, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 12),
            const Text('Inicia sesión'),
          ],
        ),
        content: const Text(
          'Para realizar una reserva necesitas iniciar sesión con Google.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancelar', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700),
            child: const Text('Iniciar Sesión',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (resultado == true && mounted) {
      await _handleGoogleSignIn(tipoHabitacion);
    }
  }

  Future<void> _handleGoogleSignIn(String? tipoHabitacion) async {
    setState(() => _isLoading = true);

    final success = await _authService.signInWithGoogle();

    setState(() => _isLoading = false);

    if (success && mounted) {
      _mostrarSnackBar(
        '¡Bienvenido ${_authService.currentUser!.name}!',
        Colors.green,
      );

      if (tipoHabitacion != null) {
        setState(() {
          _tipoHabitacionSeleccionada = tipoHabitacion;
          _paginaSeleccionada = 2;
        });
      }
    } else if (mounted) {
      _mostrarSnackBar(
        'Error al iniciar sesión. Intenta nuevamente.',
        Colors.red,
      );
    }
  }

  Future<void> _agregarReserva(Reserva reserva) async {
    // Guardar en Firestore
    await FirestoreStorageService.guardarReserva(reserva.toJson());
    
    setState(() {
      _paginaSeleccionada = 3;
    });
    
    _mostrarSnackBar('¡Reserva confirmada! ID: ${reserva.id}', Colors.green);
  }

  Future<void> _cancelarReserva(Reserva reserva) async {
    // Actualizar estado en Firestore
    await FirestoreStorageService.actualizarReserva(
      reserva.id, 
      {'estado': 'cancelada'},
    );
  }

  void _navegarDesdeMenu(int index) {
    setState(() {
      _paginaSeleccionada = index;
    });
    Navigator.pop(context);
  }

  void _mostrarSnackBar(String mensaje, MaterialColor color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.shade700, Colors.green.shade300],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.park,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cargando Los Espinos...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget paginaActual;

    switch (_paginaSeleccionada) {
      case 0:
        paginaActual = LandingPage(
          onExplorar: () => setState(() => _paginaSeleccionada = 1),
          onReservar: _irAHacerReserva,
          landingService: _landingService,
          comentarioService: _comentarioService,
          authService: _authService,
        );
        break;
      case 1:
        paginaActual = HabitacionesPage(
          onSeleccionar: _irAHacerReserva,
          habitacionService: _habitacionService,
          authService: _authService,
        );
        break;
      case 2:
        if (!_authService.isLoggedIn) {
          Future.microtask(() => setState(() => _paginaSeleccionada = 1));
          paginaActual = Container();
        } else {
          paginaActual = HacerReservaPage(
            tipoHabitacion: _tipoHabitacionSeleccionada ?? 'Cama Matrimonial',
            reservasExistentes: _reservas,
            onReservaCreada: _agregarReserva,
            authService: _authService,
            habitacionService: _habitacionService,
            pagoService: _pagoService,
          );
        }
        break;
      case 3:
        paginaActual = CuentaPage(
          authService: _authService,
          reservas: _reservas,
          habitacionService: _habitacionService,
          landingService: _landingService,
          comentarioService: _comentarioService,
          pagoService: _pagoService,
          onCancelar: _cancelarReserva,
        );
        break;
      default:
        paginaActual = Container();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Los Espinos Glamping',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Segoe UI',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.green.shade900,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.green.shade900),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.park, color: Colors.green.shade700, size: 30),
              const SizedBox(width: 10),
              Text(
                'LOS ESPINOS',
                style: TextStyle(
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        endDrawer: _buildDrawer(),
        body: paginaActual,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade800, Colors.green.shade500],
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: _authService.isLoggedIn &&
                      _authService.currentUser!.photoURL != null
                  ? NetworkImage(_authService.currentUser!.photoURL!)
                  : null,
              child: _authService.isLoggedIn &&
                      _authService.currentUser!.photoURL == null
                  ? Text(
                      _authService.currentUser!.name[0],
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : (!_authService.isLoggedIn
                      ? const Icon(Icons.person, color: Colors.green)
                      : null),
            ),
            accountName: Text(
              _authService.isLoggedIn
                  ? _authService.currentUser!.name
                  : 'Invitado',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              _authService.isLoggedIn
                  ? _authService.currentUser!.email
                  : 'Bienvenido al Glamping',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(
                  icon: Icons.home_rounded,
                  text: 'Inicio',
                  isSelected: _paginaSeleccionada == 0,
                  onTap: () => _navegarDesdeMenu(0),
                ),
                _buildMenuItem(
                  icon: Icons.bed_rounded,
                  text: 'Habitaciones',
                  isSelected: _paginaSeleccionada == 1,
                  onTap: () => _navegarDesdeMenu(1),
                ),
                _buildMenuItem(
                  icon: Icons.person_rounded,
                  text: 'Mi Perfil',
                  isSelected: _paginaSeleccionada == 3,
                  onTap: () => _navegarDesdeMenu(3),
                ),
                const Divider(height: 30),
                if (!_authService.isLoggedIn)
                  ListTile(
                    leading: const Icon(Icons.login, color: Colors.green),
                    title: const Text(
                      'Iniciar con Google',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _handleGoogleSignIn(null);
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _authService.logout();
                      _mostrarSnackBar(
                          'Sesión cerrada correctamente', Colors.green);
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Versión Web 2.0 - Firestore',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.green.shade900 : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}