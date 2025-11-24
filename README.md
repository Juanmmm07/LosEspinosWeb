# 🏕️  Espinos Glamping - Sistema de Reservas

Sistema completo de reservas y gestión para glamping desarrollado en Flutter con integración de Firebase Authentication y sistema de pagos PSE simulado.

##  Tabla de Contenidos

- [Características](#-características)
- [Capturas de Pantalla](#-capturas-de-pantalla)
- [Tecnologías](#-tecnologías)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación](#-instalación)
- [Configuración de Firebase](#-configuración-de-firebase)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Funcionalidades Principales](#-funcionalidades-principales)
- [Roles de Usuario](#-roles-de-usuario)
- [API y Servicios](#-api-y-servicios)
- [Contribuir](#-contribuir)
- [Licencia](#-licencia)

##  Características

### Para Clientes
-  **Autenticación con Google** - Inicio de sesión seguro y rápido
-  **Exploración de Habitaciones** - Visualiza habitaciones con carrusel de imágenes
-  **Sistema de Reservas** - Reserva con validación de fechas y disponibilidad
-  **Pagos PSE** - Simulación completa de pagos con PSE Colombia
-  **Sistema de Comentarios** - Comparte tu experiencia y califica
-  **Panel Personal** - Gestiona tus reservas y perfil

### Para Administradores
-  **Gestión de Habitaciones** - CRUD completo con imágenes y precios
-  **Panel de Reservas** - Visualiza y gestiona todas las reservas
-  **Moderación de Comentarios** - Aprueba o rechaza reseñas
-  **Gestión de Landing Page** - Personaliza slides y contenido
-  **Dashboard Administrativo** - Estadísticas y métricas en tiempo real

## 🛠 Tecnologías

- **Flutter 3.x** - Framework de desarrollo multiplataforma
- **Dart** - Lenguaje de programación
- **Firebase Authentication** - Autenticación con Google
- **Firebase Core** - Configuración de Firebase
- **Google Sign In** - Inicio de sesión con Google
- **Provider Pattern** - Gestión de estado mediante ChangeNotifier

##  Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.0.0)
- [Dart SDK](https://dart.dev/get-dart) (>=3.0.0)
- [Android Studio](https://developer.android.com/studio) o [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)
- Cuenta de [Firebase](https://firebase.google.com/)

##  Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/los-espinos-glamping.git
cd los-espinos-glamping
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Firebase (Ver sección siguiente)

### 4. Ejecutar la aplicación

```bash
# Para Web
flutter run -d chrome

# Para Android
flutter run -d android

# Para iOS
flutter run -d ios
```

## Configuración de Firebase

### 1. Crear un proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto llamado "losespinosweb" (o el nombre que prefieras)
3. Habilita Google Analytics (opcional)

### 2. Configurar Authentication

1. En la consola de Firebase, ve a **Authentication**
2. Habilita el método de inicio de sesión **Google**
3. Configura el correo electrónico de soporte

### 3. Configurar la aplicación Web

1. En Project Settings, agrega una aplicación **Web**
2. Registra tu aplicación con un nombre
3. Copia la configuración de Firebase

### 4. Actualizar firebase_options.dart

Reemplaza las credenciales en `lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: "TU_API_KEY",
  appId: "TU_APP_ID",
  messagingSenderId: "TU_MESSAGING_SENDER_ID",
  projectId: "TU_PROJECT_ID",
  authDomain: "TU_AUTH_DOMAIN",
  storageBucket: "TU_STORAGE_BUCKET",
);
```

### 5. Configurar emails de administrador

En `lib/services/firebase_auth_service.dart`, actualiza la lista de administradores:

```dart
final List<String> _adminEmails = [
  'admin@losespinos.com',
  'tu-email@gmail.com', // Agrega tu email aquí
];
```

### 6. Configurar Android/iOS (Opcional)

Para Android e iOS, sigue la [documentación oficial de FlutterFire](https://firebase.flutter.dev/docs/overview).

##  Estructura del Proyecto

```
lib/
├── models/              # Modelos de datos
│   ├── user.dart
│   ├── habitacion.dart
│   ├── reserva.dart
│   ├── comentario.dart
│   └── firebase_user.dart
│
├── services/           # Servicios y lógica de negocio
│   ├── firebase_auth_service.dart
│   ├── habitacion_service.dart
│   ├── comentario_service.dart
│   ├── pago_service.dart
│   └── landing_service.dart
│
├── pages/              # Páginas de la aplicación
│   ├── landing_page.dart
│   ├── habitaciones_page.dart
│   ├── hacer_reserva_page.dart
│   ├── cuenta_page.dart
│   ├── login_page.dart
│   ├── pago_pse_page.dart
│   ├── pago_procesando_page.dart
│   ├── admin_panel_page.dart
│   ├── admin_habitaciones_page.dart
│   ├── admin_landing_page.dart
│   └── admin_comentarios_page.dart
│
├── firebase_options.dart
└── main.dart
```

##  Funcionalidades Principales

### Sistema de Reservas

- **Validación de fechas**: Previene reservas en fechas ocupadas
- **Cálculo automático de precios**: Por noche y por persona (camping)
- **Información completa del huésped**: Nombre, documento, teléfono
- **Estados de reserva**: Activa, Cancelada, Completada

### Sistema de Pagos PSE

- **Simulación completa de PSE**: Integración con bancos colombianos
- **Estados de pago**: Procesando, Aprobado, Rechazado
- **Referencias únicas**: Generación automática de referencias
- **Interfaz realista**: Simula el flujo completo de pago

### Gestión de Habitaciones

```dart
// Tipos de habitaciones disponibles
- Cama Matrimonial (2 personas) - $75,000 COP/noche
- Camas de Dos Pisos (4 personas) - $100,000 COP/noche
- Zona de Camping (por persona) - $20,000 COP/noche
```

### Sistema de Comentarios

- **Moderación**: Los comentarios requieren aprobación
- **Calificación**: Sistema de estrellas (1-5)
- **Avatares**: Integración con foto de Google
- **Filtros**: Pendientes, Aprobados, Todos

##  Roles de Usuario

### Cliente
- Ver habitaciones y hacer reservas
- Gestionar sus propias reservas
- Dejar comentarios y calificaciones
- Realizar pagos simulados con PSE

### Administrador
- Acceso completo a todas las funcionalidades de cliente
- Gestionar habitaciones (CRUD completo)
- Ver y gestionar todas las reservas
- Moderar comentarios
- Personalizar landing page
- Ver estadísticas del sistema

**Email de administrador por defecto**: 
- `admin@losespinos.com`
- Agrega tu email en `firebase_auth_service.dart`

##  API y Servicios

### FirebaseAuthService

```dart
// Inicializar servicio
await authService.initialize();

// Iniciar sesión con Google
final success = await authService.signInWithGoogle();

// Cerrar sesión
await authService.logout();

// Verificar estado
bool isLoggedIn = authService.isLoggedIn;
bool isAdmin = authService.isAdmin;
```

### HabitacionService

```dart
// Obtener habitaciones activas
List<Habitacion> habitaciones = habitacionService.habitacionesActivas;

// Agregar habitación
habitacionService.agregarHabitacion(nuevaHabitacion);

// Actualizar precio
habitacionService.actualizarPrecio(habitacionId, nuevoPrecio);
```

### PagoService

```dart
// Crear transacción PSE
final resultado = await pagoService.crearTransaccionPSE(
  reservaId: reserva.id,
  userId: user.id,
  monto: 100000,
  banco: 'Bancolombia',
  tipoDocumento: 'CC',
  numeroDocumento: '123456789',
);

// Simular respuesta del banco
await pagoService.simularRespuestaPSE(pagoId, aprobar: true);
```

##  Personalización

### Colores del tema

Los colores principales se pueden modificar en `main.dart`:

```dart
theme: ThemeData(
  primarySwatch: Colors.green,
  scaffoldBackgroundColor: Colors.white,
  // ... más configuraciones
),
```

### Imágenes

Las imágenes se encuentran en `assets/images/`. Actualiza las rutas en:
- `habitacion_service.dart` - Imágenes de habitaciones
- `landing_service.dart` - Slides de la landing page

##  Testing

```bash
# Ejecutar tests
flutter test

# Ejecutar tests con cobertura
flutter test --coverage
```

## Dispositivos Soportados

-  Web (Chrome, Firefox, Safari, Edge)
-  Android 5.0+ (API 21+)
-  iOS 11.0+

##  Problemas Conocidos

- El sistema de pagos PSE es una **simulación** y no procesa pagos reales
- Las imágenes deben estar en `assets/images/` para funcionar correctamente
- La autenticación requiere configuración completa de Firebase

##  Próximas Características

- [ ] Integración con pasarela de pagos real
- [ ] Notificaciones push
- [ ] Chat en tiempo real
- [ ] Modo oscuro
- [ ] Multi-idioma (español/inglés)
- [ ] Backend con Firebase Firestore
- [ ] Sistema de descuentos y promociones
