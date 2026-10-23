import 'package:flutter/material.dart';

import '../models/estadistica_model.dart';
import '../models/user_model.dart';

class EstadisticaAlumnoScreen extends StatefulWidget {
  const EstadisticaAlumnoScreen({super.key});

  @override
  State<EstadisticaAlumnoScreen> createState() =>
      _EstadisticaAlumnoScreenState();
}

class _EstadisticaAlumnoScreenState extends State<EstadisticaAlumnoScreen> {
  static const _todasLasActividades = 'Todas las actividades';

  Alumno? _alumnoSeleccionado;
  List<RespuestaAlumno> _respuestas = [];
  String _actividadSeleccionada = _todasLasActividades;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      await EstadisticaRepository.init();
      if (!mounted) return;
      setState(() {
        _cargando = false;
        if (_alumnoSeleccionado != null) {
          _respuestas = EstadisticaRepository.paraAlumno(
            _alumnoSeleccionado!.id,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar las estadísticas.';
      });
    }
  }

  void _seleccionarAlumno(Alumno? alumno) {
    setState(() {
      _alumnoSeleccionado = alumno;
      _actividadSeleccionada = _todasLasActividades;
      _respuestas = alumno == null
          ? []
          : EstadisticaRepository.paraAlumno(alumno.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!UsuarioRepository.esMaestraLogueada) {
      return const Scaffold(
        body: Center(child: Text('Esta sección es solo para maestras.')),
      );
    }

    final respuestasFiltradas = _actividadSeleccionada == _todasLasActividades
        ? _respuestas
        : _respuestas
              .where(
                (respuesta) => respuesta.actividad == _actividadSeleccionada,
              )
              .toList();
    final aciertos = respuestasFiltradas
        .where((respuesta) => respuesta.esCorrecta)
        .length;
    final errores = respuestasFiltradas.length - aciertos;
    final puntos = aciertos * 10;
    final actividadesMinijuegos = respuestasFiltradas
        .where((respuesta) => respuesta.actividad.startsWith('Minijuegos ·'))
        .toList();
    final aciertosMinijuegos = actividadesMinijuegos
        .where((respuesta) => respuesta.esCorrecta)
        .length;
    final temas = <String, List<RespuestaAlumno>>{};
    for (final respuesta in respuestasFiltradas) {
      temas.putIfAbsent(respuesta.actividad, () => []).add(respuesta);
    }
    final actividades =
        _respuestas.map((respuesta) => respuesta.actividad).toSet().toList()
          ..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Estadística de alumno'),
        backgroundColor: const Color(0xFFE8F5E9),
        foregroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF81C784)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.insights, color: Colors.white, size: 34),
                      SizedBox(height: 12),
                      Text(
                        'Cada intento cuenta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Revisa respuestas, aciertos y temas que necesitan práctica.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<Alumno>(
                  initialValue: _alumnoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Selecciona un alumno',
                    prefixIcon: const Icon(Icons.person_search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: UsuarioRepository.alumnos
                      .map(
                        (alumno) => DropdownMenuItem(
                          value: alumno,
                          child: Text(alumno.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: _seleccionarAlumno,
                ),
                if (_alumnoSeleccionado != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _actividadSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Filtrar por actividad',
                      prefixIcon: const Icon(Icons.filter_list),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: _todasLasActividades,
                        child: Text(_todasLasActividades),
                      ),
                      ...actividades.map(
                        (actividad) => DropdownMenuItem(
                          value: actividad,
                          child: Text(actividad),
                        ),
                      ),
                    ],
                    onChanged: (actividad) {
                      setState(() {
                        _actividadSeleccionada =
                            actividad ?? _todasLasActividades;
                      });
                    },
                  ),
                ],
                if (UsuarioRepository.alumnos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Todavía no hay alumnos registrados.'),
                  ),
                if (_alumnoSeleccionado != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _ResumenCard(
                          titulo: 'Intentos',
                          valor: '${respuestasFiltradas.length}',
                          icono: Icons.assignment_turned_in,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResumenCard(
                          titulo: 'Aciertos',
                          valor: '$aciertos',
                          icono: Icons.check_circle,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResumenCard(
                          titulo: 'Errores',
                          valor: '$errores',
                          icono: Icons.lightbulb,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ResumenCard(
                          titulo: 'Puntos',
                          valor: '$puntos',
                          icono: Icons.star,
                          color: const Color(0xFFFFA000),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResumenCard(
                          titulo: 'Minijuegos',
                          valor:
                              '$aciertosMinijuegos/${actividadesMinijuegos.length}',
                          icono: Icons.extension,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Progreso por tema',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (temas.isEmpty)
                    const Text('Todavía no hay progreso registrado.')
                  else
                    ...temas.entries.map((tema) {
                      final correctas = tema.value
                          .where((respuesta) => respuesta.esCorrecta)
                          .length;
                      return Card(
                        child: ListTile(
                          title: Text(tema.key),
                          subtitle: LinearProgressIndicator(
                            value: tema.value.isEmpty
                                ? 0
                                : correctas / tema.value.length,
                          ),
                          trailing: Text('$correctas/${tema.value.length}'),
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  Text(
                    'Historial de actividades',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (respuestasFiltradas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'No hay actividades registradas para este filtro.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...respuestasFiltradas.map(
                      (respuesta) => _RespuestaCard(respuesta: respuesta),
                    ),
                ],
              ],
            ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icono, color: color),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          Text(titulo, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _RespuestaCard extends StatelessWidget {
  final RespuestaAlumno respuesta;

  const _RespuestaCard({required this.respuesta});

  @override
  Widget build(BuildContext context) {
    final color = respuesta.esCorrecta
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    respuesta.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(
                  respuesta.esCorrecta ? Icons.check_circle : Icons.cancel,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${respuesta.actividad} • ${respuesta.fecha.toLocal().toString().substring(0, 16)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _mostrarEjercicioRealizado(context, respuesta),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Ver ejercicio realizado'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _mostrarEjercicioRealizado(
  BuildContext context,
  RespuestaAlumno respuesta,
) {
  final color = respuesta.esCorrecta
      ? const Color(0xFF2E7D32)
      : const Color(0xFFC62828);
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(respuesta.actividad),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              respuesta.titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(respuesta.pregunta),
            const SizedBox(height: 16),
            _DetalleRespuesta(
              etiqueta: 'Respuesta del alumno',
              texto: respuesta.respuesta,
              color: color,
            ),
            const SizedBox(height: 10),
            _DetalleRespuesta(
              etiqueta: 'Respuesta correcta',
              texto: respuesta.respuestaCorrecta,
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  respuesta.esCorrecta ? Icons.check_circle : Icons.cancel,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  respuesta.esCorrecta ? 'Correcto' : 'Necesita práctica',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
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

class _DetalleRespuesta extends StatelessWidget {
  final String etiqueta;
  final String texto;
  final Color color;

  const _DetalleRespuesta({
    required this.etiqueta,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
        const SizedBox(height: 4),
        Text(texto.isEmpty ? '(vacía)' : texto),
      ],
    );
  }
}
