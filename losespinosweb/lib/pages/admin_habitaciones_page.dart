import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import '../models/habitacion.dart';
import '../services/habitacion_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/image_compression_service.dart';

// Importación condicional para web
import 'dart:html' as html show FileUploadInputElement, FileReader;



class AdminHabitacionesPage extends StatefulWidget {

  final HabitacionService habitacionService;

  final FirebaseAuthService authService;



  const AdminHabitacionesPage({

    super.key,

    required this.habitacionService,

    required this.authService,

  });



  @override

  State<AdminHabitacionesPage> createState() => _AdminHabitacionesPageState();

}



class _AdminHabitacionesPageState extends State<AdminHabitacionesPage> {

  final TextEditingController _searchController = TextEditingController();

  String _filtroCategoria = 'todas';



  @override

  Widget build(BuildContext context) {

    final habitaciones = widget.habitacionService.todasLasHabitaciones;

    

    final categorias = [

      'todas',

      ...habitaciones.map((h) => h.categoria).toSet().toList()

    ];

    

    var habitacionesFiltradas = habitaciones.where((h) {

      final matchesSearch = _searchController.text.isEmpty ||

          h.nombre.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesCategory =

          _filtroCategoria == 'todas' || h.categoria == _filtroCategoria;

      return matchesSearch && matchesCategory;

    }).toList();



    return Scaffold(

      appBar: AppBar(

        title: const Text('GestiÃ³n de Habitaciones'),

        backgroundColor: Colors.green.shade700,

        foregroundColor: Colors.white,

        actions: [

          IconButton(

            icon: const Icon(Icons.add_circle, size: 28),

            onPressed: () => _mostrarFormularioHabitacion(),

          )

        ],

      ),

      body: Container(

        decoration: BoxDecoration(

          gradient: LinearGradient(

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

            colors: [Colors.green.shade100, Colors.white],

          ),

        ),

        child: Column(

          children: [

            _buildFiltros(categorias),

            Expanded(

              child: habitacionesFiltradas.isEmpty

                  ? _buildEmptyState()

                  : ListView.builder(

                      padding: const EdgeInsets.all(16),

                      itemCount: habitacionesFiltradas.length,

                      itemBuilder: (context, index) =>

                          _buildHabitacionCard(habitacionesFiltradas[index]),

                    ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildFiltros(List<String> categorias) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        boxShadow: [

          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)

        ],

      ),

      child: Column(

        children: [

          TextField(

            controller: _searchController,

            decoration: InputDecoration(

              labelText: 'Buscar...',

              prefixIcon: Icon(Icons.search, color: Colors.green.shade700),

              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),

              filled: true,

              fillColor: Colors.green.shade50,

              suffixIcon: _searchController.text.isNotEmpty

                  ? IconButton(

                      icon: const Icon(Icons.clear),

                      onPressed: () {

                        _searchController.clear();

                        setState(() {});

                      },

                    )

                  : null,

            ),

            onChanged: (value) => setState(() {}),

          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(

            value: _filtroCategoria,

            decoration: InputDecoration(

              labelText: 'CategorÃ­a',

              prefixIcon: Icon(Icons.category, color: Colors.green.shade700),

              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),

              filled: true,

              fillColor: Colors.green.shade50,

            ),

            items: categorias

                .map((c) => DropdownMenuItem(

                      value: c,

                      child: Text(c == 'todas' ? 'Todas las categorÃ­as' : c),

                    ))

                .toList(),

            onChanged: (value) => setState(() => _filtroCategoria = value!),

          ),

        ],

      ),

    );

  }



  Widget _buildHabitacionCard(Habitacion habitacion) {

    return Card(

      elevation: 6,

      margin: const EdgeInsets.only(bottom: 16),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      child: Container(

        decoration: BoxDecoration(

          gradient: LinearGradient(

            colors: habitacion.activa

                ? [Colors.green.shade50, Colors.white]

                : [Colors.grey.shade100, Colors.white],

          ),

          borderRadius: BorderRadius.circular(20),

        ),

        child: ExpansionTile(

          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

          leading: Container(

            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(

              gradient: LinearGradient(

                colors: habitacion.activa

                    ? [Colors.green.shade400, Colors.green.shade700]

                    : [Colors.grey.shade400, Colors.grey.shade600],

              ),

              borderRadius: BorderRadius.circular(15),

            ),

            child: const Icon(Icons.bed, color: Colors.white, size: 28),

          ),

          title: Text(

            habitacion.nombre,

            style: TextStyle(

              fontWeight: FontWeight.bold,

              color: habitacion.activa ? Colors.green.shade800 : Colors.grey.shade600,

              fontSize: 18,

            ),

          ),

          subtitle: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 6),

              Row(

                children: [

                  Icon(Icons.attach_money, size: 16, color: Colors.green.shade700),

                  const SizedBox(width: 4),

                  Text(

                    '${habitacion.precioBase.toStringAsFixed(0)} COP',

                    style: TextStyle(

                      color: habitacion.activa ? Colors.green.shade700 : Colors.grey.shade500,

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                  const SizedBox(width: 12),

                  Icon(Icons.people, size: 16, color: Colors.green.shade700),

                  const SizedBox(width: 4),

                  Text('${habitacion.capacidad} personas',

                      style: TextStyle(color: Colors.grey.shade700)),

                ],

              ),

              const SizedBox(height: 6),

              Container(

                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                decoration: BoxDecoration(

                  color: habitacion.activa ? Colors.green : Colors.red,

                  borderRadius: BorderRadius.circular(12),

                ),

                child: Text(

                  habitacion.activa ? 'âœ“ ACTIVA' : 'âœ— INACTIVA',

                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),

                ),

              ),

            ],

          ),

          children: [

            Padding(

              padding: const EdgeInsets.all(20),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Container(

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(

                      color: Colors.green.shade50,

                      borderRadius: BorderRadius.circular(12),

                      border: Border.all(color: Colors.green.shade200),

                    ),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text('ðŸ“ ${habitacion.descripcion}', style: const TextStyle(fontSize: 14)),

                        const SizedBox(height: 8),

                        Text('ðŸ·ï¸ CategorÃ­a: ${habitacion.categoria}'),

                      ],

                    ),

                  ),

                  const SizedBox(height: 16),

                  const Text('âœ¨ Comodidades:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

                  const SizedBox(height: 8),

                  Wrap(

                    spacing: 8,

                    runSpacing: 8,

                    children: habitacion.comodidades

                        .map((c) => Container(

                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                              decoration: BoxDecoration(

                                gradient: LinearGradient(colors: [Colors.green.shade100, Colors.green.shade200]),

                                borderRadius: BorderRadius.circular(20),

                              ),

                              child: Text(c,

                                  style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w500, fontSize: 13)),

                            ))

                        .toList(),

                  ),

                  const SizedBox(height: 16),

                  

                  // ========== SECCIÃ“N DE IMÃGENES MEJORADA ==========

                  Container(

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(

                      color: Colors.purple.shade50,

                      borderRadius: BorderRadius.circular(12),

                      border: Border.all(color: Colors.purple.shade200),

                    ),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Row(

                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [

                            Text(

                              'ðŸ“¸ ImÃ¡genes (${habitacion.imagenes.length})',

                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),

                            ),

                            ElevatedButton.icon(

                              onPressed: () => _gestionarImagenes(habitacion),

                              icon: const Icon(Icons.add_photo_alternate, size: 18, color: Colors.white),

                              label: const Text('Subir Fotos', style: TextStyle(color: Colors.white)),

                              style: ElevatedButton.styleFrom(

                                backgroundColor: Colors.purple.shade700,

                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                              ),

                            ),

                          ],

                        ),

                        if (habitacion.imagenes.isNotEmpty) ...[

                          const SizedBox(height: 12),

                          SizedBox(

                            height: 100,

                            child: ListView.builder(

                              scrollDirection: Axis.horizontal,

                              itemCount: habitacion.imagenes.length,

                              itemBuilder: (context, index) {

                                final img = habitacion.imagenes[index];

                                return Container(

                                  width: 100,

                                  margin: const EdgeInsets.only(right: 8),

                                  decoration: BoxDecoration(

                                    borderRadius: BorderRadius.circular(10),

                                    border: Border.all(color: Colors.purple.shade300, width: 2),

                                  ),

                                  child: ClipRRect(

                                    borderRadius: BorderRadius.circular(8),

                                    child: _buildImageWidget(img),

                                  ),

                                );

                              },

                            ),

                          ),

                        ],

                      ],

                    ),

                  ),

                  

                  const SizedBox(height: 20),

                  Row(

                    children: [

                      Expanded(

                        child: ElevatedButton.icon(

                          onPressed: () => _editarHabitacion(habitacion),

                          icon: const Icon(Icons.edit, size: 20),

                          label: const Text('Editar'),

                          style: ElevatedButton.styleFrom(

                            backgroundColor: Colors.blue.shade700,

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(vertical: 14),

                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                          ),

                        ),

                      ),

                      const SizedBox(width: 10),

                      Expanded(

                        child: ElevatedButton.icon(

                          onPressed: () => _toggleActiva(habitacion),

                          icon: Icon(habitacion.activa ? Icons.pause : Icons.play_arrow, size: 20),

                          label: Text(habitacion.activa ? 'Pausar' : 'Activar'),

                          style: ElevatedButton.styleFrom(

                            backgroundColor: habitacion.activa ? Colors.orange.shade700 : Colors.green.shade700,

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(vertical: 14),

                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                          ),

                        ),

                      ),

                    ],

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }



  /// Widget para mostrar imagen (soporta base64 y assets)

  Widget _buildImageWidget(String imagePath) {

    if (imagePath.startsWith('data:image')) {

      // Es una imagen base64

      try {

        final base64Data = imagePath.split(',')[1];

        final bytes = base64Decode(base64Data);

        return Image.memory(bytes, fit: BoxFit.cover);

      } catch (e) {

        return _buildImageError();

      }

    } else if (imagePath.startsWith('http')) {

      // Es una URL

      return Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImageError());

    } else {

      // Es un asset

      return Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImageError());

    }

  }



  Widget _buildImageError() {

    return Container(

      color: Colors.grey.shade200,

      child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 40),

    );

  }



  Widget _buildEmptyState() {

    return Center(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Container(

            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),

            child: Icon(Icons.bed, size: 80, color: Colors.green.shade300),

          ),

          const SizedBox(height: 20),

          const Text('No hay habitaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),

          const SizedBox(height: 24),

          ElevatedButton.icon(

            onPressed: _mostrarFormularioHabitacion,

            icon: const Icon(Icons.add, color: Colors.white),

            label: const Text('Agregar habitaciÃ³n', style: TextStyle(color: Colors.white)),

            style: ElevatedButton.styleFrom(

              backgroundColor: Colors.green.shade700,

              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

            ),

          ),

        ],

      ),

    );

  }



  // ========== NUEVO DIÃLOGO PARA GESTIONAR IMÃGENES CON SUBIDA ==========

