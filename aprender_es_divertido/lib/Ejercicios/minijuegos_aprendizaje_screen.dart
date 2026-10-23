import 'dart:math';

import 'package:flutter/material.dart';

import '../models/acrostico_model.dart';
import '../models/completar_palabra_model.dart';
import '../models/ordenar_palabras_model.dart';
import '../models/user_model.dart';
import '../services/estadistica_service.dart';
import '../widgets/imagen_ejercicio_widget.dart';

class MinijuegosAprendizajeScreen extends StatefulWidget {
  const MinijuegosAprendizajeScreen({super.key});

  @override
  State<MinijuegosAprendizajeScreen> createState() =>
      _MinijuegosAprendizajeScreenState();
}

class _MinijuegosAprendizajeScreenState
    extends State<MinijuegosAprendizajeScreen> {
  final TextEditingController _respuestaController = TextEditingController();
  final Set<String> _alumnosSeleccionados = {};
  final Map<String, int> _puntajes = {};
  final Random _random = Random();

  late final bool _modoMaestra;
  Alumno? _alumnoIndividual;
  List<Alumno> _jugadores = [];
  List<_ActividadMinijuego> _actividades = [];
  int _indiceActividad = 0;
  int _indiceJugador = 0;
  bool _iniciado = false;
  bool _finalizado = false;
  bool _cargando = false;
  bool _verificando = false;
  bool _respuestaCorrecta = false;
  String? _mensaje;
  String? _respuestaSeleccionada;

  @override
  void initState() {
    super.initState();
    _modoMaestra = UsuarioRepository.esMaestraLogueada;
    if (!_modoMaestra && UsuarioRepository.alumnoActual != null) {
      _alumnoIndividual = UsuarioRepository.alumnoActual;
    }
  }

  @override
  void dispose() {
    _respuestaController.dispose();
    if (_modoMaestra) {
      UsuarioRepository.restaurarModoMaestra();
    }
    super.dispose();
  }

  Future<void> _comenzar() async {
    final jugadores = _modoMaestra
        ? _jugadoresElegidos()
        : _alumnoIndividual == null
        ? <Alumno>[]
        : <Alumno>[_alumnoIndividual!];
    if (jugadores.isEmpty) {
      _mostrarMensaje('Selecciona al menos un estudiante para comenzar.');
      return;
    }

    setState(() {
      _cargando = true;
      _mensaje = null;
    });

    await Future.wait([
      CompletarPalabraRepository.init(),
      OrdenarPalabraRepository.init(),
      AcrosticoRepository.init(),
    ]);
    if (!mounted) return;

    final actividades = _crearActividades(jugadores);
    actividades.shuffle(_random);
    if (actividades.isEmpty) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _mensaje =
            'No hay actividades compartidas para estos alumnos. Asigna ejercicios a todos o elige otro grupo.';
      });
      return;
    }

    final ordenJugadores = [...jugadores];
    if (_modoMaestra &&
        _alumnosSeleccionados.length == UsuarioRepository.alumnos.length) {
      ordenJugadores.shuffle(_random);
    }
    await UsuarioRepository.seleccionarAlumno(ordenJugadores.first);
    if (!mounted) return;
    setState(() {
      _jugadores = ordenJugadores;
      _actividades = actividades;
      _indiceActividad = 0;
      _indiceJugador = 0;
      _puntajes
        ..clear()
        ..addEntries(ordenJugadores.map((alumno) => MapEntry(alumno.id, 0)));
      _iniciado = true;
      _finalizado = false;
      _cargando = false;
      _respuestaCorrecta = false;
      _verificando = false;
      _mensaje = null;
      _respuestaSeleccionada = null;
      _respuestaController.clear();
    });
  }

  List<Alumno> _jugadoresElegidos() {
    if (_alumnoIndividual != null &&
        _alumnosSeleccionados.isEmpty) {
      return [_alumnoIndividual!];
    }
    return UsuarioRepository.alumnos
        .where((alumno) => _alumnosSeleccionados.contains(alumno.id))
        .toList();
  }

  List<_ActividadMinijuego> _crearActividades(List<Alumno> jugadores) {
    final actividades = <_ActividadMinijuego>[];
    bool compartidoPorTodos(String tipo, String id) {
      return jugadores.every((alumno) {
        switch (tipo) {
          case 'completar':
            return CompletarPalabraRepository.getEjerciciosParaAlumno(
              alumno.id,
            ).any((ejercicio) => ejercicio.id == id);
          case 'ordenar':
            return OrdenarPalabraRepository.getEjerciciosParaAlumno(
              alumno.id,
            ).any((ejercicio) => ejercicio.id == id);
          default:
            return AcrosticoRepository.getEjerciciosParaAlumno(
              alumno.id,
            ).any((ejercicio) => ejercicio.id == id);
        }
      });
    }

    for (final ejercicio in CompletarPalabraRepository.getEjercicios()) {
      if (!compartidoPorTodos('completar', ejercicio.id)) continue;
      actividades.add(
        _ActividadMinijuego(
          categoria: 'Lengua',
          titulo: 'Completar palabra',
          pregunta: 'Completa la palabra: ${ejercicio.palabraParaAlumno}',
          respuestaCorrecta: ejercicio.palabraCompleta,
          pista: ejercicio.pista,
          imagenPath: ejercicio.imagenPath,
        ),
      );
    }

    for (final ejercicio in OrdenarPalabraRepository.getEjercicios()) {
      if (!compartidoPorTodos('ordenar', ejercicio.id)) continue;
      actividades.add(
        _ActividadMinijuego(
          categoria: 'Lengua',
          titulo: 'Ordenar palabra',
          pregunta: 'Ordena las letras: ${ejercicio.palabraDesordenada}',
          respuestaCorrecta: ejercicio.palabraCorrecta,
          pista: ejercicio.pista,
          imagenPath: ejercicio.imagenPath,
        ),
      );
    }

    for (final ejercicio in AcrosticoRepository.getEjercicios()) {
      if (!compartidoPorTodos('acrostico', ejercicio.id)) continue;
      actividades.add(
        _ActividadMinijuego(
          categoria: 'Lengua',
          titulo: 'Acróstico: ${ejercicio.titulo}',
          pregunta:
              'Completa las palabras del acróstico en orden: ${ejercicio.palabrasParaAlumno.join(' · ')}',
          respuestaCorrecta: ejercicio.palabras.join(' '),
          pista: ejercicio.pista,
          imagenPath: ejercicio.imagenPath,
        ),
      );
    }

    actividades.addAll(_crearRetosMatematicos());
    return actividades;
  }

  List<_ActividadMinijuego> _crearRetosMatematicos() {
    final actividades = <_ActividadMinijuego>[];
    final generarRetos = <void Function()>[
      () {
        final a = _random.nextInt(10) + 1;
        final b = _random.nextInt(10) + 1;
        actividades.add(_retoNumerico('Suma', '$a + $b', a + b));
      },
      () {
        final a = _random.nextInt(10) + 5;
        final b = _random.nextInt(a + 1);
        actividades.add(_retoNumerico('Resta', '$a − $b', a - b));
      },
      () {
        final a = _random.nextInt(9) + 1;
        final b = _random.nextInt(9) + 1;
        actividades.add(_retoNumerico('Multiplicación', '$a × $b', a * b));
      },
      () {
        final divisor = _random.nextInt(8) + 2;
        final cociente = _random.nextInt(9) + 1;
        actividades.add(
          _retoNumerico(
            'División',
            '${divisor * cociente} ÷ $divisor',
            cociente,
          ),
        );
      },
      () {
        final a = _random.nextInt(10) + 1;
        final b = _random.nextInt(10) + 1;
        actividades.add(
          _retoNumerico('Tablas de multiplicar', '$a × $b', a * b),
        );
      },
    ];
    for (var ronda = 0; ronda < 2; ronda++) {
      for (final generar in generarRetos) {
        generar();
      }
    }

    const preguntasCirculo = [
      (
        '¿Qué objeto de la vida real tiene forma de círculo?',
        'Pelota',
        ['Pelota', 'Libro', 'Mesa'],
      ),
      (
        '¿Cuál de estos objetos suele tener forma circular?',
        'Reloj',
        ['Reloj', 'Puerta', 'Pizarra'],
      ),
      (
        '¿Qué forma tiene una moneda?',
        'Circular',
        ['Circular', 'Cuadrada', 'Triangular'],
      ),
      (
        '¿Qué objeto redondo usas para comer sopa?',
        'Plato',
        ['Cuchara', 'Plato', 'Tenedor'],
      ),
    ];
    actividades.addAll(
      preguntasCirculo.map(
        (pregunta) => _ActividadMinijuego(
          categoria: 'Matemática · Geometría',
          titulo: 'Figuras geométricas',
          pregunta: pregunta.$1,
          respuestaCorrecta: pregunta.$2,
          opciones: pregunta.$3,
        ),
      ),
    );
    return actividades;
  }

  _ActividadMinijuego _retoNumerico(
    String tema,
    String pregunta,
    int respuesta,
  ) {
    return _ActividadMinijuego(
      categoria: 'Matemática · $tema',
      titulo: tema,
      pregunta: 'Resuelve: $pregunta = ?',
      respuestaCorrecta: '$respuesta',
      esNumerica: true,
    );
  }

  Future<void> _verificarRespuesta(String respuesta) async {
    if (_verificando || _respuestaCorrecta || _finalizado) return;
    setState(() => _verificando = true);
    final actividad = _actividades[_indiceActividad];
    final esCorrecta = _normalizar(respuesta) ==
        _normalizar(actividad.respuestaCorrecta);

    await EstadisticaService.registrarRespuesta(
      context,
      actividad: 'Minijuegos · ${actividad.categoria}',
      titulo: actividad.titulo,
      pregunta: actividad.pregunta,
      respuesta: respuesta,
      respuestaCorrecta: actividad.respuestaCorrecta,
      esCorrecta: esCorrecta,
    );
    if (!mounted) return;

    setState(() {
      _verificando = false;
      _respuestaCorrecta = esCorrecta;
      if (!esCorrecta) {
        _respuestaSeleccionada = null;
      }
      _mensaje = esCorrecta
          ? '¡Muy bien, ${_jugadores[_indiceJugador].nombre}! Ganaste 10 puntos.'
          : 'Inténtalo otra vez. Necesitas resolverlo correctamente para avanzar.';
      if (esCorrecta) {
        final alumnoId = _jugadores[_indiceJugador].id;
        _puntajes[alumnoId] = (_puntajes[alumnoId] ?? 0) + 10;
      }
    });
  }

  String _normalizar(String texto) {
    var normalizado = texto.toLowerCase();
    const equivalencias = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
    };
    for (final equivalencia in equivalencias.entries) {
      normalizado = normalizado.replaceAll(equivalencia.key, equivalencia.value);
    }
    return normalizado
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'[.!?;:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _siguienteTurno() async {
    _respuestaController.clear();
    _respuestaSeleccionada = null;
    _mensaje = null;
    _respuestaCorrecta = false;

    if (_indiceJugador + 1 < _jugadores.length) {
      _indiceJugador++;
    } else {
      _indiceJugador = 0;
      _indiceActividad++;
    }

    if (_indiceActividad >= _actividades.length) {
      await _finalizarPartida();
      return;
    }

    await UsuarioRepository.seleccionarAlumno(
      _jugadores[_indiceJugador],
    );
    if (mounted) setState(() {});
  }

  Future<void> _finalizarPartida() async {
    if (_modoMaestra) {
      await UsuarioRepository.restaurarModoMaestra();
    }
    if (!mounted) return;
    setState(() {
      _finalizado = true;
      _mensaje = null;
    });
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alumnoActual = _iniciado && !_finalizado
        ? _jugadores[_indiceJugador]
        : null;
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        title: const Text('Minijuegos de aprendizaje'),
        backgroundColor: const Color(0xFFFFF3E0),
        foregroundColor: const Color(0xFFE65100),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _finalizado
          ? _buildResumen()
          : !_iniciado
          ? _buildConfiguracion()
          : _buildActividad(alumnoActual!),
    );
  }

  Widget _buildConfiguracion() {
    final alumnos = UsuarioRepository.alumnos;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '¿Quiénes van a jugar?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _modoMaestra
              ? 'Elige un estudiante o un grupo. En grupo, cada estudiante responde cada reto por turnos.'
              : 'Completa retos de Matemática y Lengua. Solo avanzarás cuando respondas correctamente.',
        ),
        const SizedBox(height: 20),
        if (_modoMaestra) ...[
          if (alumnos.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Primero registra estudiantes para iniciar.'),
              ),
            )
          else ...[
            const Text(
              'Un estudiante',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Alumno>(
              initialValue: _alumnoIndividual,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Selecciona un estudiante',
              ),
              items: alumnos
                  .map(
                    (alumno) => DropdownMenuItem(
                      value: alumno,
                      child: Text(alumno.nombre),
                    ),
                  )
                  .toList(),
              onChanged: (alumno) => setState(() {
                _alumnoIndividual = alumno;
                _alumnosSeleccionados.clear();
              }),
            ),
            const SizedBox(height: 20),
            const Text(
              'Un grupo por turnos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...alumnos.map(
              (alumno) => CheckboxListTile(
                value: _alumnosSeleccionados.contains(alumno.id),
                title: Text(alumno.nombre),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (seleccionado) => setState(() {
                  if (seleccionado == true) {
                    _alumnosSeleccionados.add(alumno.id);
                    _alumnoIndividual = null;
                  } else {
                    _alumnosSeleccionados.remove(alumno.id);
                  }
                }),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _alumnosSeleccionados
                  ..clear()
                  ..addAll(alumnos.map((alumno) => alumno.id));
                _alumnoIndividual = null;
              }),
              icon: const Icon(Icons.shuffle),
              label: const Text('Juegan todos (orden aleatorio)'),
            ),
          ],
        ] else ...[
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(_alumnoIndividual?.nombre ?? 'No hay estudiante activo'),
            subtitle: const Text('Puntaje individual'),
          ),
        ],
        if (_mensaje != null) ...[
          const SizedBox(height: 12),
          Text(_mensaje!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: (_modoMaestra && alumnos.isEmpty) ? null : _comenzar,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Comenzar aprendizaje'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Los retos se mezclan al azar. Los libros no forman parte de este minijuego.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildActividad(Alumno alumno) {
    final actividad = _actividades[_indiceActividad];
    final progreso =
        ((_indiceActividad * _jugadores.length + _indiceJugador) /
                (_actividades.length * _jugadores.length))
            .clamp(0.0, 1.0)
            .toDouble();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LinearProgressIndicator(value: progreso),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Chip(label: Text(actividad.categoria)),
            Text(
              'Actividad ${_indiceActividad + 1}/${_actividades.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (_jugadores.length > 1)
          Card(
            color: const Color(0xFFE1F5FE),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text('Turno de ${alumno.nombre}'),
              subtitle: Text(
                'Estudiante ${_indiceJugador + 1} de ${_jugadores.length}',
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          actividad.titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        if (actividad.imagenPath.isNotEmpty) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ImagenEjercicioWidget(
                imagenPath: actividad.imagenPath,
                width: 180,
                height: 140,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Text(
              actividad.pregunta,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21),
            ),
          ),
        ),
        if (actividad.opciones.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...actividad.opciones.map(
            (opcion) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed:
                    _respuestaCorrecta ||
                        _respuestaSeleccionada != null ||
                        _verificando
                    ? null
                    : () {
                        setState(() => _respuestaSeleccionada = opcion);
                        _verificarRespuesta(opcion);
                      },
                child: Text(opcion, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          TextField(
            controller: _respuestaController,
            enabled: !_respuestaCorrecta && !_verificando,
            keyboardType: actividad.esNumerica
                ? TextInputType.number
                : TextInputType.text,
            textCapitalization: actividad.esNumerica
                ? TextCapitalization.none
                : TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Tu respuesta',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: _respuestaController.clear,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
            onSubmitted: (respuesta) => _verificarRespuesta(respuesta),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _respuestaCorrecta || _verificando
                ? null
                : () => _verificarRespuesta(_respuestaController.text),
            child: const Text('Comprobar respuesta'),
          ),
        ],
        if (actividad.pista.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Pista: ${actividad.pista}', textAlign: TextAlign.center),
        ],
        if (_mensaje != null) ...[
          const SizedBox(height: 16),
          Text(
            _mensaje!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _respuestaCorrecta
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE65100),
            ),
          ),
        ],
        if (_respuestaCorrecta) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _siguienteTurno,
            icon: const Icon(Icons.arrow_forward),
            label: Text(_etiquetaSiguiente()),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Puntaje de ${alumno.nombre}: ${_puntajes[alumno.id] ?? 0}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _etiquetaSiguiente() {
    if (_indiceJugador + 1 < _jugadores.length) {
      return 'Siguiente estudiante';
    }
    if (_indiceActividad + 1 == _actividades.length) {
      return 'Ver resultados';
    }
    return 'Siguiente actividad';
  }

  Widget _buildResumen() {
    final ordenados = [..._jugadores]
      ..sort(
        (a, b) => (_puntajes[b.id] ?? 0).compareTo(_puntajes[a.id] ?? 0),
      );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.emoji_events, size: 72, color: Color(0xFFFFA000)),
        const SizedBox(height: 12),
        const Text(
          '¡Minijuego completado!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Se completaron ${_actividades.length} actividades. Cada respuesta correcta suma 10 puntos.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ...ordenados.map(
          (alumno) => Card(
            child: ListTile(
              leading: const Icon(Icons.star, color: Color(0xFFFFA000)),
              title: Text(alumno.nombre),
              trailing: Text(
                '${_puntajes[alumno.id] ?? 0} puntos',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver al menú'),
        ),
      ],
    );
  }
}

class _ActividadMinijuego {
  final String categoria;
  final String titulo;
  final String pregunta;
  final String respuestaCorrecta;
  final String pista;
  final String imagenPath;
  final List<String> opciones;
  final bool esNumerica;

  const _ActividadMinijuego({
    required this.categoria,
    required this.titulo,
    required this.pregunta,
    required this.respuestaCorrecta,
    this.pista = '',
    this.imagenPath = '',
    this.opciones = const [],
    this.esNumerica = false,
  });
}
