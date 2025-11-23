import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/landing_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/image_compression_service.dart';

import 'dart:html' as html show FileUploadInputElement, FileReader;

class AdminLandingPage extends StatefulWidget {
  final LandingService landingService;
  final FirebaseAuthService authService;

  const AdminLandingPage({
    super.key,
    required this.landingService,
    required this.authService,
  });

  @override
  State<AdminLandingPage> createState() => _AdminLandingPageState();
}

class _AdminLandingPageState extends State<AdminLandingPage> {
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    widget.landingService.addListener(_onLandingChanged);
  }

  @override
  void dispose() {
    widget.landingService.removeListener(_onLandingChanged);
    super.dispose();
  }

  void _onLandingChanged() {
    if (!_isUpdating && mounted) {
      setState(() {});
    }
  }

  Uint8List? _base64ToImage(String base64String) {
    try {
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }
      return base64Decode(cleanBase64);
    } catch (e) {
      print('❌ Error al convertir base64: $e');
      return null;
    }
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('data:image')) {
      final bytes = _base64ToImage(imagePath);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error renderizando imagen: $error');
            return _buildImageError();
          },
        );
      } else {
        return _buildImageError();
      }
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildImageError(),
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildImageError(),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 8),
          Text('Error al cargar',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

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
            icon: const Icon(Icons.add_circle, size: 28),
            onPressed: _agregarSlide,
            tooltip: 'Agregar nuevo slide',
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
        child: slides.isEmpty
            ? _buildEmptyState()
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: slides.length,
                onReorder: (oldIndex, newIndex) async {
                  setState(() => _isUpdating = true);
                  await widget.landingService
                      .reordenarSlides(oldIndex, newIndex);
                  await Future.delayed(const Duration(milliseconds: 500));
                  setState(() => _isUpdating = false);
                },
                itemBuilder: (context, index) =>
                    _buildSlideCard(slides[index], index),
              ),
      ),
    );
  }

  Widget _buildSlideCard(Map<String, String> slide, int index) {
    final imagePath = slide['image'] ?? '';
    final isBase64 = imagePath.startsWith('data:image');
    final tamanoKB =
        isBase64 ? ImageCompressionService.getTamanoBase64KB(imagePath) : 0.0;

    return Card(
      key: ValueKey('${slide['image']}_$index'),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [Colors.green.shade50, Colors.white]),
          borderRadius: BorderRadius.circular(20),
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
                      gradient: LinearGradient(colors: [
                        Colors.green.shade400,
                        Colors.green.shade700
                      ]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.image, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Slide ${index + 1}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(slide['title'] ?? '',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Icon(Icons.drag_handle, color: Colors.grey.shade400),
                ],
              ),
              const Divider(height: 24),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageWidget(imagePath),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8)
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slide['title'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (slide['subtitle'] != null &&
                                  slide['subtitle']!.isNotEmpty)
                                Text(
                                  slide['subtitle']!,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (isBase64)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '✅ ${tamanoKB.toStringAsFixed(0)}KB',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isBase64 ? Colors.purple.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isBase64
                          ? Colors.purple.shade200
                          : Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      isBase64 ? Icons.cloud_done : Icons.folder,
                      color: isBase64
                          ? Colors.purple.shade700
                          : Colors.blue.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBase64
                                ? 'Imagen Comprimida (Firestore)'
                                : 'Asset Local',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isBase64
                                  ? Colors.purple.shade900
                                  : Colors.blue.shade900,
                            ),
                          ),
                          if (!isBase64)
                            Text(
                              imagePath,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
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
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon:
                          const Icon(Icons.edit, color: Colors.white, size: 18),
                      label: const Text('Editar',
                          style: TextStyle(color: Colors.white)),
                    ),
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
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete,
                          color: Colors.white, size: 18),
                      label: const Text('Eliminar',
                          style: TextStyle(color: Colors.white)),
                    ),
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
                color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.photo_library,
                size: 80, color: Colors.green.shade300),
          ),
          const SizedBox(height: 20),
          const Text('No hay slides',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _agregarSlide,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Agregar Slide',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
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
            Text('Eliminar Slide'),
          ],
        ),
        content: const Text('¿Estás seguro de eliminar este slide?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isUpdating = true);
              await widget.landingService.eliminarSlide(index);
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() => _isUpdating = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Slide eliminado'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
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
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade700]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_photo_alternate,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Agregar Slide'),
            ],
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.green.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subtitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Subtítulo',
                    prefixIcon:
                        Icon(Icons.subtitles, color: Colors.green.shade700),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.green.shade50,
                  ),
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
                      Icon(Icons.image,
                          size: 48, color: Colors.purple.shade700),
                      const SizedBox(height: 8),
                      const Text('Imagen del Slide',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Compresión automática a ~300KB',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 11)),
                      const SizedBox(height: 12),
                      if (imagenPreview != null) ...[
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.purple.shade300, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child:
                                Image.memory(imagenPreview!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '✅ ${ImageCompressionService.getTamanoBase64KB(imagenBase64!).toStringAsFixed(0)}KB',
                          style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                setDialogState(() => isLoading = true);

                                try {
                                  Uint8List? bytes;

                                  if (kIsWeb) {
                                    final uploadInput =
                                        html.FileUploadInputElement();
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
                                    final base64String =
                                        await ImageCompressionService
                                            .comprimirYConvertirABase64(
                                      bytes,
                                      maxKB: 300,
                                    );

                                    final preview = ImageCompressionService
                                        .base64ToUint8List(base64String);

                                    setDialogState(() {
                                      imagenBase64 = base64String;
                                      imagenPreview = preview;
                                      isLoading = false;
                                    });
                                  } else {
                                    setDialogState(() => isLoading = false);
                                  }
                                } catch (e) {
                                  setDialogState(() => isLoading = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.upload_file,
                                color: Colors.white),
                        label: Text(
                          isLoading
                              ? 'Comprimiendo...'
                              : (imagenPreview == null
                                  ? 'Seleccionar Imagen'
                                  : 'Cambiar Imagen'),
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: (isLoading || imagenBase64 == null)
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('El título es obligatorio'),
                              backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      final nuevoSlide = {
                        'image': imagenBase64!,
                        'title': titleCtrl.text.trim(),
                        'subtitle': subtitleCtrl.text.trim(),
                      };

                      Navigator.pop(ctx);

                      setState(() => _isUpdating = true);

                      print('📄 Agregando slide...');
                      await widget.landingService.agregarSlide(nuevoSlide);
                      print('✅ Slide agregado, esperando sincronización...');

                      await Future.delayed(const Duration(milliseconds: 1500));

                      setState(() => _isUpdating = false);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ Slide agregado (${ImageCompressionService.getTamanoBase64KB(imagenBase64!).toStringAsFixed(0)}KB)',
                            ),
                            backgroundColor: Colors.green.shade700,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child:
                  const Text('Agregar', style: TextStyle(color: Colors.white)),
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
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade700]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Editar Slide'),
            ],
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subtitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Subtítulo',
                    prefixIcon:
                        Icon(Icons.subtitles, color: Colors.blue.shade700),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
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
                      Icon(Icons.image,
                          size: 48, color: Colors.purple.shade700),
                      const SizedBox(height: 8),
                      const Text('Imagen del Slide',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Compresión automática a ~300KB',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 11)),
                      const SizedBox(height: 12),
                      if (imagenPreview != null) ...[
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.purple.shade300, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child:
                                Image.memory(imagenPreview!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (imagenBase64.startsWith('data:image'))
                          Text(
                            '✅ ${ImageCompressionService.getTamanoBase64KB(imagenBase64).toStringAsFixed(0)}KB',
                            style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
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
                              Icon(Icons.info_outline,
                                  color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Imagen actual: Asset local\n$imagenBase64',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                setDialogState(() => isLoading = true);

                                try {
                                  Uint8List? bytes;

                                  if (kIsWeb) {
                                    final uploadInput =
                                        html.FileUploadInputElement();
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
                                    final base64String =
                                        await ImageCompressionService
                                            .comprimirYConvertirABase64(
                                      bytes,
                                      maxKB: 300,
                                    );

                                    final preview = ImageCompressionService
                                        .base64ToUint8List(base64String);

                                    setDialogState(() {
                                      imagenBase64 = base64String;
                                      imagenPreview = preview;
                                      isLoading = false;
                                    });
                                  } else {
                                    setDialogState(() => isLoading = false);
                                  }
                                } catch (e) {
                                  setDialogState(() => isLoading = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.upload_file,
                                color: Colors.white),
                        label: Text(
                          isLoading ? 'Comprimiendo...' : 'Cambiar Imagen',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: (isLoading || imagenBase64.isEmpty)
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('El título es obligatorio'),
                              backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      Navigator.pop(ctx);

                      setState(() => _isUpdating = true);

                      await widget.landingService.actualizarSlide(index, {
                        'image': imagenBase64,
                        'title': titleCtrl.text.trim(),
                        'subtitle': subtitleCtrl.text.trim(),
                      });

                      await Future.delayed(const Duration(milliseconds: 1500));

                      setState(() => _isUpdating = false);

                      if (mounted) {
                        final tamano = imagenBase64.startsWith('data:image')
                            ? ImageCompressionService.getTamanoBase64KB(
                                imagenBase64)
                            : 0.0;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tamano > 0
                                  ? '✅ Slide actualizado (${tamano.toStringAsFixed(0)}KB)'
                                  : '✅ Slide actualizado',
                            ),
                            backgroundColor: Colors.green.shade700,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child:
                  const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
