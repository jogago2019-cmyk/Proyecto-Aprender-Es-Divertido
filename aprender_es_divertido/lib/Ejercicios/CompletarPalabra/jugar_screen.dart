import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aprender_es_divertido/models/completar_palabra_model.dart';
import 'package:aprender_es_divertido/models/user_model.dart';
import 'package:aprender_es_divertido/models/menu_principal.dart';
import 'package:aprender_es_divertido/widgets/imagen_ejercicio_widget.dart';
import 'package:aprender_es_divertido/services/imagen_service.dart';
import 'package:aprender_es_divertido/services/estadistica_service.dart';

class JugarCompletarPalabraScreen extends StatefulWidget {
  final CompletarPalabraEjercicio? ejercicio;
  final bool modoPrueba;

  const JugarCompletarPalabraScreen({
    super.key,
    this.ejercicio,
    this.modoPrueba = false,
  });

  @override
  State<JugarCompletarPalabraScreen> createState() =>
      _JugarCompletarPalabraScreenState();
}

class _JugarCompletarPalabraScreenState
    extends State<JugarCompletarPalabraScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;

  // Estado del juego
  List<CompletarPalabraEjercicio> _ejercicios = [];
  int _indiceActual = 0;
  bool _mostrarResultado = false;
  bool _esCorrecto = false;
  bool _usarPista = false;
  int _letrasColoreadasHasta = 0;

  // Respuestas del alumno: mapa de posicion -> letra
  Map<int, String> _respuestasAlumno = {};
  // Guarda qué ficha física del banco se usó en cada posición.
  Map<int, int> _fichaPorPosicion = {};
  int? _posicionSeleccionada;
  List<String> _opcionesLetras = [];

  // Letra incorrecta seleccionada (para animación)
  String? _letraIncorrectaAnimando;

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
    await CompletarPalabraRepository.init();

    // Obtener ejercicios filtrados por alumno
    final alumnoId = UsuarioRepository.alumnoActual?.id;
    final ejercicios = widget.ejercicio != null
        ? [widget.ejercicio!]
        : CompletarPalabraRepository.getEjerciciosParaAlumno(alumnoId);

    if (mounted) {
      setState(() {
        _ejercicios = ejercicios;
        _indiceActual = 0;
        _respuestasAlumno = {};
        _fichaPorPosicion = {};
        _posicionSeleccionada = null;
        _opcionesLetras = ejercicios.isEmpty
            ? []
            : _crearLetrasOpciones(ejercicios.first);
        _mostrarResultado = false;
        _usarPista = false;
        _letrasColoreadasHasta = 0;
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

  void _seleccionarFicha(int posicion, int indiceFicha) {
    _playSound();
    setState(() {
      _respuestasAlumno[posicion] = _opcionesLetras[indiceFicha];
      _fichaPorPosicion[posicion] = indiceFicha;

      final posiciones = _ejercicios[_indiceActual].posicionesFaltantes;
      final siguientes = [
        ...posiciones.where((pos) => pos > posicion),
        ...posiciones.where((pos) => pos <= posicion),
      ];
      _posicionSeleccionada = null;
      for (final siguiente in siguientes) {
        if (!_respuestasAlumno.containsKey(siguiente)) {
          _posicionSeleccionada = siguiente;
          break;
        }
      }

      // Si se está mostrando un resultado incorrecto, ocultarlo para permitir seguir intentando
      if (_mostrarResultado && !_esCorrecto) {
        _mostrarResultado = false;
      }
    });
  }

  void _seleccionarPosicionFaltante(int posicion) {
    if (_mostrarResultado && _esCorrecto) return;
    setState(() {
      _posicionSeleccionada = posicion;
      if (_mostrarResultado && !_esCorrecto) {
        _mostrarResultado = false;
      }
    });
  }

  void _borrarLetraSeleccionada() {
    final posicion = _posicionSeleccionada;
    if (posicion == null || !_respuestasAlumno.containsKey(posicion)) return;

    _playSound();
    setState(() {
      _respuestasAlumno.remove(posicion);
      _fichaPorPosicion.remove(posicion);
      if (_mostrarResultado && !_esCorrecto) {
        _mostrarResultado = false;
      }
    });
  }

  Future<void> _verificarRespuesta() async {
    final ejercicioActual = _ejercicios[_indiceActual];

    // Verificar si el alumno ha respondido a todas las posiciones faltantes
    if (_respuestasAlumno.length < ejercicioActual.posicionesFaltantes.length) {
      _mostrarMensaje(
        'Por favor, selecciona letras para todas las posiciones faltantes',
      );
      return;
    }

    final esCorrecto = ejercicioActual.sonLetrasCorrectas(_respuestasAlumno);
    final respuestaCompleta = ejercicioActual.palabraCompleta.split('');
    for (final posicion in ejercicioActual.posicionesFaltantes) {
      if (posicion >= 0 &&
          posicion < respuestaCompleta.length &&
          _respuestasAlumno.containsKey(posicion)) {
        respuestaCompleta[posicion] = _respuestasAlumno[posicion]!;
      }
    }
    if (!widget.modoPrueba) {
      await EstadisticaService.registrarRespuesta(
        context,
        actividad: 'Completar palabra',
        titulo: 'Completar: ${ejercicioActual.palabraParaAlumno}',
        pregunta: 'Completa las letras faltantes',
        respuesta: respuestaCompleta.join(),
        respuestaCorrecta: ejercicioActual.palabraCompleta,
        esCorrecta: esCorrecto,
      );
    }
    if (!mounted) return;

    setState(() {
      _esCorrecto = esCorrecto;
      _mostrarResultado = true;
      _letrasColoreadasHasta = 0;
    });

    if (esCorrecto) {
      unawaited(_animarPalabraCompleta(ejercicioActual.palabraCompleta.length));
    }

    _playSound();
  }

  Future<void> _animarPalabraCompleta(int cantidadLetras) async {
    for (var cantidadColoreada = 1;
        cantidadColoreada <= cantidadLetras;
        cantidadColoreada++) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() {
        _letrasColoreadasHasta = cantidadColoreada;
      });
    }
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
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _cargarEjercicios(); // Reiniciar el juego
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
    ScaffoldMessenger.of(
      customContext ?? context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
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
    setState(() {
      _indiceActual++;
      _respuestasAlumno = {};
      _fichaPorPosicion = {};
      _posicionSeleccionada = null;
      _opcionesLetras = _indiceActual < _ejercicios.length
          ? _crearLetrasOpciones(_ejercicios[_indiceActual])
          : [];
      _mostrarResultado = false;
      _usarPista = false;
      _letrasColoreadasHasta = 0;
    });

    // Verificar si hemos terminado
    if (_indiceActual >= _ejercicios.length) {
      _mostrarFelicitaciones();
    }
  }

  void _confirmarEliminarEjercicio(CompletarPalabraEjercicio ejercicio) {
    if (!UsuarioRepository.esMaestraLogueada) return;
    final localContext = context;
    showDialog(
      context: localContext,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Eliminar Ejercicio'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el ejercicio "${ejercicio.palabraCompleta}"?',
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
              await CompletarPalabraRepository.eliminarEjercicio(ejercicio.id);

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

  // Obtener las letras disponibles para el alumno
  List<String> _crearLetrasOpciones(CompletarPalabraEjercicio ejercicio) {
    final letrasCorrectas = ejercicio.letrasFaltantes
        .map((l) => l.toUpperCase())
        .toList();
    final abecedario = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ'.split('');

    // Crear opciones: letras correctas + letras aleatorias
    final opciones = <String>[];
    opciones.addAll(letrasCorrectas);

    // Añadir letras aleatorias (evitar duplicados)
    final abecedarioFiltrado = abecedario
        .where((l) => !letrasCorrectas.contains(l))
        .toList();
    abecedarioFiltrado.shuffle();

    // Añadir suficientes letras para tener un teclado completo (4 filas x 4-5 letras = ~16-20)
    final letrasAdicionales = abecedarioFiltrado.take(
      min(16 - letrasCorrectas.length, abecedarioFiltrado.length),
    );
    opciones.addAll(letrasAdicionales);

    // Mezclar las opciones
    opciones.shuffle();

    return opciones;
  }

  bool _estaFichaSeleccionada(int indiceFicha) {
    return _fichaPorPosicion.values.contains(indiceFicha);
  }

  // Contador de casillas logradas
  Widget _buildContadorCasillas(CompletarPalabraEjercicio ejercicio) {
    final totalFaltantes = ejercicio.posicionesFaltantes.length;
    final correctas = ejercicio.posicionesFaltantes.where((pos) {
      final letraRespuesta = _respuestasAlumno[pos];
      if (letraRespuesta == null) return false;
      return ejercicio.esLetraCorrectaEnPosicion(pos, letraRespuesta);
    }).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Círculo verde con icono
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          'Casillas logradas',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$correctas / $totalFaltantes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTecladoLetras(
    CompletarPalabraEjercicio ejercicio,
    List<String> opciones,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: List.generate(opciones.length, (indiceFicha) {
        final letra = opciones[indiceFicha];
        final estaSeleccionada = _estaFichaSeleccionada(indiceFicha);
        final esCorrecta = ejercicio.letrasFaltantes
            .map((letraFaltante) => letraFaltante.toUpperCase())
            .contains(letra);
        final circleColor = _usarPista && esCorrecta
            ? const Color(0xFF5D4037)
            : const Color(0xFFE1F5FE);

        return _buildBotonLetraTeclado(
          letra: letra,
          estaSeleccionada: estaSeleccionada,
          circleColor: circleColor,
          onTap: () => _seleccionarFichaParaPosicion(indiceFicha),
        );
      }).toList(),
    );
  }

  Widget _buildBotonLetraTeclado({
    required String letra,
    required bool estaSeleccionada,
    required Color circleColor,
    required VoidCallback onTap,
  }) {
    final bool estaAnimando = _letraIncorrectaAnimando == letra;
    final textColor = circleColor == const Color(0xFF5D4037)
        ? Colors.white
        : const Color(0xFF1976D2);

    return GestureDetector(
      onTap: (_mostrarResultado && _esCorrecto) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: estaAnimando
            ? Matrix4.translationValues(0, -10, 0)
            : Matrix4.identity(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: estaSeleccionada ? Colors.green : circleColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: estaSeleccionada ? Colors.green : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              letra,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: estaSeleccionada ? Colors.white : textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_ejercicios.isEmpty) {
      return _buildSinEjercicios();
    }

    final ejercicio = _ejercicios[_indiceActual];
    final opciones = _opcionesLetras;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1F5FE),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Completar Palabra (${_indiceActual + 1}/${_ejercicios.length})',
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
              // Imagen
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4FC3F7), width: 3),
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

              // Contador de casillas logradas
              _buildContadorCasillas(ejercicio),
              const SizedBox(height: 16),

              // Botón de pista
              if (!_usarPista) ...[
                TextButton.icon(
                  onPressed: _mostrarPista,
                  icon: const Icon(
                    Icons.help,
                    color: Color(0xFF0288D1),
                    size: 18,
                  ),
                  label: const Text(
                    'Pista mágica',
                    style: TextStyle(color: Color(0xFF0288D1), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Palabra para completar con espacios para las letras faltantes
              Text(
                'Completa las letras que faltan usando las fichas de abajo para descubrir la palabra secreta.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Mostrar la palabra con espacios para elegir letras
              Align(
                alignment: Alignment.centerLeft,
                child: _buildPalabraInteractiva(ejercicio),
              ),
              const SizedBox(height: 8),
              Text(
                _posicionSeleccionada == null
                    ? 'Toca una casilla vacía para elegir dónde poner la letra.'
                    : 'Casilla ${ejercicio.posicionesFaltantes.indexOf(_posicionSeleccionada!) + 1} seleccionada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              TextButton.icon(
                onPressed:
                    (_mostrarResultado && _esCorrecto) ||
                        _posicionSeleccionada == null ||
                        !_respuestasAlumno.containsKey(_posicionSeleccionada)
                    ? null
                    : _borrarLetraSeleccionada,
                icon: const Icon(Icons.backspace_outlined),
                label: const Text('Borrar letra de esta casilla'),
              ),
              const SizedBox(height: 24),

              // Opciones de letras
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Toca o arrastra una letra:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Text(
                    'Banco disponible',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Teclado de letras en forma de matriz
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFB3E5FC), width: 2),
                ),
                padding: const EdgeInsets.all(12),
                child: _buildTecladoLetras(ejercicio, opciones),
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
                                  _respuestasAlumno = {};
                                  _fichaPorPosicion = {};
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

  Widget _buildPalabraInteractiva(CompletarPalabraEjercicio ejercicio) {
    final palabra = ejercicio.palabraCompleta;
    final posicionesFaltantes = ejercicio.posicionesFaltantes;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(palabra.length, (index) {
          final esFaltante = posicionesFaltantes.contains(index);
          final letraRespuesta = _respuestasAlumno[index];
          final estaSeleccionada = _posicionSeleccionada == index;
          final letra = palabra[index].toUpperCase();
          final esCorrecta =
              letraRespuesta != null &&
              ejercicio.letrasFaltantes
                  .map((l) => l.toUpperCase())
                  .contains(letraRespuesta.toUpperCase());

          return Semantics(
            button: esFaltante,
            label: esFaltante
                ? 'Casilla ${index + 1}${letraRespuesta == null ? ', vacía' : ', letra ${letraRespuesta.toUpperCase()}'}'
                : 'Letra $letra',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: esFaltante
                    ? () => _seleccionarPosicionFaltante(index)
                    : null,
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _debeColorearLetra(
                      index: index,
                      letraRespuesta: letraRespuesta,
                      esCorrecta: esCorrecta,
                    )
                        ? Colors.green
                        : esFaltante
                        ? const Color(0xFFE3F2FD)
                        : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(158, 158, 158, 0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: estaSeleccionada
                          ? const Color(0xFFFFA000)
                          : esFaltante && letraRespuesta == null
                          ? const Color(0xFF2196F3)
                          : Colors.transparent,
                      width: estaSeleccionada ? 3 : 2,
                    ),
                  ),
                  child: Center(
                    child: !esFaltante
                        ? Text(
                            letra,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: index < _letrasColoreadasHasta
                                  ? Colors.white
                                  : const Color(0xFF1976D2),
                            ),
                          )
                        : letraRespuesta != null
                        ? Text(
                            letraRespuesta.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  bool _debeColorearLetra({
    required int index,
    required String? letraRespuesta,
    required bool esCorrecta,
  }) {
    return index < _letrasColoreadasHasta ||
        (!_mostrarResultado && letraRespuesta != null && esCorrecta);
  }

  void _seleccionarFichaParaPosicion(int indiceFicha) {
    final ejercicio = _ejercicios[_indiceActual];

    final posicionSeleccionada = _posicionSeleccionada;
    if (posicionSeleccionada != null) {
      _seleccionarFicha(posicionSeleccionada, indiceFicha);
      return;
    }

    // Si no se eligió una casilla explícitamente, llenar la primera vacía.
    for (final pos in ejercicio.posicionesFaltantes) {
      if (!_respuestasAlumno.containsKey(pos)) {
        _seleccionarFicha(pos, indiceFicha);
        return;
      }
    }
  }

  Widget _buildSinEjercicios() {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1F5FE),
        elevation: 0,
        title: const Text(
          'Completar Palabra',
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
