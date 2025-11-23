import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';

/// Página de inicio de sesión de la aplicación.
/// Permite a los usuarios autenticarse mediante Google Sign-In.
/// Incluye animaciones de entrada y un diseño atractivo con gradientes.
class LoginPage extends StatefulWidget {
  final FirebaseAuthService authService;

  const LoginPage({super.key, required this.authService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Configurar animación de fade para la entrada
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Procesa el inicio de sesión con Google
  Future<void> _loginConGoogle() async {
    setState(() => _isLoading = true);

    final success = await widget.authService.signInWithGoogle();

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Login exitoso, cerrar pantalla y mostrar mensaje
      Navigator.pop(context, true);
      _showSnackBar(
        '¡Bienvenido ${widget.authService.currentUser!.name}!',
        Colors.green
      );
    } else if (mounted) {
      // Error en el login
      _showSnackBar(
        'Error al iniciar sesión. Intenta nuevamente.',
        Colors.red
      );
    }
  }

  /// Muestra un mensaje temporal al usuario
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade300,
              Colors.green.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo de la aplicación
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.park,
                            size: 80,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Título
                        Text(
                          'Los Espinos Glamping',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inicia sesión para continuar',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Botón de inicio de sesión con Google
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginConGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey.shade800,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(
                                  color: Colors.grey.shade300
                                ),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.green.shade700,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Logo de Google
                                      Image.network(
                                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                        height: 24,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.g_mobiledata,
                                          size: 28,
                                          color: Colors.red.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Continuar con Google',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Información sobre seguridad
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Usamos tu cuenta de Google para un inicio '
                                  'de sesión seguro y rápido.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Botón para volver
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back,
                            color: Colors.green.shade700),
                          label: Text(
                            'Volver al inicio',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}