void _gestionarImagenes(Habitacion habitacion) {
  List<String> imagenesActuales = List.from(habitacion.imagenes);
  bool isLoading = false;
  String? mensajeError;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.photo_library, size: 32, color: Colors.purple.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Gestionar Imágenes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Información de compresión
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✅ Imágenes comprimidas automáticamente (~200KB c/u)',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Botón para subir nuevas imágenes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload, size: 48, color: Colors.green.shade700),
                    const SizedBox(height: 8),
                    const Text('Subir Fotos Comprimidas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Almacenamiento 100% GRATIS en Firestore', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : () async {
                        setDialogState(() {
                          isLoading = true;
                          mensajeError = null;
                        });
                        
                        if (kIsWeb) {
                          // ============ WEB VERSION ============
                          final uploadInput = html.FileUploadInputElement();
                          uploadInput.accept = 'image/*';
                          uploadInput.multiple = true;
                          uploadInput.click();

                          uploadInput.onChange.listen((e) async {
                            final files = uploadInput.files;
                            if (files == null || files.isEmpty) {
                              setDialogState(() => isLoading = false);
                              return;
                            }

                            int agregadas = 0;
                            int errores = 0;

                            for (var file in files) {
                              try {
                                final reader = html.FileReader();
                                reader.readAsArrayBuffer(file);
                                await reader.onLoad.first;
                                
                                final bytes = reader.result as Uint8List;
                                
                                // ✅ COMPRIMIR IMAGEN AUTOMÁTICAMENTE
                                final base64String = await ImageCompressionService.comprimirYConvertirABase64(
                                  bytes,
                                  maxKB: 200,
                                );
                                
                                imagenesActuales.add(base64String);
                                agregadas++;
                              } catch (e) {
                                print('❌ Error procesando imagen: $e');
                                errores++;
                              }
                            }
                            
                            setDialogState(() => isLoading = false);
                            
                            if (context.mounted) {
                              final tamanoTotal = ImageCompressionService.getTamanoTotalMB(imagenesActuales);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✅ $agregadas imagen(es) agregada(s) '
                                    '${errores > 0 ? "($errores fallaron) " : ""}'
                                    '(${tamanoTotal.toStringAsFixed(2)}MB total)'
                                  ),
                                  backgroundColor: errores > 0 ? Colors.orange : Colors.green,
                                ),
                              );
                            }
                          });
                        } else {
                          // ============ MOBILE VERSION ============
                          try {
                            final ImagePicker picker = ImagePicker();
                            final List<XFile> images = await picker.pickMultiImage(
                              maxWidth: 1920,
                              maxHeight: 1080,
                              imageQuality: 85,
                            );

                            if (images.isEmpty) {
                              setDialogState(() => isLoading = false);
                              return;
                            }

                            int agregadas = 0;
                            int errores = 0;

                            for (var image in images) {
                              try {
                                final bytes = await image.readAsBytes();
                                
                                // ✅ COMPRIMIR IMAGEN AUTOMÁTICAMENTE
                                final base64String = await ImageCompressionService.comprimirYConvertirABase64(
                                  bytes,
                                  maxKB: 200,
                                );
                                
                                imagenesActuales.add(base64String);
                                agregadas++;
                              } catch (e) {
                                print('❌ Error procesando imagen: $e');
                                errores++;
                              }
                            }

                            setDialogState(() => isLoading = false);

                            if (context.mounted) {
                              final tamanoTotal = ImageCompressionService.getTamanoTotalMB(imagenesActuales);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✅ $agregadas imagen(es) agregada(s) '
                                    '${errores > 0 ? "($errores fallaron) " : ""}'
                                    '(${tamanoTotal.toStringAsFixed(2)}MB total)'
                                  ),
                                  backgroundColor: errores > 0 ? Colors.orange : Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              mensajeError = 'Error: $e';
                            });
                          }
                        }
                      },
                      icon: isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_photo_alternate, color: Colors.white),
                      label: Text(isLoading ? 'Comprimiendo...' : 'Seleccionar Fotos', style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (mensajeError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        mensajeError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Información de tamaño total
              if (imagenesActuales.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.storage, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '📦 Tamaño total: ${ImageCompressionService.getTamanoTotalMB(imagenesActuales).toStringAsFixed(2)}MB / 1MB máx por habitación',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Lista de imágenes actuales
              Expanded(
                child: imagenesActuales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No hay imágenes', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: imagenesActuales.length,
                        itemBuilder: (context, index) {
                          final img = imagenesActuales[index];
                          final tamano = ImageCompressionService.getTamanoBase64KB(img);
                          
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.purple.shade300, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: _buildImageWidget(img),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      imagenesActuales.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${tamano.toStringAsFixed(0)}KB',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade700,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: imagenesActuales.isEmpty || isLoading ? null : () {
                        if (!ImageCompressionService.validarConjunto(imagenesActuales, maxTotalMB: 1.0)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Las imágenes exceden 1MB total. Elimina algunas.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final habitacionActualizada = habitacion.copyWith(imagenes: imagenesActuales);
                        widget.habitacionService.actualizarHabitacion(habitacion.id, habitacionActualizada);
                        Navigator.pop(ctx);
                        setState(() {});
                        
                        final tamanoTotal = ImageCompressionService.getTamanoTotalMB(imagenesActuales);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ ${imagenesActuales.length} imagen(es) guardada(s) (${tamanoTotal.toStringAsFixed(2)}MB)'),
                            backgroundColor: Colors.green.shade700,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Guardar Cambios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}



  void _mostrarFormularioHabitacion({Habitacion? habitacionExistente}) {

    final nombreCtrl = TextEditingController(text: habitacionExistente?.nombre);

    final descripcionCtrl = TextEditingController(text: habitacionExistente?.descripcion);

    final precioCtrl = TextEditingController(text: habitacionExistente?.precioBase.toString() ?? '');

    final capacidadCtrl = TextEditingController(text: habitacionExistente?.capacidad.toString() ?? '');

    final categoriaCtrl = TextEditingController(text: habitacionExistente?.categoria ?? '');

    final comodidadesCtrl = TextEditingController(text: habitacionExistente?.comodidades.join(', ') ?? '');



    showDialog(

      context: context,

      builder: (ctx) => Dialog(

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        child: Container(

          constraints: const BoxConstraints(maxWidth: 500),

          child: SingleChildScrollView(

            padding: const EdgeInsets.all(24),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                Icon(Icons.bed, size: 60, color: Colors.green.shade700),

                const SizedBox(height: 16),

                Text(

                  habitacionExistente == null ? 'Nueva HabitaciÃ³n' : 'Editar HabitaciÃ³n',

                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade800),

                ),

                const SizedBox(height: 24),

                TextField(

                  controller: nombreCtrl,

                  decoration: InputDecoration(

                    labelText: 'Nombre',

                    prefixIcon: Icon(Icons.home, color: Colors.green.shade700),

                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                    filled: true,

                    fillColor: Colors.green.shade50,

                  ),

                ),

                const SizedBox(height: 16),

                TextField(

                  controller: descripcionCtrl,

                  decoration: InputDecoration(

                    labelText: 'DescripciÃ³n',

                    prefixIcon: Icon(Icons.description, color: Colors.green.shade700),

                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                    filled: true,

                    fillColor: Colors.green.shade50,

                  ),

                  maxLines: 3,

                ),

                const SizedBox(height: 16),

                Row(

                  children: [

                    Expanded(

                      child: TextField(

                        controller: precioCtrl,

                        decoration: InputDecoration(

                          labelText: 'Precio (COP)',

                          prefixIcon: Icon(Icons.attach_money, color: Colors.green.shade700),

                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                          filled: true,

                          fillColor: Colors.green.shade50,

                        ),

                        keyboardType: TextInputType.number,

                      ),

                    ),

                    const SizedBox(width: 12),

                    Expanded(

                      child: TextField(

                        controller: capacidadCtrl,

                        decoration: InputDecoration(

                          labelText: 'Capacidad',

                          prefixIcon: Icon(Icons.people, color: Colors.green.shade700),

                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                          filled: true,

                          fillColor: Colors.green.shade50,

                        ),

                        keyboardType: TextInputType.number,

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 16),

                TextField(

                  controller: categoriaCtrl,

                  decoration: InputDecoration(

                    labelText: 'CategorÃ­a',

                    prefixIcon: Icon(Icons.category, color: Colors.green.shade700),

                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                    filled: true,

                    fillColor: Colors.green.shade50,

                  ),

                ),

                const SizedBox(height: 16),

                TextField(

                  controller: comodidadesCtrl,

                  decoration: InputDecoration(

                    labelText: 'Comodidades (separadas por coma)',

                    prefixIcon: Icon(Icons.star, color: Colors.green.shade700),

                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                    filled: true,

                    fillColor: Colors.green.shade50,

                  ),

                  maxLines: 2,

                ),

                const SizedBox(height: 24),

                Row(

                  children: [

                    Expanded(

                      child: TextButton(

                        onPressed: () => Navigator.pop(ctx),

                        child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade700)),

                      ),

                    ),

                    const SizedBox(width: 12),

                    Expanded(

                      flex: 2,

                      child: ElevatedButton.icon(

                        onPressed: () {

                          if (nombreCtrl.text.isEmpty || precioCtrl.text.isEmpty) {

                            ScaffoldMessenger.of(context).showSnackBar(

                              const SnackBar(content: Text('Completa nombre y precio'), backgroundColor: Colors.orange),

                            );

                            return;

                          }



                          final comodidades = comodidadesCtrl.text.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();



                          final nuevaHabitacion = Habitacion(

                            id: habitacionExistente?.id ?? 'hab${DateTime.now().millisecondsSinceEpoch}',

                            nombre: nombreCtrl.text,

                            descripcion: descripcionCtrl.text,precioBase: double.tryParse(precioCtrl.text) ?? 0,

                        capacidad: int.tryParse(capacidadCtrl.text) ?? 1,

                        imagenes: habitacionExistente?.imagenes ?? ['assets/images/glamping_1.jpg'],

                        activa: habitacionExistente?.activa ?? true,

                        comodidades: comodidades.isNotEmpty ? comodidades : ['Wi-Fi', 'BaÃ±o'],

                        categoria: categoriaCtrl.text.isNotEmpty ? categoriaCtrl.text : 'HabitaciÃ³n',

                      );



                      if (habitacionExistente == null) {

                        widget.habitacionService.agregarHabitacion(nuevaHabitacion);

                      } else {

                        widget.habitacionService.actualizarHabitacion(habitacionExistente.id, nuevaHabitacion);

                      }



                      Navigator.pop(ctx);

                      setState(() {});

                      ScaffoldMessenger.of(context).showSnackBar(

                        SnackBar(

                          content: Text(habitacionExistente == null ? 'Â¡HabitaciÃ³n creada!' : 'Â¡HabitaciÃ³n actualizada!'),

                          backgroundColor: Colors.green.shade700,

                        ),

                      );

                    },

                    icon: const Icon(Icons.save, color: Colors.white),

                    label: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

                    style: ElevatedButton.styleFrom(

                      backgroundColor: Colors.green.shade700,

                      padding: const EdgeInsets.symmetric(vertical: 14),

                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                    ),

                  ),

                ),

              ],

            ),

          ],

        ),

      ),

    ),

  ),

);}

void _editarHabitacion(Habitacion habitacion) => _mostrarFormularioHabitacion(habitacionExistente: habitacion);

void _toggleActiva(Habitacion habitacion) {

showDialog(

context: context,

builder: (ctx) => AlertDialog(

shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

title: Row(

children: [

Icon(habitacion.activa ? Icons.pause_circle : Icons.play_circle,

color: habitacion.activa ? Colors.orange : Colors.green, size: 28),

const SizedBox(width: 12),

Text(habitacion.activa ? 'Pausar HabitaciÃ³n' : 'Activar HabitaciÃ³n'),

],

),

content: Text(habitacion.activa

? 'Â¿Deseas pausar "${habitacion.nombre}"?'

: 'Â¿Deseas activar "${habitacion.nombre}"?'),

actions: [

TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),

ElevatedButton(

onPressed: () {

widget.habitacionService.toggleActiva(habitacion.id);

Navigator.pop(ctx);

setState(() {});

ScaffoldMessenger.of(context).showSnackBar(

SnackBar(

content: Text(habitacion.activa ? 'HabitaciÃ³n pausada' : 'HabitaciÃ³n activada'),

backgroundColor: habitacion.activa ? Colors.orange : Colors.green,

),

);

},

style: ElevatedButton.styleFrom(backgroundColor: habitacion.activa ? Colors.orange : Colors.green),

child: Text(habitacion.activa ? 'Pausar' : 'Activar', style: const TextStyle(color: Colors.white)),

),

],

),

);

}

}