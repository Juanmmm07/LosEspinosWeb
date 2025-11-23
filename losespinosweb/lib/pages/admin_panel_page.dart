import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../services/firebase_auth_service.dart';

/// Panel de administración para gestionar todas las reservas del sistema.
/// Permite filtrar por estado, ordenar por diferentes criterios y cambiar
/// el estado de las reservas (activa, completada, cancelada).
class AdminPanelPage extends StatefulWidget {
  final List<Reserva> reservas;
  final FirebaseAuthService authService;

  const AdminPanelPage({
    super.key,
    required this.reservas,
    required this.authService
  });

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  String _filtroEstado = 'todas';
  String _ordenamiento = 'fecha';

  /// Obtiene las reservas filtradas y ordenadas según los criterios actuales
  List<Reserva> get _reservasFiltradas {
    var lista = widget.reservas.where((r) {
      if (_filtroEstado == 'todas') return true;
      return r.estado == _filtroEstado;
    }).toList();
    
    // Aplicar ordenamiento
    if (_ordenamiento == 'fecha') {
      lista.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    } else if (_ordenamiento == 'precio') {
      lista.sort((a, b) => b.precioTotal.compareTo(a.precioTotal));
    } else if (_ordenamiento == 'personas') {
      lista.sort((a, b) => b.personas.compareTo(a.personas));
    }
    
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade700, Colors.green.shade50],
            stops: const [0.0, 0.3]
          )
        ),
        child: Column(
          children: [
            _buildStatsCards(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30)
                  )
                ),
                child: Column(
                  children: [
                    _buildFilters(),
                    Expanded(child: _buildReservasList())
                  ]
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye las tarjetas de estadísticas principales
  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Reservas',
              '${widget.reservas.length}',
              Icons.event,
              Colors.blue
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Activas',
              '${widget.reservas.where((r) => r.estado == 'activa').length}',
              Icons.check_circle,
              Colors.green
            )
          ),
        ],
      ),
    );
  }

  /// Construye una tarjeta de estadística individual
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(icon, color: color, size: 28)
          ),
          const SizedBox(height: 10),
          Text(value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700
            )),
          Text(title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600
            )),
        ],
      ),
    );
  }

  /// Construye la sección de filtros y ordenamiento
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list,
                color: Colors.green.shade700,
                size: 24),
              const SizedBox(width: 8),
              const Text('Filtros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                )),
            ]
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Filtro por estado
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroEstado,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    prefixIcon: Icon(Icons.filter_alt,
                      color: Colors.green.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8
                    )
                  ),
                  items: const [
                    DropdownMenuItem(value: 'todas', child: Text('Todas')),
                    DropdownMenuItem(value: 'activa', child: Text('Activas')),
                    DropdownMenuItem(value: 'cancelada', child: Text('Canceladas')),
                    DropdownMenuItem(value: 'completada', child: Text('Completadas')),
                  ],
                  onChanged: (value) => setState(() => _filtroEstado = value!),
                )
              ),
              const SizedBox(width: 12),
              // Ordenamiento
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _ordenamiento,
                  decoration: InputDecoration(
                    labelText: 'Ordenar',
                    prefixIcon: Icon(Icons.sort,
                      color: Colors.green.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8
                    )
                  ),
                  items: const [
                    DropdownMenuItem(value: 'fecha', child: Text('Fecha')),
                    DropdownMenuItem(value: 'precio', child: Text('Precio')),
                    DropdownMenuItem(value: 'personas', child: Text('Personas')),
                  ],
                  onChanged: (value) => setState(() => _ordenamiento = value!),
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye la lista de reservas
  Widget _buildReservasList() {
    final reservas = _reservasFiltradas;
    
    if (reservas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox,
              size: 80,
              color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No hay reservas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600
              ))
          ]
        )
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reservas.length,
      itemBuilder: (context, index) => _buildReservaCard(reservas[index]),
    );
  }

  /// Construye la tarjeta de una reserva individual
  Widget _buildReservaCard(Reserva reserva) {
    // Determinar color según estado
    Color estadoColor = Colors.green;
    if (reserva.estado == 'cancelada') estadoColor = Colors.red;
    if (reserva.estado == 'completada') estadoColor = Colors.blue;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade700]
            ),
            borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(
            _getIconForHabitacion(reserva.tipoHabitacion),
            color: Colors.white,
            size: 26
          ),
        ),
        title: Text(reserva.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16
          )),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(reserva.tipoHabitacion,
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13
              )),
            const SizedBox(height: 2),
            Text(
              '${reserva.fechaInicio.day}/${reserva.fechaInicio.month}/${reserva.fechaInicio.year} → ${reserva.fechaFin.day}/${reserva.fechaFin.month}/${reserva.fechaFin.year}',
              style: const TextStyle(fontSize: 12)
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: estadoColor,
            borderRadius: BorderRadius.circular(20)
          ),
          child: Text(
            reserva.estado.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold
            )
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.badge, 'ID', reserva.id),
                _buildInfoRow(Icons.people, 'Personas', '${reserva.personas}'),
                _buildInfoRow(Icons.nights_stay, 'Noches', '${reserva.noches}'),
                _buildInfoRow(Icons.attach_money, 'Total',
                  '\$${reserva.precioTotal.toStringAsFixed(0)} COP'),
                const SizedBox(height: 16),
                // Botones de acción según estado
                Row(
                  children: [
                    if (reserva.estado == 'activa') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _cambiarEstado(reserva, 'completada'),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Completar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)
                            )
                          ),
                        )
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _cambiarEstado(reserva, 'cancelada'),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancelar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)
                            )
                          ),
                        )
                      ),
                    ] else
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _cambiarEstado(reserva, 'activa'),
                          icon: const Icon(Icons.restore, size: 18),
                          label: const Text('Reactivar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)
                            )
                          ),
                        )
                      ),
                  ]
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una fila de información en la tarjeta expandida
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Text('$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 14
            )),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right)
          ),
        ],
      ),
    );
  }

  /// Retorna el icono apropiado para cada tipo de habitación
  IconData _getIconForHabitacion(String tipo) {
    if (tipo.contains('Matrimonial')) return Icons.bed;
    if (tipo.contains('Dos Pisos')) return Icons.bungalow;
    return Icons.park;
  }

  /// Cambia el estado de una reserva después de confirmación
  void _cambiarEstado(Reserva reserva, String nuevoEstado) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        ),
        title: const Text('Confirmar cambio'),
        content: Text('¿Cambiar estado a "$nuevoEstado"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar')
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => reserva.estado = nuevoEstado);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Estado actualizado a "$nuevoEstado"'),
                  backgroundColor: Colors.green
                )
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700
            ),
            child: const Text('Confirmar',
              style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}