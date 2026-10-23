import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aprender_es_divertido/models/acrostico_model.dart';
import 'package:aprender_es_divertido/models/user_model.dart';
import 'package:aprender_es_divertido/models/menu_principal.dart';
import 'package:aprender_es_divertido/widgets/imagen_ejercicio_widget.dart';
import 'package:aprender_es_divertido/services/imagen_service.dart';
import 'package:aprender_es_divertido/services/estadistica_service.dart';

class JugarAcrosticoScreen extends StatefulWidget {
  final AcrosticoEjercicio? acrostico;
  final bool modoPrueba;

  const JugarAcrosticoScreen({
    super.key,
    this.acrostico,
    this.modoPrueba = false,
  });

  @override
  State<JugarAcrosticoScreen> createState() => _JugarAcrosticoScreenState();
}

class _JugarAcrosticoScreenState extends State<JugarAcrosticoScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;

  // Estado del juego
  List<AcrosticoEjercicio> _ejercicios = [];
  int _indiceActual = 0;
  bool _mostrarResultado = false;
  bool _esCorrecto = false;
  bool _usarPista = false;
  String? _letraPista;
  int? _palabraSeleccionada;
  int? _letraSeleccionada;

  // Respuestas del alumno - Ahora es una lista de listas de caracteres para manejar posiciones vacías
  List<List<String>> _respuestasAlumno = [];

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
    await AcrosticoRepository.init();

    // Si se proporciona un acrostico específico, usarlo
    if (widget.acrostico != null) {
      if (mounted) {
        setState(() {
          _ejercicios = [widget.acrostico!];
          _indiceActual = 0;
          _respuestasAlumno = _crearRespuestaInicial(widget.acrostico!);
          _mostrarResultado = false;
          _usarPista = false;
          _letraPista = null;
          _palabraSeleccionada = null;
          _letraSeleccionada = null;
        });
      }
      return;
    }

    // De lo contrario, cargar ejercicios para el alumno actual
    final alumnoId = UsuarioRepository.alumnoActual?.id;
    final ejercicios = AcrosticoRepository.getEjerciciosParaAlumno(alumnoId);

    if (mounted) {
      setState(() {
        _ejercicios = ejercicios;
        _indiceActual = 0;
        _respuestasAlumno = ejercicios.isNotEmpty
            ? _crearRespuestaInicial(ejercicios.first)
            : [];
        _mostrarResultado = false;
        _usarPista = false;
        _letraPista = null;
        _palabraSeleccionada = null;
        _letraSeleccionada = null;
      });

      if (ejercicios.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _mostrarMensajeSinEjercicios();
        });
      }
    }
  }

  List<List<String>> _crearRespuestaInicial(AcrosticoEjercicio ejercicio) {
    return ejercicio.palabras.asMap().entries.map((entry) {
      final palabraIndex = entry.key;
      final palabra = entry.value;
      return List<String>.generate(
        palabra.length,
        (letraIndex) => ejercicio.estaLetraOculta(palabraIndex, letraIndex)
            ? ''
            : palabra[letraIndex].toUpperCase(),
      );
    }).toList();
  }

  void _mostrarMensajeSinEjercicios() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No hay acrósticos'),
        content: const Text(
          'No se han creado acrósticos aún. Pide a tu maestra que cree acrósticos en el Taller de Contenido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

  void _seleccionarCasilla(int palabraIndex, int letraIndex) {
    if (_mostrarResultado ||
        !_ejercicios[_indiceActual].estaLetraOculta(palabraIndex, letraIndex)) {
      return;
    }

    setState(() {
      _palabraSeleccionada = palabraIndex;
      _letraSeleccionada = letraIndex;
    });
  }

  void _colocarLetra(String letra) {
    if (_mostrarResultado && _esCorrecto) return;

    final ejercicio = _ejercicios[_indiceActual];
    var palabraIndex = _palabraSeleccionada;
    var letraIndex = _letraSeleccionada;

    if (palabraIndex == null ||
        letraIndex == null ||
        !ejercicio.estaLetraOculta(palabraIndex, letraIndex)) {
      final casillaVacia = _buscarCasillaVacia(ejercicio);
      if (casillaVacia == null) return;
      palabraIndex = casillaVacia.$1;
      letraIndex = casillaVacia.$2;
    }

    _playSound();
    setState(() {
      _respuestasAlumno[palabraIndex!][letraIndex!] = letra;
      _palabraSeleccionada = palabraIndex;
      _letraSeleccionada = letraIndex;
      if (_mostrarResultado && !_esCorrecto) {
        _mostrarResultado = false;
      }
    });
  }

  (int, int)? _buscarCasillaVacia(AcrosticoEjercicio ejercicio) {
    for (
      var palabraIndex = 0;
      palabraIndex < ejercicio.palabras.length;
      palabraIndex++
    ) {
      final respuesta = _respuestasAlumno[palabraIndex];
      final indicesOcultos = List<int>.from(
        ejercicio.letrasOcultasPorPalabra[palabraIndex],
      )..sort();
      for (final letraIndex in indicesOcultos) {
        if (respuesta[letraIndex].isEmpty) {
          return (palabraIndex, letraIndex);
        }
      }
    }
    return null;
  }

  void _eliminarLetraDePosicion(int palabraIndex, int letraIndex) {
    _playSound();

    if (_mostrarResultado && _esCorrecto) return;

    setState(() {
      if (palabraIndex < _respuestasAlumno.length &&
          letraIndex < _respuestasAlumno[palabraIndex].length) {
        _respuestasAlumno[palabraIndex][letraIndex] = '';
        _palabraSeleccionada = palabraIndex;
        _letraSeleccionada = letraIndex;
      }
      if (_mostrarResultado && !_esCorrecto) {
        _mostrarResultado = false;
      }
    });
  }

  Future<void> _verificarRespuesta() async {
    final ejercicioActual = _ejercicios[_indiceActual];

    // Convertir _respuestasAlumno (List<List<String>>) a List<String> para el método de verificación
    final respuestasComoStrings = _respuestasAlumno
        .map((listaCaracteres) => listaCaracteres.join())
        .toList();
    final esCorrecto = ejercicioActual.esRespuestaCorrecta(
      respuestasComoStrings,
    );

    if (!widget.modoPrueba) {
      await EstadisticaService.registrarRespuesta(
        context,
        actividad: 'Acróstico',
        titulo: ejercicioActual.titulo,
        pregunta: 'Completa las palabras del acróstico',
        respuesta: respuestasComoStrings.join(', '),
        respuestaCorrecta: ejercicioActual.palabras.join(', '),
        esCorrecta: esCorrecto,
      );
    }
    if (!mounted) return;
    setState(() {
      _esCorrecto = esCorrecto;
      _mostrarResultado = true;
    });

    _playSound();
  }

  void _mostrarFelicitaciones() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Felicidades!'),
        content: Text(
          'Has completado todos los acrósticos de forma correcta. Has respondido ${_ejercicios.length} ejercicios.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cargarEjercicios();
            },
            child: const Text('Jugar de nuevo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.acrostico != null) {
                // Si se está mostrando un acróstico específico, simplemente volver atrás
                Navigator.pop(context);
              } else {
                _volverAlMenuPrincipal();
              }
            },
            child: Text(
              widget.acrostico != null ? 'Volver' : 'Volver al menú principal',
            ),
          ),
        ],
      ),
    );
  }

  void _volverAlMenuPrincipal() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MenuPrincipal()),
      (Route<dynamic> route) => false,
    );
  }

  void _siguienteEjercicioManual() {
    _playSound();
    setState(() {
      _indiceActual++;
      _respuestasAlumno = [];
      _mostrarResultado = false;
      _usarPista = false;
      _letraPista = null;
      _palabraSeleccionada = null;
      _letraSeleccionada = null;
    });

    if (_indiceActual < _ejercicios.length) {
      setState(() {
        _respuestasAlumno = _crearRespuestaInicial(_ejercicios[_indiceActual]);
      });
    }

    if (_indiceActual >= _ejercicios.length) {
      _mostrarFelicitaciones();
    }
  }

  void _confirmarEliminarEjercicio(AcrosticoEjercicio ejercicio) {
    if (!UsuarioRepository.esMaestraLogueada) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Eliminar Acróstico'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el acróstico "${ejercicio.titulo}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ImagenService.eliminarImagen(ejercicio.imagenPath);
              } catch (e) {
                // Ignorar error
              }

              await AcrosticoRepository.eliminarEjercicio(ejercicio.id);

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              if (!mounted) return;
              _playSound();
              if (_ejercicios.length <= 1) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Acróstico eliminado')),
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
    final ejercicio = _ejercicios[_indiceActual];
    final letrasDisponibles = ejercicio.palabras
        .join()
        .toUpperCase()
        .split('')
        .where((letra) => RegExp(r'^[A-ZÑÁÉÍÓÚÜ]$').hasMatch(letra))
        .toSet()
        .toList();
    final letrasAlternativas = letrasDisponibles
        .where((letra) => letra != _letraPista)
        .toList();
    final opciones = letrasAlternativas.isNotEmpty
        ? letrasAlternativas
        : letrasDisponibles;

    setState(() {
      _usarPista = true;
      if (opciones.isNotEmpty) {
        _letraPista = opciones[Random().nextInt(opciones.length)];
      }
    });
    _playSound();
  }

  @override
  Widget build(BuildContext context) {
    if (_ejercicios.isEmpty) {
      return _buildSinEjercicios();
    }

    final ejercicio = _ejercicios[_indiceActual];
    final opciones = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ'.split('');

    // Calcular casillas logradas
    int totalCasillas = 0;
    int casillasCompletadas = 0;
    for (int i = 0; i < ejercicio.palabras.length; i++) {
      final indicesOcultos = ejercicio.letrasOcultasPorPalabra[i];
      final respuesta = i < _respuestasAlumno.length
          ? _respuestasAlumno[i]
          : [];

      totalCasillas += indicesOcultos.length;

      // Contar cuántas posiciones ocultas están completadas
      for (final indice in indicesOcultos) {
        if (indice < respuesta.length && respuesta[indice].isNotEmpty) {
          casillasCompletadas++;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: ejercicio.colorLetras,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.acrostico != null
              ? ejercicio.titulo
              : 'Acrósticos (${_indiceActual + 1}/${_ejercicios.length})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _playSound();
            Navigator.pop(context);
          },
        ),
        actions: [
          // Mostrar botón de eliminar solo si no se está mostrando un acróstico específico
          if (widget.acrostico == null && UsuarioRepository.esMaestraLogueada)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => _confirmarEliminarEjercicio(ejercicio),
              tooltip: 'Eliminar acróstico',
            ),
          IconButton(
            icon: Icon(
              sonidoActivado ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            onPressed: _toggleSonido,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tarjeta Superior (Imagen con Banner e Información del Nivel estilo la Imagen)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Imagen grande con textos superpuestos y botón de audio flotante
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: ImagenEjercicioWidget(
                              imagenPath: ejercicio.imagenPath,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Degradado oscuro para legibilidad
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withAlpha(100),
                                Colors.transparent,
                                Colors.black.withAlpha(150),
                              ],
                            ),
                          ),
                        ),
                        // Título principal dentro de la imagen
                        Positioned(
                          bottom: 12,
                          left: 16,
                          right: 16,
                          child: Text(
                            ejercicio.titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Barra de estadísticas inferior de la tarjeta
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.green[700],
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Casillas logradas',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '$casillasCompletadas / $totalCasillas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Botón Pista mágica
                          ElevatedButton.icon(
                            onPressed: _mostrarPista,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFF8E1),
                              foregroundColor: Colors.amber[800],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.lightbulb, size: 16),
                            label: const Text(
                              'Pista mágica',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          // Botón recargar / reiniciar intento
                          CircleAvatar(
                            backgroundColor: Colors.grey[100],
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                size: 16,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                setState(() {
                                  _respuestasAlumno = _crearRespuestaInicial(
                                    ejercicio,
                                  );
                                  _mostrarResultado = false;
                                  _palabraSeleccionada = null;
                                  _letraSeleccionada = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Banner de Instrucción
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.indigo,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Toca la casilla que quieras completar y luego elige '
                        'una letra. También puedes cambiar una letra tocando '
                        'otra casilla.',
                        style: TextStyle(
                          color: Colors.indigo[900],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_usarPista) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ejercicio.pista.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ejercicio.pista,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_letraPista != null) ...[
                        if (ejercicio.pista.isNotEmpty)
                          const SizedBox(height: 8),
                        Text(
                          'Pista aleatoria: la letra «$_letraPista» aparece '
                          'en alguna palabra.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[900],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Contenedor principal de Palabras del Acróstico estilo Tarjeta Blanca
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _buildPalabrasInteractivasEstiloImagen(ejercicio),
              ),

              const SizedBox(height: 20),

              // Sección de Fichas / Teclado de Opciones de Letras
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _palabraSeleccionada != null &&
                                    _letraSeleccionada != null
                                ? 'Casilla seleccionada: palabra '
                                      '${_palabraSeleccionada! + 1}, letra '
                                      '${_letraSeleccionada! + 1}'
                                : 'Toca una casilla vacía para elegir dónde escribir',
                            style: TextStyle(
                              color: Colors.indigo[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_palabraSeleccionada != null &&
                            _letraSeleccionada != null &&
                            _respuestasAlumno[_palabraSeleccionada!][_letraSeleccionada!]
                                .isNotEmpty)
                          IconButton(
                            tooltip: 'Borrar la casilla seleccionada',
                            onPressed: () => _eliminarLetraDePosicion(
                              _palabraSeleccionada!,
                              _letraSeleccionada!,
                            ),
                            icon: const Icon(Icons.backspace_outlined),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(opciones.length, (index) {
                        final letra = opciones[index];

                        return _buildBotonLetraEstiloImagen(
                          letra: letra,
                          estaSeleccionada: false,
                          puedeSeleccionar: true,
                          onTap: () => _colocarLetra(letra),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botón Verificar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verificarRespuesta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ejercicio.colorLetras,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'VERIFICAR ACRÓSTICO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('FINALIZAR ACTIVIDAD'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ejercicio.colorLetras,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: ejercicio.colorLetras),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Resultados condicionales
              if (_mostrarResultado) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _esCorrecto ? Colors.green[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _esCorrecto ? Colors.green : Colors.blue,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _esCorrecto ? Icons.check_circle : Icons.thumb_up,
                        color: _esCorrecto ? Colors.green : Colors.indigo,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _esCorrecto
                            ? '¡Correcto! El acróstico es: ${ejercicio.letrasAcrostico}'
                            : '¡Sigue intentándolo, tú puedes!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _esCorrecto
                              ? Colors.green[800]
                              : Colors.indigo[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_esCorrecto &&
                              _indiceActual < _ejercicios.length - 1)
                            ElevatedButton(
                              onPressed: _siguienteEjercicioManual,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ejercicio.colorLetras,
                              ),
                              child: const Text(
                                'Siguiente',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          if (!_esCorrecto)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _respuestasAlumno = _crearRespuestaInicial(
                                    ejercicio,
                                  );
                                  _mostrarResultado = false;
                                  _palabraSeleccionada = null;
                                  _letraSeleccionada = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ejercicio.colorLetras,
                              ),
                              child: const Text(
                                'Intentar de nuevo',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
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

  // Widget para construir las filas de palabras interactivas idénticas al estilo de la imagen
  Widget _buildPalabrasInteractivasEstiloImagen(AcrosticoEjercicio ejercicio) {
    final palabras = ejercicio.palabras;
    final respuestasIniciales = _crearRespuestaInicial(ejercicio);

    return Column(
      children: List.generate(palabras.length, (index) {
        final palabra = palabras[index];
        final respuestaActual = _respuestasAlumno.length > index
            ? _respuestasAlumno[index]
            : respuestasIniciales[index];
        final letrasOcultas = ejercicio.posicionesLetrasOcultas;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              // Botón de audio pequeño para cada palabra
              CircleAvatar(
                backgroundColor: const Color(0xFFE3F2FD),
                radius: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.volume_up,
                    size: 14,
                    color: Colors.indigo,
                  ),
                  onPressed: _playSound,
                ),
              ),
              const SizedBox(width: 8),
              // Cajas de letras en fila
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(palabra.length, (letraIndex) {
                    final letraOriginal = palabra[letraIndex];
                    // Verificar si esta letra está oculta (nuevo formato List<List<int>>)
                    final estaQuitada =
                        index < letrasOcultas.length &&
                        letrasOcultas[index].contains(letraIndex);
                    final estaSeleccionada =
                        index == _palabraSeleccionada &&
                        letraIndex == _letraSeleccionada;

                    // Si el usuario ingresó respuesta, la mostramos en la casilla oculta
                    String letraMostrada = '';
                    if (estaQuitada) {
                      if (letraIndex < respuestaActual.length &&
                          respuestaActual[letraIndex].isNotEmpty) {
                        letraMostrada = respuestaActual[letraIndex]
                            .toUpperCase();
                      }
                      // Si está vacía o la respuesta es más corta, letraMostrada se mantiene como ''
                    } else {
                      letraMostrada = letraOriginal.toUpperCase();
                    }

                    // Colores idénticos a la imagen de referencia:
                    // Marrón oscuro para las letras iniciales/fijas, Verde brillante para las adivinadas, Celeste claro para vacías
                    Color bgColor = Colors.white;
                    Color textColor = Colors.black87;
                    Color borderColor = Colors.blue.withAlpha(50);

                    if (!estaQuitada && letraIndex == 0) {
                      // Primera letra fija o destacada (usando el color del ejercicio)
                      bgColor = ejercicio.colorLetras;
                      textColor = Colors.white;
                      borderColor = ejercicio.colorLetras.withAlpha(200);
                    } else if (estaQuitada) {
                      if (letraMostrada.isNotEmpty) {
                        // Letra descubierta por el usuario (Verde brillante)
                        bgColor = const Color(0xFF69F0AE);
                        textColor = Colors.black87;
                        borderColor = const Color(0xFF00E676);
                      } else {
                        // Casilla vacía para completar
                        bgColor = const Color(0xFFE3F2FD);
                        textColor = Colors.transparent;
                        borderColor = Colors.blue.withAlpha(100);
                      }
                    } else {
                      // Letras secundarias visibles normales
                      bgColor = const Color(0xFFE3F2FD);
                      textColor = Colors.black87;
                      borderColor = Colors.blue.withAlpha(60);
                    }
                    if (estaSeleccionada) {
                      borderColor = Colors.orange;
                    }

                    return GestureDetector(
                      onTap: () {
                        _seleccionarCasilla(index, letraIndex);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: estaSeleccionada ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            letraMostrada,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(30),
                                  blurRadius: 2,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Estilo de los botones de letras del teclado inferior
  Widget _buildBotonLetraEstiloImagen({
    required String letra,
    required bool estaSeleccionada,
    required bool puedeSeleccionar,
    required VoidCallback onTap,
  }) {
    Color backgroundColor = Colors.white;
    Color textColor = Colors.indigo;
    Color borderColor = Colors.blue.withAlpha(60);

    if (estaSeleccionada) {
      backgroundColor = const Color(0xFF69F0AE);
      textColor = Colors.black87;
      borderColor = const Color(0xFF00E676);
    } else {
      backgroundColor = const Color(0xFFE3F2FD);
      textColor = Colors.indigo[800]!;
      borderColor = Colors.blue.withAlpha(80);
    }

    return GestureDetector(
      onTap: _mostrarResultado ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            letra,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textColor,
              shadows: [
                Shadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSinEjercicios() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F2FD),
        elevation: 0,
        title: const Text(
          'Acrósticos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6A1B9A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.text_fields, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'No hay acrósticos disponibles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Pide a tu maestra que cree acrósticos en el Taller de Contenido.',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Volver al menú',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
