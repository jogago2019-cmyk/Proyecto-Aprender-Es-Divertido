import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aprender_es_divertido/models/acrostico_model.dart';
import 'package:aprender_es_divertido/Ejercicios/Acrostico/crear_acrostico_screen.dart';
import 'package:aprender_es_divertido/Ejercicios/Acrostico/jugar_acrostico_screen.dart';
import 'package:aprender_es_divertido/services/imagen_service.dart';
import 'package:aprender_es_divertido/widgets/imagen_ejercicio_widget.dart';
import 'package:aprender_es_divertido/models/user_model.dart';
import 'package:aprender_es_divertido/widgets/acceso_maestra_denegado.dart';

class ListaAcrosticosScreen extends StatefulWidget {
  const ListaAcrosticosScreen({super.key});

  @override
  State<ListaAcrosticosScreen> createState() => _ListaAcrosticosScreenState();
}

class _ListaAcrosticosScreenState extends State<ListaAcrosticosScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;

  List<AcrosticoEjercicio> _ejercicios = [];
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _cargarEjercicios();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _cargarEjercicios() async {
    setState(() {
      _cargando = true;
    });

    try {
      await AcrosticoRepository.init();
      final ejercicios = UsuarioRepository.esMaestraLogueada
          ? AcrosticoRepository.getEjercicios()
          : AcrosticoRepository.getEjerciciosParaAlumno(
              UsuarioRepository.alumnoActual?.id,
            );

      if (mounted) {
        setState(() {
          _ejercicios = ejercicios;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar los acrósticos')),
        );
      }
    }
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

  Future<void> _confirmarEliminarEjercicio(AcrosticoEjercicio ejercicio) async {
    if (!UsuarioRepository.esMaestraLogueada) return;
    _playSound();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final dialogNavigator = Navigator.of(dialogContext);
        final messenger = ScaffoldMessenger.of(context);
        return AlertDialog(
          title: const Text('Eliminar Acróstico'),
          content: Text(
            '¿Estás seguro de que quieres eliminar el acróstico "${ejercicio.titulo}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => dialogNavigator.pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                // Intentar eliminar la imagen
                try {
                  await ImagenService.eliminarImagen(ejercicio.imagenPath);
                } catch (e) {
                  // Ignorar error si no se puede eliminar la imagen
                }

                // Eliminar el ejercicio
                await AcrosticoRepository.eliminarEjercicio(ejercicio.id);

                if (!mounted) return;
                dialogNavigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Acróstico eliminado con éxito'),
                  ),
                );
                await _cargarEjercicios();
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDetallesEjercicio(AcrosticoEjercicio ejercicio) {
    if (!UsuarioRepository.esMaestraLogueada) return;
    _playSound();

    final localContext = context;
    // Calcular letras ocultas info
    final letrasOcultasInfo = ejercicio.letrasOcultasPorPalabra
        .asMap()
        .entries
        .expand(
          (entry) => entry.value
              .where(
                (index) =>
                    index >= 0 && index < ejercicio.palabras[entry.key].length,
              )
              .map(
                (index) =>
                    'Palabra ${entry.key + 1}: ${ejercicio.palabras[entry.key][index]}',
              ),
        )
        .toList();

    showDialog(
      context: localContext,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(ejercicio.titulo),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ejercicio.colorLetras, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: ImagenEjercicioWidget(
                    imagenPath: ejercicio.imagenPath,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Acróstico
              Row(
                children: [
                  const Text(
                    'Acróstico: ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: ejercicio.letrasAcrostico
                        .split('')
                        .map(
                          (letra) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ejercicio.colorLetras,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(
                              letra,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 2,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Palabras
              Text(
                'Palabras (${ejercicio.palabras.length}):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ejercicio.palabras
                    .map(
                      (palabra) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $palabra',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 8),

              // Configuración
              Text(
                'Color: ${_obtenerNombreColor(ejercicio.colorLetras)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),

              // Mostrar letras ocultas por palabra (solo las que tienen letra oculta)
              if (letrasOcultasInfo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Letras ocultas: ${letrasOcultasInfo.join(", ")}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],

              const SizedBox(height: 8),

              // Pista
              if (ejercicio.pista.isNotEmpty) ...[
                Text(
                  'Pista: ${ejercicio.pista}',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Asignación
              Text(
                'Asignado a: ${ejercicio.esParaTodos ? 'Todos los alumnos' : '${ejercicio.alumnosAsignados.length} alumnos'}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _obtenerNombreColor(Color color) {
    // Comparar con colores comunes
    final colores = {
      Colors.red: 'Rojo',
      Colors.orange: 'Naranja',
      Colors.yellow: 'Amarillo',
      Colors.green: 'Verde',
      Colors.blue: 'Azul',
      const Color(0xFF6A1B9A): 'Morado',
      Colors.pink: 'Rosa',
      Colors.teal: 'Verde azulado',
      Colors.indigo: 'Índigo',
    };

    for (final entry in colores.entries) {
      if (entry.key == color) {
        return entry.value;
      }
    }

    return 'Personalizado';
  }

  @override
  Widget build(BuildContext context) {
    if (!UsuarioRepository.esMaestraLogueada &&
        UsuarioRepository.alumnoActual == null) {
      return const AccesoMaestraDenegado();
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Lista de Acrósticos',
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6A1B9A)),
            onPressed: () {
              _playSound();
              _cargarEjercicios();
            },
            tooltip: 'Recargar lista',
          ),
        ],
      ),
      floatingActionButton: UsuarioRepository.esMaestraLogueada
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              onPressed: () {
                _playSound();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CrearAcrosticoScreen(),
                  ),
                ).then((_) => _cargarEjercicios());
              },
              tooltip: 'Crear nuevo acróstico',
              child: const Icon(Icons.add, size: 32),
            )
          : null,
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
                ),
              )
            : _ejercicios.isEmpty
            ? _buildListaVacia()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.separated(
                  itemCount: _ejercicios.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ejercicio = _ejercicios[index];
                    return _buildCardEjercicio(ejercicio);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildListaVacia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_fields, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              UsuarioRepository.esMaestraLogueada
                  ? 'No hay acrósticos creados aún'
                  : 'No hay acrósticos asignados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              UsuarioRepository.esMaestraLogueada
                  ? 'Presiona el botón + para crear tu primer acróstico'
                  : 'Pide a tu maestra que te asigne un acróstico.',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardEjercicio(AcrosticoEjercicio ejercicio) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _playSound();
          if (UsuarioRepository.esMaestraLogueada) {
            _mostrarDetallesEjercicio(ejercicio);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JugarAcrosticoScreen(acrostico: ejercicio),
              ),
            );
          }
        },
        onLongPress: UsuarioRepository.esMaestraLogueada
            ? () => _confirmarEliminarEjercicio(ejercicio)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ejercicio.colorLetras, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ImagenEjercicioWidget(
                    imagenPath: ejercicio.imagenPath,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      ejercicio.titulo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Acróstico
                    Wrap(
                      spacing: 4,
                      children: ejercicio.letrasAcrostico
                          .split('')
                          .map(
                            (letra) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ejercicio.colorLetras,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                letra,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 1,
                                      offset: Offset(0.5, 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 4),

                    // Número de palabras
                    Text(
                      '${ejercicio.palabras.length} palabras • ${ejercicio.esParaTodos ? 'Todos' : 'Específicos'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),

                    if (ejercicio.pista.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Pista: ${ejercicio.pista}',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Acciones
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón de jugar
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    onPressed: () {
                      _playSound();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              JugarAcrosticoScreen(
                                acrostico: ejercicio,
                                modoPrueba:
                                    UsuarioRepository.esMaestraLogueada,
                              ),
                        ),
                      );
                    },
                    tooltip: 'Jugar',
                  ),
                  const SizedBox(height: 4),

                  // Botón de eliminar - Más visible
                  if (UsuarioRepository.esMaestraLogueada)
                    IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red[300]!, width: 2),
                        ),
                      child: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    onPressed: () => _confirmarEliminarEjercicio(ejercicio),
                    tooltip: 'Eliminar acróstico',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
