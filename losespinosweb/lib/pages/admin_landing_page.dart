import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../services/landing_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/image_compression_service.dart';

// Importación condicional para web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html
    show FileUploadInputElement, FileReader;

/// Página de administración para gestionar los slides del carrusel
/// de la landing page. Permite crear, editar, reordenar y eliminar slides.
class AdminLandingPage extends StatefulWidget {
  final LandingService landingService;
  final FirebaseAuthService authService;

  const AdminLandingPage({super.key, required this.landingService, required this.authService});

  @override
  State<AdminLandingPage> createState() => _AdminLandingPageState();
}

class _AdminLandingPageState extends State<AdminLandingPage> {
  @override
  Widget build(BuildContext context) {
    final slides = widget.landingService.slides;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión Landing Page'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, size: 28),
            onPressed: _agregarSlide
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade100, Colors.white]
          )
        ),
        child: slides.isEmpty 
          ? _buildEmptyState() 
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: slides.length,
              onReorder: (oldIndex, newIndex) {
                widget.landingService.reordenarSlides(oldIndex, newIndex);
                setState(() {});
              },
              itemBuilder: (context, index) => _buildSlideCard(slides[index], index),
            ),
      ),
    );
  }

  Widget _buildSlideCard(Map<String, String> slide, int index) {
    return Card(
      key: ValueKey(slide['image']),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white]
          ),
          borderRadius: BorderRadius.circular(20)
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade700]
                      ),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: const Icon(Icons.image, color: Colors.white, size: 24)
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Slide ${index + 1}', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(slide['title'] ?? '', 
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ]
                    )
                  ),
                  Icon(Icons.drag_handle, color: Colors.grey.shade400),
                ],
              ),
              const Divider(height: 24),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.green.shade800, Colors.green.shade400]
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.landscape, 
                        size: 60, 
                        color: Colors.white.withOpacity(0.3))
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.7)]
                        )
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slide['title'] ?? '', 
                            style: const TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.white
                            )),
                          const SizedBox(height: 4),
                          Text(slide['subtitle'] ?? '', 
                            style: const TextStyle(fontSize: 14, color: Colors.white70)),
                        ]
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image, color: Colors.blue.shade700, size: 16),
                        const SizedBox(width: 8),
                        const Text('Imagen:', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ]
                    ),
                    const SizedBox(height: 4),
                    Text(slide['image'] ?? '', style: const TextStyle(fontSize: 12)),
                  ]
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _editarSlide(index, slide),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                        )
                      ),
                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                      label: const Text('Editar', 
                        style: TextStyle(color: Colors.white)),
                    )
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.landingService.slides.length > 1 
                        ? () => _confirmarEliminar(index) 
                        : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                        )
                      ),
                      icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                      label: const Text('Eliminar', 
                        style: TextStyle(color: Colors.white)),
                    )
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            child: Icon(Icons.photo_library, 
              size: 80, 
              color: Colors.green.shade300)
          ),
          const SizedBox(height: 20),
          const Text('No hay slides', 
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: Colors.grey
            )),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _agregarSlide,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Agregar Slide', 
              style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            )
          ),
        ]
      )
    );
  }


void _confirmarEliminar(int index) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 12),
          Text('Eliminar Slide')
        ]
      ),
      content: const Text('¿Estás seguro de eliminar este slide?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar')
        ),
        ElevatedButton(
          onPressed: () {
            widget.landingService.eliminarSlide(index);
            Navigator.pop(ctx);
            setState(() {});
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Slide eliminado'),
                  backgroundColor: Colors.red.shade700
                )
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}


