class Reserva {
  final String id;
  final String odId;
  final String nombre;
  final String tipoDocumento;
  final String numeroDocumento;
  final String telefono;
  final int personas;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String tipoHabitacion;
  final double precioTotal;
  final DateTime fechaCreacion;
  String estado;

  Reserva({
    required this.id,
    required this.odId,
    required this.nombre,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.telefono,
    required this.personas,
    required this.fechaInicio,
    required this.fechaFin,
    required this.tipoHabitacion,
    required this.precioTotal,
    DateTime? fechaCreacion,
    this.estado = 'activa',
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  int get noches => fechaFin.difference(fechaInicio).inDays;

  Map<String, dynamic> toJson() => {
    'id': id,
    'odId': odId,
    'nombre': nombre,
    'tipoDocumento': tipoDocumento,
    'numeroDocumento': numeroDocumento,
    'telefono': telefono,
    'personas': personas,
    'fechaInicio': fechaInicio.toIso8601String(),
    'fechaFin': fechaFin.toIso8601String(),
    'tipoHabitacion': tipoHabitacion,
    'precioTotal': precioTotal,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'estado': estado,
  };

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
    id: json['id'],
    odId: json['odId'],
    nombre: json['nombre'],
    tipoDocumento: json['tipoDocumento'] ?? 'CC',
    numeroDocumento: json['numeroDocumento'] ?? '',
    telefono: json['telefono'] ?? '',
    personas: json['personas'],
    fechaInicio: DateTime.parse(json['fechaInicio']),
    fechaFin: DateTime.parse(json['fechaFin']),
    tipoHabitacion: json['tipoHabitacion'],
    precioTotal: json['precioTotal'],
    fechaCreacion: DateTime.parse(json['fechaCreacion']),
    estado: json['estado'] ?? 'activa',
  );

  Reserva copyWith({
    String? id,
    String? odId,
    String? nombre,
    String? tipoDocumento,
    String? numeroDocumento,
    String? telefono,
    int? personas,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? tipoHabitacion,
    double? precioTotal,
    DateTime? fechaCreacion,
    String? estado,
  }) {
    return Reserva(
      id: id ?? this.id,
      odId: odId ?? this.odId,
      nombre: nombre ?? this.nombre,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      telefono: telefono ?? this.telefono,
      personas: personas ?? this.personas,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      tipoHabitacion: tipoHabitacion ?? this.tipoHabitacion,
      precioTotal: precioTotal ?? this.precioTotal,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      estado: estado ?? this.estado,
    );
  }
}