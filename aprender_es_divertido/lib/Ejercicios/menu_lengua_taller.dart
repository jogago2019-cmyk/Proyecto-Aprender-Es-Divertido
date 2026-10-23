import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aprender_es_divertido/Ejercicios/CompletarPalabra/crear_contenido_screen.dart';
import 'package:aprender_es_divertido/Ejercicios/CompletarPalabra/lista_ejercicios_screen.dart';
import 'package:aprender_es_divertido/Ejercicios/OrdenarPalabras/crear_contenido_screen.dart';
import 'package:aprender_es_divertido/Ejercicios/OrdenarPalabras/lista_ejercicios_screen.dart';
import 'package:aprender_es_divertido/Ejercicios/Acrostico/crear_acrostico_screen.dart';
import 'package:aprender_es_divertido/Ejercicios/Acrostico/lista_acrosticos_screen.dart';
import 'package:aprender_es_divertido/Ejercicios/LibrosPDF/crear_libro_pdf_screen.dart';
import 'package:aprender_es_divertido/Ejercicios/LibrosPDF/lista_libros_pdf_screen.dart';
import 'package:aprender_es_divertido/models/user_model.dart';

class MenuLenguaTaller extends StatefulWidget {
  const MenuLenguaTaller({super.key});

  @override
  State<MenuLenguaTaller> createState() => _MenuLenguaTallerState();
}

class _MenuLenguaTallerState extends State<MenuLenguaTaller> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playSound() {
    if (sonidoActivado) {
      _audioPlayer.play(AssetSource('sounds/softpop_sfx.mp3'));
    }
  }

  void _toggleSonido() {
    setState(() {
      sonidoActivado = !sonidoActivado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3E5F5),
        elevation: 0,
        centerTitle: true,
        title: Text(
          UsuarioRepository.esMaestraLogueada
              ? 'Lengua - Taller de Contenido'
              : 'Lengua y actividades',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6A1B9A)),
          onPressed: () {
            _playSound();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              sonidoActivado ? Icons.volume_up : Icons.volume_off,
              color: const Color(0xFF6A1B9A),
            ),
            onPressed: _toggleSonido,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                UsuarioRepository.esMaestraLogueada
                    ? 'Gestión de Ejercicios de Lengua'
                    : 'Actividades de Lengua disponibles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      'Ejercicios de Completar Palabra',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BotonModuloLengua(
                      icono: Icons.edit,
                      titulo: 'Crear Ejercicio - Completar Palabras',
                      subtitulo: 'Crea nuevos ejercicios de completar palabras para tus alumnos',
                      soloMaestra: true,
                      colorFondo: const Color(0xFFE8F5E9),
                      colorIcono: const Color(0xFF2E7D32),
                      onTap: () {
                        _playSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CrearContenidoScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _BotonModuloLengua(
                      icono: Icons.list,
                      titulo: 'Ver Ejercicios - Completar Palabras',
                      subtitulo: 'Lista de todos los ejercicios de completar palabras creados',
                      colorFondo: const Color(0xFFE3F2FD),
                      colorIcono: const Color(0xFF1976D2),
                      onTap: () {
                        _playSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ListaEjerciciosScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ejercicios de Ordenar Palabras',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BotonModuloLengua(
                      icono: Icons.edit,
                      titulo: 'Crear Ejercicio - Ordenar Palabras',
                      subtitulo: 'Crea nuevos ejercicios de palabras desordenadas para tus alumnos',
                      soloMaestra: true,
                      colorFondo: const Color(0xFFFFF3E0),
                      colorIcono: const Color(0xFFE65100),
                      onTap: () {
                        _playSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CrearContenidoOrdenarScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _BotonModuloLengua(
                      icono: Icons.list,
                      titulo: 'Ver Ejercicios - Ordenar Palabras',
                      subtitulo: 'Lista de todos los ejercicios de ordenar palabras creados',
                      colorFondo: const Color(0xFFF3E5F5),
                      colorIcono: const Color(0xFF6A1B9A),
                      onTap: () {
                        _playSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ListaEjerciciosOrdenarScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ejercicios de Acrósticos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BotonModuloLengua(
                      icono: Icons.edit,
                      titulo: 'Crear Ejercicio - Acrósticos',
                      subtitulo: 'Crea nuevos ejercicios de acrósticos para tus alumnos',
                      soloMaestra: true,
                      colorFondo: const Color(0xFFE8F5E9),
                      colorIcono: const Color(0xFF2E7D32),
                      onTap: () {
                        _playSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CrearAcrosticoScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _BotonModuloLengua(
                      icono: Icons.list,
                      titulo: 'Ver Ejercicios - Acrósticos',
                      subtitulo: 'Lista de todos los ejercicios de acrósticos creados',
                      colorFondo: const Color(0xFFE3F2FD),
                      colorIcono: const Color(0xFF1976D2),
                      onTap: () {
                        _playSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ListaAcrosticosScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Libros PDF',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BotonModuloLengua(
                      icono: Icons.picture_as_pdf,
                      titulo: 'Crear Libro PDF',
                      subtitulo:
                          'Agrega un libro PDF y configura sus preguntas o actividad final',
                      soloMaestra: true,
                      colorFondo: const Color(0xFFF3E5F5),
                      colorIcono: const Color(0xFF6A1B9A),
                      onTap: () {
                        _playSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CrearLibroPDFScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _BotonModuloLengua(
                      icono: Icons.library_books,
                      titulo: 'Ver Libros PDF',
                      subtitulo: 'Consulta y gestiona los libros PDF creados',
                      colorFondo: const Color(0xFFE3F2FD),
                      colorIcono: const Color(0xFF1976D2),
                      onTap: () {
                        _playSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ListaLibrosPDFScreen(),
                          ),
                        );
                      },
                    ),
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

// Componente reutilizable para botones del menú de lengua
class _BotonModuloLengua extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color colorFondo;
  final Color colorIcono;
  final bool soloMaestra;
  final VoidCallback onTap;

  const _BotonModuloLengua({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.colorFondo,
    required this.colorIcono,
    this.soloMaestra = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (soloMaestra && !UsuarioRepository.esMaestraLogueada) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 120,
      child: Card(
        color: colorFondo,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorIcono.withAlpha(89),
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icono,
                    size: 30,
                    color: colorIcono,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
