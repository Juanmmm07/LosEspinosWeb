class Habitacion {
  final String id;
  final String nombre;
  final String descripcion;
  final double precioBase;
  final int capacidad;
  final List<String> imagenes;
  final bool activa;
  final List<String> comodidades;
  final String categoria;

  Habitacion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioBase,
    required this.capacidad,
    required this.imagenes,
    required this.activa,
    required this.comodidades,
    required this.categoria,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'precioBase': precioBase,
    'capacidad': capacidad,
    'imagenes': imagenes,
    'activa': activa,
    'comodidades': comodidades,
    'categoria': categoria,
  };

  factory Habitacion.fromJson(Map<String, dynamic> json) => Habitacion(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    precioBase: json['precioBase'],
    capacidad: json['capacidad'],
    imagenes: List<String>.from(json['imagenes']),
    activa: json['activa'],
    comodidades: List<String>.from(json['comodidades']),
    categoria: json['categoria'],
  );

  Habitacion copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    double? precioBase,
    int? capacidad,
    List<String>? imagenes,
    bool? activa,
    List<String>? comodidades,
    String? categoria,
  }) {
    return Habitacion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioBase: precioBase ?? this.precioBase,
      capacidad: capacidad ?? this.capacidad,
      imagenes: imagenes ?? this.imagenes,
      activa: activa ?? this.activa,
      comodidades: comodidades ?? this.comodidades,
      categoria: categoria ?? this.categoria,
    );
  }
}