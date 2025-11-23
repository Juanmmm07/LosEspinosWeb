import 'package:flutter/material.dart';

import '../services/landing_service.dart';

import '../services/firebase_auth_service.dart';

import '../services/image_compression_service.dart';



/// PÃ¡gina de administraciÃ³n para gestionar los slides del carrusel

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

        title: const Text('GestiÃ³n Landing Page'),

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



  /// Construye la tarjeta de cada slide con preview y controles

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

              // Encabezado con nÃºmero de slide y handle de arrastre

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

                        Text(slide['title']!, 

                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),

                      ]

                    )

                  ),

                  Icon(Icons.drag_handle, color: Colors.grey.shade400),

                ],

              ),

              const Divider(height: 24),

              // Preview del slide

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

                          Text(slide['title']!, 

                            style: const TextStyle(

                              fontSize: 20, 

                              fontWeight: FontWeight.bold, 

                              color: Colors.white

                            )),

                          const SizedBox(height: 4),

                          Text(slide['subtitle']!, 

                            style: const TextStyle(fontSize: 14, color: Colors.white70)),

                        ]

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 16),

              // InformaciÃ³n de la ruta de imagen

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

                    Text(slide['image']!, style: const TextStyle(fontSize: 12)),

                  ]

                ),

              ),

              const SizedBox(height: 16),

              // Botones de acciÃ³n

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

                      // Solo permite eliminar si hay mÃ¡s de un slide

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



  /// Construye el estado vacÃ­o cuando no hay slides

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



  /// Muestra el diÃ¡logo para agregar un nuevo slide

  void _agregarSlide() {
  final titleCtrl = TextEditingController();
  final subtitleCtrl = TextEditingController();
  String? imagenBase64;
  Uint8List? imagenPreview;
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
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
              child: const Icon(Icons.add_photo_alternate, 
                color: Colors.white, 
                size: 24)
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

              // Sección para subir imagen
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

                    // Preview de imagen seleccionada
                    if (imagenPreview != null) ...[
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade300, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(imagenPreview, fit: BoxFit.cover),
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
                        setDialogState(() => isLoading = true);

                        try {
                          Uint8List? bytes;

                          if (kIsWeb) {
                            // WEB: Usar input de archivo
                            final uploadInput = html.FileUploadInputElement();
                            uploadInput.accept = 'image/*';
                            uploadInput.click();

                            await uploadInput.onChange.first;
                            
                            final file = uploadInput.files?.first;
                            if (file != null) {
                              final reader = html.FileReader();
                              reader.readAsArrayBuffer(file);
                              await reader.onLoad.first;
                              bytes = reader.result as Uint8List;
                            }
                          } else {
                            // MOBILE: Usar image_picker
                            final ImagePicker picker = ImagePicker();
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
                            // ✅ COMPRIMIR IMAGEN
                            imagenBase64 = await ImageCompressionService.comprimirYConvertirABase64(
                              bytes,
                              maxKB: 300, // 300KB para slides del landing
                            );

                            imagenPreview = ImageCompressionService.base64ToUint8List(imagenBase64!);
                          }

                          setDialogState(() => isLoading = false);
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
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
                ScaffoldMessenger.of(context).showSnackBar(
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
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Slide agregado (${ImageCompressionService.getTamanoBase64KB(imagenBase64!).toStringAsFixed(0)}KB)'),
                  backgroundColor: Colors.green.shade700
                )
              );
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

// ==================== MÉTODO 2: EDITAR SLIDE ====================
void _editarSlide(int index, Map<String, String> slide) {
  final titleCtrl = TextEditingController(text: slide['title']);
  final subtitleCtrl = TextEditingController(text: slide['subtitle']);
  String? imagenBase64 = slide['image']; // Imagen actual
  Uint8List? imagenPreview;
  bool isLoading = false;

  // Si la imagen actual es base64, generar preview
  if (imagenBase64 != null && imagenBase64.startsWith('data:image')) {
    try {
      imagenPreview = ImageCompressionService.base64ToUint8List(imagenBase64);
    } catch (e) {
      print('Error generando preview: $e');
    }
  }

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
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

              // Sección para cambiar imagen
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

                    // Preview de imagen
                    if (imagenPreview != null) ...[
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade300, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(imagenPreview, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (imagenBase64 != null && imagenBase64.startsWith('data:image'))
                        Text(
                          '✅ ${ImageCompressionService.getTamanoBase64KB(imagenBase64).toStringAsFixed(0)}KB',
                          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      const SizedBox(height: 8),
                    ] else if (imagenBase64 != null) ...[
                      // Mostrar que es una imagen de asset
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
                        setDialogState(() => isLoading = true);

                        try {
                          Uint8List? bytes;

                          if (kIsWeb) {
                            final uploadInput = html.FileUploadInputElement();
                            uploadInput.accept = 'image/*';
                            uploadInput.click();

                            await uploadInput.onChange.first;
                            
                            final file = uploadInput.files?.first;
                            if (file != null) {
                              final reader = html.FileReader();
                              reader.readAsArrayBuffer(file);
                              await reader.onLoad.first;
                              bytes = reader.result as Uint8List;
                            }
                          } else {
                            final ImagePicker picker = ImagePicker();
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
                            // ✅ COMPRIMIR IMAGEN
                            imagenBase64 = await ImageCompressionService.comprimirYConvertirABase64(
                              bytes,
                              maxKB: 300,
                            );

                            imagenPreview = ImageCompressionService.base64ToUint8List(imagenBase64!);
                          }

                          setDialogState(() => isLoading = false);
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
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
            onPressed: (isLoading || imagenBase64 == null) ? null : () {
              if (titleCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El título es obligatorio'),
                    backgroundColor: Colors.orange
                  )
                );
                return;
              }
              
              widget.landingService.actualizarSlide(index, {
                'image': imagenBase64!,
                'title': titleCtrl.text,
                'subtitle': subtitleCtrl.text
              });
              
              Navigator.pop(ctx);
              setState(() {});
              
              final tamano = imagenBase64!.startsWith('data:image')
                  ? ImageCompressionService.getTamanoBase64KB(imagenBase64!)
                  : 0;
              
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



  /// Muestra el diÃ¡logo para editar un slide existente

  void _editarSlide(int index, Map<String, String> slide) {

    final titleCtrl = TextEditingController(text: slide['title']);

    final subtitleCtrl = TextEditingController(text: slide['subtitle']);

    final imageCtrl = TextEditingController(text: slide['image']);

    

    showDialog(

      context: context,

      builder: (ctx) => AlertDialog(

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

                  labelText: 'TÃ­tulo',

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

                  labelText: 'SubtÃ­tulo',

                  prefixIcon: Icon(Icons.subtitles, color: Colors.blue.shade700),

                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                  filled: true,

                  fillColor: Colors.blue.shade50

                )

              ),

              const SizedBox(height: 16),

              TextField(

                controller: imageCtrl,

                decoration: InputDecoration(

                  labelText: 'Ruta de la imagen',

                  prefixIcon: Icon(Icons.image, color: Colors.blue.shade700),

                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                  filled: true,

                  fillColor: Colors.blue.shade50

                ),

                maxLines: 2

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

            onPressed: () {

              if (titleCtrl.text.isEmpty || imageCtrl.text.isEmpty) {

                ScaffoldMessenger.of(context).showSnackBar(

                  const SnackBar(

                    content: Text('Completa tÃ­tulo e imagen'),

                    backgroundColor: Colors.orange

                  )

                );

                return;

              }

              

              widget.landingService.actualizarSlide(index, {

                'image': imageCtrl.text,

                'title': titleCtrl.text,

                'subtitle': subtitleCtrl.text

              });

              

              Navigator.pop(ctx);

              setState(() {});

              

              ScaffoldMessenger.of(context).showSnackBar(

                SnackBar(

                  content: const Text('Slide actualizado'),

                  backgroundColor: Colors.green.shade700

                )

              );

            },

            style: ElevatedButton.styleFrom(

              backgroundColor: Colors.blue.shade700,

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))

            ),

            child: const Text('Guardar', style: TextStyle(color: Colors.white)),

          ),

        ],

      ),

    );

  }



  /// Muestra confirmaciÃ³n antes de eliminar un slide

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

        content: const Text('Â¿EstÃ¡s seguro de eliminar este slide?'),

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

              

              ScaffoldMessenger.of(context).showSnackBar(

                SnackBar(

                  content: const Text('Slide eliminado'),

                  backgroundColor: Colors.red.shade700

                )

              );

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

}