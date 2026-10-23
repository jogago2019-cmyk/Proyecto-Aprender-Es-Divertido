import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../Ejercicios/taller_contenido.dart';
import '../Ejercicios/menu_lengua_taller.dart';
import '../models/user_model.dart';
import '../screens/login_screen.dart';
import '../screens/seleccionar_alumno_screen.dart';
import '../screens/estadistica_alumno_screen.dart';
import '../screens/gestion_maestras_screen.dart';

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;

  void _toggleSonido() {
    setState(() {
      sonidoActivado = !sonidoActivado;
    });
  }

  void _playSound() {
    if (sonidoActivado) {
      _audioPlayer.play(AssetSource('sounds/softpop_sfx.mp3'));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si hay sesión iniciada
    if (!UsuarioRepository.esMaestraLogueada &&
        !UsuarioRepository.hayAlumnoSeleccionado) {
      // Si no hay sesión, redirigir a login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Determinar si es maestra o alumno
    final esMaestra = UsuarioRepository.esMaestraLogueada;
    final alumnoActual = UsuarioRepository.alumnoActual;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE1F5FE),
                    child: Icon(
                      esMaestra ? Icons.school : Icons.child_care,
                      size: 32,
                      color: const Color(0xFF0288D1),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esMaestra
                              ? '¡Bienvenida, Maestra!'
                              : '¡Hola, ${alumnoActual?.nombre ?? "Alumno"}!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '¿Qué exploramos hoy?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      sonidoActivado ? Icons.volume_up : Icons.volume_off,
                      color: const Color(0xFF0288D1),
                    ),
                    onPressed: _toggleSonido,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    // Botón para seleccionar alumno (solo si es maestra o no hay alumno seleccionado)
                    if (esMaestra ||
                        !UsuarioRepository.hayAlumnoSeleccionado) ...[
                      _BotonModulo(
                        etiqueta: 'SELECCIONAR USUARIO',
                        titulo: 'Comenzar Aprendizaje',
                        subtitulo: esMaestra
                            ? 'Selecciona un alumno para que comience a aprender'
                            : 'Selecciona tu nombre para empezar',
                        imagen: null,
                        icono: Icons.person_search,
                        colorFondo: const Color(0xFFE1F5FE),
                        colorIcono: const Color(0xFF0288D1),
                        accion: 'Seleccionar ahora',
                        onTap: () {
                          _playSound();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SeleccionarAlumnoScreen(esParaJugar: true),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    _BotonModulo(
                      etiqueta: 'HISTORIAS MÁGICAS',
                      titulo: 'Lengua y Cuentos',
                      subtitulo:
                          'Ejercicios de completar palabras y reconocimiento.',
                      imagen: 'assets/imagends/lengua_materia.png',
                      colorFondo: const Color(0xFFF3E5F5),
                      colorIcono: const Color(0xFF6A1B9A),
                      accion: 'Empezar ejercicio',
                      onTap: () {
                        _playSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MenuLenguaTaller(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Taller de contenido solo visible para maestra
                    if (esMaestra) ...[
                      _BotonModulo(
                        etiqueta: 'PARA MAESTROS',
                        titulo: 'Taller de Creación',
                        subtitulo:
                            'Crea ejercicios personalizados para tus alumnos.',
                        imagen: null,
                        icono: Icons.edit,
                        colorFondo: const Color(0xFFE8F5E9),
                        colorIcono: const Color(0xFF2E7D32),
                        accion: 'Crear contenido',
                        onTap: () {
                          _playSound();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TallerContenido(),
                            ),
                          );
                        },
                      ),
                    ],

                    // Botón para gestionar alumnos (solo si es maestra)
                    if (esMaestra) ...[
                      const SizedBox(height: 20),
                      _BotonModulo(
                        etiqueta: 'ADMINISTRACIÓN',
                        titulo: 'Gestionar Alumnos',
                        subtitulo: 'Crea, edita o elimina alumnos',
                        imagen: null,
                        icono: Icons.group,
                        colorFondo: const Color(0xFFF5F5F5),
                        colorIcono: Colors.grey[600]!,
                        accion: 'Gestionar ahora',
                        onTap: () {
                          _playSound();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SeleccionarAlumnoScreen(esParaJugar: false),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _BotonModulo(
                        etiqueta: 'SEGUIMIENTO',
                        titulo: 'Estadística de alumno',
                        subtitulo:
                            'Consulta respuestas, aciertos y errores por alumno.',
                        imagen: null,
                        icono: Icons.insights,
                        colorFondo: const Color(0xFFE8F5E9),
                        colorIcono: const Color(0xFF2E7D32),
                        accion: 'Ver estadísticas',
                        onTap: () {
                          _playSound();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EstadisticaAlumnoScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _BotonModulo(
                        etiqueta: 'ADMINISTRACIÓN',
                        titulo: 'Cuentas de maestras',
                        subtitulo:
                            'Consulta o elimina cuentas de este dispositivo.',
                        imagen: null,
                        icono: Icons.manage_accounts,
                        colorFondo: const Color(0xFFE1F5FE),
                        colorIcono: const Color(0xFF0288D1),
                        accion: 'Gestionar cuentas',
                        onTap: () {
                          _playSound();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const GestionMaestrasScreen(),
                            ),
                          );
                        },
                      ),
                    ],

                    // Botón para cerrar sesión (solo si es maestra)
                    if (esMaestra) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            _playSound();
                            await UsuarioRepository.logout();
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'Cerrar sesión',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                    if (!esMaestra &&
                        UsuarioRepository.hayAlumnoSeleccionado) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            await UsuarioRepository.logout();
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.switch_account),
                          label: const Text('Volver al acceso de maestra'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonModulo extends StatelessWidget {
  final String etiqueta;
  final String titulo;
  final String subtitulo;
  final String? imagen;
  final IconData? icono;
  final Color colorFondo;
  final Color colorIcono;
  final String accion;
  final VoidCallback onTap;

  const _BotonModulo({
    required this.etiqueta,
    required this.titulo,
    required this.subtitulo,
    this.imagen,
    this.icono,
    required this.colorFondo,
    required this.colorIcono,
    required this.accion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Card(
        color: colorFondo,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: colorIcono.withAlpha(89), width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorIcono.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: imagen != null
                      ? ClipOval(
                          child: Image.asset(imagen!, fit: BoxFit.contain),
                        )
                      : Icon(icono, size: 44, color: colorIcono),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        etiqueta,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: colorIcono,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            accion,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorIcono,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: colorIcono,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
