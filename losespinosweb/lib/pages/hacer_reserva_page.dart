import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reserva.dart';
import '../models/habitacion.dart';
import '../services/firebase_auth_service.dart';
import '../services/habitacion_service.dart';
import '../services/pago_service.dart';
import 'pago_pse_page.dart';

/// Página para crear una nueva reserva.
/// Permite al usuario ingresar sus datos, seleccionar fechas y número de personas.
/// Calcula automáticamente el precio total y maneja la lógica de disponibilidad.
class HacerReservaPage extends StatefulWidget {
  final String tipoHabitacion;
  final List<Reserva> reservasExistentes;
  final Function(Reserva) onReservaCreada;
  final FirebaseAuthService authService;
  final HabitacionService habitacionService;
  final PagoService pagoService;

  const HacerReservaPage({
    super.key,
    required this.tipoHabitacion,
    required this.reservasExistentes,
    required this.onReservaCreada,
    required this.authService,
    required this.habitacionService,
    required this.pagoService,
  });

  @override
  State<HacerReservaPage> createState() => _HacerReservaPageState();
}

class _HacerReservaPageState extends State<HacerReservaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _documentoCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  
  String _tipoDocumento = 'CC';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  int _personas = 1;
  double _precio = 0;
  Habitacion? _habitacionSeleccionada;

  @override
  void initState() {
    super.initState();
    // Pre-llenar el nombre si el usuario está autenticado
    if (widget.authService.isLoggedIn) {
      _nombreCtrl.text = widget.authService.currentUser!.name;
    }
    
    // Obtener la habitación seleccionada
    _habitacionSeleccionada = widget.habitacionService
        .getHabitacionByNombre(widget.tipoHabitacion);
    
    // Validar que la habitación esté disponible
    if (_habitacionSeleccionada == null || !_habitacionSeleccionada!.activa) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarError('Esta habitación no está disponible actualmente.');
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _documentoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  /// Muestra el selector de fecha para inicio o fin de estancia
  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
          // Si la fecha de fin es anterior a la de inicio, resetearla
          if (_fechaFin != null && _fechaFin!.isBefore(fecha)) {
            _fechaFin = null;
          }
        } else {
          _fechaFin = fecha;
        }
        _calcularPrecio();
      });
    }
  }

  /// Calcula el precio total según el tipo de habitación, noches y personas
  void _calcularPrecio() {
    if (_fechaInicio == null || _fechaFin == null || _habitacionSeleccionada == null) {
      return;
    }
    
    final noches = _fechaFin!.difference(_fechaInicio!).inDays;
    if (noches <= 0) return;
    
    final precioBase = _habitacionSeleccionada!.precioBase;
    
    // Para camping, el precio se multiplica por persona
    if (_habitacionSeleccionada!.nombre.toLowerCase().contains('camping') ||
        _habitacionSeleccionada!.categoria.toLowerCase().contains('camping')) {
      _precio = precioBase * noches * _personas;
    } else {
      // Para habitaciones normales, el precio es por noche independiente de personas
      _precio = precioBase * noches;
    }
    
    setState(() {});
  }

  /// Crea la reserva después de validar todos los datos
  void _crearReserva() {
    // Validar que la habitación siga activa
    if (_habitacionSeleccionada == null || !_habitacionSeleccionada!.activa) {
      _mostrarError('Esta habitación no está disponible.');
      return;
    }
    
    // Validar formulario
    if (!_formKey.currentState!.validate()) return;
    
    // Validar fechas
    if (_fechaInicio == null || _fechaFin == null) {
      _mostrarError('Selecciona ambas fechas.');
      return;
    }
    
    if (_fechaFin!.isBefore(_fechaInicio!) || 
        _fechaFin!.isAtSameMomentAs(_fechaInicio!)) {
      _mostrarError('La fecha de salida debe ser posterior a la de llegada.');
      return;
    }
    
    // Verificar conflictos con reservas existentes
    final conflicto = widget.reservasExistentes.any((r) =>
        r.estado == 'activa' &&
        r.tipoHabitacion == widget.tipoHabitacion &&
        (_fechaInicio!.isBefore(r.fechaFin) && 
         _fechaFin!.isAfter(r.fechaInicio)));
    
    if (conflicto) {
      _mostrarError('Ya existe una reserva activa para estas fechas.');
      return;
    }
    
    // Calcular precio final
    _calcularPrecio();
    if (_precio <= 0) {
      _mostrarError('Las fechas seleccionadas no son válidas.');
      return;
    }

    // Crear objeto de reserva
    final nuevaReserva = Reserva(
      id: 'RES${DateTime.now().millisecondsSinceEpoch}',
      odId: widget.authService.currentUser!.id,
      nombre: _nombreCtrl.text,
      tipoDocumento: _tipoDocumento,
      numeroDocumento: _documentoCtrl.text,
      telefono: _telefonoCtrl.text,
      personas: _personas,
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin!,
      tipoHabitacion: widget.tipoHabitacion,
      precioTotal: _precio,
      estado: 'activa',
    );

    // Mostrar diálogo de confirmación con opción de pagar
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('¡Reserva Creada!')
          ]
        ),
        content: const Text(
          '¿Deseas proceder al pago con PSE ahora?',
          style: TextStyle(fontSize: 15)
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onReservaCreada(nuevaReserva);
              Navigator.pop(context);
            },
            child: const Text('Más tarde'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PagoPSEPage(
                    reserva: nuevaReserva,
                    pagoService: widget.pagoService,
                    authService: widget.authService
                  ),
                )
              ).then((_) {
                widget.onReservaCreada(nuevaReserva);
                Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700
            ),
            icon: const Icon(Icons.payment, color: Colors.white),
            label: const Text('Pagar Ahora',
              style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Muestra un mensaje de error al usuario
  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg))
          ]
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar error si la habitación no está disponible
    if (_habitacionSeleccionada == null || !_habitacionSeleccionada!.activa) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade100, Colors.white]
          )
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                      size: 80,
                      color: Colors.red.shade400),
                    const SizedBox(height: 20),
                    const Text('Habitación no disponible',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                      )),
                    const SizedBox(height: 12),
                    const Text(
                      'Esta habitación no está disponible en este momento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16)
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final habitacion = _habitacionSeleccionada!;
    final esCamping = habitacion.nombre.toLowerCase().contains('camping') ||
                      habitacion.categoria.toLowerCase().contains('camping');
    final maxPersonas = habitacion.capacidad;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.shade100, Colors.white]
        )
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Tarjeta de información de la habitación
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.white]
                    )
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.bed,
                        size: 60,
                        color: Colors.green.shade700),
                      const SizedBox(height: 12),
                      Text(habitacion.nombre,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800
                        ),
                        textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: BorderRadius.circular(15)
                        ),
                        child: Text(habitacion.categoria,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900
                          )),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.attach_money,
                            color: Colors.green.shade700,
                            size: 20),
                          Text(
                            '${habitacion.precioBase.toStringAsFixed(0)} COP',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800
                            )
                          ),
                          Text(
                            esCamping ? ' / persona / noche' : ' / noche',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Formulario de datos del huésped
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person,
                            color: Colors.green.shade700,
                            size: 24),
                          const SizedBox(width: 8),
                          Text('Información del huésped',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800
                            ))
                        ]
                      ),
                      const SizedBox(height: 16),
                      // Campo de nombre
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline,
                            color: Colors.green.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)
                          ),
                          filled: true,
                          fillColor: Colors.green.shade50
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa tu nombre';
                          }
                          if (v.trim().length < 3) {
                            return 'El nombre debe tener al menos 3 caracteres';
                          }
                          if (RegExp(r'[0-9]').hasMatch(v)) {
                            return 'El nombre no puede contener números';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Selector de tipo de documento
                      DropdownButtonFormField<String>(
                        value: _tipoDocumento,
                        decoration: InputDecoration(
                          labelText: 'Tipo de documento',
                          prefixIcon: Icon(Icons.badge_outlined,
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
                            child: Text('Cédula de Ciudadanía (CC)')
                          ),
                          DropdownMenuItem(
                            value: 'CE',
                            child: Text('Cédula de Extranjería (CE)')
                          ),
                          DropdownMenuItem(
                            value: 'Pasaporte',
                            child: Text('Pasaporte')
                          ),
                        ],
                        onChanged: (v) => setState(() => _tipoDocumento = v!),
                      ),
                      const SizedBox(height: 16),
                      // Campo de número de documento
                      TextFormField(
                        controller: _documentoCtrl,
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
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9a-zA-Z]')
                          )
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa tu número de documento';
                          }
                          if (v.trim().length < 6) {
                            return 'El documento debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Campo de teléfono
                      TextFormField(
                        controller: _telefonoCtrl,
                        decoration: InputDecoration(
                          labelText: 'Número de teléfono',
                          prefixIcon: Icon(Icons.phone,
                            color: Colors.green.shade700),
                          prefixText: '+57 ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)
                          ),
                          filled: true,
                          fillColor: Colors.green.shade50
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10)
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa tu número de teléfono';
                          }
                          if (v.length < 10) {
                            return 'El teléfono debe tener 10 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Selector de número de huéspedes
                      DropdownButtonFormField<int>(
                        value: _personas,
                        decoration: InputDecoration(
                          labelText: 'Número de huéspedes',
                          prefixIcon: Icon(Icons.people,
                            color: Colors.green.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)
                          ),
                          filled: true,
                          fillColor: Colors.green.shade50
                        ),
                        items: List.generate(maxPersonas, (i) => i + 1)
                          .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('$e ${e == 1 ? 'huésped' : 'huéspedes'}')
                          ))
                          .toList(),
                        onChanged: (v) {
                          setState(() {
                            _personas = v ?? 1;
                            _calcularPrecio();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Sección de fechas
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month,
                            color: Colors.green.shade700,
                            size: 24),
                          const SizedBox(width: 8),
                          Text('Fechas de estancia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800
                            ))
                        ]
                      ),
                      const SizedBox(height: 16),
                      // Botón de fecha de llegada
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _seleccionarFecha(true),
                          icon: const Icon(Icons.calendar_today,
                            color: Colors.white),
                          label: Text(
                            _fechaInicio == null
                              ? 'Seleccionar llegada'
                              : 'Llegada: ${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15
                            )
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                            )
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Botón de fecha de salida
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _seleccionarFecha(false),
                          icon: const Icon(Icons.event, color: Colors.white),
                          label: Text(
                            _fechaFin == null
                              ? 'Seleccionar salida'
                              : 'Salida: ${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15
                            )
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                            )
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Resumen de la reserva (solo si hay fechas válidas)
              if (_fechaInicio != null && 
                  _fechaFin != null && 
                  _precio > 0) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade600,
                          Colors.green.shade800
                        ]
                      )
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long,
                          color: Colors.white,
                          size: 40),
                        const SizedBox(height: 8),
                        const Text('Resumen de la Reserva',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16
                          )),
                        const Divider(color: Colors.white24, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Noches:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16
                              )),
                            Text(
                              '${_fechaFin!.difference(_fechaInicio!).inDays}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold
                              )
                            ),
                          ]
                        ),
                        if (esCamping) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Huéspedes:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16
                                )),
                              Text('$_personas',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold
                                )),
                            ]
                          ),
                        ],
                        const Divider(color: Colors.white24, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold
                              )),
                            Text('\$${_precio.toStringAsFixed(0)} COP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24
                              )),
                          ]
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              // Botón de confirmar reserva
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _crearReserva,
                  icon: const Icon(Icons.check_circle,
                    color: Colors.white,
                    size: 24),
                  label: const Text('Confirmar Reserva',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                    )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)
                    ),
                    elevation: 8
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
}