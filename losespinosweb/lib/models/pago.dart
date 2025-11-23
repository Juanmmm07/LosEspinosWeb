import 'package:flutter/material.dart';
import '../services/pago_service.dart';
import 'dart:async';

class PagoProcesandoPage extends StatefulWidget {
  final String pagoId;
  final String referencia;
  final double monto;
  final PagoService pagoService;

  const PagoProcesandoPage({
    super.key,
    required this.pagoId,
    required this.referencia,
    required this.monto,
    required this.pagoService,
  });

  @override
  State<PagoProcesandoPage> createState() => _PagoProcesandoPageState();
}

class _PagoProcesandoPageState extends State<PagoProcesandoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String _estadoActual = 'procesando';
  Timer? _simulacionTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Simular respuesta del banco después de 5 segundos
    _simularRespuestaBanco();
  }

  void _simularRespuestaBanco() {
    _simulacionTimer = Timer(const Duration(seconds: 5), () async {
      // Simular aprobación (80% de probabilidad de aprobación)
      final aprobar = DateTime.now().second % 5 != 0;

      final resultado = await widget.pagoService.simularRespuestaPSE(
        widget.pagoId,
        aprobar,
      );

      if (resultado && mounted) {
        setState(() {
          _estadoActual = aprobar ? 'aprobado' : 'rechazado';
        });
        _animController.stop();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _simulacionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_estadoActual == 'procesando') {
          return await _mostrarDialogoSalir();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: _getBackgroundColor(),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIconoEstado(),
                  const SizedBox(height: 32),
                  _buildTituloEstado(),
                  const SizedBox(height: 16),
                  _buildDescripcionEstado(),
                  const SizedBox(height: 32),
                  _buildInfoPago(),
                  const SizedBox(height: 32),
                  if (_estadoActual != 'procesando') _buildBotonAccion(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_estadoActual) {
      case 'aprobado':
        return Colors.green.shade50;
      case 'rechazado':
        return Colors.red.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Widget _buildIconoEstado() {
    switch (_estadoActual) {
      case 'aprobado':
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green.shade700,
          ),
        );
      case 'rechazado':
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.cancel,
            size: 100,
            color: Colors.red.shade700,
          ),
        );
      default:
        return RotationTransition(
          turns: _animController,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.sync,
              size: 100,
              color: Colors.blue.shade700,
            ),
          ),
        );
    }
  }

  Widget _buildTituloEstado() {
    String titulo;
    Color color;

    switch (_estadoActual) {
      case 'aprobado':
        titulo = '¡Pago Exitoso!';
        color = Colors.green.shade700;
        break;
      case 'rechazado':
        titulo = 'Pago Rechazado';
        color = Colors.red.shade700;
        break;
      default:
        titulo = 'Procesando Pago';
        color = Colors.blue.shade700;
    }

    return Text(
      titulo,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescripcionEstado() {
    String descripcion;

    switch (_estadoActual) {
      case 'aprobado':
        descripcion =
            'Tu pago ha sido procesado correctamente. Tu reserva está confirmada.';
        break;
      case 'rechazado':
        descripcion =
            'El pago no pudo ser procesado. Por favor intenta nuevamente o usa otro método de pago.';
        break;
      default:
        descripcion =
            'Estamos procesando tu pago con tu banco. Por favor espera un momento...';
    }

    return Text(
      descripcion,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey.shade700,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInfoPago() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildInfoRow('Referencia', widget.referencia),
            const Divider(height: 24),
            _buildInfoRow('Monto', '\$${widget.monto.toStringAsFixed(0)} COP'),
            if (_estadoActual == 'aprobado') ...[
              const Divider(height: 24),
              _buildInfoRow('Estado', 'APROBADO'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBotonAccion() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _estadoActual == 'aprobado'
              ? Colors.green.shade700
              : Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        icon: Icon(
          _estadoActual == 'aprobado' ? Icons.home : Icons.refresh,
          color: Colors.white,
        ),
        label: Text(
          _estadoActual == 'aprobado' ? 'Volver al Inicio' : 'Intentar Nuevamente',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<bool> _mostrarDialogoSalir() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Pago en proceso'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres salir? El pago se está procesando.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Esperar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Salir',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return resultado ?? false;
  }
}