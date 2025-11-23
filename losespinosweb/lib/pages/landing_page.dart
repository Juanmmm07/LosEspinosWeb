import 'package:flutter/material.dart';
import 'dart:async';
import '../services/landing_service.dart';
import '../services/comentario_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/comentario.dart';

/// Página principal de aterrizaje del sitio.
/// Muestra un carrusel de imágenes, información del glamping,
/// habitaciones disponibles y testimonios de clientes.
class LandingPage extends StatefulWidget {
  final VoidCallback onExplorar;
  final Function(String) onReservar;
  final LandingService landingService;
  final ComentarioService comentarioService;
  final FirebaseAuthService authService;

  const LandingPage({
    super.key,
    required this.onExplorar,
    required this.onReservar,
    required this.landingService,
    required this.comentarioService,
    required this.authService,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  
  final _comentarioCtrl = TextEditingController();
  double _nuevaCalificacion = 5.0;

  @override
  void initState() {
    super.initState();
    // Registrar listeners para actualizar la UI cuando cambien los datos
    widget.landingService.addListener(_onLandingChanged);
    widget.comentarioService.addListener(_onComentariosChanged);
    widget.authService.addListener(_onAuthChanged);
    _startAutoPlay();
  }

  @override
  void dispose() {
    // Limpiar listeners y controladores
    widget.landingService.removeListener(_onLandingChanged);
    widget.comentarioService.removeListener(_onComentariosChanged);
    widget.authService.removeListener(_onAuthChanged);
    _timer?.cancel();
    _pageController.dispose();
    _comentarioCtrl.dispose();
    super.dispose();
  }

  void _onLandingChanged() => setState(() {});
  void _onComentariosChanged() => setState(() {});
  void _onAuthChanged() => setState(() {});

  /// Inicia el carrusel automático de imágenes que cambia cada 5 segundos
  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final slides = widget.landingService.slides;
      if (slides.isEmpty) return;
      
      if (_currentPage < slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  /// Envía un comentario nuevo para revisión del administrador
  void _enviarComentario() {
    if (_comentarioCtrl.text.isEmpty) return;

    final user = widget.authService.currentUser!;
    
    final nuevoComentario = Comentario(
      id: 'landing_com_${DateTime.now().millisecondsSinceEpoch}',
      odId: user.id,
      userName: user.name,
      texto: _comentarioCtrl.text,
      calificacion: _nuevaCalificacion,
      fecha: DateTime.now(),
      aprobado: false,
      avatarUrl: user.photoURL,
    );

    widget.comentarioService.agregarComentario(nuevoComentario);
    _comentarioCtrl.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Comentario enviado a revisión.'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Inicia sesión con Google y muestra confirmación
  Future<void> _iniciarSesionGoogle() async {
    final success = await widget.authService.signInWithGoogle();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('¡Bienvenido ${widget.authService.currentUser!.name}!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Sección hero con carrusel de imágenes
          SliverToBoxAdapter(
            child: SizedBox(
              height: size.height > 600 ? size.height : 600,
              child: Stack(
                children: [
                  // Carrusel de imágenes
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: widget.landingService.slides.length,
                    itemBuilder: (context, index) {
                      return _buildSlide(widget.landingService.slides[index]);
                    },
                  ),
                  // Degradado inferior para mejorar legibilidad
                  Positioned(
                    bottom: 0, left: 0, right: 0, height: 250,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                        ),
                      ),
                    ),
                  ),
                  // Indicadores de página y botón de reserva
                  Positioned.fill(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            // Indicadores de página
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.landingService.slides.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentPage == index ? 32 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: _currentPage == index
                                        ? Colors.green.shade400
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Botón principal de reserva
                            ElevatedButton(
                              onPressed: widget.onExplorar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 22),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 8,
                              ),
                              child: const Text(
                                'RESERVAR AHORA',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              ),
                            ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Contenido principal
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    // Sección de características
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                      child: Column(
                        children: [
                          Text('La Experiencia Los Espinos',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.green.shade900),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text('Lujo y naturaleza en perfecta armonía',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 50),
                          _buildFeatureGrid(),
                        ],
                      ),
                    ),
                    // Sección de habitaciones
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Column(
                        children: [
                          Text('Nuestros Refugios',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.green.shade900),
                          ),
                          const SizedBox(height: 12),
                          Text('Elige el espacio ideal para tu descanso',
                            style: TextStyle(fontSize: 16, color: Colors.green.shade800),
                          ),
                          const SizedBox(height: 50),
                          _buildRoomCards(context),
                        ],
                      ),
                    ),
                    // Sección de testimonios
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                      child: Column(
                        children: [
                          Text('Lo que dicen nuestros huéspedes',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.green.shade900),
                          ),
                          const SizedBox(height: 50),
                          _buildTestimonials(),
                          const SizedBox(height: 60),
                          _buildCommentSection(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
              color: Colors.green.shade900,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.park, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text('LOS ESPINOS GLAMPING',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 3),
                  ),
                  const SizedBox(height: 30),
                  Text('© 2025 Todos los derechos reservados',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un slide individual del carrusel
  Widget _buildSlide(Map<String, String> slide) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(slide['image'] ?? '', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.green.shade800,
            child: const Icon(Icons.image_not_supported, size: 100, color: Colors.white24),
          ),
        ),
        Container(color: Colors.black.withOpacity(0.3)),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(slide['title']?.toUpperCase() ?? '',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2,
                  shadows: [Shadow(blurRadius: 20, color: Colors.black)]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(slide['subtitle'] ?? '',
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w300,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye la cuadrícula de características del glamping
  Widget _buildFeatureGrid() {
    final features = [
      {'icon': Icons.wifi, 'title': 'Wi-Fi Satelital', 'desc': 'Conexión de alta velocidad'},
      {'icon': Icons.spa, 'title': 'Zona Wellness', 'desc': 'Masajes y relajación'},
      {'icon': Icons.local_fire_department, 'title': 'Fogatas Privadas', 'desc': 'Bajo las estrellas'},
      {'icon': Icons.pets, 'title': 'Pet Friendly', 'desc': 'Mascotas bienvenidas'},
    ];
    return Wrap(
      spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
      children: features.map((f) => Container(
        width: 260, padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            Icon(f['icon'] as IconData, size: 48, color: Colors.green.shade600),
            const SizedBox(height: 20),
            Text(f['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade800)),
            const SizedBox(height: 8),
            Text(f['desc'] as String, style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
          ],
        ),
      )).toList(),
    );
  }

  /// Construye las tarjetas de habitaciones disponibles
  Widget _buildRoomCards(BuildContext context) {
    final rooms = [
      {'name': 'Cama Matrimonial', 'price': '75.000', 'img': Icons.king_bed},
      {'name': 'Camas de Dos Pisos', 'price': '100.000', 'img': Icons.bungalow},
      {'name': 'Zona de Camping', 'price': '20.000', 'img': Icons.nature_people},
    ];
    return Wrap(
      spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
      children: rooms.map((room) => SizedBox(
        width: 320,
        child: Card(
          elevation: 0, color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.green.shade100)),
          child: Column(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green.shade300, Colors.green.shade600]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Center(child: Icon(room['img'] as IconData, size: 70, color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(room['name'] as String, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                    const SizedBox(height: 8),
                    Text('\$${room['price']} COP / noche', style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.onExplorar,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.green.shade600, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('VER DETALLES', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  /// Construye el carrusel de testimonios aprobados
  Widget _buildTestimonials() {
    final comentarios = widget.comentarioService.comentariosAprobados.take(3).toList();
    if (comentarios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Text('Sé el primero en compartir tu experiencia.', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: comentarios.length,
        itemBuilder: (context, index) {
          final c = comentarios[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => Icon(i < c.calificacion ? Icons.star : Icons.star_border, color: Colors.amber.shade400, size: 24)),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: Text('"${c.texto}"', textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, height: 1.5, color: Colors.black87),
                      maxLines: 3, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(c.userName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Construye la sección de comentarios según el estado de autenticación
  Widget _buildCommentSection(BuildContext context) {
    // Si no hay sesión iniciada, mostrar botón de login
    if (!widget.authService.isLoggedIn) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.green.shade900, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            const Icon(Icons.rate_review_outlined, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text('¿Ya nos visitaste?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Queremos saber cómo fue tu experiencia', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _iniciarSesionGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Iniciar sesión con Google'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      );
    }

    // Si hay sesión, mostrar formulario de comentario
    final user = widget.authService.currentUser!;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade100,
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? Text(user.name[0], style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)) : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, ${user.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                  const Text('Comparte tu experiencia', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Calificación:', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: List.generate(5, (index) => IconButton(
              icon: Icon(index < _nuevaCalificacion ? Icons.star : Icons.star_border, color: Colors.amber.shade500, size: 32),
              onPressed: () => setState(() => _nuevaCalificacion = index + 1.0),
            )),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comentarioCtrl,
            decoration: InputDecoration(hintText: 'Escribe aquí tu comentario...', hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(20),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _enviarComentario,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
              ),
              child: const Text('Publicar Comentario'),
            ),
          ),
        ],
      ),
    );
  }
}