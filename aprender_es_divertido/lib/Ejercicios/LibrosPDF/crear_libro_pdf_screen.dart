import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:aprender_es_divertido/models/pdf_book_model.dart';
import 'package:aprender_es_divertido/models/acrostico_model.dart';
import 'package:aprender_es_divertido/Ejercicios/Acrostico/crear_acrostico_screen.dart';
import 'package:aprender_es_divertido/models/user_model.dart';
import 'package:aprender_es_divertido/widgets/acceso_maestra_denegado.dart';

class CrearLibroPDFScreen extends StatefulWidget {
  const CrearLibroPDFScreen({super.key});

  @override
  State<CrearLibroPDFScreen> createState() => _CrearLibroPDFScreenState();
}

class _CrearLibroPDFScreenState extends State<CrearLibroPDFScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;

  // Formulario
  final _formKey = GlobalKey<FormState>();
  String _titulo = '';
  String _rutaPDF = '';
  TipoActividadFinal _tipoActividadFinal = TipoActividadFinal.nada;
  String? _idAcrosticoAsociado;
  bool _esParaTodos = true;
  final List<String> _alumnosAsignados = [];

  // Preguntas
  final List<PreguntaMultipleChoice> _preguntas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
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

  Future<void> _cargarDatosIniciales() async {
    await LibroPDFRepository.init();
    await AcrosticoRepository.init();
  }

  Future<void> _seleccionarPDF() async {
    _playSound();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        if (mounted) {
          setState(() {
            _rutaPDF = result.files.first.path!;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF seleccionado: ${_rutaPDF.split('/').last}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al seleccionar el archivo PDF')),
        );
      }
    }
  }

  void _agregarPregunta() {
    _playSound();

    showDialog(
      context: context,
      builder: (context) => _DialogoAgregarPregunta(
        onPreguntaAgregada: (pregunta) {
          setState(() {
            _preguntas.add(pregunta);
          });
        },
        paginaActual: 1, // Por defecto página 1
      ),
    );
  }

  void _editarPregunta(int index) {
    _playSound();

    showDialog(
      context: context,
      builder: (context) => _DialogoAgregarPregunta(
        onPreguntaAgregada: (pregunta) {
          setState(() {
            _preguntas[index] = pregunta;
          });
        },
        preguntaExistente: _preguntas[index],
        paginaActual: _preguntas[index].paginaAsociada,
      ),
    );
  }

  void _eliminarPregunta(int index) {
    _playSound();

    setState(() {
      _preguntas.removeAt(index);
    });
  }

  Future<void> _seleccionarAcrostico() async {
    _playSound();

    final acrosticos = AcrosticoRepository.getEjercicios();

    if (acrosticos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay acrósticos creados. Crea uno primero.'),
        ),
      );
      return;
    }

    final acrostico = await showDialog<AcrosticoEjercicio>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Acróstico'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: acrosticos.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(acrosticos[index].titulo),
              subtitle: Text(acrosticos[index].letrasAcrostico),
              onTap: () => Navigator.pop(context, acrosticos[index]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (acrostico != null) {
      setState(() {
        _idAcrosticoAsociado = acrostico.id;
      });
    }
  }

  Future<void> _crearAcrostico() async {
    _playSound();

    final acrostico = await Navigator.push<AcrosticoEjercicio>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CrearAcrosticoScreen(devolverEjercicioAlGuardar: true),
      ),
    );

    if (acrostico != null && mounted) {
      setState(() {
        _idAcrosticoAsociado = acrostico.id;
      });
    }
  }

  Future<void> _desasociarAcrostico() async {
    _playSound();
    setState(() {
      _idAcrosticoAsociado = null;
    });
  }

  Future<void> _guardarLibro() async {
    if (!UsuarioRepository.esMaestraLogueada) return;
    if (!_formKey.currentState!.validate()) return;

    if (_rutaPDF.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un archivo PDF')),
      );
      return;
    }
    if (!_esParaTodos && _alumnosAsignados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un alumno o elige todos.'),
        ),
      );
      return;
    }

    _playSound();

    final nuevoLibro = LibroPDF.nuevo(
      titulo: _titulo,
      rutaPDF: _rutaPDF,
      preguntas: _preguntas,
      tipoActividadFinal: _tipoActividadFinal,
      idAcrosticoAsociado: _idAcrosticoAsociado,
      alumnosAsignados: _alumnosAsignados,
      esParaTodos: _esParaTodos,
    );

    try {
      await LibroPDFRepository.agregarLibro(nuevoLibro);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Libro guardado correctamente')),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el libro')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!UsuarioRepository.esMaestraLogueada) {
      return const AccesoMaestraDenegado();
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3E5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Crear Libro PDF',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              const Text(
                'Información del Libro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Título del Libro',
                  hintText: 'Ej: El Quijote, Matemáticas Básicas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.book, color: Color(0xFF6A1B9A)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
                onSaved: (value) => _titulo = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Selector de PDF
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Archivo PDF',
                        hintText: _rutaPDF.isEmpty
                            ? 'Selecciona un archivo PDF'
                            : _rutaPDF.split('/').last,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.picture_as_pdf,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (_rutaPDF.isEmpty) {
                          return 'Debes seleccionar un archivo PDF';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.attach_file,
                      color: Color(0xFF6A1B9A),
                    ),
                    onPressed: _seleccionarPDF,
                    tooltip: 'Seleccionar PDF',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Asignar libro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Disponible para todos los alumnos'),
                      value: _esParaTodos,
                      activeThumbColor: const Color(0xFF6A1B9A),
                      onChanged: (value) {
                        setState(() {
                          _esParaTodos = value;
                          if (value) _alumnosAsignados.clear();
                        });
                      },
                    ),
                    if (!_esParaTodos) ...[
                      const Divider(height: 1),
                      if (UsuarioRepository.alumnos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Primero registra alumnos para poder asignar el libro.',
                          ),
                        )
                      else
                        ...UsuarioRepository.alumnos.map(
                          (alumno) => CheckboxListTile(
                            title: Text(alumno.nombre),
                            value: _alumnosAsignados.contains(alumno.id),
                            activeColor: const Color(0xFF6A1B9A),
                            onChanged: (seleccionado) {
                              setState(() {
                                if (seleccionado == true) {
                                  _alumnosAsignados.add(alumno.id);
                                } else {
                                  _alumnosAsignados.remove(alumno.id);
                                }
                              });
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Configuración de actividad final
              const Text(
                'Actividad Final',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona qué actividad realizar al terminar de leer el libro:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // Selector de tipo de actividad
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: RadioGroup<TipoActividadFinal>(
                    groupValue: _tipoActividadFinal,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _tipoActividadFinal = value);
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<TipoActividadFinal>(
                          title: const Text('Solo lectura (sin actividades)'),
                          subtitle: const Text(
                            'Terminar la lectura sin preguntas ni acróstico',
                          ),
                          value: TipoActividadFinal.nada,
                          activeColor: const Color(0xFF6A1B9A),
                        ),
                        RadioListTile<TipoActividadFinal>(
                          title: const Text('Preguntas de comprensión'),
                          subtitle: Text(
                            '${_preguntas.length} preguntas creadas',
                          ),
                          value: TipoActividadFinal.preguntas,
                          activeColor: const Color(0xFF6A1B9A),
                        ),
                        RadioListTile<TipoActividadFinal>(
                          title: const Text('Acróstico'),
                          subtitle: Text(
                            _idAcrosticoAsociado != null
                                ? 'Acróstico asociado'
                                : 'No hay acróstico seleccionado',
                          ),
                          value: TipoActividadFinal.acrostico,
                          activeColor: const Color(0xFF6A1B9A),
                        ),
                        RadioListTile<TipoActividadFinal>(
                          title: const Text('Preguntas y Acróstico'),
                          subtitle: const Text('Ambas actividades al final'),
                          value: TipoActividadFinal.ambos,
                          activeColor: const Color(0xFF6A1B9A),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botón para asociar acróstico
              if (_tipoActividadFinal == TipoActividadFinal.acrostico ||
                  _tipoActividadFinal == TipoActividadFinal.ambos) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.link),
                      label: _idAcrosticoAsociado != null
                          ? const Text('Cambiar Acróstico')
                          : const Text('Asociar Acróstico'),
                      onPressed: _seleccionarAcrostico,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Acróstico'),
                      onPressed: _crearAcrostico,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (_idAcrosticoAsociado != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text('Desasociar'),
                    onPressed: _desasociarAcrostico,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
              ],

              if (_tipoActividadFinal != TipoActividadFinal.nada) ...[
                const Text(
                  'Preguntas de Comprensión',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Agrega preguntas de multiple choice que aparecerán al final de la lectura:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Pregunta'),
                  onPressed: _agregarPregunta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                if (_preguntas.isNotEmpty) ...[
                  const Text(
                    'Preguntas creadas:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _preguntas.length,
                    itemBuilder: (context, index) {
                      final pregunta = _preguntas[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pregunta ${index + 1}: ${pregunta.textoPregunta}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (pregunta.paginaAsociada >= 1)
                                Text(
                                  'Página: ${pregunta.paginaAsociada}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              Text(
                                'Opciones: ${pregunta.opciones.length} (${pregunta.tieneRespuestaCorrecta ? "Correcta: ${pregunta.respuestaCorrecta?.texto ?? ""}" : "Sin respuesta correcta"})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Editar'),
                                    onPressed: () => _editarPregunta(index),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                    ),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.delete, size: 16),
                                    label: const Text('Eliminar'),
                                    onPressed: () => _eliminarPregunta(index),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // Botón de guardar
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Libro'),
                  onPressed: _guardarLibro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Diálogo para agregar/editar pregunta
class _DialogoAgregarPregunta extends StatefulWidget {
  final Function(PreguntaMultipleChoice) onPreguntaAgregada;
  final PreguntaMultipleChoice? preguntaExistente;
  final int paginaActual;

  const _DialogoAgregarPregunta({
    required this.onPreguntaAgregada,
    this.preguntaExistente,
    this.paginaActual = 1,
  });

  @override
  State<_DialogoAgregarPregunta> createState() =>
      _DialogoAgregarPreguntaState();
}

class _DialogoAgregarPreguntaState extends State<_DialogoAgregarPregunta> {
  final _formKey = GlobalKey<FormState>();
  String _textoPregunta = '';
  int _paginaAsociada = 1;
  final List<OpcionRespuesta> _opciones = [];
  String? _explicacion;

  @override
  void initState() {
    super.initState();
    if (widget.preguntaExistente != null) {
      final pregunta = widget.preguntaExistente!;
      _textoPregunta = pregunta.textoPregunta;
      _paginaAsociada = pregunta.paginaAsociada >= 1
          ? pregunta.paginaAsociada
          : 1;
      _opciones.addAll(pregunta.opciones);
      _explicacion = pregunta.explicacion;
    } else {
      _paginaAsociada = widget.paginaActual;
      // Agregar 2 opciones por defecto
      _opciones.addAll([
        OpcionRespuesta(id: '1', texto: 'Opción 1', esCorrecta: false),
        OpcionRespuesta(id: '2', texto: 'Opción 2', esCorrecta: false),
      ]);
    }
  }

  void _agregarOpcion() {
    setState(() {
      _opciones.add(
        OpcionRespuesta(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          texto: 'Nueva opción',
          esCorrecta: false,
        ),
      );
    });
  }

  void _eliminarOpcion(int index) {
    if (_opciones.length > 2) {
      // Mantener al menos 2 opciones
      setState(() {
        _opciones.removeAt(index);
      });
    }
  }

  void _guardarPregunta() {
    if (!_formKey.currentState!.validate()) return;

    // Verificar que hay al menos una respuesta correcta
    if (!_opciones.any((o) => o.esCorrecta)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes marcar al menos una opción como correcta'),
        ),
      );
      return;
    }

    final pregunta = PreguntaMultipleChoice.nueva(
      textoPregunta: _textoPregunta,
      opciones: _opciones,
      paginaAsociada: _paginaAsociada == -1 ? -1 : _paginaAsociada,
      explicacion: _explicacion?.isNotEmpty == true ? _explicacion : null,
    );

    widget.onPreguntaAgregada(pregunta);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.preguntaExistente != null
            ? 'Editar Pregunta'
            : 'Agregar Pregunta',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _textoPregunta,
                decoration: InputDecoration(
                  labelText: 'Texto de la pregunta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La pregunta es obligatoria';
                  }
                  return null;
                },
                onChanged: (value) => _textoPregunta = value,
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _paginaAsociada.toString(),
                decoration: InputDecoration(
                  labelText: 'Página asociada (-1 para general)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Ej: 1, 2, -1',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final pagina = int.tryParse(value) ?? _paginaAsociada;
                  if (pagina >= -1) {
                    setState(() => _paginaAsociada = pagina);
                  }
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _explicacion,
                decoration: InputDecoration(
                  labelText: 'Explicación (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => _explicacion = value,
              ),
              const SizedBox(height: 16),

              const Text(
                'Opciones de respuesta:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ..._opciones.asMap().entries.map((entry) {
                final index = entry.key;
                final opcion = entry.value;
                return _buildOpcionCard(index, opcion);
              }),

              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar Opción'),
                onPressed: _agregarOpcion,
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardarPregunta,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A1B9A),
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildOpcionCard(int index, OpcionRespuesta opcion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Checkbox para marcar como correcta
            Checkbox(
              value: opcion.esCorrecta,
              onChanged: (value) {
                setState(() {
                  _opciones[index] = opcion.copyWith(
                    esCorrecta: value ?? false,
                  );
                });
              },
              activeColor: const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 8),
            // Texto de la opción
            Expanded(
              child: TextFormField(
                initialValue: opcion.texto,
                decoration: InputDecoration(
                  labelText: 'Opción ${index + 1}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _opciones[index] = opcion.copyWith(texto: value);
                  });
                },
              ),
            ),
            // Botón eliminar
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _eliminarOpcion(index),
              tooltip: 'Eliminar opción',
            ),
          ],
        ),
      ),
    );
  }
}
