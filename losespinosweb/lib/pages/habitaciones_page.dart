import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../services/habitacion_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/habitacion.dart';

class HabitacionesPage extends StatelessWidget {
  final Function(String) onSeleccionar;
  final HabitacionService habitacionService;
  final FirebaseAuthService authService;

  const HabitacionesPage({
    super.key,
    required this.onSeleccionar,
    required this.habitacionService,
    required this.authService,
  });

  void _handleReservar(BuildContext context, String tipoHabitacion) {
    if (!authService.isLoggedIn) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.lock_person, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 12),
              const Text('Inicia sesión'),
            ],
          ),
          content: const Text(
            'Para realizar una reserva necesitas iniciar sesión primero.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await authService.signInWithGoogle();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text('¡Bienvenido ${authService.currentUser!.name}!'),
                        ],
                      ),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  onSeleccionar(tipoHabitacion);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700),
              child: const Text('Iniciar con Google',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      onSeleccionar(tipoHabitacion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitaciones = habitacionService.habitacionesActivas;

    if (habitaciones.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade100, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bed_outlined, size: 100, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text(
                'No hay habitaciones disponibles',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              Text(
                'Vuelve pronto para ver nuestras opciones',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.shade100, Colors.white],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: habitaciones.length,
        itemBuilder: (context, index) {
          final habitacion = habitaciones[index];
          return _HabitacionCard(
            habitacion: habitacion,
            onReservar: () => _handleReservar(context, habitacion.nombre),
          );
        },
      ),
    );
  }
}

class _HabitacionCard extends StatefulWidget {
  final Habitacion habitacion;
  final VoidCallback onReservar;

  const _HabitacionCard({required this.habitacion, required this.onReservar});

  @override
  State<_HabitacionCard> createState() => _HabitacionCardState();
}

class _HabitacionCardState extends State<_HabitacionCard> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Uint8List? _base64ToImage(String base64String) {
    try {
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(cleanBase64);
    } catch (e) {
      print('❌ Error al convertir base64: $e');
      return null;
    }
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('data:image')) {
      try {
        final bytes = _base64ToImage(imagePath);
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Error renderizando: $error');
              return _buildImageError();
            },
          );
        }
      } catch (e) {
        print('❌ Error: $e');
      }
      return _buildImageError();
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildImageError(),
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _buildImageError(),
    );
  }

  Widget _buildImageError() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.green.shade800, Colors.green.shade600]),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 100, color: Colors.white24),
            SizedBox(height: 16),
            Text('Error al cargar imagen',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildImageCarousel(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getIconForHabitacion(widget.habitacion.nombre),
                          color: Colors.green.shade700, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.habitacion.nombre,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.habitacion.categoria,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.attach_money,
                          color: Colors.green.shade700, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '\$${widget.habitacion.precioBase.toStringAsFixed(0)} COP',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800),
                      ),
                      Text(' / noche',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.people,
                          color: Colors.green.shade700, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Capacidad: ${widget.habitacion.capacidad} ${widget.habitacion.capacidad == 1 ? "persona" : "personas"}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.habitacion.descripcion,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Comodidades incluidas:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.habitacion.comodidades
                        .map(
                          (comodidad) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.green.shade100,
                                Colors.green.shade200
                              ]),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getComodidadIcon(comodidad),
                                    size: 16, color: Colors.green.shade800),
                                const SizedBox(width: 6),
                                Text(
                                  comodidad,
                                  style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: widget.onReservar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.calendar_today,
                          color: Colors.white, size: 22),
                      label: const Text(
                        'Reservar ahora',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (widget.habitacion.imagenes.isEmpty) return _buildPlaceholderImage();

    return Stack(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemCount: widget.habitacion.imagenes.length,
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: _buildImageWidget(widget.habitacion.imagenes[index]),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.habitacion.imagenes.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentImageIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentImageIndex == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        if (widget.habitacion.imagenes.length > 1) ...[
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () {
                  if (_currentImageIndex > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () {
                  if (_currentImageIndex <
                      widget.habitacion.imagenes.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_right,
                      color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${_currentImageIndex + 1}/${widget.habitacion.imagenes.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade300, Colors.green.shade600],
        ),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Center(
        child: Icon(Icons.image_not_supported,
            size: 80, color: Colors.white.withOpacity(0.5)),
      ),
    );
  }

  IconData _getIconForHabitacion(String nombre) {
    if (nombre.toLowerCase().contains('matrimonial')) return Icons.king_bed;
    if (nombre.toLowerCase().contains('dos pisos')) return Icons.bungalow;
    if (nombre.toLowerCase().contains('camping')) return Icons.park;
    return Icons.bed;
  }

  IconData _getComodidadIcon(String comodidad) {
    final c = comodidad.toLowerCase();
    if (c.contains('wifi')) return Icons.wifi;
    if (c.contains('tv')) return Icons.tv;
    if (c.contains('baño')) return Icons.bathroom;
    if (c.contains('desayuno')) return Icons.restaurant;
    if (c.contains('terraza') || c.contains('vista')) return Icons.balcony;
    if (c.contains('fogata')) return Icons.local_fire_department;
    if (c.contains('hamaca')) return Icons.deck;
    if (c.contains('comedor')) return Icons.dining;
    return Icons.check_circle;
  }
}
