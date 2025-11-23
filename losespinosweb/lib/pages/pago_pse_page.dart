import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reserva.dart';
import '../services/pago_service.dart';
import '../services/firebase_auth_service.dart';
import 'pago_procesando_page.dart';

/// Página para realizar pagos mediante PSE (Pagos Seguros en Línea).
/// Solicita información bancaria y de identificación del usuario
/// para procesar el pago de una reserva.
class PagoPSEPage extends StatefulWidget {
  final Reserva reserva;
  final PagoService pagoService;
  final FirebaseAuthService authService;

  const PagoPSEPage({
    super.key,
    required this.reserva,
    required this.pagoService,
    required this.authService,
  });

  @override
  State<PagoPSEPage> createState() => _PagoPSEPageState();
}

class _PagoPSEPageState extends State<PagoPSEPage> {
  final _formKey = GlobalKey<FormState>();
  String? _bancoSeleccionado;
  String _tipoDocumento = 'CC';
  final _numeroDocumentoController = TextEditingController();
  bool _isProcessing = false;
  bool _aceptoTerminos = false;

  @override
  void initState() {
    super.initState();
    // Pre-llenar datos desde la reserva
    _tipoDocumento = widget.reserva.tipoDocumento;
    _numeroDocumentoController.text = widget.reserva.numeroDocumento;
  }

  @override
  void dispose() {
    _numeroDocumentoController.dispose();
    super.dispose();
  }

  /// Procesa el pago creando una transacción PSE
  Future<void> _procesarPago() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_aceptoTerminos) {
      _mostrarError('Debes aceptar los términos y condiciones');
      return;
    }
    
    if (_bancoSeleccionado == null) {
      _mostrarError('Por favor selecciona tu banco');
      return;
    }
    
    setState(() => _isProcessing = true);
    
    try {
      final resultado = await widget.pagoService.crearTransaccionPSE(
        reservaId: widget.reserva.id,
        odId: widget.authService.currentUser!.id,
        monto: widget.reserva.precioTotal,
        banco: _bancoSeleccionado!,
        tipoDocumento: _tipoDocumento,
        numeroDocumento: _numeroDocumentoController.text.trim(),
      );
      
      if (resultado['success'] && mounted) {
        // Navegar a pantalla de procesamiento
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PagoProcesandoPage(
              pagoId: resultado['pagoId'],
              referencia: resultado['referencia'],
              monto: widget.reserva.precioTotal,
              pagoService: widget.pagoService,
            ),
          )
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _mostrarError('Error al procesar el pago. Intenta nuevamente.');
    }
  }

  /// Muestra un mensaje de error al usuario
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje))
          ]
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Pago PSE'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0
      ),
      body: _isProcessing 
        ? _buildProcessingView() 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildLogoCard(),
                  const SizedBox(height: 16),
                  _buildResumenCard(),
                  const SizedBox(height: 16),
                  _buildFormularioCard(),
                  const SizedBox(height: 16),
                  _buildTerminosCard(),
                  const SizedBox(height: 24),
                  _buildBotonPagar(),
                ],
              ),
            ),
          ),
    );
  }

  /// Muestra indicador de carga mientras se procesa
  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 24),
          Text('Conectando con tu banco...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500
            )),
        ],
      ),
    );
  }

  /// Construye la tarjeta con el logo de PSE
  Widget _buildLogoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green.shade50]
          )
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 2
                )
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance,
                    size: 40,
                    color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PSE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2
                        )),
                      Text('Pagos Seguros en Línea',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600
                        )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security,
                  color: Colors.green.shade700,
                  size: 16),
                const SizedBox(width: 6),
                Text('Transacción 100% segura',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600
                  )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el resumen del pago
  Widget _buildResumenCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long,
                  color: Colors.green.shade700,
                  size: 24),
                const SizedBox(width: 8),
                const Text('Resumen del Pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                  ))
              ]
            ),
            const Divider(height: 24),
            _buildInfoRow('Reserva', widget.reserva.id),
            const SizedBox(height: 8),
            _buildInfoRow('Habitación', widget.reserva.tipoHabitacion),
            const SizedBox(height: 8),
            _buildInfoRow('Noches', '${widget.reserva.noches}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL A PAGAR:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  )),
                Text('\$${widget.reserva.precioTotal.toStringAsFixed(0)} COP',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700
                  )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el formulario de datos de pago
  Widget _buildFormularioCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                  color: Colors.green.shade700,
                  size: 24),
                const SizedBox(width: 8),
                const Text('Datos de Pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                  ))
              ]
            ),
            const SizedBox(height: 20),
            // Selector de banco
            DropdownButtonFormField<String>(
              value: _bancoSeleccionado,
              decoration: InputDecoration(
                labelText: 'Selecciona tu banco',
                prefixIcon: Icon(Icons.account_balance,
                  color: Colors.green.shade700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
                filled: true,
                fillColor: Colors.green.shade50
              ),
              items: PagoService.bancosPSE
                .map((banco) => DropdownMenuItem(
                  value: banco,
                  child: Text(banco)
                ))
                .toList(),
              onChanged: (value) => setState(() => _bancoSeleccionado = value),
              validator: (value) => 
                value == null ? 'Selecciona tu banco' : null,
            ),
            const SizedBox(height: 16),
            // Tipo de documento
            DropdownButtonFormField<String>(
              value: _tipoDocumento,
              decoration: InputDecoration(
                labelText: 'Tipo de documento',
                prefixIcon: Icon(Icons.badge,
                  color: Colors.green.shade700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
                filled: true,
                fillColor: Colors.green.shade50
              ),
              items: const [
                DropdownMenuItem(
                  value: 'CC',
                  child: Text('Cédula de Ciudadanía')
                ),
                DropdownMenuItem(
                  value: 'CE',
                  child: Text('Cédula de Extranjería')
                ),
                DropdownMenuItem(
                  value: 'Pasaporte',
                  child: Text('Pasaporte')
                ),
              ],
              onChanged: (value) => setState(() => _tipoDocumento = value!),
            ),
            const SizedBox(height: 16),
            // Número de documento
            TextFormField(
              controller: _numeroDocumentoController,
              decoration: InputDecoration(
                labelText: 'Número de documento',
                prefixIcon: Icon(Icons.fingerprint,
                  color: Colors.green.shade700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
                filled: true,
                fillColor: Colors.green.shade50
              ),
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]'))
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu número de documento';
                }
                if (value.length < 6) {
                  return 'Documento inválido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la sección de términos y condiciones
  Widget _buildTerminosCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: _aceptoTerminos,
              activeColor: Colors.green.shade700,
              onChanged: (value) => 
                setState(() => _aceptoTerminos = value ?? false),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => 
                  setState(() => _aceptoTerminos = !_aceptoTerminos),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800
                    ),
                    children: [
                      const TextSpan(text: 'Acepto los '),
                      TextSpan(
                        text: 'términos y condiciones',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline
                        )
                      ),
                      const TextSpan(text: ' del servicio PSE'),
                    ]
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el botón de pagar
  Widget _buildBotonPagar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _procesarPago,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)
          ),
          elevation: 6
        ),
        icon: const Icon(Icons.lock, color: Colors.white, size: 22),
        label: const Text('Pagar con PSE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold
          )),
      ),
    );
  }

  /// Construye una fila de información
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600
          )),
        Text(value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600
          )),
      ],
    );
  }
}