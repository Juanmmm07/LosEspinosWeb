import 'package:flutter/material.dart';

class Pago {
  final String id;
  final String reservaId;
  final String odId;
  final double monto;
  final String metodoPago;
  final String estado;
  final DateTime fecha;
  final String? banco;
  final String? referencia;
  final String? tipoDocumento;
  final String? numeroDocumento;

  Pago({
    required this.id,
    required this.reservaId,
    required this.odId,
    required this.monto,
    required this.metodoPago,
    required this.estado,
    required this.fecha,
    this.banco,
    this.referencia,
    this.tipoDocumento,
    this.numeroDocumento,
  });

  Pago copyWith({
    String? id,
    String? reservaId,
    String? odId,
    double? monto,
    String? metodoPago,
    String? estado,
    DateTime? fecha,
    String? banco,
    String? referencia,
    String? tipoDocumento,
    String? numeroDocumento,
  }) {
    return Pago(
      id: id ?? this.id,
      reservaId: reservaId ?? this.reservaId,
      odId: odId ?? this.odId,
      monto: monto ?? this.monto,
      metodoPago: metodoPago ?? this.metodoPago,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      banco: banco ?? this.banco,
      referencia: referencia ?? this.referencia,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reservaId': reservaId,
    'odId': odId,
    'monto': monto,
    'metodoPago': metodoPago,
    'estado': estado,
    'fecha': fecha.toIso8601String(),
    'banco': banco,
    'referencia': referencia,
    'tipoDocumento': tipoDocumento,
    'numeroDocumento': numeroDocumento,
  };

  factory Pago.fromJson(Map<String, dynamic> json) => Pago(
    id: json['id'],
    reservaId: json['reservaId'],
    odId: json['odId'],
    monto: json['monto'],
    metodoPago: json['metodoPago'],
    estado: json['estado'],
    fecha: DateTime.parse(json['fecha']),
    banco: json['banco'],
    referencia: json['referencia'],
    tipoDocumento: json['tipoDocumento'],
    numeroDocumento: json['numeroDocumento'],
  );
}

class PagoService extends ChangeNotifier {
  final List<Pago> _pagos = [];

  List<Pago> get todosLosPagos => List.from(_pagos);
  
  List<Pago> get pagosAprobados => 
      _pagos.where((p) => p.estado == 'aprobado').toList();
  
  List<Pago> get pagosPendientes => 
      _pagos.where((p) => p.estado == 'pendiente' || p.estado == 'procesando').toList();

  // Lista de bancos PSE Colombia
  static const List<String> bancosPSE = [
    'Bancolombia',
    'Banco de Bogota',
    'Davivienda',
    'BBVA Colombia',
    'Banco de Occidente',
    'Banco Popular',
    'Banco Caja Social',
    'Banco AV Villas',
    'Scotiabank Colpatria',
    'Banco GNB Sudameris',
    'Banco Pichincha',
    'Banco Falabella',
    'Bancoomeva',
    'Banco Agrario',
    'Banco Santander',
  ];

  Future<Map<String, dynamic>> crearTransaccionPSE({
    required String reservaId,
    required String odId,
    required double monto,
    required String banco,
    required String tipoDocumento,
    required String numeroDocumento,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final pagoId = 'PAG${DateTime.now().millisecondsSinceEpoch}';
    final referencia = 'REF${DateTime.now().millisecondsSinceEpoch}';

    final pago = Pago(
      id: pagoId,
      reservaId: reservaId,
      odId: odId,
      monto: monto,
      metodoPago: 'PSE',
      estado: 'procesando',
      fecha: DateTime.now(),
      banco: banco,
      referencia: referencia,
      tipoDocumento: tipoDocumento,
      numeroDocumento: numeroDocumento,
    );

    _pagos.add(pago);
    notifyListeners();

    return {
      'success': true,
      'pagoId': pagoId,
      'referencia': referencia,
      'urlBanco': 'https://pse-simulacion.com/pago/$pagoId',
    };
  }

  Future<bool> simularRespuestaPSE(String pagoId, bool aprobar) async {
    await Future.delayed(const Duration(seconds: 2));

    final index = _pagos.indexWhere((p) => p.id == pagoId);
    if (index == -1) return false;

    _pagos[index] = _pagos[index].copyWith(
      estado: aprobar ? 'aprobado' : 'rechazado',
    );

    notifyListeners();
    return true;
  }

  Pago? getPagoById(String id) {
    try {
      return _pagos.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Pago> getPagosPorUsuario(String odId) {
    return _pagos
        .where((p) => p.odId == odId)
        .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  List<Pago> getPagosPorReserva(String reservaId) {
    return _pagos.where((p) => p.reservaId == reservaId).toList();
  }

  bool reservaTienePagoAprobado(String reservaId) {
    return _pagos.any((p) => 
      p.reservaId == reservaId && p.estado == 'aprobado'
    );
  }

  double get totalRecaudado {
    return pagosAprobados.fold(0.0, (sum, p) => sum + p.monto);
  }

  int get totalTransacciones => _pagos.length;
  int get transaccionesAprobadas => pagosAprobados.length;
  int get transaccionesPendientes => pagosPendientes.length;
}