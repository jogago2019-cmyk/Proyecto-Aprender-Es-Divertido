import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aprender_es_divertido/models/acrostico_model.dart';
import 'package:aprender_es_divertido/models/user_model.dart';
import 'package:aprender_es_divertido/services/imagen_service.dart';
import 'package:aprender_es_divertido/widgets/imagen_ejercicio_widget.dart';
import 'package:aprender_es_divertido/widgets/acceso_maestra_denegado.dart';

class CrearAcrosticoScreen extends StatefulWidget {
  final bool devolverEjercicioAlGuardar;

  const CrearAcrosticoScreen({
    super.key,
    this.devolverEjercicioAlGuardar = false,
  });

  @override
  State<CrearAcrosticoScreen> createState() => _CrearAcrosticoScreenState();
}

class _CrearAcrosticoScreenState extends State<CrearAcrosticoScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;

  // Controladores para los campos
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _pistaController = TextEditingController();
  final List<TextEditingController> _palabrasControllers = [];

  // Variables para la imagen
  File? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();

  // Configuraciones del acróstico
  Color _colorSeleccionado = const Color(0xFF6A1B9A); // Morado por defecto
  List<List<int>> _letrasOcultasPorPalabra =
      []; // Lista de índices de letras a ocultar en cada palabra

  // Estado para asignación de alumnos
  int _tipoAsignacion = 0; // 0 = Todos, 1 = Específicos
  List<String> _alumnosSeleccionados = [];

  bool get _esParaTodos => _tipoAsignacion == 0;

  @override
  void initState() {
    super.initState();
    // Inicializar con 5 palabras por defecto
    for (int i = 0; i < 5; i++) {
      _palabrasControllers.add(TextEditingController());
      _letrasOcultasPorPalabra.add([]); // Por defecto: no ocultar ninguna letra
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tituloController.dispose();
    _pistaController.dispose();
    for (final controller in _palabrasControllers) {
      controller.dispose();
    }
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

  Future<void> _seleccionarImagen() async {
    _playSound();

    // Verificar permisos
    if (!kIsWeb) {
      // Para Android 13+, necesitamos permisos específicos
      final status = await Permission.photos.request();
      if (!mounted) return;
      if (!status.isGranted) {
        // Intentar con otro permiso para versiones anteriores
        final status2 = await Permission.storage.request();
        if (!mounted) return;
        if (!status2.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Necesitamos permiso para acceder a la biblioteca de fotos',
              ),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      }
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() {
          _imagenSeleccionada = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al seleccionar la imagen')),
        );
      }
    }
  }

  void _removerImagen() {
    _playSound();
    setState(() {
      _imagenSeleccionada = null;
    });
  }

  void _agregarPalabra() {
    _playSound();
    setState(() {
      _palabrasControllers.add(TextEditingController());
      _letrasOcultasPorPalabra.add([]); // Nueva palabra sin letras ocultas
    });
  }

  void _eliminarPalabra(int index) {
    _playSound();
    if (_palabrasControllers.length <= 3) return; // Mínimo 3 palabras

    setState(() {
      _palabrasControllers[index].dispose();
      _palabrasControllers.removeAt(index);
      _letrasOcultasPorPalabra.removeAt(index);
    });
  }

  void _actualizarLetraOculta(int palabraIndex, int letraIndex) {
    _playSound();
    setState(() {
      final indicesOcultos = _letrasOcultasPorPalabra[palabraIndex];

      // Si ya está seleccionada esa letra para esta palabra, deseleccionar
      if (indicesOcultos.contains(letraIndex)) {
        indicesOcultos.remove(letraIndex);
      } else {
        // Agregar la letra a la lista de ocultas
        indicesOcultos.add(letraIndex);
      }
      // Notificar cambio
      _letrasOcultasPorPalabra[palabraIndex] = List.from(indicesOcultos);
    });
  }

  // Obtener las palabras actuales del formulario
  List<String> _obtenerPalabras() {
    return _palabrasControllers
        .map((controller) => controller.text.trim().toUpperCase())
        .where((palabra) => palabra.isNotEmpty)
        .toList();
  }

  // Obtener las letras iniciales del acróstico
  String _obtenerLetrasAcrostico() {
    final palabras = _obtenerPalabras();
    return palabras
        .map((palabra) => palabra.isNotEmpty ? palabra[0].toUpperCase() : '')
        .join();
  }

  bool _validarFormulario() {
    if (_tituloController.text.isEmpty) {
      _mostrarError('Por favor, ingresa un título para el tema');
      return false;
    }

    final palabras = _obtenerPalabras();
    if (palabras.length < 3) {
      _mostrarError('Por favor, ingresa al menos 3 palabras');
      return false;
    }

    if (_imagenSeleccionada == null) {
      _mostrarError('Por favor, selecciona una imagen de cabecera');
      return false;
    }

    return true;
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  Future<void> _guardarEjercicio() async {
    if (!UsuarioRepository.esMaestraLogueada) return;
    _playSound();

    if (!_validarFormulario()) {
      return;
    }

    final titulo = _tituloController.text.trim();
    final pista = _pistaController.text.trim();
    final palabras = _obtenerPalabras();

    // Guardar la imagen con el nombre del título
    final imagenPath = await ImagenService.guardarImagen(
      _imagenSeleccionada!,
      'acrostico_$titulo',
    );

    // Crear el ejercicio
    // Asegurar que _letrasOcultasPorPalabra tenga el mismo largo que palabras
    final letrasOcultasAjustadas = List<List<int>>.from(
      _letrasOcultasPorPalabra,
    );
    while (letrasOcultasAjustadas.length < palabras.length) {
      letrasOcultasAjustadas.add([]);
    }
    // Si hay más elementos que palabras, recortar
    if (letrasOcultasAjustadas.length > palabras.length) {
      letrasOcultasAjustadas.removeRange(
        palabras.length,
        letrasOcultasAjustadas.length,
      );
    }

    // Convertir las listas para guardar solo índices válidos
    final letrasOcultasFinal = letrasOcultasAjustadas
        .map((indices) => indices.toList())
        .toList();

    final ejercicio = AcrosticoEjercicio(
      id: AcrosticoRepository.generarId(),
      titulo: titulo,
      imagenPath: imagenPath,
      palabras: palabras,
      colorLetras: _colorSeleccionado,
      letrasOcultasPorPalabra: letrasOcultasFinal,
      pista: pista.isEmpty ? 'Descubre el mensaje oculto' : pista,
      alumnosAsignados: _alumnosSeleccionados,
      esParaTodos: _esParaTodos,
    );

    // Guardar en el repositorio
    await AcrosticoRepository.agregarEjercicio(ejercicio);

    if (!mounted) return;

    if (widget.devolverEjercicioAlGuardar) {
      Navigator.pop(context, ejercicio);
      return;
    }

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Acróstico guardado con éxito. Título: $titulo')),
    );

    // Limpiar formulario
    _limpiarFormulario();
  }

  void _limpiarFormulario() {
    setState(() {
      _tituloController.clear();
      _pistaController.clear();
      _imagenSeleccionada = null;

      // Limpiar todos los controladores de palabras
      for (final controller in _palabrasControllers) {
        controller.clear();
      }

      // Resetear a 5 palabras vacías
      _palabrasControllers.clear();
      for (int i = 0; i < 5; i++) {
        _palabrasControllers.add(TextEditingController());
      }

      _colorSeleccionado = const Color(0xFF6A1B9A);
      _letrasOcultasPorPalabra = List.generate(
        5,
        (_) => <int>[],
      ); // Resetear a 5 palabras sin ocultar
      _tipoAsignacion = 0;
      _alumnosSeleccionados = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!UsuarioRepository.esMaestraLogueada) {
      return const AccesoMaestraDenegado();
    }
    final palabras = _obtenerPalabras();
    final tienePalabras = palabras.isNotEmpty;
    final letrasAcrostico = _obtenerLetrasAcrostico();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Crear Acróstico',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen seleccionada
              _buildSeccionImagen(),
              const SizedBox(height: 24),

              // Título
              Text(
                'Título del tema',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tituloController,
                decoration: InputDecoration(
                  hintText: 'Ejemplo: El Amor, La Amistad, La Naturaleza',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.title, color: Color(0xFF6A1B9A)),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Color de las letras
              Text(
                'Color de las letras del acróstico',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              _buildSelectorColor(),
              const SizedBox(height: 24),

              // Filas del Acróstico - Letras para ocultar
              Text(
                'Filas del Acróstico',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca una letra en cada fila para marcarla como incógnita (roja con ?).',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              _buildSelectorLetrasPorPalabra(),
              const SizedBox(height: 24),

              // Palabras
              Text(
                'Palabras del acróstico (mínimo 3)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              _buildListaPalabras(),

              if (tienePalabras) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Acróstico actual: ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Wrap(
                      spacing: 4,
                      children: letrasAcrostico
                          .split('')
                          .map(
                            (letra) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _colorSeleccionado,
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
              ],

              const SizedBox(height: 24),

              // Pista
              Text(
                'Pista (opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pistaController,
                decoration: InputDecoration(
                  hintText:
                      'Ejemplo: Descubre el mensaje oculto en las primeras letras',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.lightbulb,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Asignación de alumnos
              _buildSeccionAsignacionAlumnos(),

              const SizedBox(height: 32),

              // Botón guardar
              ElevatedButton(
                onPressed: _guardarEjercicio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Guardar Acróstico',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionImagen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selecciona una imagen de cabecera',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: kIsWeb ? null : _seleccionarImagen,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _imagenSeleccionada == null
                    ? Colors.grey[400]!
                    : Colors.green,
                width: 2,
              ),
            ),
            child: _imagenSeleccionada != null
                ? ImagenEjercicioWidget(
                    imagenPath: _imagenSeleccionada!.path,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text(
                        kIsWeb
                            ? 'Selección de imágenes no disponible en Web'
                            : 'Toca para seleccionar una imagen',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
        if (_imagenSeleccionada != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _removerImagen,
              tooltip: 'Remover imagen',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectorColor() {
    final coloresDisponibles = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      const Color(0xFF6A1B9A), // Morado
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: coloresDisponibles.map((color) {
        final estaSeleccionado = color == _colorSeleccionado;
        return GestureDetector(
          onTap: () {
            _playSound();
            setState(() {
              _colorSeleccionado = color;
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: estaSeleccionado ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
            child: estaSeleccionado
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectorLetrasPorPalabra() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _palabrasControllers.asMap().entries.map((entry) {
        final palabraIndex = entry.key;
        final controller = entry.value;
        final palabra = controller.text.trim().toUpperCase();
        final indicesOcultos = _letrasOcultasPorPalabra[palabraIndex];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Primera letra (del acróstico)
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _colorSeleccionado,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        palabra.isNotEmpty ? palabra[0] : '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    palabra,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  // Indicador de letras ocultas
                  if (indicesOcultos.isNotEmpty && palabra.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ocultas: ${indicesOcultos.map((idx) => idx < palabra.length ? palabra[idx] : '?').join(", ")}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Palabra con letras seleccionables
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: palabra.split('').asMap().entries.map((letterEntry) {
                  final letraIndex = letterEntry.key;
                  final letra = letterEntry.value;
                  final estaOculta = indicesOcultos.contains(letraIndex);

                  return GestureDetector(
                    onTap: () =>
                        _actualizarLetraOculta(palabraIndex, letraIndex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: estaOculta ? Colors.red[400] : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: estaOculta
                              ? Colors.red[600]!
                              : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: estaOculta
                            ? const Icon(
                                Icons.help,
                                size: 16,
                                color: Colors.white,
                              ) // ? para incógnita
                            : Text(
                                letra,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListaPalabras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._palabrasControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Palabra ${index + 1}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixText: '${String.fromCharCode(65 + index)}. ',
                    prefixStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) => setState(() {}),
                ),
              ),
              if (_palabrasControllers.length > 3)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _eliminarPalabra(index),
                  tooltip: 'Eliminar palabra',
                ),
            ],
          );
        }),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _agregarPalabra,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Agregar otra palabra'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.grey[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionAsignacionAlumnos() {
    final alumnos = UsuarioRepository.alumnos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Asignar a:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),

        // Opción para todos
        Card(
          elevation: 0,
          color: _esParaTodos ? Colors.blue[50] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _esParaTodos ? Colors.blue : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _playSound();
              setState(() {
                _tipoAsignacion = 0;
                _alumnosSeleccionados = [];
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _esParaTodos
                            ? const Color(0xFF6A1B9A)
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: _esParaTodos
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF6A1B9A),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Todos los alumnos',
                    style: TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  if (_esParaTodos)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Opción para alumnos específicos
        Card(
          elevation: 0,
          color: !_esParaTodos ? Colors.orange[50] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: !_esParaTodos ? Colors.orange : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _playSound();
              setState(() {
                _tipoAsignacion = 1;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: !_esParaTodos
                            ? Colors.orange[800]!
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: !_esParaTodos
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.orange[800],
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Alumnos específicos',
                    style: TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  if (!_esParaTodos)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.orange,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),

        // Lista de alumnos (solo si no es para todos)
        if (!_esParaTodos && alumnos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange[200]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.orange[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona los alumnos:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: alumnos.map((alumno) {
                    final estaSeleccionado = _alumnosSeleccionados.contains(
                      alumno.id,
                    );
                    return FilterChip(
                      label: Text(alumno.nombre),
                      selected: estaSeleccionado,
                      onSelected: (selected) {
                        _playSound();
                        setState(() {
                          if (selected) {
                            _alumnosSeleccionados.add(alumno.id);
                          } else {
                            _alumnosSeleccionados.remove(alumno.id);
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.orange[200],
                      checkmarkColor: Colors.orange[800],
                      labelStyle: TextStyle(
                        color: estaSeleccionado
                            ? Colors.orange[800]
                            : Colors.grey[700],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        if (!_esParaTodos && alumnos.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'No hay alumnos creados aún. Primero crea alumnos en la gestión de usuarios.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[700],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
