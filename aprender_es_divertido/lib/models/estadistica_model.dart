import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'user_model.dart';

class RespuestaAlumno {
  final String id;
  final String alumnoId;
  final String alumnoNombre;
  final String actividad;
  final String titulo;
  final String pregunta;
  final String respuesta;
  final String respuestaCorrecta;
  final bool esCorrecta;
  final DateTime fecha;

  RespuestaAlumno({
    required this.id,
    required this.alumnoId,
    required this.alumnoNombre,
    required this.actividad,
    required this.titulo,
    required this.pregunta,
    required this.respuesta,
    required this.respuestaCorrecta,
    required this.esCorrecta,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'alumnoId': alumnoId,
    'alumnoNombre': alumnoNombre,
    'actividad': actividad,
    'titulo': titulo,
    'pregunta': pregunta,
    'respuesta': respuesta,
    'respuestaCorrecta': respuestaCorrecta,
    'esCorrecta': esCorrecta,
    'fecha': fecha.toIso8601String(),
  };

  factory RespuestaAlumno.fromJson(Map<String, dynamic> json) {
    return RespuestaAlumno(
      id: json['id'] as String? ?? '',
      alumnoId: json['alumnoId'] as String? ?? '',
      alumnoNombre: json['alumnoNombre'] as String? ?? '',
      actividad: json['actividad'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      pregunta: json['pregunta'] as String? ?? '',
      respuesta: json['respuesta'] as String? ?? '',
      respuestaCorrecta: json['respuestaCorrecta'] as String? ?? '',
      esCorrecta: json['esCorrecta'] as bool? ?? false,
      fecha:
          DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class EstadisticaRepository {
  static const String _respuestasKey = 'respuestas_alumnos';
  static List<RespuestaAlumno> _respuestas = [];
  static bool _inicializado = false;

  static Future<void> init() async {
    if (_inicializado) return;

    final prefs = await SharedPreferences.getInstance();
    final datos = prefs.getString(_respuestasKey);
    if (datos != null && datos.isNotEmpty) {
      final lista = jsonDecode(datos) as List<dynamic>;
      _respuestas = lista
          .map(
            (dato) => RespuestaAlumno.fromJson(
              dato as Map<String, dynamic>,
            ),
          )
          .toList();
    }
    _inicializado = true;
  }

  static Future<void> registrarRespuesta({
    required String actividad,
    required String titulo,
    required String pregunta,
    required String respuesta,
    required String respuestaCorrecta,
    required bool esCorrecta,
  }) async {
    await init();
    final alumno = UsuarioRepository.alumnoActual;
    if (alumno == null || UsuarioRepository.esMaestraLogueada) return;

    _respuestas.add(
      RespuestaAlumno(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        alumnoId: alumno.id,
        alumnoNombre: alumno.nombre,
        actividad: actividad,
        titulo: titulo,
        pregunta: pregunta,
        respuesta: respuesta,
        respuestaCorrecta: respuestaCorrecta,
        esCorrecta: esCorrecta,
        fecha: DateTime.now(),
      ),
    );
    await _guardar();
  }

  static List<RespuestaAlumno> paraAlumno(String alumnoId) {
    return _respuestas.where((respuesta) => respuesta.alumnoId == alumnoId)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  static Future<void> eliminarRespuestasAlumno(String alumnoId) async {
    await init();
    _respuestas.removeWhere((respuesta) => respuesta.alumnoId == alumnoId);
    await _guardar();
  }

  static Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = await prefs.setString(
      _respuestasKey,
      jsonEncode(_respuestas.map((respuesta) => respuesta.toJson()).toList()),
    );
    if (!guardado) {
      throw StateError('No se pudieron guardar las respuestas del alumno.');
    }
  }
}