void _agregarSlide() {
  final titleCtrl = TextEditingController();
  final subtitleCtrl = TextEditingController();
  String? imagenBase64;
  Uint8List? imagenPreview;
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700]
                ),
                borderRadius: BorderRadius.circular(10)
              ),
              child: const Icon(Icons.add_photo_alternate, color: Colors.white, size: 24)
            ),
            const SizedBox(width: 12),
            const Text('Agregar Slide')
          ]
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.title, color: Colors.green.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.green.shade50
                )
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subtitleCtrl,
                decoration: InputDecoration(
                  labelText: 'Subtítulo',
                  prefixIcon: Icon(Icons.subtitles, color: Colors.green.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.green.shade50
                )
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.image, size: 48, color: Colors.purple.shade700),
                    const SizedBox(height: 8),
                    const Text('Imagen del Slide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Compresión automática a ~300KB', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const SizedBox(height: 12),
                    if (imagenPreview != null) ...[
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade300, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(imagenPreview!, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '✅ ${ImageCompressionService.getTamanoBase64KB(imagenBase64!).toStringAsFixed(0)}KB',
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : () async {
                        setDialogState(() {
                          isLoading = true;
                        });

                        try {
                          Uint8List? bytes;

                          if (kIsWeb) {
                            final uploadInput = html.FileUploadInputElement();
                            uploadInput.accept = 'image/*';
                            uploadInput.click();

                            await uploadInput.onChange.first;
                            
                            final files = uploadInput.files;
                            if (files != null && files.isNotEmpty) {
                              final file = files.first;
                              final reader = html.FileReader();
                              reader.readAsArrayBuffer(file);
                              await reader.onLoad.first;
                              bytes = reader.result as Uint8List?;
                            }
                          } else {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1920,
                              maxHeight: 1080,
                            );
                            
                            if (image != null) {
                              bytes = await image.readAsBytes();
                            }
                          }

                          if (bytes != null) {
                            final base64String = await ImageCompressionService.comprimirYConvertirABase64(
                              bytes,
                              maxKB: 300,
                            );

                            final preview = ImageCompressionService.base64ToUint8List(base64String);
                            
                            setDialogState(() {
                              imagenBase64 = base64String;
                              imagenPreview = preview;
                              isLoading = false;
                            });
                          } else {
                            setDialogState(() {
                              isLoading = false;
                            });
                          }
                        } catch (e) {
                          setDialogState(() {
                            isLoading = false;
                          });
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.upload_file, color: Colors.white),
                      label: Text(
                        isLoading ? 'Comprimiendo...' : (imagenPreview == null ? 'Seleccionar Imagen' : 'Cambiar Imagen'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar')
          ),
          ElevatedButton(
            onPressed: (isLoading || imagenBase64 == null) ? null : () {
              if (titleCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('El título es obligatorio'),
                    backgroundColor: Colors.orange
                  )
                );
                return;
              }
              
              widget.landingService.agregarSlide({
                'image': imagenBase64!,
                'title': titleCtrl.text,
                'subtitle': subtitleCtrl.text
              });
              
              Navigator.pop(ctx);
              setState(() {});
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Slide agregado (${ImageCompressionService.getTamanoBase64KB(imagenBase64!).toStringAsFixed(0)}KB)'),
                    backgroundColor: Colors.green.shade700
                  )
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}


void _editarSlide(int index, Map<String, String> slide) {
  final titleCtrl = TextEditingController(text: slide['title']);
  final subtitleCtrl = TextEditingController(text: slide['subtitle']);
  String imagenBase64 = slide['image'] ?? '';
  Uint8List? imagenPreview;
  bool isLoading = false;

  if (imagenBase64.isNotEmpty && imagenBase64.startsWith('data:image')) {
    try {
      imagenPreview = ImageCompressionService.base64ToUint8List(imagenBase64);
    } catch (e) {
      print('Error generando preview: $e');
    }
  }

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700]
                ),
                borderRadius: BorderRadius.circular(10)
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 24)
            ),
            const SizedBox(width: 12),
            const Text('Editar Slide')
          ]
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.title, color: Colors.blue.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.blue.shade50
                )
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subtitleCtrl,
                decoration: InputDecoration(
                  labelText: 'Subtítulo',
                  prefixIcon: Icon(Icons.subtitles, color: Colors.blue.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.blue.shade50
                )
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.image, size: 48, color: Colors.purple.shade700),
                    const SizedBox(height: 8),
                    const Text('Imagen del Slide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Compresión automática a ~300KB', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const SizedBox(height: 12),
                    if (imagenPreview != null) ...[
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade300, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(imagenPreview!, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (imagenBase64.startsWith('data:image'))
                        Text(
                          '✅ ${ImageCompressionService.getTamanoBase64KB(imagenBase64).toStringAsFixed(0)}KB',
                          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      const SizedBox(height: 8),
                    ] else if (imagenBase64.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Imagen actual: Asset local\n$imagenBase64',
                                style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : () async {
                        setDialogState(() {
                          isLoading = true;
                        });

                        try {
                          Uint8List? bytes;

                          if (kIsWeb) {
                            final uploadInput = html.FileUploadInputElement();
                            uploadInput.accept = 'image/*';
                            uploadInput.click();

                            await uploadInput.onChange.first;
                            
                            final files = uploadInput.files;
                            if (files != null && files.isNotEmpty) {
                              final file = files.first;
                              final reader = html.FileReader();
                              reader.readAsArrayBuffer(file);
                              await reader.onLoad.first;
                              bytes = reader.result as Uint8List?;
                            }
                          } else {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1920,
                              maxHeight: 1080,
                            );
                            
                            if (image != null) {
                              bytes = await image.readAsBytes();
                            }
                          }

                          if (bytes != null) {
                            final base64String = await ImageCompressionService.comprimirYConvertirABase64(
                              bytes,
                              maxKB: 300,
                            );

                            final preview = ImageCompressionService.base64ToUint8List(base64String);
                            
                            setDialogState(() {
                              imagenBase64 = base64String;
                              imagenPreview = preview;
                              isLoading = false;
                            });
                          } else {
                            setDialogState(() {
                              isLoading = false;
                            });
                          }
                        } catch (e) {
                          setDialogState(() {
                            isLoading = false;
                          });
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.upload_file, color: Colors.white),
                      label: Text(
                        isLoading ? 'Comprimiendo...' : 'Cambiar Imagen',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar')
          ),
          ElevatedButton(
            onPressed: (isLoading || imagenBase64.isEmpty) ? null : () {
              if (titleCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('El título es obligatorio'),
                    backgroundColor: Colors.orange
                  )
                );
                return;
              }
              
              widget.landingService.actualizarSlide(index, {
                'image': imagenBase64,
                'title': titleCtrl.text,
                'subtitle': subtitleCtrl.text
              });
              
              Navigator.pop(ctx);
              setState(() {});
              
              final tamano = imagenBase64.startsWith('data:image')
                  ? ImageCompressionService.getTamanoBase64KB(imagenBase64)
                  : 0.0;
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      tamano > 0 
                          ? '✅ Slide actualizado (${tamano.toStringAsFixed(0)}KB)'
                          : '✅ Slide actualizado'
                    ),
                    backgroundColor: Colors.green.shade700
                  )
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
}