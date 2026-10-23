import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aprender_es_divertido/models/pdf_book_model.dart';
import 'package:aprender_es_divertido/Ejercicios/LibrosPDF/ver_libro_pdf_screen.dart';
import 'package:aprender_es_divertido/Ejercicios/LibrosPDF/crear_libro_pdf_screen.dart';
import 'package:aprender_es_divertido/models/user_model.dart';

class ListaLibrosPDFScreen extends StatefulWidget {
  const ListaLibrosPDFScreen({super.key});

  @override
  State<ListaLibrosPDFScreen> createState() => _ListaLibrosPDFScreenState();
}

class _ListaLibrosPDFScreenState extends State<ListaLibrosPDFScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;
  List<LibroPDF> _libros = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarLibros();
  }

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

  Future<void> _cargarLibros() async {
    setState(() => _cargando = true);
    await LibroPDFRepository.init();
    setState(() {
      _libros = UsuarioRepository.esMaestraLogueada
          ? LibroPDFRepository.getLibros()
          : LibroPDFRepository.getLibrosParaAlumno(
              UsuarioRepository.alumnoActual?.id,
            );
      _cargando = false;
    });
  }

  void _navegarACrearLibro() {
    if (!UsuarioRepository.esMaestraLogueada) return;
    _playSound();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CrearLibroPDFScreen(),
      ),
    ).then((_) => _cargarLibros());
  }

  void _verLibro(LibroPDF libro) {
    _playSound();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerLibroPDFScreen(libro: libro),
      ),
    ).then((_) => _cargarLibros());
  }

  Future<void> _eliminarLibro(String libroId) async {
    if (!UsuarioRepository.esMaestraLogueada) return;
    _playSound();
    
    // Confirmar eliminación
    bool confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Libro'),
        content: const Text('¿Estás seguro de que quieres eliminar este libro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await LibroPDFRepository.eliminarLibro(libroId);
      await _cargarLibros();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Libro eliminado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3E5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Libros PDF',
          style: TextStyle(
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _libros.isEmpty
              ? _buildEmptyState()
              : _buildLibrosList(),
      floatingActionButton: UsuarioRepository.esMaestraLogueada
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              onPressed: _navegarACrearLibro,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              UsuarioRepository.esMaestraLogueada
                  ? 'No hay libros PDF añadidos'
                  : 'No hay libros asignados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              UsuarioRepository.esMaestraLogueada
                  ? 'Toca el botón + para añadir tu primer libro'
                  : 'Pide a tu maestra que te asigne un libro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrosList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _libros.length,
      itemBuilder: (context, index) {
        final libro = _libros[index];
        return _buildLibroCard(libro);
      },
    );
  }

  Widget _buildLibroCard(LibroPDF libro) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono de libro
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                size: 30,
                color: Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(width: 16),
            // Información del libro
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libro.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Página actual: ${libro.paginaActual}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Indicadores de actividades
                  Row(
                    children: [
                      if (libro.tienePreguntas)
                        const Chip(
                          label: Text('Preguntas'),
                          backgroundColor: Color(0xFFE3F2FD),
                          labelStyle: TextStyle(color: Color(0xFF1976D2), fontSize: 10),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      if (libro.tieneAcrostico)
                        const SizedBox(width: 4),
                      if (libro.tieneAcrostico)
                        const Chip(
                          label: Text('Acróstico'),
                          backgroundColor: Color(0xFFF3E5F5),
                          labelStyle: TextStyle(color: Color(0xFF6A1B9A), fontSize: 10),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Botones de acción
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                  onPressed: () => _verLibro(libro),
                  tooltip: 'Ver actividad con libro',
                ),
                const SizedBox(height: 4),
                if (UsuarioRepository.esMaestraLogueada)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarLibro(libro.id),
                    tooltip: 'Eliminar',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
