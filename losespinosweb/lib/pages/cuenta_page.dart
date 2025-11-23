import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../services/habitacion_service.dart';
import '../services/landing_service.dart';
import '../services/comentario_service.dart';
import '../services/pago_service.dart';
import '../models/reserva.dart';
import 'admin_panel_page.dart';
import 'admin_habitaciones_page.dart';
import 'admin_landing_page.dart';
import 'agregar_comentario_page.dart';
import 'admin_comentarios_page.dart';

class CuentaPage extends StatefulWidget {
  final FirebaseAuthService authService;
  final List<Reserva> reservas;
  final HabitacionService habitacionService;
  final LandingService landingService;
  final ComentarioService comentarioService;
  final PagoService pagoService;
  final Function(Reserva) onCancelar;

  const CuentaPage({
    super.key,
    required this.authService,
    required this.reservas,
    required this.habitacionService,
    required this.landingService,
    required this.comentarioService,
    required this.pagoService,
    required this.onCancelar,
  });

  @override
  State<CuentaPage> createState() => _CuentaPageState();
}

class _CuentaPageState extends State<CuentaPage> {
  String _filtroReservas = 'todas';

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final isLoggedIn = widget.authService.isLoggedIn;

    if (!isLoggedIn) return _buildLoginPrompt(context);

