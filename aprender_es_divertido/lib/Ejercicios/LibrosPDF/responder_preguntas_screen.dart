import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aprender_es_divertido/models/pdf_book_model.dart';
import 'package:aprender_es_divertido/services/estadistica_service.dart';

class ResponderPreguntasScreen extends StatefulWidget {
  final LibroPDF libro;

  const ResponderPreguntasScreen({super.key, required this.libro});

  @override
  State<ResponderPreguntasScreen> createState() => _ResponderPreguntasScreenState();
}

class _ResponderPreguntasScreenState extends State<ResponderPreguntasScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;
  
  int _preguntaActual = 0;
  final Map<String, String> _respuestasSeleccionadas = {};
  final Map<String, bool> _preguntasRespondidas = {};
  
  List<PreguntaMultipleChoice> _preguntas = [];

  @override
  void initState() {
    super.initState();
    // Obtener preguntas generales y de todas las páginas
    _preguntas = List.from(widget.libro.preguntas);
    // Ordenar preguntas por página (generales primero, luego por orden de página)
    _preguntas.sort((a, b) {
      if (a.paginaAsociada == -1 && b.paginaAsociada == -1) return 0;
      if (a.paginaAsociada == -1) return -1;
      if (b.paginaAsociada == -1) return 1;
      return a.paginaAsociada.compareTo(b.paginaAsociada);
    });
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

  Future<void> _seleccionarRespuesta(
    String preguntaId,
    String opcionId,
  ) async {
    if (_respuestasSeleccionadas[preguntaId] == opcionId) return;
    _playSound();

    setState(() {
      _respuestasSeleccionadas[preguntaId] = opcionId;
      _preguntasRespondidas[preguntaId] = true;
    });

    final pregunta = _preguntas.firstWhere((item) => item.id == preguntaId);
    final opcion = pregunta.opciones.firstWhere((item) => item.id == opcionId);
    final respuestaCorrecta = pregunta.respuestaCorrecta;
    await EstadisticaService.registrarRespuesta(
      context,
      actividad: 'Preguntas del libro',
      titulo: widget.libro.titulo,
      pregunta: pregunta.textoPregunta,
      respuesta: opcion.texto,
      respuestaCorrecta: respuestaCorrecta?.texto ?? '(sin definir)',
      esCorrecta: pregunta.esOpcionCorrecta(opcionId),
    );
  }

  bool _esRespuestaCorrecta(String preguntaId, String opcionId) {
    final pregunta = _preguntas.firstWhere((p) => p.id == preguntaId);
    return pregunta.esOpcionCorrecta(opcionId);
  }

  void _siguientePregunta() {
    if (_preguntaActual < _preguntas.length - 1) {
      _playSound();
      setState(() => _preguntaActual++);
    }
  }

  void _anteriorPregunta() {
    if (_preguntaActual > 0) {
      _playSound();
      setState(() => _preguntaActual--);
    }
  }

  void _irAPregunta(int index) {
    _playSound();
    setState(() => _preguntaActual = index);
  }

  int get _preguntasRespondidasCount {
    return _respuestasSeleccionadas.length;
  }

  int get _respuestasCorrectasCount {
    int count = 0;
    for (final entry in _respuestasSeleccionadas.entries) {
      if (_esRespuestaCorrecta(entry.key, entry.value)) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final preguntaActual = _preguntas[_preguntaActual];
    final respuestaSeleccionada = _respuestasSeleccionadas[preguntaActual.id];

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3E5F5),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Preguntas: ${widget.libro.titulo}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
      body: Column(
        children: [
          // Progreso
          _buildProgreso(),
          
          // Contenido de la pregunta
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de la pregunta
                  if (preguntaActual.paginaAsociada >= 1)
                    Text(
                      'Pregunta sobre página ${preguntaActual.paginaAsociada}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(height: 8),
                  
                  // Texto de la pregunta
                  Text(
                    preguntaActual.textoPregunta,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Opciones de respuesta
                  Expanded(
                    child: ListView.builder(
                      itemCount: preguntaActual.opciones.length,
                      itemBuilder: (context, index) {
                        final opcion = preguntaActual.opciones[index];
                        final estaSeleccionada = respuestaSeleccionada == opcion.id;
                        final esCorrecta = preguntaActual.esOpcionCorrecta(opcion.id);
                        
                        // Determinar el color de fondo
                        Color? colorFondo;
                        if (estaSeleccionada) {
                          if (esCorrecta) {
                            colorFondo = Colors.green[100];
                          } else {
                            colorFondo = Colors.red[100];
                          }
                        } else if (_respuestasSeleccionadas.containsKey(preguntaActual.id)) {
                          // Si ya se respondió esta pregunta, mostrar la correcta
                          if (esCorrecta) {
                            colorFondo = Colors.green[100];
                          }
                        }
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: colorFondo,
                          elevation: estaSeleccionada ? 4 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: estaSeleccionada 
                                  ? (esCorrecta ? Colors.green : Colors.red)
                                  : Colors.grey[300]!,
                              width: estaSeleccionada ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _seleccionarRespuesta(preguntaActual.id, opcion.id),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Checkbox como selector
                                  Checkbox(
                                    value: estaSeleccionada,
                                    onChanged: (value) => _seleccionarRespuesta(preguntaActual.id, opcion.id),
                                    activeColor: esCorrecta ? Colors.green : Colors.blue,
                                    shape: const CircleBorder(),
                                  ),
                                  const SizedBox(width: 12),
                                  // Texto de la opción
                                  Expanded(
                                    child: Text(
                                      opcion.texto,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: estaSeleccionada 
                                            ? (esCorrecta ? Colors.green[800] : Colors.red[800])
                                            : const Color(0xFF4A4A4A),
                                      ),
                                    ),
                                  ),
                                  // Indicador de correcta
                                  if (esCorrecta && _respuestasSeleccionadas.containsKey(preguntaActual.id))
                                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Navegación
          _buildNavegacion(),
          
          // Explicación (si existe y ya se respondió)
          if (preguntaActual.explicacion != null && 
              _respuestasSeleccionadas.containsKey(preguntaActual.id)) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Card(
                color: const Color(0xFFFFF3E0),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    preguntaActual.explicacion!,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgreso() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Pregunta ${_preguntaActual + 1}/${_preguntas.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A1B9A),
            ),
          ),
          const Spacer(),
          Text(
            'Correctas: $_respuestasCorrectasCount/$_preguntasRespondidasCount',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavegacion() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón anterior
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 24),
            onPressed: _anteriorPregunta,
            disabledColor: Colors.grey[300],
            color: const Color(0xFF6A1B9A),
          ),
          
          // Indicador de progreso visual
          if (_preguntas.length <= 10) ...[
            Row(
              children: List.generate(_preguntas.length, (index) {
                return GestureDetector(
                  onTap: () => _irAPregunta(index),
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _preguntaActual == index 
                          ? const Color(0xFF6A1B9A)
                          : (_respuestasSeleccionadas.containsKey(_preguntas[index].id)
                              ? Colors.green
                              : Colors.grey[300]),
                    ),
                  ),
                );
              }),
            ),
          ] else ...[
            const SizedBox(width: 100),
          ],
          
          // Botón siguiente
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 24),
            onPressed: _siguientePregunta,
            disabledColor: Colors.grey[300],
            color: const Color(0xFF6A1B9A),
          ),
        ],
      ),
    );
  }
}
