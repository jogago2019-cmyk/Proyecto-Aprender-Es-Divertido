import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aprender_es_divertido/models/ordenar_palabras_model.dart';
import 'package:aprender_es_divertido/models/user_model.dart';
import 'package:aprender_es_divertido/Ejercicios/OrdenarPalabras/jugar_screen.dart';
import 'package:aprender_es_divertido/services/imagen_service.dart';
import 'package:aprender_es_divertido/widgets/imagen_ejercicio_widget.dart';

class ListaEjerciciosOrdenarScreen extends StatefulWidget {
  const ListaEjerciciosOrdenarScreen({super.key});

  @override
  State<ListaEjerciciosOrdenarScreen> createState() =>
      _ListaEjerciciosOrdenarScreenState();
}

class _ListaEjerciciosOrdenarScreenState
    extends State<ListaEjerciciosOrdenarScreen> {
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

  void _eliminarEjercicio(OrdenarPalabraEjercicio ejercicio) {
    if (!UsuarioRepository.esMaestraLogueada) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Eliminar Ejercicio'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el ejercicio "${ejercicio.palabraCorrecta}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Eliminar la imagen del almacenamiento
              await ImagenService.eliminarImagen(ejercicio.imagenPath);

              // Eliminar el ejercicio del repositorio
              await OrdenarPalabraRepository.eliminarEjercicio(ejercicio.id);

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              if (!mounted) return;
              _playSound();
              setState(() {});
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ejercicios = UsuarioRepository.esMaestraLogueada
        ? OrdenarPalabraRepository.getEjercicios()
        : OrdenarPalabraRepository.getEjerciciosParaAlumno(
            UsuarioRepository.alumnoActual?.id,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3E5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Lista de Ejercicios - Ordenar Palabras',
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ejercicios de Ordenar Palabras',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${ejercicios.length} ejercicios creados',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ejercicios.isEmpty
                    ? _buildSinEjercicios()
                    : ListView.separated(
                        itemCount: ejercicios.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _buildEjercicioCard(ejercicios[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSinEjercicios() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            UsuarioRepository.esMaestraLogueada
                ? 'No hay ejercicios creados'
                : 'No hay ejercicios asignados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            UsuarioRepository.esMaestraLogueada
                ? 'Crea tu primer ejercicio para empezar'
                : 'Pide a tu maestra que te asigne una actividad.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEjercicioCard(OrdenarPalabraEjercicio ejercicio) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Imagen
            ImagenEjercicioCircular(imagenPath: ejercicio.imagenPath, size: 60),
            const SizedBox(width: 16),
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    UsuarioRepository.esMaestraLogueada
                        ? ejercicio.palabraCorrecta.toUpperCase()
                        : 'Ordena las letras',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!UsuarioRepository.esMaestraLogueada)
                    Text(
                      'Letras: ${ejercicio.palabraDesordenada.toUpperCase()}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  if (ejercicio.pista.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Pista: ${ejercicio.pista}',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF039BE5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (UsuarioRepository.esMaestraLogueada)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.green,
                      size: 32,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JugarOrdenarPalabraScreen(
                          ejercicio: ejercicio,
                          modoPrueba: true,
                        ),
                      ),
                    ),
                    tooltip: 'Probar ejercicio',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarEjercicio(ejercicio),
                    tooltip: 'Eliminar',
                  ),
                ],
              )
            else
              IconButton(
                iconSize: 36,
                icon: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.green,
                  size: 32,
                ),
                tooltip: 'Resolver',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const JugarOrdenarPalabraScreen(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