    final userReservas = widget.reservas
        .where((r) => r.odId == user!.id)
        .toList()
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade50, Colors.white])),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: _buildProfileHeader(context, user!, userReservas)),
          if (user.isAdmin) SliverToBoxAdapter(child: _buildAdminTabs(context)),
          if (!user.isAdmin)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _buildReservasHeader(userReservas),
                  const SizedBox(height: 16),
                  _buildReservasList(userReservas, context)
                ]),
              ),
            ),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildLogoutButton(context))),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade300, Colors.green.shade600])),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 12,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.green.shade400,
                          Colors.green.shade700
                        ]),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.account_circle,
                        size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  const Text('Inicia sesión',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Accede a tu perfil y gestiona\ntus reservas fácilmente',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final success =
                            await widget.authService.signInWithGoogle();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Row(children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                  'Bienvenido ${widget.authService.currentUser!.name}!')
                            ]),
                            backgroundColor: Colors.green.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ));
                          setState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 8),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text('Iniciar con Google',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, user, List<Reserva> userReservas) {
    final reservasActivas =
        userReservas.where((r) => r.estado == 'activa').length;
    final totalGastado =
        userReservas.fold<double>(0, (sum, r) => sum + r.precioTotal);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade700, Colors.green.shade900]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 3)),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Icon(
                            user.isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            size: 40,
                            color: Colors.green.shade700)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: user.isAdmin
                                ? Colors.amber.shade600
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                user.isAdmin ? Icons.star : Icons.verified_user,
                                color: Colors.white,
                                size: 14),
                            const SizedBox(width: 6),
                            Text(user.isAdmin ? 'ADMINISTRADOR' : 'CLIENTE',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!user.isAdmin) ...[
              const SizedBox(height: 24),
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(Icons.event_available,
                          reservasActivas.toString(), 'Activas')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildStatCard(Icons.history,
                          userReservas.length.toString(), 'Total')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildStatCard(Icons.attach_money,
                          '\$${totalGastado.toStringAsFixed(0)}', 'Gastado')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildAdminTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAdminCard(
              context,
              'Gestión de Habitaciones',
              'Editar, agregar y gestionar habitaciones',
              Icons.bed,
              Colors.green,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AdminHabitacionesPage(
                          habitacionService: widget.habitacionService,
                          authService: widget.authService)))),
          const SizedBox(height: 12),
          _buildAdminCard(
              context,
              'Panel de Reservas',
              'Gestiona todas las reservas y estados',
              Icons.dashboard,
              Colors.amber,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AdminPanelPage(
                          reservas: widget.reservas,
                          authService: widget.authService)))),
          const SizedBox(height: 12),
          _buildAdminCard(
              context,
              'Gestión de Landing',
              'Editar el contenido de la página principal',
              Icons.web,
              Colors.blue,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AdminLandingPage(
                          landingService: widget.landingService,
                          authService: widget.authService)))),
          const SizedBox(height: 12),
          _buildAdminCard(
              context,
              'Gestión de Comentarios',
              'Moderar y aprobar comentarios',
              Icons.comment,
              Colors.purple,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AdminComentariosPage(
                          comentarioService: widget.comentarioService)))),
        ],
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String title, String subtitle,
      IconData icon, MaterialColor color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.shade50, Colors.white]),
              borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color.shade400, color.shade700]),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color.shade700, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservasHeader(List<Reserva> userReservas) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.event_note, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 12),
            const Text('Mis Reservas',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list, color: Colors.green.shade700),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onSelected: (value) => setState(() => _filtroReservas = value),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'todas', child: Text('Todas')),
                PopupMenuItem(value: 'activa', child: Text('Activas')),
                PopupMenuItem(value: 'cancelada', child: Text('Canceladas')),
                PopupMenuItem(value: 'completada', child: Text('Completadas')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAdminCard(
            context,
            'Dejar un Comentario',
            'Comparte tu experiencia',
            Icons.rate_review,
            Colors.purple,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AgregarComentarioPage(
                        authService: widget.authService,
                        comentarioService: widget.comentarioService)))),
      ],
    );
  }

  Widget _buildReservasList(List<Reserva> userReservas, BuildContext context) {
    var reservasFiltradas = userReservas;
    if (_filtroReservas != 'todas')
      reservasFiltradas =
          userReservas.where((r) => r.estado == _filtroReservas).toList();
    if (reservasFiltradas.isEmpty) return _buildEmptyState();
    return Column(
        children: reservasFiltradas
            .map((reserva) => _buildReservaCard(reserva, context))
            .toList());
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.event_busy,
                  size: 60, color: Colors.green.shade300)),
          const SizedBox(height: 20),
          const Text('No hay reservas',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
              _filtroReservas == 'todas'
                  ? 'Haz tu primera reserva!'
                  : 'No tienes reservas $_filtroReservas',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildReservaCard(Reserva reserva, BuildContext context) {
    Color estadoColor = Colors.green;
    IconData estadoIcon = Icons.check_circle;
    if (reserva.estado == 'cancelada') {
      estadoColor = Colors.red;
      estadoIcon = Icons.cancel;
    } else if (reserva.estado == 'completada') {
      estadoColor = Colors.blue;
      estadoIcon = Icons.task_alt;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient:
                LinearGradient(colors: [Colors.green.shade50, Colors.white])),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.green.shade400,
                          Colors.green.shade700
                        ]),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(_getIconForHabitacion(reserva.tipoHabitacion),
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reserva.tipoHabitacion,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('ID: ${reserva.id}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: estadoColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(estadoIcon, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(reserva.estado.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.person, 'Nombre', reserva.nombre),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.people, 'Personas', '${reserva.personas}'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.calendar_today, 'Check-in',
                  '${reserva.fechaInicio.day}/${reserva.fechaInicio.month}/${reserva.fechaInicio.year}'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.event, 'Check-out',
                  '${reserva.fechaFin.day}/${reserva.fechaFin.month}/${reserva.fechaFin.year}'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.nights_stay, 'Noches', '${reserva.noches}'),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.attach_money, color: estadoColor, size: 24),
                  const SizedBox(width: 8),
                  const Text('Total: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text('\$${reserva.precioTotal.toStringAsFixed(0)} COP',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: estadoColor)),
                ],
              ),
              if (reserva.estado == 'activa') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarCancelacion(reserva, context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Cancelar Reserva',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green.shade700),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  void _confirmarCancelacion(Reserva reserva, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 12),
          Text('Cancelar Reserva')
        ]),
        content: Text(
            '¿Estás seguro de que deseas cancelar la reserva de ${reserva.tipoHabitacion}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              widget.onCancelar(reserva);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Row(children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Reserva cancelada exitosamente')
                ]),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Sí, cancelar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getIconForHabitacion(String tipo) {
    if (tipo.contains('Matrimonial')) return Icons.king_bed;
    if (tipo.contains('Dos Pisos')) return Icons.bungalow;
    return Icons.park;
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text('Cerrar sesión',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white))
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.logout, color: Colors.red.shade700),
          const SizedBox(width: 12),
          const Text('Cerrar sesión')
        ]),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              widget.authService.logout();
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Row(children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Sesión cerrada correctamente')
                ]),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
