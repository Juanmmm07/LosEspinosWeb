import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:html' as html;

import '../services/firebase_auth_service.dart';
import '../services/comentario_service.dart';
import '../services/image_compression_service.dart';
import '../models/comentario.dart';

class AgregarComentarioPage extends StatefulWidget {
  final FirebaseAuthService authService;
  final ComentarioService comentarioService;

  const AgregarComentarioPage({
    super.key,
    required this.authService,
    required this.comentarioService,
  });

  @override
  State<AgregarComentarioPage> createState() => _AgregarComentarioPageState();
}

class _AgregarComentarioPageState extends State<AgregarComentarioPage> {
  final _formKey = GlobalKey<FormState>();
  final _textoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  double _calificacion = 5.0;
  bool _isLoading = false;

  final List<String> _imagenesBase64 = [];
  final List<Uint8List> _imagenesPreview = [];

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  /// Selecciona imágenes para WEB con compresión automática
  Future<void> _seleccionarImagenWeb() async {
    if (_imagenesBase64.length >= 4) {
      _mostrarMensaje('Máximo 4 fotos permitidas', Colors.orange);
      return;
    }

    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.multiple = true;
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      setState(() => _isLoading = true);

      int agregadas = 0;
      int errores = 0;

      for (var file in files) {
        if (_imagenesBase64.length >= 4) break;

        try {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoad.first;

          final bytes = reader.result as Uint8List;

          // ✅ COMPRIMIR AUTOMÁTICAMENTE
          final base64String = await ImageCompressionService.comprimirYConvertirABase64(
            bytes,
            maxKB: 250,
          );

          final uint8List = ImageCompressionService.base64ToUint8List(base64String);

          setState(() {
            _imagenesBase64.add(base64String);
            _imagenesPreview.add(uint8List);
          });

          agregadas++;
        } catch (e) {
          print('❌ Error procesando imagen: $e');
          errores++;
        }
      }

      setState(() => _isLoading = false);

      if (agregadas > 0) {
        final tamanoPromedio = _imagenesBase64.isEmpty
            ? 0
            : ImageCompressionService.getTamanoBase64KB(_imagenesBase64.last);

        _mostrarMensaje(
          '✅ $agregadas ${agregadas == 1 ? "foto agregada" : "fotos agregadas"} '
          '(~${tamanoPromedio.toStringAsFixed(0)}KB c/u)',
          Colors.green,
        );
      }

      if (errores > 0) {
        _mostrarMensaje(
          '❌ $errores ${errores == 1 ? "imagen falló" : "imágenes fallaron"}',
          Colors.red,
        );
      }
    });
  }

  /// Selecciona una sola imagen para MOBILE
  Future<void> _seleccionarImagen(ImageSource source) async {
    if (_imagenesBase64.length >= 4) {
      _mostrarMensaje('Máximo 4 fotos permitidas', Colors.orange);
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final bytes = await image.readAsBytes();

      // ✅ COMPRIMIR AUTOMÁTICAMENTE
      final base64String = await ImageCompressionService.comprimirYConvertirABase64(
        bytes,
        maxKB: 250,
      );

      final uint8List = ImageCompressionService.base64ToUint8List(base64String);

      setState(() {
        _imagenesBase64.add(base64String);
        _imagenesPreview.add(uint8List);
        _isLoading = false;
      });

      final tamano = ImageCompressionService.getTamanoBase64KB(base64String);
      _mostrarMensaje(
        '✅ Foto agregada (~${tamano.toStringAsFixed(0)}KB)',
        Colors.green,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al cargar imagen: $e', Colors.red);
    }
  }

  /// Selecciona múltiples imágenes para MOBILE
  Future<void> _seleccionarMultiplesImagenes() async {
    if (_imagenesBase64.length >= 4) {
      _mostrarMensaje('Máximo 4 fotos permitidas', Colors.orange);
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      setState(() => _isLoading = true);

      int agregadas = 0;
      int errores = 0;

      for (var image in images) {
        if (_imagenesBase64.length >= 4) break;

        try {
          final bytes = await image.readAsBytes();

          // ✅ COMPRIMIR AUTOMÁTICAMENTE
          final base64String = await ImageCompressionService.comprimirYConvertirABase64(
            bytes,
            maxKB: 250,
          );

          final uint8List = ImageCompressionService.base64ToUint8List(base64String);

          _imagenesBase64.add(base64String);
          _imagenesPreview.add(uint8List);
          agregadas++;
        } catch (e) {
          print('❌ Error procesando imagen: $e');
          errores++;
        }
      }

      setState(() => _isLoading = false);

      if (agregadas > 0) {
        _mostrarMensaje(
          '✅ $agregadas ${agregadas == 1 ? "foto agregada" : "fotos agregadas"}',
          Colors.green,
        );
      }

      if (errores > 0) {
        _mostrarMensaje(
          '❌ $errores ${errores == 1 ? "imagen falló" : "imágenes fallaron"}',
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al cargar imágenes: $e', Colors.red);
    }
  }

  void _eliminarImagen(int index) {
    setState(() {
      _imagenesBase64.removeAt(index);
      _imagenesPreview.removeAt(index);
    });
    _mostrarMensaje('Foto eliminada', Colors.grey);
  }

  void _mostrarOpcionesImagen() {
    if (kIsWeb) {
      _seleccionarImagenWeb();
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.photo_camera, color: Colors.blue.shade700),
                  ),
                  title: const Text('Tomar foto',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Usa la cámara del dispositivo'),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarImagen(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.photo_library, color: Colors.purple.shade700),
                  ),
                  title: const Text('Seleccionar de galería',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Elige fotos guardadas'),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarImagen(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.photo_library_outlined, color: Colors.green.shade700),
                  ),
                  title: const Text('Seleccionar múltiples',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Hasta ${4 - _imagenesBase64.length} fotos'),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarMultiplesImagenes();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _enviarComentario() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar tamaño total
    if (!ImageCompressionService.validarConjunto(_imagenesBase64, maxTotalMB: 0.9)) {
      _mostrarMensaje(
        '⚠️ Las imágenes ocupan demasiado espacio. Elimina algunas.',
        Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final user = widget.authService.currentUser!;
    final nuevoComentario = Comentario(
      id: 'com${DateTime.now().millisecondsSinceEpoch}',
      odId: user.id,
      userName: user.name,
      texto: _textoController.text.trim(),
      calificacion: _calificacion,
      fecha: DateTime.now(),
      aprobado: false,
      avatarUrl: user.photoURL,
      imagenes: List.from(_imagenesBase64),
    );

    widget.comentarioService.agregarComentario(nuevoComentario);

    setState(() => _isLoading = false);

    if (mounted) {
      final tamanoTotal = ImageCompressionService.getTamanoTotalMB(_imagenesBase64);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Comentario enviado con ${_imagenesBase64.length} fotos '
                  '(${tamanoTotal.toStringAsFixed(2)}MB total)',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Dejar un Comentario'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rate_review,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tu opinión importa',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Comparte tu experiencia con otros viajeros',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star,
                              color: Colors.amber.shade600, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Calificación',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              _calificacion.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < _calificacion
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber.shade600,
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Slider(
                              value: _calificacion,
                              min: 1,
                              max: 5,
                              divisions: 4,
                              activeColor: Colors.green.shade700,
                              inactiveColor: Colors.green.shade200,
                              label: _calificacion.toStringAsFixed(1),
                              onChanged: (value) =>
                                  setState(() => _calificacion = value),
                            ),
                            Text(
                              _getCalificacionTexto(_calificacion),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note,
                              color: Colors.green.shade700, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Tu comentario',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _textoController,
                        decoration: InputDecoration(
                          hintText: 'Cuéntanos sobre tu experiencia...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.green.shade50,
                        ),
                        maxLines: 6,
                        maxLength: 500,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor escribe un comentario';
                          }
                          if (value.trim().length < 10) {
                            return 'El comentario debe tener al menos 10 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_photo_alternate,
                              color: Colors.purple.shade700, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Agregar Fotos',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_imagenesBase64.length}/4',
                              style: TextStyle(
                                color: Colors.purple.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '✅ Fotos comprimidas automáticamente (~250KB c/u)',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blue.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _imagenesBase64.length < 4 && !_isLoading
                                  ? _mostrarOpcionesImagen
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            disabledBackgroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_a_photo,
                                  color: Colors.white, size: 24),
                          label: Text(
                            _isLoading
                                ? 'Comprimiendo...'
                                : _imagenesBase64.isEmpty
                                    ? 'Seleccionar Fotos'
                                    : 'Agregar Más Fotos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (_imagenesPreview.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Fotos seleccionadas:',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${ImageCompressionService.getTamanoTotalMB(_imagenesBase64).toStringAsFixed(2)}MB total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              _imagenesPreview.asMap().entries.map((entry) {
                            final index = entry.key;
                            final imageData = entry.value;
                            final tamano =
                                ImageCompressionService.getTamanoBase64KB(
                                    _imagenesBase64[index]);

                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      imageData,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey.shade400,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () => _eliminarImagen(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade600,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${tamano.toStringAsFixed(0)}KB',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _enviarComentario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 22),
                  label: Text(
                    _isLoading ? 'Enviando...' : 'Enviar Comentario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getCalificacionTexto(double cal) {
    if (cal >= 4.5) return '¡Excelente!';
    if (cal >= 3.5) return 'Muy bueno';
    if (cal >= 2.5) return 'Bueno';
    if (cal >= 1.5) return 'Regular';
    return 'Necesita mejorar';
  }
}