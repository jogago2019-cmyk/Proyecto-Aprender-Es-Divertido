import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aprender_es_divertido/models/ordenar_palabras_model.dart';
import 'package:aprender_es_divertido/models/user_model.dart';
import 'package:aprender_es_divertido/models/menu_principal.dart';
import 'package:aprender_es_divertido/widgets/imagen_ejercicio_widget.dart';
import 'package:aprender_es_divertido/services/imagen_service.dart';
import 'package:aprender_es_divertido/services/estadistica_service.dart';

class JugarOrdenarPalabraScreen extends StatefulWidget {
  final OrdenarPalabraEjercicio? ejercicio;
  final bool modoPrueba;

  const JugarOrdenarPalabraScreen({
    super.key,
    this.ejercicio,
    this.modoPrueba = false,
  });

  @override
  State<JugarOrdenarPalabraScreen> createState() =>
      _JugarOrdenarPalabraScreenState();
}

class _JugarOrdenarPalabraScreenState extends State<JugarOrdenarPalabraScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;

  // Estado del juego
  List<OrdenarPalabraEjercicio> _ejercicios = [];
  int _indiceActual = 0;
  bool _mostrarResultado = false;
  bool _esCorrecto = false;
  bool _usarPista = false;
  bool _mostrarImagen = false;

  // Cada elemento guarda el índice de la letra colocada en esa posición.
  List<int?> _respuestaPorPosicion = [];
  int? _posicionSeleccionada;

  String get _respuestaAlumno {
    final letras = _obtenerLetrasDesordenadas();
    return _respuestaPorPosicion
        .map((indice) => indice == null ? '' : letras[indice])
        .join();
  }

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
    // Asegurarse de que el repositorio esté inicializado
    await OrdenarPalabraRepository.init();

    // Obtener ejercicios filtrados por alumno
    final alumnoId = UsuarioRepository.alumnoActual?.id;
    final ejercicios = widget.ejercicio != null
        ? [widget.ejercicio!]
        : OrdenarPalabraRepository.getEjerciciosParaAlumno(alumnoId);

    if (mounted) {
      setState(() {
        _ejercicios = ejercicios;
        _indiceActual = 0;
        _respuestaPorPosicion = ejercicios.isEmpty
            ? []
            : List<int?>.filled(
                ejercicios.first.palabraDesordenada.length,
                null,
              );
        _posicionSeleccionada = null;
        _mostrarResultado = false;
        _usarPista = false;
        _mostrarImagen = false; // Inicialmente la imagen no se muestra
      });

      // Mostrar mensaje si no hay ejercicios
      if (ejercicios.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _mostrarMensajeSinEjercicios();
        });
      }
    }
  }

  void _mostrarMensajeSinEjercicios() {
    final localContext = context;
    showDialog(
      context: localContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No hay ejercicios'),
        content: const Text(
          'No se han creado ejercicios aún. Pide a tu maestra que cree ejercicios en el Taller de Contenido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
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

  void _seleccionarPosicion(int posicion) {
    if (_mostrarResultado && _esCorrecto) return;
    setState(() {
      _posicionSeleccionada = posicion;
      if (_mostrarResultado && !_esCorrecto) {
        _mostrarResultado = false;
      }
    });
  }

  void _agregarLetraARespuesta(int indiceLetra) {
    if (_respuestaPorPosicion.contains(indiceLetra)) return;

    final posicion =
        _posicionSeleccionada ??
        _respuestaPorPosicion.indexWhere((indice) => indice == null);
    if (posicion < 0 || posicion >= _respuestaPorPosicion.length) return;

    _playSound();
    setState(() {
      _respuestaPorPosicion[posicion] = indiceLetra;
      final siguientePosicion = _respuestaPorPosicion.indexWhere(
        (indice) => indice == null,
      );
      _posicionSeleccionada = siguientePosicion < 0 ? null : siguientePosicion;
      if (_mostrarResultado && !_esCorrecto) {
        _mostrarResultado = false;
      }
    });
  }

  void _eliminarLetraSeleccionada() {
    final posicion = _posicionSeleccionada;
    if (posicion == null || _respuestaPorPosicion[posicion] == null) return;

    _playSound();
    setState(() {
      _respuestaPorPosicion[posicion] = null;
      if (_mostrarResultado && !_esCorrecto) {
        _mostrarResultado = false;
      }
    });
  }

  Future<void> _verificarRespuesta() async {
    final ejercicioActual = _ejercicios[_indiceActual];

    if (_respuestaPorPosicion.any((indice) => indice == null)) {
      _mostrarMensaje('Completa todos los espacios antes de verificar');
      return;
    }

    final esCorrecto = ejercicioActual.esPalabraCorrecta(_respuestaAlumno);
    if (!widget.modoPrueba) {
      await EstadisticaService.registrarRespuesta(
        context,
        actividad: 'Ordenar palabras',
        titulo: 'Ordena: ${ejercicioActual.palabraDesordenada}',
        pregunta: 'Ordena las letras para formar la palabra',
        respuesta: _respuestaAlumno,
        respuestaCorrecta: ejercicioActual.palabraCorrecta,
        esCorrecta: esCorrecto,
      );
    }
    if (!mounted) return;

    setState(() {
      _esCorrecto = esCorrecto;
      _mostrarResultado = true;
      _mostrarImagen = esCorrecto; // Mostrar imagen solo si es correcto
    });

    _playSound();
  }

  void _mostrarFelicitaciones() {
    final localContext = context;
    showDialog(
      context: localContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¡Felicidades!'),
        content: Text(
          'Has completado todos los ejercicios de forma correcta. Has respondido ${_ejercicios.length} ejercicios.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _cargarEjercicios(); // Reiniciar el juego
            },
            child: const Text('Jugar de nuevo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _volverAlMenuPrincipal();
            },
            child: const Text('Volver al menú principal'),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(String mensaje, [BuildContext? customContext]) {
    if (mounted) {
      ScaffoldMessenger.of(
        customContext ?? context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  void _volverAlMenuPrincipal() {
    if (widget.modoPrueba) {
      Navigator.pop(context);
      return;
    }

    // Navegar al menu principal, eliminando todas las pantallas anteriores
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MenuPrincipal()),
      (Route<dynamic> route) => false,
    );
  }

  void _siguienteEjercicioManual() {
    _playSound();
    final siguienteIndice = _indiceActual + 1;
    if (siguienteIndice >= _ejercicios.length) {
      _mostrarFelicitaciones();
      return;
    }

    setState(() {
      _indiceActual = siguienteIndice;
      _respuestaPorPosicion = List<int?>.filled(
        _ejercicios[_indiceActual].palabraDesordenada.length,
        null,
      );
      _posicionSeleccionada = null;
      _mostrarResultado = false;
      _usarPista = false;
      _mostrarImagen = false; // Reiniciar para el siguiente ejercicio
    });
  }

  void _confirmarEliminarEjercicio(OrdenarPalabraEjercicio ejercicio) {
    if (!UsuarioRepository.esMaestraLogueada) return;
    final localContext = context;
    showDialog(
      context: localContext,
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
              // Intentar eliminar la imagen
              try {
                await ImagenService.eliminarImagen(ejercicio.imagenPath);
              } catch (e) {
                // Ignorar error si no se puede eliminar la imagen
              }

              // Eliminar el ejercicio
              await OrdenarPalabraRepository.eliminarEjercicio(ejercicio.id);

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              if (!mounted) return;
              _playSound();

              // Si este era el ultimo ejercicio, volver al menu
              if (_ejercicios.length <= 1) {
                Navigator.pop(context);
              } else {
                // Recargar ejercicios y continuar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ejercicio eliminado')),
                );
                await _cargarEjercicios();
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _mostrarPista() {
    setState(() {
      _usarPista = true;
    });
    _playSound();
  }

  int? _obtenerIndiceLetraPista(List<String> letras) {
    final palabra = _ejercicios[_indiceActual].palabraCorrecta.toUpperCase();
    final letrasColocadas = _respuestaPorPosicion
        .whereType<int>()
        .map((indice) => letras[indice].toUpperCase())
        .toList();
    final letrasNecesarias = <String, int>{};

    for (final letra in palabra.split('')) {
      letrasNecesarias[letra] = (letrasNecesarias[letra] ?? 0) + 1;
      final cantidadColocada = letrasColocadas
          .where((colocada) => colocada == letra)
          .length;
      if (cantidadColocada < letrasNecesarias[letra]!) {
        for (var indice = 0; indice < letras.length; indice++) {
          if (!_respuestaPorPosicion.contains(indice) &&
              letras[indice].toUpperCase() == letra) {
            return indice;
          }
        }
      }
    }
    return null;
  }

  // Obtener las letras desordenadas para mostrar como opciones
  List<String> _obtenerLetrasDesordenadas() {
    final ejercicio = _ejercicios[_indiceActual];
    final palabra = ejercicio.palabraDesordenada;
    return palabra.isNotEmpty ? palabra.split('') : [];
  }

  @override
  Widget build(BuildContext context) {
    if (_ejercicios.isEmpty) {
      return _buildSinEjercicios();
    }

    final ejercicio = _ejercicios[_indiceActual];
    final letrasDesordenadas = _obtenerLetrasDesordenadas();
    final indiceLetraPista = _usarPista
        ? _obtenerIndiceLetraPista(letrasDesordenadas)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1F5FE),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Ordenar Palabra (${_indiceActual + 1}/${_ejercicios.length})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0288D1),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0288D1)),
          onPressed: () {
            _playSound();
            Navigator.pop(context);
          },
        ),
        actions: [
          // Botón para eliminar el ejercicio actual (solo visible en modo individual)
          if (UsuarioRepository.esMaestraLogueada && !widget.modoPrueba)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarEliminarEjercicio(ejercicio),
              tooltip: 'Eliminar ejercicio',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen - solo se muestra después de respuesta correcta
              if (_mostrarImagen) ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4FC3F7),
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: ImagenEjercicioWidget(
                      imagenPath: ejercicio.imagenPath,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                // Espacio reservado para la imagen (mismo tamaño)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 3),
                    color: Colors.grey[100],
                  ),
                  child: Center(
                    child: Text(
                      '¿Qué es?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Instrucción
              Text(
                'Ordena las letras para formar la palabra:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),

              // Palabra desordenada a ordenar
              Text(
                ejercicio.palabraDesordenada.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0288D1),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),

              // Pista
              if (_usarPista) ...[
                const Text(
                  'Una letra correcta está resaltada; tú decides dónde colocarla.',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF039BE5),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (ejercicio.pista.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Pista: ${ejercicio.pista}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF039BE5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Botón de pista
              if (!_usarPista) ...[
                TextButton.icon(
                  onPressed: _mostrarPista,
                  icon: const Icon(Icons.help, color: Color(0xFF0288D1)),
                  label: const Text(
                    '¿Necesitas una pista?',
                    style: TextStyle(color: Color(0xFF0288D1)),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 24),

              // Campo de respuesta
              Text(
                'Escribe la palabra ordenada:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Posiciones de la respuesta: selecciona una para colocar o borrar una letra.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(letrasDesordenadas.length, (posicion) {
                  final indiceLetra = _respuestaPorPosicion[posicion];
                  final seleccionada = _posicionSeleccionada == posicion;
                  return Semantics(
                    button: true,
                    label: indiceLetra == null
                        ? 'Espacio ${posicion + 1}, vacío'
                        : 'Espacio ${posicion + 1}, letra ${letrasDesordenadas[indiceLetra].toUpperCase()}',
                    child: InkWell(
                      onTap: (_mostrarResultado && _esCorrecto)
                          ? null
                          : () => _seleccionarPosicion(posicion),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 56,
                        decoration: BoxDecoration(
                          color: seleccionada
                              ? const Color(0xFFFFF3CD)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: seleccionada
                                ? const Color(0xFFFFA000)
                                : const Color(0xFF4FC3F7),
                            width: seleccionada ? 3 : 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          indiceLetra == null
                              ? '_'
                              : letrasDesordenadas[indiceLetra].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0288D1),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona cualquier espacio y luego toca la letra que quieres colocar. '
                'Si el espacio ya tiene una letra, puedes reemplazarla.',
                textAlign: TextAlign.center,
              ),
              TextButton.icon(
                onPressed:
                    (_mostrarResultado && _esCorrecto) ||
                        _posicionSeleccionada == null ||
                        _respuestaPorPosicion[_posicionSeleccionada!] == null
                    ? null
                    : _eliminarLetraSeleccionada,
                icon: const Icon(Icons.backspace_outlined),
                label: const Text('Borrar letra del espacio seleccionado'),
              ),
              const SizedBox(height: 24),

              // Teclado de letras
              Text(
                'Toca las letras para formar la palabra:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Botones de letras desordenadas
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(letrasDesordenadas.length, (indice) {
                  final letra = letrasDesordenadas[indice];
                  return _buildBotonLetra(
                    letra: letra.toUpperCase(),
                    usada: _respuestaPorPosicion.contains(indice),
                    resaltada: indiceLetraPista == indice,
                    onTap: () => _agregarLetraARespuesta(indice),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Botón verificar
              ElevatedButton(
                onPressed: _verificarRespuesta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'VERIFICAR RESPUESTA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Mensaje de resultado
              if (_mostrarResultado) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: _esCorrecto
                        ? Colors.green[100]
                        : const Color(0xFFB3E5FC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _esCorrecto
                          ? Colors.green
                          : const Color(0xFF4FC3F7),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _esCorrecto
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '¡Correcto!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_indiceActual < _ejercicios.length - 1)
                                  ElevatedButton(
                                    onPressed: _siguienteEjercicioManual,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0288D1),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: const Text(
                                      'Siguiente ejercicio',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _volverAlMenuPrincipal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[600],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Volver al menú',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.thumb_up,
                                  color: Color(0xFF0288D1),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '¡Sigue intentándolo, tú puedes!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0288D1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                _playSound();
                                setState(() {
                                  _respuestaPorPosicion = List<int?>.filled(
                                    letrasDesordenadas.length,
                                    null,
                                  );
                                  _posicionSeleccionada = null;
                                  _mostrarResultado = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4FC3F7),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Intentar de nuevo',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonLetra({
    required String letra,
    required bool usada,
    required bool resaltada,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: (_mostrarResultado && _esCorrecto) || usada ? null : onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: usada
              ? Colors.grey[300]
              : resaltada
              ? const Color(0xFFFFF59D)
              : Colors.grey[100]!,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: resaltada && !usada
                ? const Color(0xFFFFA000)
                : Colors.grey[400]!,
            width: resaltada && !usada ? 3 : 2,
          ),
        ),
        child: Center(
          child: Text(
            letra,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: usada ? Colors.grey[600] : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSinEjercicios() {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1F5FE),
        elevation: 0,
        title: const Text(
          'Ordenar Palabra',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0288D1),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0288D1)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'No hay ejercicios disponibles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Pide a tu maestra que cree ejercicios en el Taller de Contenido.',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver al menú'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
