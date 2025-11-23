import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../services/comentario_service.dart';
import '../models/comentario.dart';

/// Página de administración para gestionar los comentarios de los clientes.
/// Permite aprobar, rechazar o eliminar comentarios, además de visualizar
/// las imágenes adjuntas por los usuarios.
class AdminComentariosPage extends StatefulWidget {
  final ComentarioService comentarioService;

  const AdminComentariosPage({super.key, required this.comentarioService});

  @override
  State<AdminComentariosPage> createState() => _AdminComentariosPageState();
}

class _AdminComentariosPageState extends State<AdminComentariosPage> {
  String _filtro = 'pendientes';

  /// Obtiene los comentarios según el filtro seleccionado
  List<Comentario> _getComentariosFiltrados() {
    switch (_filtro) {
      case 'pendientes':
        return widget.comentarioService.comentariosPendientes;
      case 'aprobados':
        return widget.comentarioService.comentariosAprobados;
      default:
        return widget.comentarioService.todosLosComentarios;
    }
  }

  /// Convierte una cadena Base64 a Uint8List para mostrar la imagen
  Uint8List? _base64ToImage(String base64String) {
    try {
      if (base64String.startsWith('data:image')) {
        final base64Data = base64String.split(',')[1];
        return base64Decode(base64Data);
      }
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final comentarios = _getComentariosFiltrados();
    
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Gestión de Comentarios'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: comentarios.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: comentarios.length,
                    itemBuilder: (context, index) => 
                        _buildComentarioCard(comentarios[index]),
                  ),
          ),
        ],
      ),
    );
  }

  /// Construye los filtros de estado de comentarios
  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFiltroChip(
              'Pendientes',
              'pendientes',
              widget.comentarioService.comentariosPendientes.length
            )
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFiltroChip(
              'Aprobados',
              'aprobados',
              widget.comentarioService.comentariosAprobados.length
            )
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFiltroChip(
              'Todos',
              'todos',
              widget.comentarioService.todosLosComentarios.length
            )
          ),
        ],
      ),
    );
  }

  /// Construye un chip de filtro individual
  Widget _buildFiltroChip(String label, String valor, int count) {
    final isSelected = _filtro == valor;
    
    return GestureDetector(
      onTap: () => setState(() => _filtro = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade700 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el estado vacío cuando no hay comentarios
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle
            ),
            child: Icon(Icons.comment_bank,
              size: 80,
              color: Colors.green.shade300),
          ),
          const SizedBox(height: 20),
          Text('No hay comentarios $_filtro',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey
            )),
        ],
      ),
    );
  }

  /// Construye la tarjeta de un comentario individual
  Widget _buildComentarioCard(Comentario comentario) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: comentario.aprobado
              ? [Colors.green.shade50, Colors.white]
              : [Colors.orange.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con avatar y datos del usuario
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: comentario.aprobado
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: comentario.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              comentario.avatarUrl!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: comentario.aprobado
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                                size: 24,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: comentario.aprobado
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comentario.userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          )),
                        Text(
                          '${comentario.fecha.day}/${comentario.fecha.month}/${comentario.fecha.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6
                    ),
                    decoration: BoxDecoration(
                      color: comentario.aprobado
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      comentario.aprobado ? 'APROBADO' : 'PENDIENTE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: comentario.aprobado
                          ? Colors.green.shade900
                          : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Calificación con estrellas
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < comentario.calificacion
                      ? Icons.star
                      : Icons.star_border,
                    color: Colors.amber.shade600,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Texto del comentario
              Text(comentario.texto,
                style: const TextStyle(fontSize: 14, height: 1.5)),

              // Mostrar imágenes si existen
              if (comentario.imagenes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.image,
                      color: Colors.purple.shade700,
                      size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${comentario.imagenes.length} ${comentario.imagenes.length == 1 ? "foto adjunta" : "fotos adjuntas"}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade800
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Carrusel de imágenes
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: comentario.imagenes.length,
                    itemBuilder: (context, index) {
                      final imageBytes = _base64ToImage(
                        comentario.imagenes[index]
                      );

                      return GestureDetector(
                        onTap: () => _mostrarImagenCompleta(
                          context,
                          comentario.imagenes,
                          index
                        ),
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.purple.shade200,
                              width: 2
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imageBytes != null
                                ? Image.memory(
                                    imageBytes,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.broken_image,
                                        color: Colors.grey.shade400,
                                        size: 40),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.broken_image,
                                      color: Colors.grey.shade400,
                                      size: 40),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Botones de acción según estado del comentario
              if (!comentario.aprobado) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _aprobarComentario(comentario),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                          ),
                        ),
                        icon: const Icon(Icons.check,
                          color: Colors.white,
                          size: 20),
                        label: const Text('Aprobar',
                          style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rechazarComentario(comentario),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                          ),
                        ),
                        icon: const Icon(Icons.close,
                          color: Colors.white,
                          size: 20),
                        label: const Text('Rechazar',
                          style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _eliminarComentario(comentario),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                      ),
                    ),
                    icon: const Icon(Icons.delete,
                      color: Colors.white,
                      size: 20),
                    label: const Text('Eliminar',
                      style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra las imágenes en pantalla completa con navegación
  void _mostrarImagenCompleta(
    BuildContext context,
    List<String> imagenes,
    int initialIndex
  ) {
    final PageController pageController = PageController(
      initialPage: initialIndex
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            // Carrusel de imágenes
            PageView.builder(
              controller: pageController,
              itemCount: imagenes.length,
              itemBuilder: (context, index) {
                final imageBytes = _base64ToImage(imagenes[index]);

                return InteractiveViewer(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade800,
                                child: const Icon(Icons.broken_image,
                                  color: Colors.white,
                                  size: 80),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.broken_image,
                                color: Colors.white,
                                size: 80),
                            ),
                    ),
                  ),
                );
              },
            ),
            // Botón de cerrar
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                    color: Colors.white,
                    size: 24),
                ),
              ),
            ),
            // Botones de navegación si hay múltiples imágenes
            if (imagenes.length > 1) ...[
              Positioned(
                top: 0,
                left: 10,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left,
                        color: Colors.white,
                        size: 32),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 10,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right,
                        color: Colors.white,
                        size: 32),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Aprueba un comentario para que sea visible públicamente
  void _aprobarComentario(Comentario comentario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Aprobar Comentario')
          ]
        ),
        content: const Text('¿Aprobar este comentario para publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar')
          ),
          ElevatedButton(
            onPressed: () {
              widget.comentarioService.aprobarComentario(comentario.id);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Comentario aprobado'),
                  backgroundColor: Colors.green.shade700,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            child: const Text('Aprobar',
              style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Rechaza y elimina un comentario
  void _rechazarComentario(Comentario comentario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Rechazar Comentario')
          ]
        ),
        content: const Text('¿Rechazar y eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar')
          ),
          ElevatedButton(
            onPressed: () {
              widget.comentarioService.rechazarComentario(comentario.id);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Comentario rechazado'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            child: const Text('Rechazar',
              style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Elimina un comentario aprobado
  void _eliminarComentario(Comentario comentario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 12),
            Text('Eliminar Comentario')
          ]
        ),
        content: const Text('¿Eliminar permanentemente este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar')
          ),
          ElevatedButton(
            onPressed: () {
              widget.comentarioService.eliminarComentario(comentario.id);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Comentario eliminado'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            child: const Text('Eliminar',
              style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}