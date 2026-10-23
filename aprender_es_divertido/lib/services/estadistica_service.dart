import 'package:flutter/material.dart';

import '../models/estadistica_model.dart';

class EstadisticaService {
  static Future<void> registrarRespuesta(
    BuildContext context, {
    required String actividad,
    required String titulo,
    required String pregunta,
    required String respuesta,
    required String respuestaCorrecta,
    required bool esCorrecta,
  }) async {
    try {
      await EstadisticaRepository.registrarRespuesta(
        actividad: actividad,
        titulo: titulo,
        pregunta: pregunta,
        respuesta: respuesta,
        respuestaCorrecta: respuestaCorrecta,
        esCorrecta: esCorrecta,
      );
    } catch (error) {
      debugPrint('Error al guardar una respuesta del alumno: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar esta respuesta en las estadísticas.',
          ),
        ),
      );
    }
  }
}
