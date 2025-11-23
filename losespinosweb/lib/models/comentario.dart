class Comentario {
  final String id;
  final String odId;
  final String userName;
  final String texto;
  final double calificacion;
  final DateTime fecha;
  final bool aprobado;
  final String? avatarUrl;
  final List<String> imagenes;

  Comentario({
    required this.id,
    required this.odId,
    required this.userName,
    required this.texto,
    required this.calificacion,
    required this.fecha,
    this.aprobado = false,
    this.avatarUrl,
    this.imagenes = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'odId': odId,
    'userName': userName,
    'texto': texto,
    'calificacion': calificacion,
    'fecha': fecha.toIso8601String(),
    'aprobado': aprobado,
    'avatarUrl': avatarUrl,
    'imagenes': imagenes,
  };

  factory Comentario.fromJson(Map<String, dynamic> json) => Comentario(
    id: json['id'],
    odId: json['odId'],
    userName: json['userName'],
    texto: json['texto'],
    calificacion: json['calificacion'],
    fecha: DateTime.parse(json['fecha']),
    aprobado: json['aprobado'] ?? false,
    avatarUrl: json['avatarUrl'],
    imagenes: json['imagenes'] != null 
        ? List<String>.from(json['imagenes']) 
        : [],
  );

  Comentario copyWith({
    String? id,
    String? odId,
    String? userName,
    String? texto,
    double? calificacion,
    DateTime? fecha,
    bool? aprobado,
    String? avatarUrl,
    List<String>? imagenes,
  }) {
    return Comentario(
      id: id ?? this.id,
      odId: odId ?? this.odId,
      userName: userName ?? this.userName,
      texto: texto ?? this.texto,
      calificacion: calificacion ?? this.calificacion,
      fecha: fecha ?? this.fecha,
      aprobado: aprobado ?? this.aprobado,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      imagenes: imagenes ?? this.imagenes,
    );
  }
}