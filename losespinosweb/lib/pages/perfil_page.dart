import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../models/reserva.dart';
import '../services/habitacion_service.dart';
import 'login_page.dart';
import 'admin_habitaciones_page.dart';

class PerfilPage extends StatelessWidget {
  final FirebaseAuthService authService;
  final List<Reserva> reservas;
  final HabitacionService habitacionService;

  const PerfilPage({
    Key? key,
    required this.authService,
    required this.reservas,
    required this.habitacionService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    
    if (!authService.isLoggedIn) {
      return _buildLoginRequired(context);
    }

    final misReservas = reservas.where((r) => r.odId == user?.id).toList();
    final reservasActivas = misReservas.where((r) => r.estado == 'activa').toList();
    final totalGastado = _calcularTotal(misReservas);
    
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Mi Perfil 🌿'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserCard(user!),
            const SizedBox(height: 20),
            _buildStatsCard(reservasActivas.length, misReservas.length, totalGastado),
            const SizedBox(height: 20),
            if (authService.isAdmin) _buildAdminSection(context),
            const SizedBox(height: 20),
            _buildRecentReservas(misReservas, context),
            const SizedBox(height: 20),
            _buildActionsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil 🌿'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade100, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 80,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Mi Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Inicia sesión para ver tu perfil\ny gestionar tus datos',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginPage(authService: authService),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email ?? 'No email',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: user.isAdmin ? Colors.orange.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.isAdmin ? '👑 Administrador' : '👤 Cliente',
                        style: TextStyle(
                          color: user.isAdmin ? Colors.orange.shade800 : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Editar perfil
                },
                icon: Icon(Icons.edit, color: Colors.green.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(int activas, int total, String totalGastado) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Mis Estadísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.event_available,
                  'Activas',
                  activas.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.history,
                  'Total',
                  total.toString(),
                  Colors.green.shade700,
                ),
                _buildStatItem(
                  Icons.attach_money,
                  'Gastado',
                  '\$$totalGastado',
                  Colors.green.shade900,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.green.shade800, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Panel de Administración',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Gestiona habitaciones, precios, fotos y descripciones',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminHabitacionesPage(
                          habitacionService: habitacionService,
                          authService: authService,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bed, color: Colors.white),
                  label: const Text(
                    'Gestionar Habitaciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReservas(List<Reserva> misReservas, BuildContext context) {
    final reservasRecientes = misReservas.take(3).toList();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reservas Recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (reservasRecientes.isEmpty)
              _buildEmptyReservas()
            else
              ...reservasRecientes.map((reserva) => _buildReservaItem(reserva, context)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReservaItem(Reserva reserva, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(reserva.estado),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getReservaIcon(reserva.tipoHabitacion),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reserva.tipoHabitacion,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reserva.fechaInicio.day}/${reserva.fechaInicio.month}/${reserva.fechaInicio.year}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(reserva.estado).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              reserva.estado.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(reserva.estado),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReservas() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.event_note,
            size: 50,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No tienes reservas',
            style: TextStyle(
              color: Colors.green.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Haz tu primera reserva!',
            style: TextStyle(
              color: Colors.green.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionItem(
              Icons.settings,
              'Configuración',
              'Ajustes de la cuenta',
              () {},
            ),
            const Divider(),
            _buildActionItem(
              Icons.help,
              'Ayuda y Soporte',
              'Centro de ayuda',
              () {},
            ),
            const Divider(),
            _buildActionItem(
              Icons.logout,
              'Cerrar Sesión',
              'Salir de tu cuenta',
              () {
                _showLogoutDialog(context);
              },
              isLogout: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLogout ? Colors.red.shade50 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isLogout ? Colors.red : Colors.green,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isLogout ? Colors.red.shade600 : Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isLogout ? Colors.red : Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'activa':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'completada':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getReservaIcon(String tipoHabitacion) {
    if (tipoHabitacion.contains('Matrimonial')) return Icons.king_bed;
    if (tipoHabitacion.contains('Dos Pisos')) return Icons.bed;
    if (tipoHabitacion.contains('Camping')) return Icons.park;
    return Icons.hotel;
  }

  String _calcularTotal(List<Reserva> reservas) {
    final total = reservas.fold(0.0, (sum, r) => sum + r.precioTotal);
    return total.toStringAsFixed(0);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                authService.logout();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesión cerrada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}